package dev.runstick.app

import android.annotation.SuppressLint
import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanFilter
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.os.Handler
import android.os.Looper
import android.os.ParcelUuid
import android.util.Log
import android.widget.ArrayAdapter
import androidx.appcompat.app.AlertDialog
import java.util.UUID

/**
 * Minimal "which device?" dialog. Scanning is stopped on dismiss and capped in time,
 * because a BLE scan left running is one of the fastest ways to flatten a phone battery.
 */
@SuppressLint("MissingPermission") // BLUETOOTH_SCAN / _CONNECT checked before this is shown
class DevicePicker(private val activity: Activity) {

    data class Entry(val name: String, val mac: String, val alreadyConnected: Boolean)

    private val handler = Handler(Looper.getMainLooper())
    private var scanning = false
    private var callback: ScanCallback? = null

    /**
     * @param includeConnected list devices the system already has a GATT link to. Needed
     *        for the strap: once Strava is connected to it the strap stops advertising, so
     *        it can never show up in a scan.
     */
    fun show(
        title: String,
        serviceUuid: UUID,
        includeConnected: Boolean,
        onPicked: (Entry) -> Unit,
    ) {
        val manager = activity.getSystemService(BluetoothManager::class.java)
        val adapter = manager?.adapter
        if (adapter == null || !adapter.isEnabled) {
            AlertDialog.Builder(activity)
                .setTitle(title)
                .setMessage("Turn Bluetooth on first.")
                .setPositiveButton("OK", null)
                .show()
            return
        }

        val entries = mutableListOf<Entry>()
        val seen = mutableSetOf<String>()
        val labels = mutableListOf<String>()
        val rssi = mutableMapOf<String, Int>()

        val listAdapter = ArrayAdapter(activity, android.R.layout.simple_list_item_1, labels)

        fun label(e: Entry) = buildString {
            append(e.name)
            append("\n")
            append(e.mac)
            if (e.alreadyConnected) {
                append("  -  already connected")
            } else {
                rssi[e.mac]?.let { append("  -  ").append(it).append(" dBm") }
            }
        }

        fun add(entry: Entry) {
            if (!seen.add(entry.mac)) {
                // Refresh the RSSI on the row we already have.
                val index = entries.indexOfFirst { it.mac == entry.mac }
                if (index >= 0) {
                    labels[index] = label(entries[index])
                    listAdapter.notifyDataSetChanged()
                }
                return
            }
            entries += entry
            labels += label(entry)
            listAdapter.notifyDataSetChanged()
        }

        if (includeConnected) {
            for (device in manager.getConnectedDevices(BluetoothProfile.GATT)) {
                add(Entry(device.name ?: "(unnamed)", device.address, alreadyConnected = true))
            }
        }

        AlertDialog.Builder(activity)
            .setTitle(title)
            .setAdapter(listAdapter) { _, which -> onPicked(entries[which]) }
            .setNegativeButton("Cancel", null)
            .setOnDismissListener { stopScan(adapter) }
            .show()

        val scanCallback = object : ScanCallback() {
            override fun onScanResult(callbackType: Int, result: ScanResult) {
                val device = result.device ?: return
                val name = result.scanRecord?.deviceName ?: device.name ?: "(unnamed)"
                val address = device.address
                val strength = result.rssi
                // AOSP delivers scan results on the main thread, but that is not
                // contractual and OEM stacks have varied. Touching the adapter off the
                // main thread would crash the picker, so post it and stop worrying.
                handler.post {
                    rssi[address] = strength
                    add(Entry(name, address, alreadyConnected = false))
                }
            }

            override fun onScanFailed(errorCode: Int) {
                Log.w(TAG, "scan failed: $errorCode")
            }
        }
        callback = scanCallback

        val filters = listOf(
            ScanFilter.Builder().setServiceUuid(ParcelUuid(serviceUuid)).build()
        )
        val settings = ScanSettings.Builder()
            .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
            .build()

        try {
            adapter.bluetoothLeScanner?.startScan(filters, settings, scanCallback)
            scanning = true
            handler.postDelayed({ stopScan(adapter) }, SCAN_TIMEOUT_MS)
        } catch (e: SecurityException) {
            Log.e(TAG, "scan refused", e)
        }
    }

    private fun stopScan(adapter: BluetoothAdapter) {
        if (!scanning) return
        scanning = false
        handler.removeCallbacksAndMessages(null)
        try {
            callback?.let { adapter.bluetoothLeScanner?.stopScan(it) }
        } catch (e: SecurityException) {
            Log.e(TAG, "stopScan refused", e)
        }
        callback = null
    }

    private companion object {
        const val TAG = "DevicePicker"
        const val SCAN_TIMEOUT_MS = 20_000L
    }
}
