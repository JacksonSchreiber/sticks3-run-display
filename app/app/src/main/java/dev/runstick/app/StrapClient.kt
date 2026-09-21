package dev.runstick.app

import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCallback
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattDescriptor
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.bluetooth.BluetoothStatusCodes
import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.HandlerThread
import android.os.SystemClock
import android.util.Log
import java.util.UUID

/**
 * Chest-strap client, written against raw [BluetoothGatt] rather than a BLE library.
 *
 * Strava is reading the same strap on the same phone. Android gives every app its own
 * GATT client multiplexed over one physical link, but the strap's CCCD is a single value
 * on the *device*, shared by everyone. That one fact drives most of the rules here:
 *
 *  - Subscribing writes CCCD 0x0001. That is idempotent, so doing it while Strava already
 *    subscribed changes nothing.
 *  - We NEVER write 0x0000, and never touch the CCCD on teardown. A tidy-looking
 *    "unsubscribe" would stop the strap notifying every app on the phone, and Strava's
 *    heart-rate trace would silently flatline mid-run. Stopping means disconnect() +
 *    close() on our own client and nothing else.
 *  - The CCCD write may fail (already written, busy, not permitted) and that is fine:
 *    arriving notifications are the real proof we are subscribed, not the write result.
 *
 * All GATT calls are made on one dedicated handler thread and issued one at a time
 * (connect -> discoverServices -> setCharacteristicNotification -> writeDescriptor);
 * the Android stack drops overlapping operations silently.
 */
@SuppressLint("MissingPermission") // callers hold BLUETOOTH_CONNECT; checked in MainActivity
class StrapClient(private val context: Context) {

    companion object {
        private const val TAG = "StrapClient"

        val HR_SERVICE: UUID = UUID.fromString("0000180d-0000-1000-8000-00805f9b34fb")
        val HR_MEASUREMENT: UUID = UUID.fromString("00002a37-0000-1000-8000-00805f9b34fb")
        val CCCD: UUID = UUID.fromString("00002902-0000-1000-8000-00805f9b34fb")

        /** A reading older than this is not a heart rate any more. */
        const val MAX_HR_AGE_MS = 5_000L

        /** Some stacks return stale service lists if discovery starts the same instant. */
        private const val DISCOVERY_DELAY_MS = 600L

        private val BACKOFF_MS = longArrayOf(1_000, 2_000, 5_000, 10_000, 20_000, 30_000)

        /** After this many failed re-arms, throw the client away and make a fresh one. */
        private const val HARD_RESET_AFTER = 4
    }

    private val thread = HandlerThread("strap-gatt").apply { start() }
    private val handler = Handler(thread.looper)
    private val adapter: BluetoothAdapter? =
        context.getSystemService(BluetoothManager::class.java)?.adapter

    private var gatt: BluetoothGatt? = null
    private var device: BluetoothDevice? = null
    private var attempts = 0
    private var stopped = true

    @Volatile
    var isLinked = false
        private set

    @Volatile
    private var lastBpm = 0

    @Volatile
    private var lastBpmAtMs = 0L

    /** @param nowMs must be [SystemClock.elapsedRealtime]. */
    fun heartRate(nowMs: Long): Int? {
        val at = lastBpmAtMs
        return if (lastBpm > 0 && at != 0L && nowMs - at <= MAX_HR_AGE_MS) lastBpm else null
    }

    fun start(mac: String) {
        handler.post {
            stopped = false
            attempts = 0
            lastBpm = 0
            lastBpmAtMs = 0L
            device = try {
                adapter?.getRemoteDevice(mac)
            } catch (e: IllegalArgumentException) {
                Log.e(TAG, "bad strap MAC $mac", e)
                null
            }
            openGatt()
        }
    }

    fun stop() {
        handler.post {
            stopped = true
            handler.removeCallbacks(reconnect)
            isLinked = false
            val g = gatt
            gatt = null
            if (g != null) {
                // disconnect() + close() and nothing else. See the class comment.
                g.disconnect()
                handler.postDelayed({ g.close() }, 250L)
            }
        }
    }

    fun release() {
        stop()
        handler.postDelayed({ thread.quitSafely() }, 500L)
    }

    // --- connection ---------------------------------------------------------

    private fun openGatt() {
        val d = device ?: return
        gatt?.close()
        // Connection order rule: go straight to the saved MAC. A strap that Strava is
        // already connected to has stopped advertising, so scanning would never find it -
        // but connectGatt() on the address works either way, because Android just adds
        // our client to the link that already exists.
        gatt = d.connectGatt(context, false, callback, BluetoothDevice.TRANSPORT_LE)
        Log.i(TAG, "connectGatt ${d.address}")
    }

