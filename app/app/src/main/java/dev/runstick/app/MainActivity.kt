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
import dev.runstick.app.databinding.DialogStravaSetupBinding
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class MainActivity : AppCompatActivity() {

    private lateinit var binding: ActivityMainBinding
    private lateinit var prefs: Prefs
    private val picker by lazy { DevicePicker(this) }
    private val workouts by lazy { workoutStore(this, prefs) }
    private val uploadFlow by lazy { UploadFlow(this, prefs) { showStravaSetup() } }

    /** Newest recorded workout, loaded off the main thread. */
    private var lastLog: WorkoutLog? = null
    private var wasRunning = false

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

        binding.btnUpload.setOnClickListener { lastLog?.let { uploadFlow.start(it) } }
        binding.btnAllWorkouts.setOnClickListener {
            startActivity(Intent(this, WorkoutsActivity::class.java))
        }
        binding.btnStravaSetup.setOnClickListener { showStravaSetup() }
        binding.btnOpenActivity.setOnClickListener {
            val id = StravaJobs.state.value.activityId ?: return@setOnClickListener
            openUrl(StravaApi.activityUrl(id))
        }

        lifecycleScope.launch {
            repeatOnLifecycle(Lifecycle.State.STARTED) {
                RunService.state.collect { render(it) }
            }
        }
        lifecycleScope.launch {
            repeatOnLifecycle(Lifecycle.State.STARTED) {
                StravaJobs.state.collect { renderStrava(it) }
            }
        }

        // Only a fresh launch: after a rotation the same redirect intent comes back again.
        if (savedInstanceState == null) handleAuthRedirect(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleAuthRedirect(intent)
    }

    override fun onResume() {
        super.onResume()
        renderStatic()
        loadLastWorkout()
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

        // After an auto-stop the service leaves its reason in Prefs until the next run.
        val note = ui.note ?: if (!ui.running) prefs.autoStopNote else null
        binding.tvNote.text = note ?: ""
        binding.tvNote.visibility = if (note == null) View.GONE else View.VISIBLE

        // The service closes the workout file before it publishes running=false.
        if (wasRunning && !ui.running) loadLastWorkout()
        wasRunning = ui.running
        renderWorkout()
    }

    // --- last workout + Strava ----------------------------------------------

    private fun loadLastWorkout() {
        lifecycleScope.launch {
            val running = RunService.isRunning
            lastLog = withContext(Dispatchers.IO) { workouts.latest(skipNewest = running) }
            renderWorkout()
        }
    }

    private fun renderWorkout() {
        val log = lastLog
        binding.tvWorkout.text =
            if (log == null) getString(R.string.no_workout) else workoutSummaryText(this, prefs, log.summary)

        // A run that auto-stop cut back to the last heartbeat says so in both places it is
        // shown, and a tap explains why, so a shorter time than expected is never a mystery.
        val recordedSec = log?.let { prefs.trimmedFromSec(it.startEpochMs) }
        val explain = if (log != null && recordedSec != null) {
            View.OnClickListener { showTrimmedInfo(recordedSec, log.durationSec) }
        } else null
        binding.tvWorkout.setOnClickListener(explain)
        binding.tvWorkout.isClickable = explain != null
        binding.tvTrimmed.setOnClickListener(explain)
        // Under the big time only while that finished, trimmed run is what it is showing.
        val ui = RunService.state.value
        val onScreen = explain != null && !ui.running && ui.elapsedSec > 0 && ui.elapsedSec == log?.durationSec
        binding.tvTrimmed.visibility = if (onScreen) View.VISIBLE else View.GONE
        binding.btnUpload.isEnabled = log != null && !RunService.isRunning && !StravaJobs.isBusy
    }

    private fun showTrimmedInfo(recordedSec: Int, keptSec: Int) {
        AlertDialog.Builder(this)
            .setTitle(R.string.trimmed_title)
            .setMessage(trimmedMessage(this, recordedSec, keptSec))
            .setPositiveButton(android.R.string.ok, null)
            .show()
    }

    private fun renderStrava(s: StravaUi) {
        binding.tvStravaStatus.text = getString(
            if (prefs.stravaConnected) R.string.strava_connected else R.string.strava_not_connected
        )
        binding.tvUploadStatus.text = s.status ?: ""
        binding.tvUploadStatus.visibility = if (s.status == null) View.GONE else View.VISIBLE
        binding.btnOpenActivity.visibility = if (s.activityId == null) View.GONE else View.VISIBLE
        binding.btnStravaSetup.isEnabled = !s.busy
        renderWorkout()
    }

    private fun showStravaSetup() {
        val dialogBinding = DialogStravaSetupBinding.inflate(layoutInflater)
        dialogBinding.etClientId.setText(prefs.clientId ?: "")
        dialogBinding.etClientSecret.setText(prefs.clientSecret ?: "")
        val builder = AlertDialog.Builder(this)
            .setTitle(R.string.strava_setup_title)
            .setView(dialogBinding.root)
            .setPositiveButton(R.string.strava_connect, null)
            .setNeutralButton(android.R.string.cancel, null)
        if (prefs.stravaConnected) {
            builder.setNegativeButton(R.string.strava_disconnect) { _, _ ->
                prefs.clearTokens()
                StravaJobs.disconnected(this)
            }
        }
        val dialog = builder.create()
        dialog.setOnShowListener {
            // Set here rather than in the builder so a validation failure keeps it open.
            dialog.getButton(AlertDialog.BUTTON_POSITIVE).setOnClickListener {
                val id = dialogBinding.etClientId.text?.toString()?.trim().orEmpty()
                val secret = dialogBinding.etClientSecret.text?.toString()?.trim().orEmpty()
                if (id.isEmpty() || secret.isEmpty()) {
                    Toast.makeText(this, R.string.strava_need_credentials, Toast.LENGTH_SHORT).show()
                    return@setOnClickListener
                }
                prefs.clientId = id
                prefs.clientSecret = secret
                dialog.dismiss()
                startAuthorise(id)
            }
        }
        dialog.show()
    }

    private fun startAuthorise(clientId: String) {
        val state = StravaClient.randomHex(16)
        prefs.oauthState = state
        // ACTION_VIEW on the mobile endpoint: the Strava app takes it if installed,
        // otherwise the browser does. Either way the answer comes back to onNewIntent.
        openUrl(StravaApi.authorizeUrl(clientId, state))
    }

    private fun handleAuthRedirect(intent: Intent?) {
        val uri = intent?.data ?: return
        if (intent.action != Intent.ACTION_VIEW || uri.scheme != "runstick") return
        // Relaunching from recents replays the original intent, code and all.
        if (intent.flags and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY != 0) return

        val result = StravaApi.checkRedirect(
            expectedState = prefs.oauthState,
            state = uri.getQueryParameter("state"),
            code = uri.getQueryParameter("code"),
            error = uri.getQueryParameter("error"),
            scope = uri.getQueryParameter("scope"),
        )
        if (result is AuthRedirect.Stale) return
        prefs.oauthState = null // one use: a replay of this intent now fails the check
        when (result) {
            is AuthRedirect.Code -> StravaJobs.connect(this, result.code)
            AuthRedirect.Denied -> StravaJobs.note(getString(R.string.strava_denied))
            AuthRedirect.MissingWriteScope -> StravaJobs.note(getString(R.string.strava_missing_scope))
            is AuthRedirect.Failed -> StravaJobs.note(getString(R.string.strava_auth_error, result.error))
            AuthRedirect.Stale -> Unit
        }
    }
}
