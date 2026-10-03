package dev.runstick.app

import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.content.res.ColorStateList
import android.net.Uri
import android.view.View
import android.widget.EditText
import android.widget.Toast
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.core.widget.doAfterTextChanged
import com.google.android.material.color.MaterialColors
import dev.runstick.app.databinding.DialogUploadBinding
import java.io.File
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.time.format.FormatStyle
import java.util.Locale

// Workout bits shared by the main screen and the history screen.

/**
 * The only way to get a [WorkoutStore] in the app, so every delete and prune also drops
 * that workout's Prefs entries (uploaded id, trimmed-from).
 */
fun workoutStore(context: Context, prefs: Prefs): WorkoutStore =
    WorkoutStore(File(context.filesDir, "workouts")) { prefs.forgetWorkout(it) }

/** One line: local date/time · duration · miles · avg HR, then the flags. */
fun workoutSummaryText(context: Context, prefs: Prefs, s: WorkoutSummary): String {
    val start = DateTimeFormatter.ofLocalizedDateTime(FormatStyle.MEDIUM, FormatStyle.SHORT)
        .withZone(ZoneId.systemDefault())
        .format(Instant.ofEpochMilli(s.startEpochMs))
    val miles = String.format(Locale.US, "%.2f mi", s.distanceM / PaceEstimator.METERS_PER_MILE)
    val parts = mutableListOf(start, formatElapsed(s.durationSec), miles)
    parts += s.avgHr?.let { context.getString(R.string.workout_avg_hr, it) }
        ?: context.getString(R.string.workout_no_hr)
    var text = parts.joinToString(" · ")
    if (s.simulated) text += " " + context.getString(R.string.workout_simulated)
    if (prefs.trimmedFromSec(s.startEpochMs) != null) text += " · " + context.getString(R.string.workout_trimmed)
    if (prefs.uploadedActivityId(s.startEpochMs) != null) {
        text += " · " + context.getString(R.string.workout_uploaded)
    }
    return text
}

fun trimmedMessage(context: Context, recordedSec: Int, keptSec: Int): String =
    context.getString(
        R.string.trimmed_message,
        AutoStop.AUTO_STOP_SEC / 60,
        formatElapsed(recordedSec),
        formatElapsed(keptSec),
    )

fun Context.openUrl(url: String) {
    try {
        startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)))
    } catch (e: ActivityNotFoundException) {
        Toast.makeText(this, R.string.strava_no_browser, Toast.LENGTH_LONG).show()
    }
}

/**
 * Upload one workout: the "already uploaded" confirm, then the dialog with name, time,
 * distance/pace and the treadmill box. Works for any [WorkoutLog], from either screen.
 *
 * @param onNotConnected what to do when Strava isn't set up yet (the main screen opens
 *        its setup dialog; history points back to the main screen).
 */
