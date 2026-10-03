package dev.runstick.app

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Toast
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.lifecycleScope
import androidx.lifecycle.repeatOnLifecycle
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import dev.runstick.app.databinding.ActivityWorkoutsBinding
import dev.runstick.app.databinding.ItemWorkoutBinding
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/**
 * Every kept workout, newest first: upload (or upload again), open on Strava, delete.
 * Rows hold summaries only; the full log is read again when one is uploaded.
 */
class WorkoutsActivity : AppCompatActivity() {

    private lateinit var binding: ActivityWorkoutsBinding
    private lateinit var prefs: Prefs
    private val workouts by lazy { workoutStore(this, prefs) }
    private val adapter = Adapter()

    // Connecting from here would bring the OAuth redirect back to a second MainActivity on
    // top of this screen, so point at the main screen's Set up Strava instead.
    private val uploadFlow by lazy {
        UploadFlow(this, prefs) {
            Toast.makeText(this, R.string.workouts_need_strava, Toast.LENGTH_LONG).show()
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityWorkoutsBinding.inflate(layoutInflater)
        setContentView(binding.root)
        prefs = Prefs(this)

        binding.rvWorkouts.layoutManager = LinearLayoutManager(this)
        binding.rvWorkouts.adapter = adapter

        lifecycleScope.launch {
            repeatOnLifecycle(Lifecycle.State.STARTED) {
                // Upload progress, and the Uploaded flag on the row once it lands.
                StravaJobs.state.collect { s ->
                    binding.tvStatus.text = s.status ?: ""
                    binding.tvStatus.visibility = if (s.status == null) View.GONE else View.VISIBLE
                    adapter.notifyDataSetChanged()
                }
            }
        }
    }

    override fun onResume() {
        super.onResume()
        reload()
    }

    private fun reload() {
        lifecycleScope.launch {
            // Same rule as the main screen: mid-run, the newest file is still being written.
            val running = RunService.isRunning
            val list = withContext(Dispatchers.IO) { workouts.summaries(skipNewest = running) }
            adapter.items = list
            adapter.notifyDataSetChanged()
            binding.tvEmpty.visibility = if (list.isEmpty()) View.VISIBLE else View.GONE
        }
    }

    private fun onRowClicked(s: WorkoutSummary) {
        val activityId = prefs.uploadedActivityId(s.startEpochMs)
        var message = workoutSummaryText(this, prefs, s)
        // The row says "trimmed (tap for why)": this dialog is the tap, so explain here.
        prefs.trimmedFromSec(s.startEpochMs)?.let { recorded ->
            message += "\n\n" + trimmedMessage(this, recorded, s.durationSec)
        }
        val builder = AlertDialog.Builder(this)
            .setMessage(message)
            .setPositiveButton(if (activityId == null) R.string.upload_to_strava else R.string.upload_again) { _, _ ->
                upload(s)
            }
            .setNegativeButton(R.string.workout_delete) { _, _ -> confirmDelete(s) }
        if (activityId != null) {
            builder.setNeutralButton(R.string.open_in_strava) { _, _ ->
                openUrl(StravaApi.activityUrl(activityId))
            }
        }
        val dialog = builder.show()
        // Nothing may change under a running upload.
        val busy = StravaJobs.isBusy
        dialog.getButton(AlertDialog.BUTTON_POSITIVE).isEnabled = !busy
        dialog.getButton(AlertDialog.BUTTON_NEGATIVE).isEnabled = !busy
    }

    private fun upload(s: WorkoutSummary) {
        lifecycleScope.launch {
            val log = withContext(Dispatchers.IO) { workouts.load(s.startEpochMs) }
            if (log == null) {
                Toast.makeText(this@WorkoutsActivity, R.string.workout_unreadable, Toast.LENGTH_LONG).show()
                reload()
                return@launch
            }
            uploadFlow.start(log)
        }
    }

    private fun confirmDelete(s: WorkoutSummary) {
        AlertDialog.Builder(this)
            .setTitle(R.string.workout_delete_title)
            .setMessage(R.string.workout_delete_message)
            .setPositiveButton(R.string.workout_delete) { _, _ ->
                if (StravaJobs.isBusy) {
                    Toast.makeText(this, R.string.upload_busy, Toast.LENGTH_SHORT).show()
                    return@setPositiveButton
                }
                lifecycleScope.launch {
                    val ok = withContext(Dispatchers.IO) { workouts.delete(s.startEpochMs) }
                    if (!ok) {
                        Toast.makeText(this@WorkoutsActivity, R.string.workout_delete_failed, Toast.LENGTH_LONG).show()
                    }
                    reload()
                }
            }
            .setNegativeButton(android.R.string.cancel, null)
            .show()
    }

    private inner class Adapter : RecyclerView.Adapter<Adapter.Row>() {
        var items: List<WorkoutSummary> = emptyList()

        inner class Row(val b: ItemWorkoutBinding) : RecyclerView.ViewHolder(b.root)

        override fun onCreateViewHolder(parent: ViewGroup, viewType: Int) =
            Row(ItemWorkoutBinding.inflate(LayoutInflater.from(parent.context), parent, false))

        override fun getItemCount() = items.size

        override fun onBindViewHolder(holder: Row, position: Int) {
            val s = items[position]
            holder.b.tvSummary.text = workoutSummaryText(this@WorkoutsActivity, prefs, s)
            holder.b.tvSummary.setOnClickListener { onRowClicked(s) }
        }
    }
}
