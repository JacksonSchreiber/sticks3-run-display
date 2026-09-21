package dev.runstick.app

import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class PacketEncoderTest {

    private fun hex(bytes: ByteArray) = bytes.joinToString(" ") { "%02X".format(it) }

    private fun bytes(vararg v: Int) = ByteArray(v.size) { v[it].toByte() }

    @Test
    fun `golden vector from the protocol doc`() {
        // HR 152, pace 8:45 /mi (525 s), elapsed 1:02:03 (3723 s), 7.12 mi (712), all flags.
        val packet = PacketEncoder.encode(
            RunData(
                hrBpm = 152,
                paceSecPerMile = 525,
                elapsedSec = 3723,
                distanceCentiMiles = 712,
                runActive = true,
                gpsOk = true,
                strapOk = true,
            )
        )
        assertEquals("01 1F 98 0D 02 8B 0E C8 02", hex(packet))
        assertArrayEquals(bytes(0x01, 0x1F, 0x98, 0x0D, 0x02, 0x8B, 0x0E, 0xC8, 0x02), packet)
    }

    @Test
    fun `packet is always nine bytes`() {
        assertEquals(9, PacketEncoder.encode(RunData(null, null, 0, 0, false, false, false)).size)
    }

    @Test
    fun `invalid heart rate zeroes the byte and clears the flag`() {
        val p = PacketEncoder.encode(
            RunData(null, 525, 10, 5, runActive = true, gpsOk = true, strapOk = true)
        )
        assertEquals(0, p[2].toInt())
        assertEquals(0, p[1].toInt() and PacketEncoder.FLAG_HR_VALID)
        // The other flags are untouched.
        assertEquals(PacketEncoder.FLAG_PACE_VALID, p[1].toInt() and PacketEncoder.FLAG_PACE_VALID)
    }

    @Test
    fun `a zero bpm reading counts as invalid`() {
        val p = PacketEncoder.encode(RunData(0, null, 0, 0, true, false, true))
        assertEquals(0, p[2].toInt())
        assertEquals(0, p[1].toInt() and PacketEncoder.FLAG_HR_VALID)
    }

    @Test
    fun `invalid pace encodes as 0xFFFF with the flag clear`() {
        val p = PacketEncoder.encode(RunData(152, null, 0, 0, true, false, true))
        assertEquals(0xFF, p[3].toInt() and 0xFF)
        assertEquals(0xFF, p[4].toInt() and 0xFF)
        assertEquals(0, p[1].toInt() and PacketEncoder.FLAG_PACE_VALID)
    }

    @Test
    fun `pace is capped at 59 59`() {
        val p = PacketEncoder.encode(RunData(null, 9999, 0, 0, true, true, false))
        assertEquals(3599, (p[3].toInt() and 0xFF) or ((p[4].toInt() and 0xFF) shl 8))
    }

    @Test
    fun `elapsed wraps at u16`() {
        val p = PacketEncoder.encode(RunData(null, null, 65_536 + 7, 0, true, false, false))
        assertEquals(7, (p[5].toInt() and 0xFF) or ((p[6].toInt() and 0xFF) shl 8))

        val q = PacketEncoder.encode(RunData(null, null, 65_535, 0, true, false, false))
        assertEquals(65_535, (q[5].toInt() and 0xFF) or ((q[6].toInt() and 0xFF) shl 8))
    }

    @Test
    fun `each flag lands on its own bit`() {
        fun flags(d: RunData) = PacketEncoder.encode(d)[1].toInt() and 0xFF
        assertEquals(0x00, flags(RunData(null, null, 0, 0, false, false, false)))
        assertEquals(0x04, flags(RunData(null, null, 0, 0, true, false, false)))
        assertEquals(0x08, flags(RunData(null, null, 0, 0, false, true, false)))
        assertEquals(0x10, flags(RunData(null, null, 0, 0, false, false, true)))
        assertEquals(0x03, flags(RunData(70, 600, 0, 0, false, false, false)))
        // Bits 5-7 are reserved and must go out as zero.
        assertEquals(0, flags(RunData(70, 600, 0, 0, true, true, true)) and 0xE0)
    }

    @Test
    fun `status decodes battery and charging`() {
        assertEquals(StickStatus(87, false), StatusDecoder.parse(bytes(87, 0x00)))
        assertEquals(StickStatus(87, true), StatusDecoder.parse(bytes(87, 0x01)))
        assertEquals(StickStatus(100, false), StatusDecoder.parse(bytes(200, 0x00)))
        assertNull(StatusDecoder.parse(bytes(50)))
        assertNull(StatusDecoder.parse(null))
    }
}
