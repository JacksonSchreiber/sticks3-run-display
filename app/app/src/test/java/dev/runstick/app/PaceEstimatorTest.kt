package dev.runstick.app

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import kotlin.math.abs

class PaceEstimatorTest {

    /** Feed `count` samples at 1 Hz starting at `startMs`; returns the last timestamp. */
    private fun feed(
        e: PaceEstimator,
        speed: Float,
        count: Int,
        startMs: Long,
        accuracy: Float? = 0.3f,
    ): Long {
        var t = startMs
        repeat(count) {
            e.onSpeed(speed, accuracy, t)
            t += 1000L
        }
        return t - 1000L
    }

    @Test
    fun `steady three metres per second is about 536 seconds per mile`() {
        val e = PaceEstimator()
        val last = feed(e, 3.0f, 20, 10_000L)
        assertEquals(536, e.paceSecPerMile(last))
    }

    @Test
    fun `the first accepted sample seeds the average`() {
        val e = PaceEstimator()
        e.onSpeed(3.0f, 0.3f, 1_000L)
        // No warm-up: one good sample is already usable.
        assertEquals(536, e.paceSecPerMile(1_000L))
        assertTrue(e.hasFix(1_000L))
    }

    @Test
    fun `it converges smoothly rather than jumping`() {
        val e = PaceEstimator()
        feed(e, 3.0f, 20, 0L)
        // One wild-but-plausible sample must not yank the number.
        e.onSpeed(6.0f, 0.3f, 20_000L)
        val speed = e.smoothedSpeedMps(20_000L)!!
        assertTrue("moved toward 6 but nowhere near it: $speed", speed in 3.1..3.9)
    }

    @Test
    fun `samples with poor speed accuracy are ignored`() {
        val e = PaceEstimator()
        feed(e, 3.0f, 20, 0L)
        val before = e.smoothedSpeedMps(19_000L)!!

        // 9 m/s with a 5 m/s sigma: a city-canyon reflection, not a sprint.
        repeat(5) { assertFalse(e.onSpeed(9.0f, 5.0f, 20_000L + it * 1000L)) }

        assertEquals(before, e.smoothedSpeedMps(19_000L)!!, 1e-9)
        // Rejected samples do not refresh the fix either.
        assertFalse(e.hasFix(35_000L))
    }

    @Test
    fun `a missing accuracy estimate is accepted`() {
        val e = PaceEstimator()
        assertTrue(e.onSpeed(3.0f, null, 0L))
        assertEquals(536, e.paceSecPerMile(0L))
    }

    @Test
    fun `stopping gives no pace`() {
        val e = PaceEstimator()
        feed(e, 3.0f, 20, 0L)
        val last = feed(e, 0.0f, 15, 20_000L)
        assertTrue("still has a fix", e.hasFix(last))
        assertNull("standing still must read as --", e.paceSecPerMile(last))
    }

    @Test
    fun `a stale fix gives no pace and no GPS_OK`() {
        val e = PaceEstimator()
        val last = feed(e, 3.0f, 20, 0L)
        assertNotNull(e.paceSecPerMile(last + 9_000L))
        assertTrue(e.hasFix(last + 9_000L))

        assertNull(e.paceSecPerMile(last + 11_000L))
        assertFalse(e.hasFix(last + 11_000L))
    }

    @Test
    fun `no samples at all means no fix`() {
        val e = PaceEstimator()
        assertFalse(e.hasFix(0L))
        assertFalse(e.hasFix(Long.MAX_VALUE / 2))
        assertNull(e.paceSecPerMile(0L))
    }

    @Test
    fun `a gap pulls harder than a one second step`() {
        val quick = PaceEstimator()
        val gapped = PaceEstimator()
        quick.onSpeed(3.0f, 0.3f, 0L)
        gapped.onSpeed(3.0f, 0.3f, 0L)

        quick.onSpeed(4.0f, 0.3f, 1_000L)
        gapped.onSpeed(4.0f, 0.3f, 5_000L)

        val a = quick.smoothedSpeedMps(1_000L)!!
        val b = gapped.smoothedSpeedMps(5_000L)!!
        assertTrue("time-aware alpha did not widen: $a vs $b", b > a)
        assertTrue(abs(a - 3.22) < 0.01)
    }

    @Test
    fun `pace is capped at 59 59`() {
        val e = PaceEstimator()
        // 0.5 m/s is the slowest speed that still counts as moving: 3218 s/mi, under the cap.
        e.onSpeed(0.5f, 0.1f, 0L)
        assertEquals(3219, e.paceSecPerMile(0L))
        assertTrue(e.paceSecPerMile(0L)!! <= PacketEncoder.PACE_MAX)
    }

    @Test
    fun `reset clears everything`() {
        val e = PaceEstimator()
        feed(e, 3.0f, 10, 0L)
        e.reset()
        assertFalse(e.hasFix(9_000L))
        assertNull(e.paceSecPerMile(9_000L))
    }
}
