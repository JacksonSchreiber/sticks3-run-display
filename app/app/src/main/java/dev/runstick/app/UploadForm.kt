package dev.runstick.app

import java.util.Locale
import kotlin.math.abs
import kotlin.math.roundToInt

/** What the upload dialog starts with. */
object UploadDefaults {
    fun name(log: WorkoutLog): String = when {
        log.simulated -> "RunStick test (simulated)"
        log.hasNoDistance -> "Treadmill run"
        else -> "Run"
    }

    fun treadmill(log: WorkoutLog): Boolean = log.hasNoDistance

    /** Recorded miles as shown in the distance box (2 dp, Locale.US). */
    fun miles(log: WorkoutLog): String = TimeText.formatMiles(log.totalDistanceM / PaceEstimator.METERS_PER_MILE)

    /** Recorded duration as shown in the time box. */
    fun time(log: WorkoutLog): String = TimeText.formatTime(log.durationSec)

    /**
     * The distance override in metres from what the user typed, or null to keep the
     * recorded distance (box left at its prefill: no point rescaling by rounding error).
     * Accepts a comma decimal separator. Returns NaN for unusable input.
     */
    fun overrideMeters(log: WorkoutLog, typed: String): Double? {
        val text = typed.trim().replace(',', '.')
        if (text == miles(log) && !log.hasNoDistance) return null
        val mi = TimeText.parseMiles(text) ?: return Double.NaN
        return mi * PaceEstimator.METERS_PER_MILE
    }

    fun description(log: WorkoutLog, distanceTyped: Boolean, timeTyped: Boolean = false): String = buildString {
        append("Recorded with RunStick.")
        if (log.avgHr != null) append(" Avg HR ${log.avgHr} bpm, max ${log.maxHr} bpm.")
        if (timeTyped) append(" Time entered by hand.")
        if (distanceTyped) append(" Distance entered by hand.")
    }
}

/** Parsing and formatting for the treadmill-style boxes. Locale.US, like the Stick. */
object TimeText {
    private val LEAD = Regex("""\d{1,4}""")
    private val TWO = Regex("""\d{2}""")

    private val SEPARATORS = Regex("""[.,\s]""")
    private val BARE = Regex("""\d{3,6}""")

    /**
     * Not every keyboard offers a colon on a number pad, so a dot, a comma or a space also separate the
     * parts, and bare digits are read right to left: "3000" = 30:00, "10530" = 1:05:30, "941" = 9:41.
     */
    private fun normalize(text: String): String {
        val t = text.trim().replace(SEPARATORS, ":")
        if (!t.matches(BARE)) return t
        val ss = t.takeLast(2); val rest = t.dropLast(2)
        return if (rest.length <= 2) "$rest:$ss" else "${rest.dropLast(2)}:${rest.takeLast(2)}:$ss"
    }

    /** "mm:ss" or "h:mm:ss" (or the forms [normalize] accepts) -> seconds. Null when malformed, out of range or zero. */
    fun parseTime(text: String): Int? {
        val parts = normalize(text).split(':')
        // Digits only: toInt() alone would let "-1" and "+5" through.
        if (parts.size !in 2..3 || !parts[0].matches(LEAD) || parts.drop(1).any { !it.matches(TWO) }) {
            return null
        }
        val n = parts.map { it.toInt() }
        if (n.drop(1).any { it > 59 }) return null
        val sec = if (n.size == 2) n[0] * 60 + n[1] else n[0] * 3600 + n[1] * 60 + n[2]
        return sec.takeIf { it > 0 }
    }

    /** "m:ss" per mile -> seconds per mile. Null when malformed or zero. */
    fun parsePace(text: String): Int? {
        val norm = normalize(text)
        if (norm.split(':').size != 2) return null
        return parseTime(norm)
    }

    /** Miles > 0, dot or comma decimal. */
    fun parseMiles(text: String): Double? {
        val mi = text.trim().replace(',', '.').toDoubleOrNull() ?: return null
        return mi.takeIf { it > 0.0 && !it.isInfinite() && !it.isNaN() }
    }

    fun formatTime(sec: Int): String = formatElapsed(sec)

    fun formatPace(secPerMile: Double): String = formatPace(secPerMile.roundToInt())

    fun formatMiles(miles: Double): String = String.format(Locale.US, "%.2f", miles)
}

