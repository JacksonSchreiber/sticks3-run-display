package dev.runstick.app

/**
 * Decides when a forgotten run should end itself: the strap came off, so heart rate has
 * been missing for [limitSec] of run time. Fed once per tick. Pure.
 *
 * Only arms after the first real HR value, so a run without a strap (or a strap that
 * never linked) keeps going forever, exactly as before.
 */
class AutoStop(private val limitSec: Int = AUTO_STOP_SEC) {

    private var lastHrSec: Int? = null

    fun reset() {
        lastHrSec = null
    }

    /** @return true once HR has been absent for [limitSec]; the caller stops the run. */
    fun onTick(tSec: Int, hrBpm: Int?): Boolean {
        if (hrBpm != null) {
            lastHrSec = tSec
            return false
        }
        val last = lastHrSec ?: return false
        return tSec - last >= limitSec
    }

    companion object {
        const val AUTO_STOP_SEC = 300
    }
}
