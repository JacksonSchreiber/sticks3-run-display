package dev.runstick.app

import java.time.Instant
import java.time.ZoneOffset
import java.time.format.DateTimeFormatter
import java.util.Locale

/**
 * [WorkoutLog] -> Garmin TrainingCenterDatabase v2, the format Strava takes for a run with
 * heart rate and distance but no GPS track.
 *
 * Deliberately no `<Position>`: treadmill runs have none, and a track of made-up points
 * would draw a fake map. Strava builds pace from the per-point `<DistanceMeters>`.
 * Nothing user-typed goes into the XML (name and description travel in the upload form),
 * so there is nothing to escape.
 */
object TcxWriter {

    private val TIME: DateTimeFormatter =
        DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss'Z'", Locale.US).withZone(ZoneOffset.UTC)

    /**
     * @param distanceOverrideM typed distance, or null for the recorded one.
     * @param timeOverrideSec typed time, or null for the recorded one. The whole timeline
     *        is rescaled to it first ([WorkoutLog.rescaledTo]); distances, HR summaries
     *        and the lap time are then all computed from that one rescaled list.
     */
    fun build(log: WorkoutLog, distanceOverrideM: Double?, timeOverrideSec: Int? = null): String =
        render(if (timeOverrideSec != null) log.rescaledTo(timeOverrideSec) else log, distanceOverrideM)

    private fun render(log: WorkoutLog, distanceOverrideM: Double?): String {
        val dist = distances(log, distanceOverrideM)
        val total = distanceOverrideM ?: log.totalDistanceM
        val start = time(log.startEpochMs)

        val sb = StringBuilder()
        sb.append("""<?xml version="1.0" encoding="UTF-8"?>""").append('\n')
        sb.append(
            """<TrainingCenterDatabase xmlns="http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2" """ +
                """xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" """ +
                """xsi:schemaLocation="http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2 """ +
                """http://www.garmin.com/xmlschemas/TrainingCenterDatabasev2.xsd">"""
        ).append('\n')
        sb.append("  <Activities>\n")
        sb.append("    <Activity Sport=\"Running\">\n")
        sb.append("      <Id>").append(start).append("</Id>\n")
        sb.append("      <Lap StartTime=\"").append(start).append("\">\n")
        // Schema order matters: TotalTimeSeconds, DistanceMeters, Calories (required by
        // the XSD even though we don't know it), optional HR, Intensity, TriggerMethod.
        sb.append("        <TotalTimeSeconds>").append(log.durationSec).append("</TotalTimeSeconds>\n")
        sb.append("        <DistanceMeters>").append(meters(total)).append("</DistanceMeters>\n")
        sb.append("        <Calories>0</Calories>\n")
        log.avgHr?.let {
            sb.append("        <AverageHeartRateBpm><Value>").append(it).append("</Value></AverageHeartRateBpm>\n")
        }
        log.maxHr?.let {
            sb.append("        <MaximumHeartRateBpm><Value>").append(it).append("</Value></MaximumHeartRateBpm>\n")
        }
        sb.append("        <Intensity>Active</Intensity>\n")
        sb.append("        <TriggerMethod>Manual</TriggerMethod>\n")
        sb.append("        <Track>\n")
        log.samples.forEachIndexed { i, s ->
            sb.append("          <Trackpoint>\n")
            sb.append("            <Time>").append(time(log.startEpochMs + s.tSec * 1000L)).append("</Time>\n")
            sb.append("            <DistanceMeters>").append(meters(dist[i])).append("</DistanceMeters>\n")
            s.hrBpm?.let {
                sb.append("            <HeartRateBpm><Value>").append(it).append("</Value></HeartRateBpm>\n")
            }
            sb.append("          </Trackpoint>\n")
        }
        sb.append("        </Track>\n")
        sb.append("      </Lap>\n")
        sb.append("    </Activity>\n")
        sb.append("  </Activities>\n")
        sb.append("</TrainingCenterDatabase>\n")
        return sb.toString()
    }

    /**
     * Per-sample cumulative distance. With an override: scale the recorded profile when
     * there is one, otherwise (treadmill) spread the override evenly over time, i.e.
     * constant pace - the only honest guess without a speed signal.
     */
    fun distances(log: WorkoutLog, overrideM: Double?): List<Double> {
        val recorded = log.samples.map { it.distanceM }
        if (overrideM == null) return recorded
        if (!log.hasNoDistance) {
            val k = overrideM / log.totalDistanceM
            return recorded.map { it * k }
        }
        val dur = log.durationSec
        if (dur <= 0) return recorded.map { overrideM }
        return log.samples.map { overrideM * it.tSec / dur }
    }

    private fun time(epochMs: Long): String = TIME.format(Instant.ofEpochMilli(epochMs))

    private fun meters(m: Double): String = String.format(Locale.US, "%.1f", m)
}