class UploadFlow(
    private val activity: AppCompatActivity,
    private val prefs: Prefs,
    private val onNotConnected: () -> Unit,
) {
    fun start(log: WorkoutLog) {
        if (StravaJobs.isBusy) {
            Toast.makeText(activity, R.string.upload_busy, Toast.LENGTH_SHORT).show()
            return
        }
        if (!prefs.stravaConnected) {
            onNotConnected()
            return
        }
        val oldId = prefs.uploadedActivityId(log.startEpochMs)
        if (oldId == null) {
            showDialog(log)
            return
        }
        AlertDialog.Builder(activity)
            .setTitle(R.string.upload_again_title)
            .setMessage(R.string.upload_again_message)
            .setPositiveButton(R.string.upload_again) { _, _ -> showDialog(log) }
            .setNeutralButton(R.string.upload_open_old) { _, _ ->
                activity.openUrl(StravaApi.activityUrl(oldId))
            }
            .setNegativeButton(android.R.string.cancel, null)
            .show()
    }

    private fun showDialog(log: WorkoutLog) {
        val b = DialogUploadBinding.inflate(activity.layoutInflater)
        val start = TimeDistancePace.forLog(log)
        val calc = start.calc

        b.etName.setText(UploadDefaults.name(log))
        b.etTime.setText(start.time)
        b.etDistance.setText(start.distance)
        b.etPace.setText(start.pace)
        b.cbTreadmill.isChecked = UploadDefaults.treadmill(log)

        val noteColors: ColorStateList = b.tvTimeNote.textColors
        val warnColor = MaterialColors.getColor(b.tvTimeNote, com.google.android.material.R.attr.colorError)
        fun renderNote() {
            when (Stretch.of(log.durationSec, b.etTime.text?.toString().orEmpty())) {
                Stretch.NONE -> b.tvTimeNote.visibility = View.GONE
                Stretch.NOTE -> {
                    b.tvTimeNote.visibility = View.VISIBLE
                    b.tvTimeNote.setTextColor(noteColors)
                }
                Stretch.WARN -> {
                    b.tvTimeNote.visibility = View.VISIBLE
                    b.tvTimeNote.setTextColor(warnColor)
                }
            }
        }

        // One guard for every programmatic setText, so a recomputed box never re-triggers
        // the watcher of the box that caused it. Only real typing changes what is held.
        var programmatic = false
        fun fill(field: EditText, text: String) {
            programmatic = true
            field.setText(text)
            programmatic = false
        }
        b.etTime.doAfterTextChanged { e ->
            if (programmatic) return@doAfterTextChanged
            b.tilTime.error = null
            renderNote()
            val update = calc.onTime(e?.toString().orEmpty()) ?: return@doAfterTextChanged
            when (update.field) {
                TimeDistancePace.Field.DISTANCE -> fill(b.etDistance, update.text)
                TimeDistancePace.Field.PACE -> fill(b.etPace, update.text)
            }
        }
        b.etDistance.doAfterTextChanged { e ->
            if (programmatic) return@doAfterTextChanged
            b.tilDistance.error = null
            b.tilPace.error = null
            calc.onDistance(e?.toString().orEmpty())?.let { fill(b.etPace, it) }
        }
        b.etPace.doAfterTextChanged { e ->
            if (programmatic) return@doAfterTextChanged
            b.tilPace.error = null
            b.tilDistance.error = null
            calc.onPace(e?.toString().orEmpty())?.let { fill(b.etDistance, it) }
        }

        val dialog = AlertDialog.Builder(activity)
            .setTitle(R.string.upload_title)
            .setView(b.root)
            .setPositiveButton(R.string.upload, null)
            .setNegativeButton(android.R.string.cancel, null)
            .create()
        dialog.setOnShowListener {
            // Set here rather than in the builder so a validation failure keeps it open.
            dialog.getButton(AlertDialog.BUTTON_POSITIVE).setOnClickListener {
                if (StravaJobs.isBusy) {
                    Toast.makeText(activity, R.string.upload_busy, Toast.LENGTH_SHORT).show()
                    return@setOnClickListener
                }
                val input = UploadInput.resolve(
                    log,
                    time = b.etTime.text?.toString().orEmpty(),
                    distance = b.etDistance.text?.toString().orEmpty(),
                    pace = b.etPace.text?.toString().orEmpty(),
                    paceHeld = calc.held == TimeDistancePace.Field.PACE,
                )
                when (input) {
                    UploadInput.BadTime -> b.tilTime.error = activity.getString(R.string.upload_need_time)
                    UploadInput.BadPace -> b.tilPace.error = activity.getString(R.string.upload_need_pace)
                    UploadInput.BadDistance -> b.tilDistance.error = activity.getString(R.string.upload_need_distance)
                    is UploadInput.Ok -> {
                        val name = b.etName.text?.toString()?.trim()
                            .takeUnless { it.isNullOrEmpty() } ?: UploadDefaults.name(log)
                        dialog.dismiss()
                        StravaJobs.upload(
                            context = activity,
                            log = log,
                            name = name,
                            distanceOverrideM = input.distanceOverrideM,
                            timeOverrideSec = input.timeOverrideSec,
                            trainer = b.cbTreadmill.isChecked,
                        )
                    }
                }
            }
        }
        renderNote()
        dialog.show()
    }
}