/**
 * The time / distance / pace boxes. Time is the anchor; distance and pace are two views of
 * the same number, and whichever was typed last is held when the time changes.
 *
 * Values are kept as exact doubles internally, so changing the time and changing it back
 * restores the prefilled distance instead of drifting by the pace's rounding.
 * Each handler returns the text to put in the other box, or null to leave it alone (a
 * half-typed value like "8:" never overwrites anything).
 */
class TimeDistancePace private constructor(
    private var timeSec: Int?,
    private var miles: Double?,
    private var paceSec: Double?,
    holdPace: Boolean,
) {
    enum class Field { DISTANCE, PACE }

    data class Update(val field: Field, val text: String)

    /** Which of distance / pace is kept when the time changes. */
    var held: Field = if (holdPace) Field.PACE else Field.DISTANCE
        private set

    /** User edited the time: recompute whichever of distance/pace is not held. */
    fun onTime(text: String): Update? {
        val t = TimeText.parseTime(text)
        timeSec = t
        if (t == null) return null
        return when (held) {
            Field.PACE -> paceSec?.let { p ->
                miles = t / p
                Update(Field.DISTANCE, TimeText.formatMiles(t / p))
            }
            Field.DISTANCE -> miles?.let { m ->
                paceSec = t / m
                Update(Field.PACE, TimeText.formatPace(t / m))
            }
        }
    }

    /** User edited the distance: it is now held; returns the new pace text. */
    fun onDistance(text: String): String? {
        held = Field.DISTANCE
        val m = TimeText.parseMiles(text) ?: return null
        miles = m
        val t = timeSec ?: return null
        paceSec = t / m
        return TimeText.formatPace(t / m)
    }

    /** User edited the pace: it is now held; returns the new distance text. */
    fun onPace(text: String): String? {
        held = Field.PACE
        val p = TimeText.parsePace(text)?.toDouble() ?: return null
        paceSec = p
        val t = timeSec ?: return null
        miles = t / p
        return TimeText.formatMiles(t / p)
    }

    companion object {
        data class Start(val calc: TimeDistancePace, val time: String, val distance: String, val pace: String)

        /**
         * A run with GPS distance starts with its pace held, so editing only the time scales
         * the distance with it. A treadmill run (no distance, no pace) starts with
         * distance held: that is the box to fill in.
         */
        fun forLog(log: WorkoutLog): Start {
            val t = log.durationSec.takeIf { it > 0 }
            // Under the no-distance threshold the recorded miles are GPS drift at best:
            // treat them as unknown so a time edit can't derive a 400-minute pace from them.
            val m = if (log.hasNoDistance) null else log.totalDistanceM / PaceEstimator.METERS_PER_MILE
            val p = if (t != null && m != null) t / m else null
            return Start(
                calc = TimeDistancePace(t, m, p, holdPace = p != null),
                time = UploadDefaults.time(log),
                distance = UploadDefaults.miles(log),
                pace = p?.let { TimeText.formatPace(it) } ?: "",
            )
        }
    }
}

/** What the upload dialog's boxes come to. */
sealed class UploadInput {
    /** Null overrides mean "as recorded". */
    data class Ok(val timeOverrideSec: Int?, val distanceOverrideM: Double?) : UploadInput()
    object BadTime : UploadInput()
    object BadDistance : UploadInput()
    object BadPace : UploadInput()

    companion object {
        /**
         * The upload uses the time and distance boxes; pace only feeds the distance box. A
         * held pace that doesn't parse is flagged, since the distance box would be stale.
         */
        fun resolve(log: WorkoutLog, time: String, distance: String, pace: String, paceHeld: Boolean): UploadInput {
            val sec = TimeText.parseTime(time) ?: return BadTime
            if (paceHeld && pace.isNotBlank() && TimeText.parsePace(pace) == null) return BadPace
            val meters = UploadDefaults.overrideMeters(log, distance)
            if (meters != null && meters.isNaN()) return BadDistance
            // Compare seconds, not text: "0:30:00" and "30:00" are both "unchanged".
            return Ok(timeOverrideSec = sec.takeIf { it != log.durationSec }, distanceOverrideM = meters)
        }
    }
}

/** The note under the time box when the entered time differs from the recording. */
enum class Stretch {
    NONE, NOTE, WARN;

    companion object {
        /** More than this fractional change is worth a warning colour. */
        const val WARN_FRACTION = 0.15

        fun of(recordedSec: Int, timeText: String): Stretch {
            val entered = TimeText.parseTime(timeText) ?: return NONE
            if (recordedSec <= 0 || entered == recordedSec) return NONE
            return if (abs(entered.toDouble() / recordedSec - 1.0) > WARN_FRACTION) WARN else NOTE
        }
    }
}
