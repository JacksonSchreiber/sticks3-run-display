package dev.runstick.app

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder

class WorkoutLogTest {

    @get:Rule
    val tmp = TemporaryFolder()

    private val log = WorkoutLog(
        startEpochMs = 1_759_320_000_000L,
        simulated = false,
        samples = listOf(
            WorkoutSample(0, null, 0.0),
            WorkoutSample(1, 140, 2.5),
            WorkoutSample(2, 150, 5.0),
            WorkoutSample(3, null, 7.5),
        ),
    )

    private val text =
        "#runstick-workout v1 start=1759320000000 simulated=0\n" +
            "t,hr,dist_m\n" +
            "0,,0.0\n" +
            "1,140,2.5\n" +
            "2,150,5.0\n" +
            "3,,7.5\n"

    @Test
    fun `serialises to header plus csv rows`() {
        assertEquals(text, log.serialize())
    }

    @Test
    fun `round trips including null heart rate`() {
        assertEquals(log, WorkoutLog.parse(log.serialize()))
        val sim = log.copy(simulated = true)
        assertEquals(sim, WorkoutLog.parse(sim.serialize()))
    }

    @Test
    fun `summaries ignore missing heart rate`() {
        assertEquals(3, log.durationSec)
        assertEquals(7.5, log.totalDistanceM, 1e-9)
        assertEquals(145, log.avgHr)
        assertEquals(150, log.maxHr)
        assertTrue(log.hasNoDistance)
    }

    @Test
    fun `no heart rate at all gives null summaries`() {
        val noHr = WorkoutLog(0L, false, listOf(WorkoutSample(0, null, 0.0), WorkoutSample(1, null, 1.0)))
        assertNull(noHr.avgHr)
        assertNull(noHr.maxHr)
        val empty = WorkoutLog(0L, false, emptyList())
        assertEquals(0, empty.durationSec)
        assertEquals(0.0, empty.totalDistanceM, 0.0)
    }

    @Test
    fun `average heart rate rounds to nearest`() {
        val l = WorkoutLog(0L, false, listOf(WorkoutSample(0, 140, 0.0), WorkoutSample(1, 141, 0.0)))
        assertEquals(141, l.avgHr) // 140.5 rounds up
    }

    @Test
    fun `a half-written last row is skipped`() {
        val parsed = WorkoutLog.parse(text + "4,15")!!
        assertEquals(log.samples, parsed.samples)
        val badHr = WorkoutLog.parse(text + "4,x,9.0\n")!!
        assertEquals(4, badHr.samples.size)
    }

    @Test
    fun `missing header is rejected`() {
        assertNull(WorkoutLog.parse(""))
        assertNull(WorkoutLog.parse("0,,0.0\n1,140,2.5\n"))
        assertNull(WorkoutLog.parse("#runstick-workout v1 simulated=0\n"))
    }

    @Test
    fun `distance uses dot decimals`() {
        assertEquals("12,,1609.3\n", WorkoutLog.sampleLine(WorkoutSample(12, null, 1609.344)))
    }

    // --- trim (auto-stop) ---------------------------------------------------

    @Test
    fun `trim drops the tail after the last heartbeat but keeps mid-run gaps`() {
        val l = WorkoutLog(
            9L, false,
            listOf(
                WorkoutSample(0, 140, 0.0),
                WorkoutSample(1, null, 3.0), // mid-run dropout stays
                WorkoutSample(2, 150, 6.0),
                WorkoutSample(3, null, 9.0),
                WorkoutSample(4, null, 12.0),
            ),
        )
        val t = l.trimmedToLastHr()
        assertEquals(listOf(0, 1, 2), t.samples.map { it.tSec })
        assertEquals(9L, t.startEpochMs)
        assertEquals(2, t.durationSec)
        assertEquals(6.0, t.totalDistanceM, 1e-9)
        assertEquals(145, t.avgHr)
        assertEquals(150, t.maxHr)
    }

    @Test
    fun `trim is a no-op without any heart rate or when it already ends on one`() {
        val noHr = WorkoutLog(0L, false, listOf(WorkoutSample(0, null, 0.0), WorkoutSample(1, null, 1.0)))
        assertEquals(noHr, noHr.trimmedToLastHr())
        val endsOnHr = WorkoutLog(0L, false, listOf(WorkoutSample(0, null, 0.0), WorkoutSample(1, 120, 1.0)))
        assertEquals(endsOnHr, endsOnHr.trimmedToLastHr())
        val empty = WorkoutLog(0L, false, emptyList())
        assertEquals(empty, empty.trimmedToLastHr())
    }

