package dev.runstick.app

/**
 * One second of run state in the exact units `docs/ble-protocol.md` uses.
 *
 * `null` means "not valid" for the two fields that have a valid-bit; the Stick shows `--`.
 */
data class RunData(
    val hrBpm: Int?,
    val paceSecPerMile: Int?,
    val elapsedSec: Int,
    val distanceCentiMiles: Int,
    val runActive: Boolean,
    val gpsOk: Boolean,
    val strapOk: Boolean,
)

/** phone -> Stick DATA characteristic: 9 bytes, little-endian, protocol version 1. */
object PacketEncoder {

    const val VERSION = 1
    const val PACKET_SIZE = 9

    const val FLAG_HR_VALID = 0x01
    const val FLAG_PACE_VALID = 0x02
    const val FLAG_RUN_ACTIVE = 0x04
    const val FLAG_GPS_OK = 0x08
    const val FLAG_STRAP_OK = 0x10

    const val PACE_INVALID = 0xFFFF

    /** The Stick renders pace as `m:ss` capped at 59:59, so never send more than that. */
    const val PACE_MAX = 3599

    fun encode(d: RunData): ByteArray {
        val hrValid = d.hrBpm != null && d.hrBpm > 0
        val paceValid = d.paceSecPerMile != null

        var flags = 0
        if (hrValid) flags = flags or FLAG_HR_VALID
        if (paceValid) flags = flags or FLAG_PACE_VALID
        if (d.runActive) flags = flags or FLAG_RUN_ACTIVE
        if (d.gpsOk) flags = flags or FLAG_GPS_OK
        if (d.strapOk) flags = flags or FLAG_STRAP_OK

        val out = ByteArray(PACKET_SIZE)
        out[0] = VERSION.toByte()
        out[1] = flags.toByte()
        out[2] = if (hrValid) d.hrBpm!!.coerceIn(0, 0xFF).toByte() else 0
        putU16(out, 3, if (paceValid) d.paceSecPerMile!!.coerceIn(0, PACE_MAX) else PACE_INVALID)
        // The protocol says elapsed wraps after 18.2 h, so mask rather than clamp.
        putU16(out, 5, d.elapsedSec and 0xFFFF)
        putU16(out, 7, d.distanceCentiMiles.coerceIn(0, 0xFFFF))
        return out
    }

    private fun putU16(buf: ByteArray, offset: Int, value: Int) {
        buf[offset] = (value and 0xFF).toByte()
        buf[offset + 1] = ((value ushr 8) and 0xFF).toByte()
    }
}

/** Stick -> phone STATUS characteristic. */
data class StickStatus(val batteryPct: Int, val charging: Boolean)

/**
 * Kept as a pure `ByteArray` function so the only line that touches Nordic's `Data`
 * wrapper is the one-line conversion in [StickClient].
 */
object StatusDecoder {
    fun parse(payload: ByteArray?): StickStatus? {
        if (payload == null || payload.size < 2) return null
        return StickStatus(
            batteryPct = (payload[0].toInt() and 0xFF).coerceIn(0, 100),
            charging = (payload[1].toInt() and 0x01) != 0,
        )
    }
}
