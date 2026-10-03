package dev.runstick.app

import java.io.BufferedWriter
import java.io.File
import java.io.IOException
import java.nio.file.AtomicMoveNotSupportedException
import java.nio.file.Files
import java.nio.file.StandardCopyOption

/**
 * The workouts folder: `workout_<startEpochMs>.csv`, newest [KEEP] kept. Plain java.io so
 * it runs in JVM tests against a temp folder.
 *
 * @param onRemoved called with the start time of every workout [delete] or [prune] removes,
 *        so per-workout state kept elsewhere (Prefs) goes with it.
 */
class WorkoutStore(val dir: File, private val onRemoved: (Long) -> Unit = {}) {

    fun fileFor(startEpochMs: Long) = File(dir, "workout_$startEpochMs.csv")

    /** Newest first, by the start time in the name (mtime changes on every append). */
    fun files(): List<File> =
        (dir.listFiles() ?: emptyArray())
            .mapNotNull { f -> startOf(f)?.let { it to f } }
            .sortedByDescending { it.first }
            .map { it.second }

    /** @param skipNewest pass true during a run: the newest file is the one being written. */
    fun latest(skipNewest: Boolean = false): WorkoutLog? {
        for (f in files().drop(if (skipNewest) 1 else 0)) {
            val log = read(f)
            if (log != null) return log
        }
        return null
    }

    /** Every readable workout, newest first. Parses each file, so call it off the main thread. */
    fun summaries(skipNewest: Boolean = false): List<WorkoutSummary> =
        files().drop(if (skipNewest) 1 else 0).mapNotNull { read(it)?.summary }

    fun load(startEpochMs: Long): WorkoutLog? = read(fileFor(startEpochMs))

    /** Removes one workout. True if it is gone (including "was never there"). */
    fun delete(startEpochMs: Long): Boolean {
        val f = fileFor(startEpochMs)
        if (f.exists() && !f.delete()) return false
        onRemoved(startEpochMs)
        return true
    }

    fun prune(keep: Int = KEEP) {
        for (f in files().drop(keep)) {
            val start = startOf(f) ?: continue
            if (f.delete()) onRemoved(start)
        }
    }

    private fun read(f: File): WorkoutLog? = try {
        WorkoutLog.parse(f.readText())
    } catch (e: IOException) {
        null
    }

    companion object {
        const val KEEP = 50
        private val NAME = Regex("""workout_(\d+)\.csv""")

        fun startOf(f: File): Long? = NAME.matchEntire(f.name)?.groupValues?.get(1)?.toLongOrNull()
    }
}

/**
 * Appends one run to its file as it happens. Rows are buffered and flushed every
 * [FLUSH_EVERY] samples, so a killed process loses at most a few seconds.
 */
class WorkoutRecorder(
    private val file: File,
    startEpochMs: Long,
    simulated: Boolean,
) {
    private var writer: BufferedWriter? = null
    private var lastT = -1
    private var unflushed = 0

    init {
        file.parentFile?.mkdirs()
        writer = file.bufferedWriter().apply {
            write(WorkoutLog.headerLines(startEpochMs, simulated))
            flush()
        }
    }

    /** Duration in seconds so far (the last sample's t). */
    val durationSec: Int get() = lastT.coerceAtLeast(0)

    fun add(sample: WorkoutSample) {
        val w = writer ?: return
        // The tick loop can repeat a second when it re-anchors; duplicate timestamps would
        // make a broken TCX, whereas a skipped second is harmless.
        if (sample.tSec <= lastT) return
        lastT = sample.tSec
        try {
            w.write(WorkoutLog.sampleLine(sample))
            if (++unflushed >= FLUSH_EVERY) {
                w.flush()
                unflushed = 0
            }
        } catch (e: IOException) {
            // Disk full or similar: stop recording rather than crash the run.
            close()
        }
    }

    /** Distance of the run after a trim in [finish]; null when nothing was trimmed. */
    var trimmedDistanceM: Double? = null
        private set

    /**
     * Flushes and closes. With [trimToLastHr] (auto-stop only) the file is rewritten to end
     * at the last heartbeat. A run shorter than [minSec] after that is deleted.
     * @return the saved run's duration in seconds, or null if it was discarded.
     */
    fun finish(minSec: Int = MIN_SEC, trimToLastHr: Boolean = false): Int? {
        close()
        var duration = durationSec
        if (trimToLastHr) {
            val log = try {
                WorkoutLog.parse(file.readText())
            } catch (e: IOException) {
                null
            }
            val trimmed = log?.trimmedToLastHr()
            if (trimmed != null && trimmed !== log) {
                // On a failed rewrite the untrimmed file stays: too long beats lost.
                if (rewrite(trimmed)) {
                    duration = trimmed.durationSec
                    trimmedDistanceM = trimmed.totalDistanceM
                }
            }
        }
        if (duration < minSec) {
            file.delete()
            return null
        }
        return duration
    }

    /** Temp file + rename, so a crash mid-write can never leave half a workout. */
    private fun rewrite(log: WorkoutLog): Boolean {
        val tmp = File(file.parentFile, file.name + ".tmp")
        return try {
            tmp.writeText(log.serialize())
            try {
                Files.move(
                    tmp.toPath(), file.toPath(),
                    StandardCopyOption.ATOMIC_MOVE, StandardCopyOption.REPLACE_EXISTING,
                )
            } catch (e: AtomicMoveNotSupportedException) {
                Files.move(tmp.toPath(), file.toPath(), StandardCopyOption.REPLACE_EXISTING)
            }
            true
        } catch (e: IOException) {
            tmp.delete()
            false
        }
    }

    private fun close() {
        try {
            writer?.close()
        } catch (e: IOException) {
            // nothing useful to do; what was flushed is still on disk
        }
        writer = null
    }

    companion object {
        const val FLUSH_EVERY = 5
        const val MIN_SEC = 60
    }
}
