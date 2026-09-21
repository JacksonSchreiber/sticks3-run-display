package dev.runstick.app

import kotlin.math.pow
import kotlin.math.roundToInt

/**
 * Smooths `Location.getSpeed()` (Doppler, not position differencing) into a pace.
 *
 * Doppler speed at 1 Hz is already better than differencing fixes, so the only work here
 * is rejecting junk and taking the shake out. All timestamps must come from one monotonic
 * clock - the service feeds `Location.elapsedRealtimeNanos` - because a GPS wall-clock
 * jump would otherwise blow up the time-aware smoothing factor.
 */
class PaceEstimator(
    /** Weight given to a new sample after a 1 s gap; ~0.22 is roughly an 8 s window. */
    private val alphaAt1Hz: Double = 0.22,
    /** Android reports speed accuracy as a 68% confidence sigma; above 1 m/s it is noise. */
    private val maxSpeedAccuracyMps: Float = 1.0f,
    /** Below this the runner is standing still and pace is meaningless. */
    private val minMovingMps: Double = 0.5,
    private val staleAfterMs: Long = 10_000L,
) {

    private var smoothed = 0.0
    private var lastAcceptedMs = 0L
    private var seeded = false

    /**
     * @param speedAccuracyMps null when the fix carries no accuracy estimate.
     * @return true when the sample was accepted, so the caller knows whether to also
     *         integrate it into distance.
     */
    fun onSpeed(speedMps: Float, speedAccuracyMps: Float?, timestampMs: Long): Boolean {
        if (speedMps.isNaN() || speedMps < 0f) return false
        if (speedAccuracyMps != null && speedAccuracyMps > maxSpeedAccuracyMps) return false

        val v = speedMps.toDouble()
        if (!seeded) {
            // Seed on the first good sample instead of easing up from zero: otherwise the
            // first half-minute of every run reads far too slow.
            smoothed = v
            seeded = true
        } else {
            val dt = (timestampMs - lastAcceptedMs).coerceAtLeast(0L) / 1000.0
            // Time-aware: alphaAt1Hz is the weight for a 1 s gap, so a GPS dropout pulls
            // harder when the signal comes back and a burst of samples pulls less.
            val alpha = if (dt <= 0.0) alphaAt1Hz
            else (1.0 - (1.0 - alphaAt1Hz).pow(dt)).coerceIn(0.0, 1.0)
            smoothed += alpha * (v - smoothed)
        }
        lastAcceptedMs = timestampMs
        return true
    }

    /** Drives the GPS_OK flag: we have accepted a sample recently enough to trust. */
    fun hasFix(nowMs: Long): Boolean = seeded && (nowMs - lastAcceptedMs) <= staleAfterMs

    /** @return seconds per mile, or null for "--". */
    fun paceSecPerMile(nowMs: Long): Int? {
        if (!hasFix(nowMs)) return null
        if (smoothed < minMovingMps) return null
        return (METERS_PER_MILE / smoothed).roundToInt().coerceIn(0, PacketEncoder.PACE_MAX)
    }

    fun smoothedSpeedMps(nowMs: Long): Double? = if (hasFix(nowMs)) smoothed else null

    fun reset() {
        smoothed = 0.0
        lastAcceptedMs = 0L
        seeded = false
    }

    companion object {
        const val METERS_PER_MILE = 1609.344
    }
}