    private val reconnect = Runnable {
        if (stopped) return@Runnable
        val g = gatt
        if (g != null && attempts <= HARD_RESET_AFTER) {
            // gatt.connect() re-arms the existing client with autoConnect semantics: it
            // waits for the strap to come back instead of failing fast, which is what we
            // want mid-run. Some stacks wedge the client though, hence the hard reset.
            if (!g.connect()) openGatt()
        } else {
            openGatt()
        }
    }

    private fun scheduleReconnect() {
        if (stopped) return
        handler.removeCallbacks(reconnect)
        val delay = BACKOFF_MS[attempts.coerceAtMost(BACKOFF_MS.lastIndex)]
        attempts++
        Log.i(TAG, "reconnect in ${delay}ms (attempt $attempts)")
        handler.postDelayed(reconnect, delay)
    }

    // --- GATT callbacks (all delivered on the binder pool, re-posted to our thread) ---

    private val callback = object : BluetoothGattCallback() {

        override fun onConnectionStateChange(g: BluetoothGatt, status: Int, newState: Int) {
            handler.post {
                if (g !== gatt) return@post
                when (newState) {
                    BluetoothProfile.STATE_CONNECTED -> {
                        Log.i(TAG, "connected (status=$status)")
                        attempts = 0
                        handler.postDelayed({
                            if (g === gatt) g.discoverServices()
                        }, DISCOVERY_DELAY_MS)
                    }

                    BluetoothProfile.STATE_DISCONNECTED -> {
                        Log.i(TAG, "disconnected (status=$status)")
                        isLinked = false
                        scheduleReconnect()
                    }
                }
            }
        }

        override fun onServicesDiscovered(g: BluetoothGatt, status: Int) {
            handler.post {
                if (g !== gatt) return@post
                if (status != BluetoothGatt.GATT_SUCCESS) {
                    Log.w(TAG, "service discovery failed: $status")
                    scheduleReconnect()
                    return@post
                }
                val ch = g.getService(HR_SERVICE)?.getCharacteristic(HR_MEASUREMENT)
                if (ch == null) {
                    Log.e(TAG, "device exposes no 0x180D/0x2A37 - wrong device picked?")
                    return@post
                }
                // Local routing only: this tells our own client to deliver the strap's
                // notifications to us. It does not write anything to the strap.
                val routed = g.setCharacteristicNotification(ch, true)
                isLinked = routed
                if (!routed) {
                    Log.w(TAG, "setCharacteristicNotification refused")
                    scheduleReconnect()
                    return@post
                }
                enableCccd(g, ch)
            }
        }

        override fun onDescriptorWrite(g: BluetoothGatt, d: BluetoothGattDescriptor, status: Int) {
            // Informational only. When Strava got here first the strap may answer with an
            // error, and the notifications still flow, so never tear down on this.
            if (status != BluetoothGatt.GATT_SUCCESS) {
                Log.i(TAG, "CCCD write returned $status - harmless if already subscribed")
            }
        }

        override fun onCharacteristicChanged(
            g: BluetoothGatt,
            ch: BluetoothGattCharacteristic,
            value: ByteArray,
        ) {
            if (ch.uuid == HR_MEASUREMENT) onHrPayload(value)
        }

        @Suppress("DEPRECATION")
        override fun onCharacteristicChanged(g: BluetoothGatt, ch: BluetoothGattCharacteristic) {
            // API 31-32 only. From 33 the framework calls the value-carrying overload above,
            // and handling both would double-count every reading.
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) return
            if (ch.uuid == HR_MEASUREMENT) onHrPayload(ch.value)
        }
    }

    @Suppress("DEPRECATION") // the pre-33 writeDescriptor path, kept for API 31-32
    private fun enableCccd(g: BluetoothGatt, ch: BluetoothGattCharacteristic) {
        val cccd = ch.getDescriptor(CCCD)
        if (cccd == null) {
            Log.w(TAG, "no CCCD on 0x2A37; relying on an existing subscription")
            return
        }
        // ENABLE, never DISABLE. See the class comment: this value is shared with Strava.
        val enable = BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE
        val queued = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            g.writeDescriptor(cccd, enable) == BluetoothStatusCodes.SUCCESS
        } else {
            cccd.setValue(enable)
            g.writeDescriptor(cccd)
        }
        Log.i(TAG, "CCCD enable queued=$queued")
    }

    private fun onHrPayload(payload: ByteArray?) {
        val bpm = HeartRateParser.parse(payload) ?: return
        if (bpm <= 0) return
        lastBpm = bpm
        lastBpmAtMs = SystemClock.elapsedRealtime()
        isLinked = true // notifications arriving is the only proof that matters
    }
}
