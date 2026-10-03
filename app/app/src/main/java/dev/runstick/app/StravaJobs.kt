package dev.runstick.app

import android.content.Context
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.IOException

/** The Strava part of the screen. */
data class StravaUi(
    val busy: Boolean = false,
    val status: String? = null,
    /** Set after a successful upload: the "Open in Strava" target. */
    val activityId: Long? = null,
    /** Bumped when the connection changes, so the screen re-reads Prefs. */
    val revision: Int = 0,
)

/**
 * Token exchange and uploads run here rather than in the activity's scope, so rotating the
 * phone mid-upload doesn't cancel it. Same pattern as [RunService.state].
 */
object StravaJobs {

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private val _state = MutableStateFlow(StravaUi())
    val state: StateFlow<StravaUi> = _state.asStateFlow()

    val isBusy: Boolean get() = _state.value.busy

    fun connect(context: Context, code: String) {
        if (isBusy) return
        val app = context.applicationContext
        val prefs = Prefs(app)
        set(StravaUi(busy = true, status = app.getString(R.string.strava_connecting)))
        scope.launch {
            val status = try {
                StravaClient(prefs).exchangeCode(code)
                app.getString(R.string.strava_connected_ok)
            } catch (e: Exception) {
                app.getString(R.string.strava_connect_failed, describe(app, e))
            }
            set(StravaUi(status = status))
        }
    }

    fun disconnected(context: Context) {
        set(StravaUi(status = context.getString(R.string.strava_disconnected)))
    }

    fun note(status: String) {
        if (!isBusy) set(StravaUi(status = status))
    }

    fun upload(
        context: Context,
        log: WorkoutLog,
        name: String,
        distanceOverrideM: Double?,
        timeOverrideSec: Int?,
        trainer: Boolean,
    ) {
        if (isBusy) return
        val app = context.applicationContext
        val prefs = Prefs(app)
        set(StravaUi(busy = true, status = app.getString(R.string.upload_sending)))
        scope.launch {
            val result = try {
                val tcx = withContext(Dispatchers.Default) {
                    TcxWriter.build(log, distanceOverrideM, timeOverrideSec)
                }
                val fields = StravaApi.uploadFields(
                    name = name,
                    description = UploadDefaults.description(
                        log,
                        distanceTyped = distanceOverrideM != null,
                        timeTyped = timeOverrideSec != null,
                    ),
                    trainer = trainer,
                    startEpochMs = log.startEpochMs,
                    uploadEpochSec = System.currentTimeMillis() / 1000L,
                )
                val activityId = StravaClient(prefs).upload(log.startEpochMs, tcx, fields) {
                    set(_state.value.copy(status = app.getString(R.string.upload_processing)))
                }
                prefs.setUploaded(log.startEpochMs, activityId)
                StravaUi(status = app.getString(R.string.upload_done), activityId = activityId)
            } catch (e: Exception) {
                StravaUi(status = describe(app, e))
            }
            set(result)
        }
    }

    private fun set(ui: StravaUi) {
        _state.value = ui.copy(revision = _state.value.revision + 1)
    }

    private fun describe(context: Context, e: Exception): String = when (e) {
        is StravaException.NotConnected -> context.getString(R.string.strava_err_not_connected)
        is StravaException.NeedsReconnect -> context.getString(R.string.strava_err_reconnect)
        is StravaException.RateLimited -> context.getString(R.string.strava_err_rate_limited)
        is StravaException.StillProcessing -> context.getString(R.string.strava_err_still_processing)
        is StravaException.Rejected -> e.message ?: ""
        is StravaException.Http -> context.getString(R.string.strava_err_http, e.code, e.message)
        is IOException -> context.getString(R.string.strava_err_network)
        else -> e.toString()
    }
}
