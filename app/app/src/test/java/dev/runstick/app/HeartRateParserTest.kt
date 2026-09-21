package dev.runstick.app

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class HeartRateParserTest {

    private fun bytes(vararg v: Int) = ByteArray(v.size) { v[it].toByte() }

    @Test
    fun `uint8 format`() {
        assertEquals(152, HeartRateParser.parse(bytes(0x00, 152)))
        assertEquals(255, HeartRateParser.parse(bytes(0x00, 0xFF)))
    }

    @Test
    fun `uint16 little endian format`() {
        assertEquals(300, HeartRateParser.parse(bytes(0x01, 0x2C, 0x01)))
        assertEquals(152, HeartRateParser.parse(bytes(0x01, 0x98, 0x00)))
    }

    @Test
    fun `flag bits other than bit 0 do not change the width`() {
        // 0x06 = sensor contact supported + detected, still a uint8 rate.
        assertEquals(148, HeartRateParser.parse(bytes(0x06, 148)))
        // 0x07 = same, but bit 0 set, so uint16.
        assertEquals(148, HeartRateParser.parse(bytes(0x07, 0x94, 0x00)))
    }

    @Test
    fun `trailing energy expended and RR intervals are ignored`() {
        // flags 0x18 = energy expended present + RR present, uint8 rate.
        assertEquals(160, HeartRateParser.parse(bytes(0x18, 160, 0x20, 0x03, 0x0E, 0x03)))
        // Same with a uint16 rate.
        assertEquals(160, HeartRateParser.parse(bytes(0x19, 0xA0, 0x00, 0x20, 0x03, 0x0E, 0x03)))
    }

    @Test
    fun `short or missing payloads give null`() {
        assertNull(HeartRateParser.parse(null))
        assertNull(HeartRateParser.parse(ByteArray(0)))
        assertNull(HeartRateParser.parse(bytes(0x00)))
        // uint16 claimed but only one byte of rate present.
        assertNull(HeartRateParser.parse(bytes(0x01, 0x98)))
    }
}