    @Test
    fun `auto-stop finish rewrites the file to end at the last heartbeat`() {
        val store = WorkoutStore(tmp.newFolder("workouts"))
        val file = store.fileFor(11L)
        val rec = WorkoutRecorder(file, 11L, simulated = false)
        for (t in 0..400) rec.add(WorkoutSample(t, if (t <= 100) 130 else null, t * 3.0))
        assertEquals(100, rec.finish(trimToLastHr = true))
        val back = store.latest()!!
        assertEquals(101, back.samples.size)
        assertEquals(100, back.durationSec)
        assertEquals(300.0, back.totalDistanceM, 1e-9)
        assertEquals(listOf(file.name), file.parentFile!!.list()!!.toList()) // no temp left
    }

    @Test
    fun `manual finish keeps the tail`() {
        val file = tmp.newFolder("w").resolve("workout_12.csv")
        val rec = WorkoutRecorder(file, 12L, simulated = false)
        for (t in 0..400) rec.add(WorkoutSample(t, if (t <= 100) 130 else null, t * 3.0))
        assertEquals(400, rec.finish())
        assertEquals(400, WorkoutLog.parse(file.readText())!!.durationSec)
    }

    @Test
    fun `minimum length applies to the trimmed run`() {
        val file = tmp.newFolder("w").resolve("workout_13.csv")
        val rec = WorkoutRecorder(file, 13L, simulated = false)
        for (t in 0..400) rec.add(WorkoutSample(t, if (t <= 59) 130 else null, 0.0))
        assertNull(rec.finish(trimToLastHr = true))
        assertFalse(file.exists())
    }

    // --- store + recorder ---------------------------------------------------

    @Test
    fun `recorder flushes every five samples and keeps a long run`() {
        val store = WorkoutStore(tmp.newFolder("workouts"))
        val file = store.fileFor(1_000L)
        val rec = WorkoutRecorder(file, 1_000L, simulated = true)
        for (t in 0 until 4) rec.add(WorkoutSample(t, 120, t.toDouble()))
        assertEquals(0, WorkoutLog.parse(file.readText())!!.samples.size)
        rec.add(WorkoutSample(4, 120, 4.0))
        assertEquals(5, WorkoutLog.parse(file.readText())!!.samples.size)

        for (t in 5..60) rec.add(WorkoutSample(t, 120, t.toDouble()))
        assertEquals(60, rec.finish())
        val back = store.latest()!!
        assertEquals(1_000L, back.startEpochMs)
        assertTrue(back.simulated)
        assertEquals(61, back.samples.size)
        assertEquals(60, back.durationSec)
    }

    @Test
    fun `recorder drops repeated seconds`() {
        val file = tmp.newFolder("w").resolve("workout_5.csv")
        val rec = WorkoutRecorder(file, 5L, simulated = false)
        rec.add(WorkoutSample(0, 100, 0.0))
        rec.add(WorkoutSample(1, 101, 1.0))
        rec.add(WorkoutSample(1, 102, 1.5))
        rec.add(WorkoutSample(3, 103, 3.0))
        rec.finish(minSec = 0)
        assertEquals(listOf(0, 1, 3), WorkoutLog.parse(file.readText())!!.samples.map { it.tSec })
    }

    @Test
    fun `short runs are discarded`() {
        val store = WorkoutStore(tmp.newFolder("workouts"))
        val file = store.fileFor(7L)
        val rec = WorkoutRecorder(file, 7L, simulated = false)
        for (t in 0..59) rec.add(WorkoutSample(t, null, 0.0))
        assertNull(rec.finish())
        assertFalse(file.exists())
        assertNull(store.latest())
    }

    @Test
    fun `store keeps the newest ten`() {
        val dir = tmp.newFolder("workouts")
        val store = WorkoutStore(dir)
        for (i in 1..12) store.fileFor(i * 1000L).writeText(WorkoutLog(i * 1000L, false, emptyList()).serialize())
        dir.resolve("notes.txt").writeText("not a workout")
        store.prune()
        assertEquals((12 downTo 3).map { it * 1000L }, store.files().map { WorkoutStore.startOf(it) })
        assertTrue(dir.resolve("notes.txt").exists())
    }

    @Test
    fun `latest skips an unreadable newest file`() {
        val store = WorkoutStore(tmp.newFolder("workouts"))
        store.fileFor(1L).writeText(WorkoutLog(1L, false, emptyList()).serialize())
        store.fileFor(2L).writeText("garbage")
        assertEquals(1L, store.latest()!!.startEpochMs)
        store.fileFor(3L).writeText(WorkoutLog(3L, false, emptyList()).serialize())
        assertEquals(3L, store.latest()!!.startEpochMs)
        // Mid-run the newest file is the one being recorded.
        assertEquals(1L, store.latest(skipNewest = true)!!.startEpochMs)
    }
}
