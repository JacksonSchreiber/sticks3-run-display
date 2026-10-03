package dev.runstick.app

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class TcxWriterTest {

    private val start = 1_759_320_000_000L // 2025-10-01T12:00:00Z

    private val header =
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" +
            "<TrainingCenterDatabase xmlns=\"http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2\" " +
            "xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" " +
            "xsi:schemaLocation=\"http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2 " +
            "http://www.garmin.com/xmlschemas/TrainingCenterDatabasev2.xsd\">\n" +
            "  <Activities>\n" +
            "    <Activity Sport=\"Running\">\n" +
            "      <Id>2025-10-01T12:00:00Z</Id>\n" +
            "      <Lap StartTime=\"2025-10-01T12:00:00Z\">\n"

    private val footer =
        "        </Track>\n" +
            "      </Lap>\n" +
            "    </Activity>\n" +
            "  </Activities>\n" +
            "</TrainingCenterDatabase>\n"

    @Test
    fun `golden output for a small log`() {
        val log = WorkoutLog(
            start, false,
            listOf(
                WorkoutSample(0, null, 0.0),
                WorkoutSample(1, 140, 3.0),
                WorkoutSample(2, 150, 6.0),
            ),
        )
        val expected = header +
            "        <TotalTimeSeconds>2</TotalTimeSeconds>\n" +
            "        <DistanceMeters>6.0</DistanceMeters>\n" +
            "        <Calories>0</Calories>\n" +
            "        <AverageHeartRateBpm><Value>145</Value></AverageHeartRateBpm>\n" +
            "        <MaximumHeartRateBpm><Value>150</Value></MaximumHeartRateBpm>\n" +
            "        <Intensity>Active</Intensity>\n" +
            "        <TriggerMethod>Manual</TriggerMethod>\n" +
            "        <Track>\n" +
            "          <Trackpoint>\n" +
            "            <Time>2025-10-01T12:00:00Z</Time>\n" +
            "            <DistanceMeters>0.0</DistanceMeters>\n" +
            "          </Trackpoint>\n" +
            "          <Trackpoint>\n" +
            "            <Time>2025-10-01T12:00:01Z</Time>\n" +
            "            <DistanceMeters>3.0</DistanceMeters>\n" +
            "            <HeartRateBpm><Value>140</Value></HeartRateBpm>\n" +
            "          </Trackpoint>\n" +
            "          <Trackpoint>\n" +
            "            <Time>2025-10-01T12:00:02Z</Time>\n" +
            "            <DistanceMeters>6.0</DistanceMeters>\n" +
            "            <HeartRateBpm><Value>150</Value></HeartRateBpm>\n" +
            "          </Trackpoint>\n" +
            footer
        assertEquals(expected, TcxWriter.build(log, null))
    }

    @Test
    fun `override scales a recorded distance profile`() {
        val log = WorkoutLog(
            start, false,
            listOf(
                WorkoutSample(0, 140, 0.0),
                WorkoutSample(1, 141, 500.0),
                WorkoutSample(2, 142, 1000.0),
            ),
        )
        val expected = header +
            "        <TotalTimeSeconds>2</TotalTimeSeconds>\n" +
            "        <DistanceMeters>1500.0</DistanceMeters>\n" +
            "        <Calories>0</Calories>\n" +
            "        <AverageHeartRateBpm><Value>141</Value></AverageHeartRateBpm>\n" +
            "        <MaximumHeartRateBpm><Value>142</Value></MaximumHeartRateBpm>\n" +
            "        <Intensity>Active</Intensity>\n" +
            "        <TriggerMethod>Manual</TriggerMethod>\n" +
            "        <Track>\n" +
            "          <Trackpoint>\n" +
            "            <Time>2025-10-01T12:00:00Z</Time>\n" +
            "            <DistanceMeters>0.0</DistanceMeters>\n" +
            "            <HeartRateBpm><Value>140</Value></HeartRateBpm>\n" +
            "          </Trackpoint>\n" +
            "          <Trackpoint>\n" +
            "            <Time>2025-10-01T12:00:01Z</Time>\n" +
            "            <DistanceMeters>750.0</DistanceMeters>\n" +
            "            <HeartRateBpm><Value>141</Value></HeartRateBpm>\n" +
            "          </Trackpoint>\n" +
            "          <Trackpoint>\n" +
            "            <Time>2025-10-01T12:00:02Z</Time>\n" +
            "            <DistanceMeters>1500.0</DistanceMeters>\n" +
            "            <HeartRateBpm><Value>142</Value></HeartRateBpm>\n" +
            "          </Trackpoint>\n" +
            footer
        assertEquals(expected, TcxWriter.build(log, 1500.0))
    }

    @Test
    fun `override on a zero-distance run is spread at constant pace`() {
        val log = WorkoutLog(
            start, false,
            listOf(
                WorkoutSample(0, null, 0.0),
                WorkoutSample(1, null, 0.0),
                WorkoutSample(2, null, 0.0),
                WorkoutSample(4, null, 0.0), // a skipped second stays proportional to time
            ),
        )
        val expected = header +
            "        <TotalTimeSeconds>4</TotalTimeSeconds>\n" +
            "        <DistanceMeters>1000.0</DistanceMeters>\n" +
            "        <Calories>0</Calories>\n" +
            "        <Intensity>Active</Intensity>\n" +
            "        <TriggerMethod>Manual</TriggerMethod>\n" +
            "        <Track>\n" +
            "          <Trackpoint>\n" +
            "            <Time>2025-10-01T12:00:00Z</Time>\n" +
            "            <DistanceMeters>0.0</DistanceMeters>\n" +
            "          </Trackpoint>\n" +
            "          <Trackpoint>\n" +
            "            <Time>2025-10-01T12:00:01Z</Time>\n" +
            "            <DistanceMeters>250.0</DistanceMeters>\n" +
            "          </Trackpoint>\n" +
            "          <Trackpoint>\n" +
            "            <Time>2025-10-01T12:00:02Z</Time>\n" +
            "            <DistanceMeters>500.0</DistanceMeters>\n" +
            "          </Trackpoint>\n" +
            "          <Trackpoint>\n" +
            "            <Time>2025-10-01T12:00:04Z</Time>\n" +
            "            <DistanceMeters>1000.0</DistanceMeters>\n" +
            "          </Trackpoint>\n" +
            footer
        assertEquals(expected, TcxWriter.build(log, 1000.0))
    }

    @Test
    fun `gps drift below the threshold is not scaled up`() {
        // 40 m of indoor drift must not become the shape of a 5 km run.
        val log = WorkoutLog(
            start, false,
            listOf(WorkoutSample(0, null, 0.0), WorkoutSample(5, null, 40.0), WorkoutSample(10, null, 40.0)),
        )
        assertEquals(listOf(0.0, 2500.0, 5000.0), TcxWriter.distances(log, 5000.0))
    }

    @Test
    fun `no position elements ever`() {
        val samples = (0..120).map { WorkoutSample(it, 130 + it % 20, it * 2.9) }
        val log = WorkoutLog(start, true, samples)
        for (xml in listOf(TcxWriter.build(log, null), TcxWriter.build(log, 500.0))) {
            assertFalse(xml.contains("Position"))
            assertFalse(xml.contains("Latitude"))
            assertEquals(121, Regex("<Trackpoint>").findAll(xml).count())
        }
    }

    @Test
    fun `times are utc whatever the milliseconds`() {
        val log = WorkoutLog(start + 999L, false, listOf(WorkoutSample(0, 100, 0.0), WorkoutSample(61, 100, 0.0)))
        val xml = TcxWriter.build(log, null)
        assertTrue(xml.contains("<Id>2025-10-01T12:00:00Z</Id>"))
        assertTrue(xml.contains("<Time>2025-10-01T12:01:01Z</Time>"))
    }

    // --- time override (typed treadmill time) -------------------------------

    private fun times(xml: String) =
        Regex("<Time>([^<]+)</Time>").findAll(xml).map { java.time.Instant.parse(it.groupValues[1]) }.toList()

    private fun trackDistances(xml: String) =
        Regex("<Trackpoint>\\s*<Time>[^<]+</Time>\\s*<DistanceMeters>([^<]+)</DistanceMeters>")
            .findAll(xml).map { it.groupValues[1].toDouble() }.toList()

    private fun trackHr(xml: String) =
        Regex("<HeartRateBpm><Value>(\\d+)</Value></HeartRateBpm>").findAll(xml).map { it.groupValues[1].toInt() }.toList()

    @Test
    fun `typed time stretches the treadmill run onto it`() {
        // 30:00 recorded, the treadmill said 31:45 and 3.10 mi.
        val samples = (0..1800).map { WorkoutSample(it, 120 + it % 50, 0.0) }
        val log = WorkoutLog(start, false, samples)
        val miles = 3.10 * PaceEstimator.METERS_PER_MILE
        val xml = TcxWriter.build(log, miles, timeOverrideSec = 1905)

        val secs = times(xml).map { it.epochSecond - start / 1000 }
        assertTrue("strictly increasing", secs.zipWithNext().all { (a, b) -> b > a })
        assertEquals(0L, secs.first())
        assertEquals(1905L, secs.last())
        assertTrue(xml.contains("<TotalTimeSeconds>1905</TotalTimeSeconds>"))

        val d = trackDistances(xml)
        assertEquals(String.format(java.util.Locale.US, "%.1f", miles).toDouble(), d.last(), 1e-9)
        assertTrue(d.zipWithNext().all { (a, b) -> b >= a })
        // 3.10 mi = 4988.97 m, on the lap as well as the last trackpoint.
        assertEquals(4989.0, d.last(), 1e-9)
        assertTrue(xml.contains("<DistanceMeters>4989.0</DistanceMeters>\n        <Calories>"))

        // Stretching keeps every sample, so the HR trace is identical, in order.
        assertEquals(samples.map { it.hrBpm }, trackHr(xml))
    }

    @Test
    fun `typed shorter time squeezes without breaking the track`() {
        val samples = (0..1800).map { WorkoutSample(it, 120 + it % 50, it * 2.5) }
        val log = WorkoutLog(start, false, samples)
        val xml = TcxWriter.build(log, null, timeOverrideSec = 1500)
        val secs = times(xml).map { it.epochSecond - start / 1000 }
        assertTrue(secs.zipWithNext().all { (a, b) -> b > a })
        assertEquals(1500L, secs.last())
        assertTrue(xml.contains("<TotalTimeSeconds>1500</TotalTimeSeconds>"))
        // Distance rides along with the samples; the last one survives, so the total holds.
        assertEquals(4500.0, trackDistances(xml).last(), 1e-9)
        // HR values are an in-order subsequence of the recording.
        val hr = trackHr(xml)
        var i = 0
        for (v in hr) {
            while (i < samples.size && samples[i].hrBpm != v) i++
            assertTrue("hr $v out of order", i < samples.size)
            i++
        }
    }

    @Test
    fun `time override equal to the recording changes nothing`() {
        val log = WorkoutLog(start, false, listOf(WorkoutSample(0, 100, 0.0), WorkoutSample(90, 110, 300.0)))
        assertEquals(TcxWriter.build(log, null), TcxWriter.build(log, null, timeOverrideSec = 90))
    }
}
