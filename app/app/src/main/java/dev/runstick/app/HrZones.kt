package dev.runstick.app

/**
 * Heart-rate zone 1-5 as a percentage of max HR: Z1 under 60%, Z2 60-70, Z3 70-80,
 * Z4 80-90, Z5 90 and up. Anything below 60% is still Z1, so a digit always shows while
 * HR is valid. Pure; one instance per run, [reset] on start.
 *
 * Hysteresis: at 1 Hz a heart rate sitting on a boundary would flick the Stick's digit
 * back and forth every second, so the zone only moves up once HR is [HYSTERESIS_BPM] past
 * the boundary, and down once it is that far below it.
 */
class HrZones {

    private var zone = 0

    fun reset() {
        zone = 0
    }

    /** @return the zone for this tick, or 0 when HR or max HR is missing. */
    fun update(hrBpm: Int?, maxHr: Int?): Int {
        if (maxHr == null || maxHr <= 0 || hrBpm == null || hrBpm <= 0) return 0
        val b = boundaries(maxHr)
        if (zone == 0) {
            // First reading of the run: nothing to be sticky about yet.
            zone = rawZone(hrBpm, maxHr)
            return zone
        }
        // Loops, so a big jump (or a changed max HR) can cross several zones at once.
        while (zone < 5 && hrBpm >= b[zone - 1] + HYSTERESIS_BPM) zone++
        while (zone > 1 && hrBpm <= b[zone - 2] - HYSTERESIS_BPM) zone--
        return zone
    }

    companion object {
        const val HYSTERESIS_BPM = 2
        const val MIN_MAX_HR = 120
        const val MAX_MAX_HR = 230

        private val PERCENT = intArrayOf(60, 70, 80, 90)

        /**
         * First bpm of zones 2..5: ceil(maxHr * pct / 100) in integer maths, so an
         * integer HR is in the upper zone exactly when it is at or above the percentage.
         */
        fun boundaries(maxHr: Int): IntArray = IntArray(PERCENT.size) { (maxHr * PERCENT[it] + 99) / 100 }

        /** The zone with no hysteresis. */
        fun rawZone(hrBpm: Int, maxHr: Int): Int = 1 + boundaries(maxHr).count { hrBpm >= it }

        /** "Z1 <114 · Z2 114-132 · Z3 133-151 · Z4 152-170 · Z5 171+" for max 190. */
        fun rangesText(maxHr: Int): String {
            val b = boundaries(maxHr)
            return "Z1 <${b[0]} · Z2 ${b[0]}-${b[1] - 1} · Z3 ${b[1]}-${b[2] - 1} · " +
                "Z4 ${b[2]}-${b[3] - 1} · Z5 ${b[3]}+"
        }

        fun validMaxHr(bpm: Int): Boolean = bpm in MIN_MAX_HR..MAX_MAX_HR
    }
}
