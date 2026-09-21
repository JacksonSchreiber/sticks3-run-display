package dev.runstick.app

/**
 * Bluetooth SIG Heart Rate Measurement (0x2A37).
 *
 * Layout: one flags byte, then the rate. Flags bit 0 picks the width of the rate field
 * (0 = uint8, 1 = uint16 little-endian). Everything after it - energy expended, RR
 * intervals - is optional and irrelevant to us, so trailing bytes are simply ignored.
 */
object HeartRateParser {

    /** @return bpm as reported, or null if the payload is too short to hold one. */
    fun parse(payload: ByteArray?): Int? {
        if (payload == null || payload.size < 2) return null
        val wide = (payload[0].toInt() and 0x01) != 0
        return if (wide) {
            if (payload.size < 3) null
            else (payload[1].toInt() and 0xFF) or ((payload[2].toInt() and 0xFF) shl 8)
        } else {
            payload[1].toInt() and 0xFF
        }
    }
}
