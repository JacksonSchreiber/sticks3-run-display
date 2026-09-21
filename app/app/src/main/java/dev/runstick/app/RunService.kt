package dev.runstick.app

import android.Manifest
import android.annotation.SuppressLint
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.location.Location
import android.location.LocationManager
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.os.SystemClock
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat
import androidx.core.content.ContextCompat
import androidx.core.location.LocationListenerCompat
import androidx.core.location.LocationManagerCompat
import androidx.core.location.LocationRequestCompat
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import java.util.Locale
import kotlin.math.roundToInt
import kotlin.random.Random

/** Everything the one screen shows. */
data class UiState(
    val running: Boolean = false,
    val simulate: Boolean = false,
    val hrBpm: Int? = null,
    val paceSecPerMile: Int? = null,
    val elapsedSec: Int = 0,
    val distanceCentiMiles: Int = 0,
    val strapLinked: Boolean = false,
    val stickLinked: Boolean = false,
    val gpsOk: Boolean = false,
    val stickBatteryPct: Int? = null,
    val stickCharging: Boolean = false,
    val note: String? = null,
)

// Locale.US throughout: these are the Stick's display formats from the protocol doc, not
// prose, and a comma decimal separator would not match what the Stick shows.
fun formatPace(secPerMile: Int?): String =
    if (secPerMile == null) "--"
    else String.format(Locale.US, "%d:%02d", secPerMile / 60, secPerMile % 60)

fun formatElapsed(sec: Int): String {
    val h = sec / 3600
    val m = (sec % 3600) / 60
    val s = sec % 60
    return if (h > 0) String.format(Locale.US, "%d:%02d:%02d", h, m, s)
    else String.format(Locale.US, "%d:%02d", m, s)
}

fun formatDistance(centiMiles: Int): String =
    String.format(Locale.US, "%.2f mi", centiMiles / 100.0)

/**
 * Owns the strap, the Stick and GPS, and ticks once a second for the length of a run.
 *
 * Started only from the visible activity. That matters: a foreground service started while
 * the app is in the foreground may use location without ACCESS_BACKGROUND_LOCATION, which
 * is why that permission is never requested.
 */
@SuppressLint("MissingPermission") // permissions are checked in MainActivity before start
class RunService : Service() {

