package dev.runstick.app

import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class HrZonesTest {

    @Test
    fun `boundaries are 60 70 80 90 percent rounded up`() {
        assertArrayEquals(intArrayOf(114, 133, 152, 171), HrZones.boundaries(190))
        // 185: 111, 129.5 -> 130, 148, 166.5 -> 167
        assertArrayEquals(intArrayOf(111, 130, 148, 167), HrZones.boundaries(185))
    }

    @Test
    fun `raw zones at the boundaries`() {
        val max = 190
        assertEquals(1, HrZones.rawZone(60, max)) // anything under 60% is still zone 1
        assertEquals(1, HrZones.rawZone(113, max))
        assertEquals(2, HrZones.rawZone(114, max))
        assertEquals(2, HrZones.rawZone(132, max))
        assertEquals(3, HrZones.rawZone(133, max))
        assertEquals(3, HrZones.rawZone(151, max))
        assertEquals(4, HrZones.rawZone(152, max))
        assertEquals(4, HrZones.rawZone(170, max))
        assertEquals(5, HrZones.rawZone(171, max))
        assertEquals(5, HrZones.rawZone(220, max))
    }

    @Test
    fun `first reading takes the raw zone`() {
        assertEquals(4, HrZones().update(152, 190))
        assertEquals(1, HrZones().update(90, 190))
    }

    @Test
    fun `moving up needs 2 bpm past the boundary`() {
        val z = HrZones()
        assertEquals(3, z.update(150, 190))
        assertEquals(3, z.update(152, 190)) // on the Z4 boundary: not yet
        assertEquals(3, z.update(153, 190))
        assertEquals(4, z.update(154, 190))
    }

    @Test
    fun `moving down needs 2 bpm below the boundary`() {
        val z = HrZones()
        assertEquals(4, z.update(160, 190))
        assertEquals(4, z.update(151, 190)) // raw zone 3, but only 1 bpm under 152
        assertEquals(4, z.update(152, 190))
        assertEquals(3, z.update(150, 190))
        // and back up across the same boundary needs 154 again
        assertEquals(3, z.update(153, 190))
        assertEquals(4, z.update(154, 190))
    }

    @Test
    fun `a boundary-hugging heart rate does not flicker`() {
        val z = HrZones()
        z.update(152, 190)
        val seen = listOf(151, 152, 153, 151, 152, 151, 153, 152).map { z.update(it, 190) }.toSet()
        assertEquals(setOf(4), seen)
    }

    @Test
    fun `big jumps cross several zones at once`() {
        val z = HrZones()
        assertEquals(1, z.update(100, 190))
        assertEquals(5, z.update(180, 190))
        assertEquals(1, z.update(100, 190))
    }

    @Test
    fun `no max heart rate or no heart rate means zone 0`() {
        val z = HrZones()
        assertEquals(0, z.update(150, null))
        assertEquals(0, z.update(150, 0))
        assertEquals(0, z.update(null, 190))
        assertEquals(0, z.update(0, 190))
        assertEquals(0, z.update(-5, 190))
    }

    @Test
    fun `invalid readings don't disturb the held zone`() {
        val z = HrZones()
        assertEquals(4, z.update(155, 190))
        assertEquals(0, z.update(null, 190))
        assertEquals(4, z.update(151, 190)) // hysteresis still applies after the dropout
    }

    @Test
    fun `reset starts the next run fresh`() {
        val z = HrZones()
        z.update(160, 190)
        z.reset()
        assertEquals(3, z.update(151, 190))
    }

    @Test
    fun `range text matches the main screen format`() {
        assertEquals("Z1 <114 · Z2 114-132 · Z3 133-151 · Z4 152-170 · Z5 171+", HrZones.rangesText(190))
    }

    @Test
    fun `max heart rate range is 120 to 230`() {
        assertFalse(HrZones.validMaxHr(119))
        assertTrue(HrZones.validMaxHr(120))
        assertTrue(HrZones.validMaxHr(230))
        assertFalse(HrZones.validMaxHr(231))
    }
}
