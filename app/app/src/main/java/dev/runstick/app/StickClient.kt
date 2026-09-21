package dev.runstick.app

import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCharacteristic
import android.content.Context
import android.util.Log
import no.nordicsemi.android.ble.BleManager
import no.nordicsemi.android.ble.ConnectionPriorityRequest
import java.util.UUID

/**
 * RunStick client. Unlike the strap, we own both ends of this link and nothing else on the
 * phone talks to it, so there is no reason to hand-roll the GATT queue: Nordic's BleManager
 * already serialises operations and re-establishes the link after a drop.
 */
class StickClient(context: Context) : BleManager(context) {

    companion object {
        private const val TAG = "StickClient"

        val SERVICE: UUID = UUID.fromString("7a1c0001-5f3e-4b2a-9c6d-2f8e41d0b7a5")
        val DATA: UUID = UUID.fromString("7a1c0002-5f3e-4b2a-9c6d-2f8e41d0b7a5")
        val STATUS: UUID = UUID.fromString("7a1c0003-5f3e-4b2a-9c6d-2f8e41d0b7a5")
    }

    private var dataChar: BluetoothGattCharacteristic? = null
    private var statusChar: BluetoothGattCharacteristic? = null

    @Volatile
    var status: StickStatus? = null
        private set

    override fun getMinLogPriority(): Int = Log.INFO

    override fun log(priority: Int, message: String) {
        Log.println(priority, TAG, message)
    }

    override fun isRequiredServiceSupported(gatt: BluetoothGatt): Boolean {
        val service = gatt.getService(SERVICE) ?: return false
        dataChar = service.getCharacteristic(DATA)
        statusChar = service.getCharacteristic(STATUS)
        return dataChar != null
    }

    override fun initialize() {
        // We write 9 bytes once a second. Low-latency intervals would buy nothing and cost
        // the Stick's small battery real runtime, so ask for balanced explicitly rather
        // than inheriting whatever the last connection left behind.
        requestConnectionPriority(ConnectionPriorityRequest.CONNECTION_PRIORITY_BALANCED).enqueue()

        if (statusChar != null) {
            // Nordic's Data wrapper is confined to this one line; the decoding is pure.
            setNotificationCallback(statusChar).with { _, data ->
                status = StatusDecoder.parse(data.value)
            }
            enableNotifications(statusChar).enqueue()
        }
    }

    override fun onServicesInvalidated() {
        dataChar = null
        statusChar = null
        status = null
    }

    fun connectTo(device: BluetoothDevice) {
        // useAutoConnect: the library still makes the *first* connection with
        // autoConnect=false (a platform quirk), then reconnects with autoConnect=true.
        // That is exactly right here - after a dropout we want the stack to park and
        // resume on its own rather than burn radio on active retries.
        connect(device)
            .useAutoConnect(true)
            .enqueue()
    }

    /** Fire-and-forget: at 1 Hz a dropped packet is replaced 1 s later. */
    fun writeData(packet: ByteArray) {
        val characteristic = dataChar ?: return
        writeCharacteristic(
            characteristic,
            packet,
            BluetoothGattCharacteristic.WRITE_TYPE_NO_RESPONSE,
        ).enqueue()
    }
}
