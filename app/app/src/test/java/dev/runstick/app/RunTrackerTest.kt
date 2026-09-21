package dev.runstick.app

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class RunTrackerTest {

    @Test
    fun `elapsed counts whole seconds from start`() {
        val t = RunTracker()
        assertEquals(0, t.elapsedSec(5_000L))

        t.start(10_000L)
        assertEquals(0, t.elapsedSec(10_000L))
        assertEquals(0, t.elapsedSec(10_999L))
        assertEquals(1, t.elapsedSec(11_000L))
        assertEquals(3_723, t.elapsedSec(10_000L + 3_723_000L))
    }

    @Test
    fun `elapsed freezes when the run stops`() {
        val t = RunTracker()
        t.start(0L)
        t.stop(60_000L)
        assertFalse(t.isRunning)
        assertEquals(60, t.elapsedSec(999_000L))
    }

    @Test
    fun `distance integrates speed over the gaps between samples`() {
        val t = RunTracker()
        t.start(0L)
        // 3 m/s for 10 s. The first sample only anchors the clock, so 10 gaps need 11 samples.
        var ms = 0L
        repeat(11) {
            t.onSpeed(3.0, ms)
            ms += 1000L
        }
        assertEquals(30.0, t.distanceMeters(), 1e-9)
        // 30 m = 0.018641 mi -> 1 centi-mile after truncation.
        assertEquals(1, t.distanceCentiMiles())
    }

    @Test
    fun `centi-miles match the protocol unit`() {
        val t = RunTracker()
        t.start(0L)
        var ms = 0L
        t.onSpeed(4.0, ms)
        repeat(2_865) {
            ms += 1000L
            t.onSpeed(4.0, ms)
        }
        assertEquals(11_460.0, t.distanceMeters(), 1e-9)
        // 11 460 m / 1609.344 = 7.1209 mi -> 712, the golden vector's distance.
        assertEquals(712, t.distanceCentiMiles())
    }

    @Test
    fun `a long gap contributes no distance`() {
        val t = RunTracker()
        t.start(0L)
        t.onSpeed(3.0, 0L)
        t.onSpeed(3.0, 1_000L)        // +3 m
        t.onSpeed(3.0, 61_000L)       // 60 s tunnel: unknown ground, adds nothing
        t.onSpeed(3.0, 62_000L)       // +3 m
        assertEquals(6.0, t.distanceMeters(), 1e-9)
    }

    @Test
    fun `the gap limit is tighter than the pace staleness window`() {
        // A sample 8 s late is still a valid fix for pace, but integrating 8 s of assumed
        // speed would invent distance, so the tracker must drop it.
        assertTrue(RunTracker.MAX_GAP_MS < 10_000L)

        val t = RunTracker()
        t.start(0L)
        t.onSpeed(3.0, 0L)
        t.onSpeed(3.0, 4_000L)        // exactly at the limit: counted, +12 m
        t.onSpeed(3.0, 12_000L)       // 8 s later: dropped
        assertEquals(12.0, t.distanceMeters(), 1e-9)
    }

    @Test
    fun `out of order or duplicate timestamps add nothing`() {
        val t = RunTracker()
        t.start(0L)
        t.onSpeed(3.0, 5_000L)
        t.onSpeed(3.0, 5_000L)
        t.onSpeed(3.0, 4_000L)
        assertEquals(0.0, t.distanceMeters(), 1e-9)
    }

    @Test
    fun `samples before start and after stop are dropped`() {
        val t = RunTracker()
        t.onSpeed(3.0, 0L)
        t.onSpeed(3.0, 1_000L)
        assertEquals(0.0, t.distanceMeters(), 1e-9)

        t.start(2_000L)
        assertTrue(t.isRunning)
        t.onSpeed(3.0, 2_000L)
        t.onSpeed(3.0, 3_000L)
        t.stop(3_000L)
        t.onSpeed(3.0, 4_000L)
        assertEquals(3.0, t.distanceMeters(), 1e-9)
    }

    @Test
    fun `start clears a previous run`() {
        val t = RunTracker()
        t.start(0L)
        t.onSpeed(3.0, 0L)
        t.onSpeed(3.0, 1_000L)
        t.start(10_000L)
        assertEquals(0.0, t.distanceMeters(), 1e-9)
        assertEquals(0, t.elapsedSec(10_500L))
    }
}