    companion object {
        private const val TAG = "RunService"

        const val ACTION_START = "dev.runstick.app.action.START"
        const val ACTION_STOP = "dev.runstick.app.action.STOP"

        private const val CHANNEL_ID = "run"
        private const val NOTIFICATION_ID = 1

        /** Long enough for a three-hour run plus slack; the lock is released on stop anyway. */
        private const val WAKE_LOCK_TIMEOUT_MS = 4L * 60 * 60 * 1000

        /** Stall recovery only - Nordic retries on its own, so don't stack attempts. */
        private const val STICK_RETRY_MS = 12_000L

        private val _state = MutableStateFlow(UiState())
        val state: StateFlow<UiState> = _state.asStateFlow()

        val isRunning: Boolean get() = _state.value.running

        fun start(context: Context) {
            ContextCompat.startForegroundService(
                context,
                Intent(context, RunService::class.java).setAction(ACTION_START),
            )
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, RunService::class.java))
        }
    }

    private val scope = CoroutineScope(Dispatchers.Main.immediate + SupervisorJob())
    private var ticker: Job? = null

    private val prefs by lazy { Prefs(this) }
    private val pace = PaceEstimator()
    private val tracker = RunTracker()
    private val simulator = Simulator()

    private var strap: StrapClient? = null
    private var stick: StickClient? = null
    private var stickDevice: BluetoothDevice? = null
    private var lastStickAttemptMs = 0L

    private var wakeLock: PowerManager.WakeLock? = null
    private var locationManager: LocationManager? = null
    private var locationRequested = false
    private var simulate = false
    private var started = false

    private val locationListener = object : LocationListenerCompat {
        override fun onLocationChanged(location: Location) = onLocation(location)
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopSelf()
            return START_NOT_STICKY
        }
        if (!started) startRun()
        // Never START_STICKY: a system restart would bring the run back with no visible
        // activity, which is exactly the case the background-location exemption excludes.
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        stopRun()
        scope.cancel()
        super.onDestroy()
    }

    // --- run lifecycle ------------------------------------------------------

    private fun startRun() {
        started = true
        simulate = prefs.simulate
        val now = SystemClock.elapsedRealtime()

        createChannel()
        ServiceCompat.startForeground(
            this,
            NOTIFICATION_ID,
            buildNotification(UiState(running = true, simulate = simulate)),
            foregroundTypes(),
        )

        wakeLock = getSystemService(PowerManager::class.java)
            ?.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "runstick:run")
            ?.apply {
                setReferenceCounted(false)
                // Without this the 1 Hz tick stops as soon as the screen goes off and the
                // phone goes into the pocket, which is the whole point of the app.
                acquire(WAKE_LOCK_TIMEOUT_MS)
            }

        tracker.start(now)
        pace.reset()
        simulator.start(now)

        connectStick()
        if (!simulate) {
            connectStrap()
            startLocation()
        }

        ticker = scope.launch { tickLoop() }
    }

    private fun stopRun() {
        if (!started) return
        started = false

        ticker?.cancel()
        ticker = null

        stopLocation()
        strap?.release()
        strap = null
        stick?.let { client ->
            client.disconnect().enqueue()
            client.close()
        }
        stick = null
        stickDevice = null

        tracker.stop(SystemClock.elapsedRealtime())
        wakeLock?.let { if (it.isHeld) it.release() }
        wakeLock = null

        // Keep the finished run's elapsed/distance on screen; only the live values go away.
        _state.value = _state.value.copy(
            running = false,
            hrBpm = null,
            paceSecPerMile = null,
            strapLinked = false,
            stickLinked = false,
            gpsOk = false,
            note = null,
        )
        ServiceCompat.stopForeground(this, ServiceCompat.STOP_FOREGROUND_REMOVE)
    }

    /**
     * FGS type gating on Android 14+ is strict: LOCATION needs fine location granted, and
     * CONNECTED_DEVICE needs a Bluetooth permission. In simulate mode there is no location
     * permission, so we must not claim the LOCATION type at all.
     */
    private fun foregroundTypes(): Int {
        var types = ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE
        if (!simulate && granted(Manifest.permission.ACCESS_FINE_LOCATION)) {
            types = types or ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION
        }
        return types
    }

    private fun granted(permission: String) =
        ContextCompat.checkSelfPermission(this, permission) == PackageManager.PERMISSION_GRANTED

    // --- devices ------------------------------------------------------------

    private fun connectStrap() {
        val mac = prefs.strapMac ?: return
        strap = StrapClient(this).also { it.start(mac) }
    }

    private fun connectStick() {
        val mac = prefs.stickMac ?: return
        val adapter = getSystemService(BluetoothManager::class.java)?.adapter ?: return
        stickDevice = try {
            adapter.getRemoteDevice(mac)
        } catch (e: IllegalArgumentException) {
            Log.e(TAG, "bad Stick MAC $mac", e)
            return
        }
        stick = StickClient(this)
        lastStickAttemptMs = SystemClock.elapsedRealtime()
        stickDevice?.let { stick?.connectTo(it) }
    }

    private fun maybeReconnectStick(nowMs: Long) {
        val client = stick ?: return
        val device = stickDevice ?: return
        if (client.isConnected) return
        if (nowMs - lastStickAttemptMs < STICK_RETRY_MS) return
        lastStickAttemptMs = nowMs
        client.connectTo(device)
    }

    // --- location -----------------------------------------------------------

    private fun startLocation() {
        if (!granted(Manifest.permission.ACCESS_FINE_LOCATION)) return
        val lm = getSystemService(LocationManager::class.java) ?: return
        locationManager = lm
        // Platform LocationManager on purpose: GPS_PROVIDER gives raw Doppler speed at a
        // dependable 1 Hz without dragging in Play Services.
        val request = LocationRequestCompat.Builder(1000L)
            .setMinUpdateIntervalMillis(1000L)
            .setQuality(LocationRequestCompat.QUALITY_HIGH_ACCURACY)
            .build()
        try {
            LocationManagerCompat.requestLocationUpdates(
                lm,
                LocationManager.GPS_PROVIDER,
                request,
                ContextCompat.getMainExecutor(this),
                locationListener,
            )
            locationRequested = true
        } catch (e: SecurityException) {
            Log.e(TAG, "location updates refused", e)
        } catch (e: IllegalArgumentException) {
            Log.e(TAG, "no GPS provider", e)
        }
    }

    private fun stopLocation() {
        if (!locationRequested) return
        locationRequested = false
        locationManager?.let { LocationManagerCompat.removeUpdates(it, locationListener) }
        locationManager = null
    }

    private fun onLocation(location: Location) {
        if (!location.hasSpeed()) return
        // elapsedRealtimeNanos is monotonic; Location.getTime() is GPS wall clock and can
        // step, which would wreck the time-aware smoothing and the distance integral.
        val t = location.elapsedRealtimeNanos / 1_000_000L
        val accuracy =
            if (location.hasSpeedAccuracy()) location.speedAccuracyMetersPerSecond else null
        if (pace.onSpeed(location.speed, accuracy, t)) {
            tracker.onSpeed(location.speed.toDouble(), t)
        }
    }

    // --- the 1 Hz tick ------------------------------------------------------

    private suspend fun tickLoop() {
        var next = SystemClock.elapsedRealtime()
        while (scope.isActive && started) {
            tick()
            next += 1000L
            val sleep = next - SystemClock.elapsedRealtime()
            if (sleep > 0) {
                delay(sleep)
            } else {
                // Fell behind (doze, GC pause): re-anchor instead of spinning to catch up.
                next = SystemClock.elapsedRealtime()
                delay(1000L)
            }
        }
    }

    private fun tick() {
        val now = SystemClock.elapsedRealtime()
        val data = if (simulate) simulator.next(now) else buildData(now)

        // Write every second even when nothing is valid: the Stick distinguishes
        // "connected but no data" from "link lost" by the 5 s packet gap alone.
        stick?.writeData(PacketEncoder.encode(data))
        maybeReconnectStick(now)

        val status = stick?.status
        val ui = UiState(
            running = true,
            simulate = simulate,
            hrBpm = data.hrBpm,
            paceSecPerMile = data.paceSecPerMile,
            elapsedSec = data.elapsedSec,
            distanceCentiMiles = data.distanceCentiMiles,
            strapLinked = data.strapOk,
            stickLinked = stick?.isConnected == true,
            gpsOk = data.gpsOk,
            stickBatteryPct = status?.batteryPct,
            stickCharging = status?.charging == true,
            note = note(),
        )
        _state.value = ui

        getSystemService(NotificationManager::class.java)
            ?.notify(NOTIFICATION_ID, buildNotification(ui))
    }

    private fun buildData(now: Long): RunData = RunData(
        hrBpm = strap?.heartRate(now),
        paceSecPerMile = pace.paceSecPerMile(now),
        elapsedSec = tracker.elapsedSec(now),
        distanceCentiMiles = tracker.distanceCentiMiles(),
        runActive = true,
        gpsOk = pace.hasFix(now),
        strapOk = strap?.isLinked == true,
    )

    private fun note(): String? = when {
        simulate -> null
        prefs.strapMac == null -> "No strap picked"
        prefs.stickMac == null -> "No RunStick picked"
        else -> null
    }

    // --- notification -------------------------------------------------------

    private fun createChannel() {
        val manager = getSystemService(NotificationManager::class.java) ?: return
        if (manager.getNotificationChannel(CHANNEL_ID) != null) return
        manager.createNotificationChannel(
            NotificationChannel(CHANNEL_ID, "Run", NotificationManager.IMPORTANCE_LOW).apply {
                description = "Shows the live run while the screen is off"
                setShowBadge(false)
            }
        )
    }

    private fun buildNotification(ui: UiState): android.app.Notification {
        val flags = PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        val open = PendingIntent.getActivity(
            this, 0, Intent(this, MainActivity::class.java), flags,
        )
        val stop = PendingIntent.getService(
            this,
            1,
            Intent(this, RunService::class.java).setAction(ACTION_STOP),
            flags,
        )

        val title = buildString {
            append(ui.hrBpm?.toString() ?: "--")
            append(" bpm   ")
            append(formatPace(ui.paceSecPerMile))
            append(" /mi")
        }
        val text = buildString {
            append(formatElapsed(ui.elapsedSec))
            append("  ")
            append(formatDistance(ui.distanceCentiMiles))
            append("   ")
            if (ui.simulate) {
                append("simulated")
            } else {
                append(if (ui.strapLinked) "strap ok" else "no strap")
                append(" / ")
                append(if (ui.gpsOk) "gps ok" else "no gps")
            }
            append(" / ")
            append(if (ui.stickLinked) "stick ok" else "no stick")
        }

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_run)
            .setContentTitle(title)
            .setContentText(text)
            .setContentIntent(open)
            .addAction(0, "Stop", stop)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setSilent(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_WORKOUT)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
            .build()
    }

    /**
     * Synthetic data so the Stick can be bench-tested indoors with no strap and no sky:
     * heart rate wandering 120-170, pace wandering 7:30-9:30, everything else ticking.
     */
    private class Simulator {
        private val random = Random(20260921)
        private var hr = 140.0
        private var paceSec = 510.0
        private var startMs = 0L
        private var lastMs = 0L
        private var centiMiles = 0.0

        fun start(nowMs: Long) {
            startMs = nowMs
            lastMs = nowMs
            centiMiles = 0.0
        }

        fun next(nowMs: Long): RunData {
            val dt = (nowMs - lastMs).coerceIn(0L, 5_000L) / 1000.0
            lastMs = nowMs
            hr = (hr + random.nextDouble(-2.0, 2.0)).coerceIn(120.0, 170.0)
            paceSec = (paceSec + random.nextDouble(-4.0, 4.0)).coerceIn(450.0, 570.0)
            centiMiles += 100.0 * dt / paceSec
            return RunData(
                hrBpm = hr.roundToInt(),
                paceSecPerMile = paceSec.roundToInt(),
                elapsedSec = ((nowMs - startMs) / 1000L).toInt(),
                distanceCentiMiles = centiMiles.toInt(),
                runActive = true,
                gpsOk = true,
                strapOk = true,
            )
        }
    }
}
