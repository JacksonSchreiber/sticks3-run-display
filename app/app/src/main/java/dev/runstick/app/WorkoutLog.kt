package dev.runstick.app

import java.util.Locale

/** One second of a run, as sent to the Stick. */
data class WorkoutSample(val tSec: Int, val hrBpm: Int?, val distanceM: Double)

/**
 * A recorded run: wall-clock start plus one sample per second.
 *
 * On disk it is one header line and then CSV rows, so the service can append a row at a
 * time and a crash leaves a readable file. Pure Kotlin so it can be unit-tested.
 *
 * ```
 * #runstick-workout v1 start=1759320000000 simulated=0
 * t,hr,dist_m
 * 0,,0.0
 * 1,142,2.8
 * ```
 */
data class WorkoutLog(
    /** Epoch milliseconds, UTC. Also the file's identity. */
    val startEpochMs: Long,
    val simulated: Boolean,
    val samples: List<WorkoutSample>,
) {
    val durationSec: Int get() = samples.lastOrNull()?.tSec ?: 0

    /** Distance only ever grows, but take the max anyway so a bad row can't shrink it. */
    val totalDistanceM: Double get() = samples.maxOfOrNull { it.distanceM } ?: 0.0

    val avgHr: Int?
        get() {
            val hrs = samples.mapNotNull { it.hrBpm }
            return if (hrs.isEmpty()) null else Math.round(hrs.average()).toInt()
        }

    val maxHr: Int? get() = samples.mapNotNull { it.hrBpm }.maxOrNull()

    /** No usable GPS distance: a treadmill, or a run with no fix at all. */
    val hasNoDistance: Boolean get() = totalDistanceM < NO_DISTANCE_M

    /**
     * Drops every sample after the last one with a heart rate, so an auto-stopped run ends
     * at the last heartbeat rather than five idle minutes later. Gaps mid-run are kept;
     * a log with no HR at all is returned unchanged.
     */
    fun trimmedToLastHr(): WorkoutLog {
        val last = samples.indexOfLast { it.hrBpm != null }
        if (last < 0 || last == samples.lastIndex) return this
        return copy(samples = samples.subList(0, last + 1).toList())
    }

    /**
     * The same run stretched (or squeezed) onto [totalSec], e.g. the time a treadmill
     * showed. Every sample time is multiplied by totalSec / durationSec, so the HR trace
     * keeps its shape; times are rounded to whole seconds and kept strictly increasing.
     * Nothing is trimmed: the app can't know where the belt actually started.
     */
    fun rescaledTo(totalSec: Int): WorkoutLog {
        val recorded = durationSec
        if (totalSec <= 0 || recorded <= 0 || totalSec == recorded) return this
        val out = ArrayList<WorkoutSample>(samples.size)
        for (s in samples) {
            // Multiply first: the last sample then lands exactly on totalSec.
            val t = Math.round(s.tSec.toDouble() * totalSec / recorded).toInt()
            if (out.isNotEmpty() && out.last().tSec >= t) {
                // Squeezing puts several samples on one second; keep the latest, so the
                // final sample (end time, full distance) always survives.
                out[out.lastIndex] = s.copy(tSec = out.last().tSec)
            } else {
                out += s.copy(tSec = t)
            }
        }
        return copy(samples = out)
    }

    val summary: WorkoutSummary
        get() = WorkoutSummary(startEpochMs, simulated, durationSec, totalDistanceM, avgHr)

    fun serialize(): String = buildString {
        append(headerLines(startEpochMs, simulated))
        samples.forEach { append(sampleLine(it)) }
    }

    companion object {
        /**
         * Below this the recorded distance is treated as "none". Well above zero because a
         * phone on a treadmill can still collect tens of metres of GPS drift near a
         * window, and scaling a typed-in 5 km onto that drift would make nonsense splits.
         */
        const val NO_DISTANCE_M = 100.0

        private const val MAGIC = "#runstick-workout v1"
        private const val COLUMNS = "t,hr,dist_m"

        /** Everything before the first sample, newline-terminated. */
        fun headerLines(startEpochMs: Long, simulated: Boolean): String =
            "$MAGIC start=$startEpochMs simulated=${if (simulated) 1 else 0}\n$COLUMNS\n"

        /** Locale.US: a comma decimal separator would break the CSV. */
        fun sampleLine(s: WorkoutSample): String =
            String.format(Locale.US, "%d,%s,%.1f\n", s.tSec, s.hrBpm?.toString() ?: "", s.distanceM)

        /**
         * Returns null when the header is missing. Rows that don't parse are skipped: a
         * process killed mid-write can leave half a line at the end.
         */
        fun parse(text: String): WorkoutLog? {
            val lines = text.lineSequence().iterator()
            if (!lines.hasNext()) return null
            val header = lines.next().trim()
            if (!header.startsWith(MAGIC)) return null
            val fields = header.removePrefix(MAGIC).trim().split(' ')
                .mapNotNull { kv -> kv.split('=', limit = 2).takeIf { it.size == 2 } }
                .associate { (k, v) -> k to v }
            val start = fields["start"]?.toLongOrNull() ?: return null
            val simulated = fields["simulated"] == "1"

            val samples = ArrayList<WorkoutSample>()
            for (raw in lines) {
                val line = raw.trim()
                if (line.isEmpty() || line == COLUMNS) continue
                val cols = line.split(',')
                if (cols.size != 3) continue
                val t = cols[0].toIntOrNull() ?: continue
                val dist = cols[2].toDoubleOrNull() ?: continue
                val hr = if (cols[1].isEmpty()) null else (cols[1].toIntOrNull() ?: continue)
                samples += WorkoutSample(t, hr, dist)
            }
            return WorkoutLog(start, simulated, samples)
        }
    }
}

/** Just what a list row needs, so the history screen doesn't hold 50 full logs. */
data class WorkoutSummary(
    val startEpochMs: Long,
    val simulated: Boolean,
    val durationSec: Int,
    val distanceM: Double,
    val avgHr: Int?,
)
