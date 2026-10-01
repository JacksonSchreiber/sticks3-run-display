package dev.runstick.app

import java.io.BufferedWriter
import java.io.File
import java.io.IOException

/**
 * The workouts folder: `workout_<startEpochMs>.csv`, newest [KEEP] kept. Plain java.io so
 * it runs in JVM tests against a temp folder.
 */
class WorkoutStore(val dir: File) {

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
            val log = try {
                WorkoutLog.parse(f.readText())
            } catch (e: IOException) {
                null
            }
            if (log != null) return log
        }
        return null
    }

    fun prune(keep: Int = KEEP) {
        files().drop(keep).forEach { it.delete() }
    }

    companion object {
        const val KEEP = 10
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

    /**
     * Flushes and closes. A run shorter than [minSec] is deleted; returns whether the file
     * was kept.
     */
    fun finish(minSec: Int = MIN_SEC): Boolean {
        close()
        if (durationSec < minSec) {
            file.delete()
            return false
        }
        return true
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
