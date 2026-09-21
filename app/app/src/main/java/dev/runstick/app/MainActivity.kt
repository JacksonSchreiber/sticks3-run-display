package dev.runstick.app

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.provider.Settings
import android.view.View
import android.view.WindowManager
import android.widget.Toast
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.lifecycleScope
import androidx.lifecycle.repeatOnLifecycle
import dev.runstick.app.databinding.ActivityMainBinding
import kotlinx.coroutines.launch

class MainActivity : AppCompatActivity() {

    private lateinit var binding: ActivityMainBinding
    private lateinit var prefs: Prefs
    private val picker by lazy { DevicePicker(this) }

    private val requestPermissions =
        registerForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) {
            renderStatic()
        }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        prefs = Prefs(this)

        binding.swSimulate.isChecked = prefs.simulate
        binding.swSimulate.setOnCheckedChangeListener { _, checked ->
            prefs.simulate = checked
            renderStatic()
        }

        binding.btnPermissions.setOnClickListener { requestMissingPermissions() }

        binding.btnPickStrap.setOnClickListener {
            if (!requireBluetoothPermissions()) return@setOnClickListener
            picker.show(
                title = getString(R.string.pick_strap),
                serviceUuid = StrapClient.HR_SERVICE,
                // A strap Strava already holds is not advertising, so it can only appear
                // in the connected-devices list.
                includeConnected = true,
            ) { entry ->
                prefs.strapMac = entry.mac
                prefs.strapName = entry.name
                renderStatic()
            }
        }

        binding.btnPickStick.setOnClickListener {
            if (!requireBluetoothPermissions()) return@setOnClickListener
            picker.show(
                title = getString(R.string.pick_stick),
                serviceUuid = StickClient.SERVICE,
                includeConnected = false,
            ) { entry ->
                prefs.stickMac = entry.mac
                prefs.stickName = entry.name
                renderStatic()
            }
        }

        binding.btnStart.setOnClickListener { startRun() }
        binding.btnStop.setOnClickListener { RunService.stop(this) }

        binding.btnIgnoreBatteryOptimisations.setOnClickListener { askBatteryExemption() }
        binding.btnAppSettings.setOnClickListener {
            startActivity(
                Intent(
                    Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                    Uri.fromParts("package", packageName, null),
                )
            )
        }

        lifecycleScope.launch {
            repeatOnLifecycle(Lifecycle.State.STARTED) {
                RunService.state.collect { render(it) }
            }
        }
    }

    override fun onResume() {
        super.onResume()
        renderStatic()
    }

    // --- permissions --------------------------------------------------------

    private fun missingPermissions(): List<String> {
        val wanted = mutableListOf(
            Manifest.permission.BLUETOOTH_CONNECT,
            Manifest.permission.BLUETOOTH_SCAN,
        )
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            wanted += Manifest.permission.POST_NOTIFICATIONS
        }
        // Simulate mode needs no location at all: it invents the pace. Bluetooth is still
        // required, because we are still writing to a real Stick.
        if (!prefs.simulate) {
            wanted += Manifest.permission.ACCESS_FINE_LOCATION
            wanted += Manifest.permission.ACCESS_COARSE_LOCATION
        }
        return wanted.filter {
            ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED
        }
    }

    private fun requestMissingPermissions() {
        val missing = missingPermissions()
        if (missing.isEmpty()) {
            Toast.makeText(this, R.string.permissions_ok, Toast.LENGTH_SHORT).show()
            return
        }
        AlertDialog.Builder(this)
            .setTitle(R.string.permission_title)
            .setMessage(R.string.permission_rationale)
            .setPositiveButton(R.string.grant_permissions) { _, _ ->
                requestPermissions.launch(missing.toTypedArray())
            }
            .setNegativeButton(android.R.string.cancel, null)
            .show()
    }

    private fun requireBluetoothPermissions(): Boolean {
        val needed = listOf(
            Manifest.permission.BLUETOOTH_CONNECT,
            Manifest.permission.BLUETOOTH_SCAN,
        ).filter {
            ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED
        }
        if (needed.isEmpty()) return true
        requestPermissions.launch(needed.toTypedArray())
        return false
    }

    // --- start / stop -------------------------------------------------------

    private fun startRun() {
        val missing = missingPermissions()
        if (missing.isNotEmpty()) {
            requestMissingPermissions()
            return
        }
        if (prefs.stickMac == null) {
            Toast.makeText(this, R.string.need_stick, Toast.LENGTH_LONG).show()
            return
        }
        if (!prefs.simulate && prefs.strapMac == null) {
            Toast.makeText(this, R.string.need_strap, Toast.LENGTH_LONG).show()
            return
        }
        // Started from the visible activity on purpose: that is what lets the foreground
        // service use location without ACCESS_BACKGROUND_LOCATION.
        RunService.start(this)
    }

    private fun askBatteryExemption() {
        val power = getSystemService(PowerManager::class.java)
        if (power != null && power.isIgnoringBatteryOptimizations(packageName)) {
            Toast.makeText(this, R.string.battery_already_exempt, Toast.LENGTH_SHORT).show()
            return
        }
        try {
            startActivity(
                Intent(
                    Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                    Uri.parse("package:$packageName"),
                )
            )
        } catch (e: Exception) {
            // Some OEM builds hide this screen; fall back to the app's settings page.
            startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
        }
    }

    // --- rendering ----------------------------------------------------------

    /** Things that change only when the user touches something. */
    private fun renderStatic() {
        val simulate = prefs.simulate
        // Guard the assignment so re-rendering can never re-enter the change listener.
        if (binding.swSimulate.isChecked != simulate) binding.swSimulate.isChecked = simulate

        val strap = prefs.strapName ?: prefs.strapMac
        val stick = prefs.stickName ?: prefs.stickMac
        binding.btnPickStrap.text =
            if (strap == null) getString(R.string.pick_strap) else getString(R.string.strap_named, strap)
        binding.btnPickStick.text =
            if (stick == null) getString(R.string.pick_stick) else getString(R.string.stick_named, stick)

        val missing = missingPermissions()
        binding.btnPermissions.isEnabled = missing.isNotEmpty()
        binding.btnPermissions.text =
            if (missing.isEmpty()) getString(R.string.permissions_ok)
            else getString(R.string.grant_permissions)

        if (!RunService.isRunning) render(RunService.state.value)
    }

    private fun render(ui: UiState) {
        binding.tvHr.text = ui.hrBpm?.toString() ?: "--"
        binding.tvPace.text = formatPace(ui.paceSecPerMile)
        binding.tvElapsed.text = formatElapsed(ui.elapsedSec)
        binding.tvDistance.text = formatDistance(ui.distanceCentiMiles)

        binding.btnStart.isEnabled = !ui.running
        binding.btnStop.isEnabled = ui.running
        binding.swSimulate.isEnabled = !ui.running
        binding.btnPickStrap.isEnabled = !ui.running
        binding.btnPickStick.isEnabled = !ui.running

        binding.tvStrapStatus.text = when {
            ui.simulate -> getString(R.string.strap_simulated)
            ui.strapLinked -> getString(R.string.strap_connected)
            ui.running -> getString(R.string.strap_connecting)
            else -> getString(R.string.strap_idle)
        }
        binding.tvStickStatus.text = when {
            ui.stickLinked -> getString(R.string.stick_connected)
            ui.running -> getString(R.string.stick_connecting)
            else -> getString(R.string.stick_idle)
        }
        binding.tvGpsStatus.text = when {
            ui.simulate -> getString(R.string.gps_simulated)
            ui.gpsOk -> getString(R.string.gps_ok)
            ui.running -> getString(R.string.gps_searching)
            else -> getString(R.string.gps_idle)
        }
        binding.tvBatteryStatus.text = ui.stickBatteryPct?.let {
            if (ui.stickCharging) getString(R.string.stick_battery_charging, it)
            else getString(R.string.stick_battery, it)
        } ?: getString(R.string.stick_battery_unknown)

        binding.tvNote.text = ui.note ?: ""
        binding.tvNote.visibility = if (ui.note == null) View.GONE else View.VISIBLE
    }
}
