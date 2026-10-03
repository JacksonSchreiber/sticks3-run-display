package dev.runstick.app

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class UploadFormTest {

    private val mile = PaceEstimator.METERS_PER_MILE

    /** 30:00 with [meters] of recorded distance, HR throughout. */
    private fun log(meters: Double, sec: Int = 1800) = WorkoutLog(
        0L, false, listOf(WorkoutSample(0, 140, 0.0), WorkoutSample(sec, 150, meters)),
    )

    // --- parsing / formatting -----------------------------------------------

    @Test
    fun `time parses mm-ss and h-mm-ss`() {
        assertEquals(1800, TimeText.parseTime("30:00"))
        assertEquals(3930, TimeText.parseTime("1:05:30"))
        assertEquals(330, TimeText.parseTime(" 5:30 "))
        assertEquals(4500, TimeText.parseTime("75:00"))
        assertEquals(1800, TimeText.parseTime("0:30:00"))
    }

    @Test
    fun `time rejects malformed, out of range and zero`() {
        for (bad in listOf("5:75", "", " ", "0:00", "0:00:00", "1:60:00", "30", "30:0", "-1:00", "+5:00",
                "1:2:3", "a:bc", "1:05:30:00", "12345:00", "5:30.5")) {
            assertNull("'$bad'", TimeText.parseTime(bad))
        }
    }

    @Test
    fun `time and pace accept any number pad`() {
        assertEquals(1800, TimeText.parseTime("3000"))
        assertEquals(1800, TimeText.parseTime("30.00"))
        assertEquals(1800, TimeText.parseTime("30,00"))
        assertEquals(1800, TimeText.parseTime("30 00"))
        assertEquals(3930, TimeText.parseTime("10530"))
        assertEquals(3930, TimeText.parseTime("1.05.30"))
        assertEquals(330, TimeText.parseTime("530"))
        assertNull(TimeText.parseTime("575"))          // 5:75
        assertNull(TimeText.parseTime("30"))           // too short to read
        assertEquals(581, TimeText.parsePace("941"))
        assertEquals(581, TimeText.parsePace("9.41"))
        assertEquals(605, TimeText.parsePace("1005"))
        assertNull(TimeText.parsePace("10530"))        // pace over an hour
    }

    @Test
    fun `time formats back to what parses`() {
        for (sec in listOf(59, 60, 330, 1800, 3599, 3600, 3930, 36_000)) {
            assertEquals(sec, TimeText.parseTime(TimeText.formatTime(sec)))
        }
        assertEquals("30:00", TimeText.formatTime(1800))
        assertEquals("1:05:30", TimeText.formatTime(3930))
    }

    @Test
    fun `pace is m-ss only`() {
        assertEquals(510, TimeText.parsePace("8:30"))
        assertNull(TimeText.parsePace("8:60"))
        assertNull(TimeText.parsePace("1:05:30"))
        assertNull(TimeText.parsePace("0:00"))
        assertNull(TimeText.parsePace("8"))
        assertEquals("8:30", TimeText.formatPace(510.4))
        assertEquals("8:31", TimeText.formatPace(510.5))
    }

    @Test
    fun `miles accept a comma and must be positive`() {
        assertEquals(3.1, TimeText.parseMiles("3.1")!!, 1e-12)
        assertEquals(3.1, TimeText.parseMiles("3,1")!!, 1e-12)
        assertNull(TimeText.parseMiles("0"))
        assertNull(TimeText.parseMiles("-1"))
        assertNull(TimeText.parseMiles(""))
        assertNull(TimeText.parseMiles("abc"))
        assertEquals("3.10", TimeText.formatMiles(3.104))
    }

    // --- time / distance / pace ---------------------------------------------

    @Test
    fun `treadmill run starts with distance held and no pace`() {
        val start = TimeDistancePace.forLog(log(0.0))
        assertEquals("30:00", start.time)
        assertEquals("0.00", start.distance)
        assertEquals("", start.pace)
        assertEquals(TimeDistancePace.Field.DISTANCE, start.calc.held)
        // Nothing to derive from yet.
        assertNull(start.calc.onTime("31:00"))
    }

    @Test
    fun `distance edit fills pace, pace edit fills distance`() {
        val calc = TimeDistancePace.forLog(log(0.0)).calc
        assertEquals("10:00", calc.onDistance("3.00"))
        assertEquals(TimeDistancePace.Field.DISTANCE, calc.held)
        assertEquals("3.53", calc.onPace("8:30")) // 1800 / 510
        assertEquals(TimeDistancePace.Field.PACE, calc.held)
    }

    @Test
    fun `time edit keeps whichever was typed last`() {
        val calc = TimeDistancePace.forLog(log(0.0)).calc
        calc.onDistance("3.00")
        assertEquals(TimeDistancePace.Update(TimeDistancePace.Field.PACE, "11:00"), calc.onTime("33:00"))
        calc.onPace("10:00")
        assertEquals(TimeDistancePace.Update(TimeDistancePace.Field.DISTANCE, "3.60"), calc.onTime("36:00"))
    }

    @Test
    fun `half-typed values never overwrite the other box`() {
        val calc = TimeDistancePace.forLog(log(0.0)).calc
        calc.onDistance("3.00")
        assertNull(calc.onTime("3"))
        assertNull(calc.onTime("30:"))
        assertNull(calc.onDistance(""))
        assertNull(calc.onPace("8:"))
        // and a half-typed time is not used for a later distance edit
        calc.onTime("30:")
        assertNull(calc.onDistance("3.10"))
    }

    @Test
    fun `gps run holds its exact pace so a time edit scales distance and undoes cleanly`() {
        val l = log(3.104 * mile) // 30:00 for 3.104 mi: 9:39.9 /mi
        val start = TimeDistancePace.forLog(l)
        assertEquals("3.10", start.distance)
        assertEquals("9:40", start.pace)
        assertEquals(TimeDistancePace.Field.PACE, start.calc.held)
        assertEquals(TimeDistancePace.Update(TimeDistancePace.Field.DISTANCE, "3.31"), start.calc.onTime("32:00"))
        // Back to the recorded time gives back the recorded distance, not 3.11.
        assertEquals(TimeDistancePace.Update(TimeDistancePace.Field.DISTANCE, "3.10"), start.calc.onTime("30:00"))
    }

    @Test
    fun `gps drift under the threshold is not a pace source`() {
        val start = TimeDistancePace.forLog(log(40.0))
        assertEquals("0.02", start.distance)
        assertEquals("", start.pace)
        assertNull(start.calc.onTime("31:00"))
    }

    // --- what gets uploaded -------------------------------------------------

    @Test
    fun `prefilled boxes upload as recorded`() {
        val l = log(3.104 * mile)
        assertEquals(UploadInput.Ok(null, null), UploadInput.resolve(l, "30:00", "3.10", "9:40", paceHeld = true))
        // Same seconds, different spelling: still unchanged.
        assertEquals(UploadInput.Ok(null, null), UploadInput.resolve(l, "0:30:00", "3.10", "9:40", paceHeld = true))
    }

    @Test
    fun `edited time and distance become overrides`() {
        val r = UploadInput.resolve(log(0.0), "32:15", "3.20", "10:05", paceHeld = false) as UploadInput.Ok
        assertEquals(1935, r.timeOverrideSec)
        assertEquals(3.2 * mile, r.distanceOverrideM!!, 1e-6)
    }

    @Test
    fun `bad boxes are reported`() {
        assertEquals(UploadInput.BadTime, UploadInput.resolve(log(0.0), "5:75", "3.0", "", paceHeld = false))
        assertEquals(UploadInput.BadTime, UploadInput.resolve(log(0.0), "", "3.0", "", paceHeld = false))
        // A treadmill run needs a distance.
        assertEquals(UploadInput.BadDistance, UploadInput.resolve(log(0.0), "30:00", "0.00", "", paceHeld = false))
        assertEquals(UploadInput.BadPace, UploadInput.resolve(log(0.0), "30:00", "3.00", "8:", paceHeld = true))
        // A stale pace box doesn't matter while distance is the held value.
        assertTrue(UploadInput.resolve(log(0.0), "30:00", "3.00", "8:", paceHeld = false) is UploadInput.Ok)
    }

    @Test
    fun `stretch note and warning`() {
        assertEquals(Stretch.NONE, Stretch.of(1800, "30:00"))
        assertEquals(Stretch.NONE, Stretch.of(1800, "30:"))
        assertEquals(Stretch.NOTE, Stretch.of(1800, "31:00"))
        assertEquals(Stretch.NOTE, Stretch.of(1800, "34:30")) // +15.0%: not more than 15%
        assertEquals(Stretch.WARN, Stretch.of(1800, "34:31"))
        assertEquals(Stretch.WARN, Stretch.of(1800, "25:00"))
    }

    @Test
    fun `description says what was typed`() {
        assertEquals(
            "Recorded with RunStick. Avg HR 145 bpm, max 150 bpm. Time entered by hand. Distance entered by hand.",
            UploadDefaults.description(log(0.0), distanceTyped = true, timeTyped = true),
        )
    }
}
