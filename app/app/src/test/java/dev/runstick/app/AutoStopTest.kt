package dev.runstick.app

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class AutoStopTest {

    @Test
    fun `never stops a run where heart rate was never seen`() {
        val a = AutoStop()
        for (t in 0..10_000) assertFalse(a.onTick(t, null))
    }

    @Test
    fun `a gap of 4 59 does not stop, 5 00 does`() {
        val a = AutoStop()
        assertFalse(a.onTick(100, 140))
        for (t in 101..399) assertFalse("t=$t", a.onTick(t, null))
        assertTrue(a.onTick(400, null))
    }

    @Test
    fun `heart rate returning resets the gap`() {
        val a = AutoStop()
        a.onTick(0, 140)
        for (t in 1..299) assertFalse(a.onTick(t, null))
        assertFalse(a.onTick(300, 150))
        for (t in 301..599) assertFalse("t=$t", a.onTick(t, null))
        assertTrue(a.onTick(600, null))
    }

    @Test
    fun `gap is measured in run time even when ticks skip`() {
        val a = AutoStop()
        a.onTick(10, 140)
        assertFalse(a.onTick(200, null))
        assertTrue(a.onTick(310, null))
    }

    @Test
    fun `reset forgets the last heartbeat`() {
        val a = AutoStop()
        a.onTick(0, 140)
        a.reset()
        assertFalse(a.onTick(1_000, null))
    }
}
