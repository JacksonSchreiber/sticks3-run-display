package dev.runstick.app

/**
 * Elapsed time and distance for one run.
 *
 * Contract: the tracker trusts whatever it is handed. Deciding which location samples are
 * good enough lives in [PaceEstimator] (accuracy rule); the service only calls [onSpeed]
 * for samples the estimator accepted. Distance is integrated from Doppler speed rather
 * than differenced from fixes, which is both steadier and cheaper.
 */
class RunTracker {

    private var startMs: Long? = null
    private var stopMs: Long? = null
    private var lastSampleMs: Long? = null
    private var meters = 0.0

    val isRunning: Boolean get() = startMs != null && stopMs == null

    fun start(nowMs: Long) {
        startMs = nowMs
        stopMs = null
        lastSampleMs = null
        meters = 0.0
    }

    fun stop(nowMs: Long) {
        if (isRunning) stopMs = nowMs
    }

    fun elapsedSec(nowMs: Long): Int {
        val begin = startMs ?: return 0
        val end = stopMs ?: nowMs
        return ((end - begin).coerceAtLeast(0L) / 1000L).toInt()
    }

    /** Integrate speed over the gap since the previous accepted sample. */
    fun onSpeed(speedMps: Double, timestampMs: Long, maxGapMs: Long = MAX_GAP_MS) {
        if (!isRunning) return
        val previous = lastSampleMs
        lastSampleMs = timestampMs
        // The first sample only anchors the clock - we have no idea what happened before it.
        if (previous == null) return
        val dtMs = timestampMs - previous
        // A long gap is unknown ground (tunnel, dropout); guessing would inflate the total.
        if (dtMs <= 0L || dtMs > maxGapMs) return
        meters += speedMps * (dtMs / 1000.0)
    }

    fun distanceMeters(): Double = meters

    fun distanceCentiMiles(): Int =
        (meters / PaceEstimator.METERS_PER_MILE * 100.0).toInt().coerceIn(0, 0xFFFF)

    companion object {
        /**
         * Deliberately shorter than PaceEstimator's 10 s staleness window: a sample
         * arriving 8 s after the last one is still a usable fix for pace, but assuming
         * the runner held that speed for the whole 8 s would invent distance.
         */
        const val MAX_GAP_MS = 4_000L
    }
}
