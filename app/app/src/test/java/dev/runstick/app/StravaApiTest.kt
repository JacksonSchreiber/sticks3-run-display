package dev.runstick.app

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/** Fake ids and tokens only: this repo is public. */
class StravaApiTest {

    @Test
    fun `authorise url carries every required parameter`() {
        val url = StravaApi.authorizeUrl("12345", "st4te")
        assertEquals(
            "https://www.strava.com/oauth/mobile/authorize" +
                "?client_id=12345" +
                "&redirect_uri=runstick%3A%2F%2Flocalhost%2Fstrava" +
                "&response_type=code" +
                "&approval_prompt=auto" +
                "&scope=activity%3Awrite" +
                "&state=st4te",
            url,
        )
    }

    @Test
    fun `redirect is checked for state, denial and scope`() {
        fun check(state: String? = "s", code: String? = "c", error: String? = null, scope: String? = "read,activity:write") =
            StravaApi.checkRedirect("s", state, code, error, scope)

        assertEquals(AuthRedirect.Code("c"), check())
        assertEquals(AuthRedirect.Code("c"), check(scope = "activity:write"))
        assertEquals(AuthRedirect.Stale, check(state = "other"))
        assertEquals(AuthRedirect.Stale, check(state = null))
        assertEquals(AuthRedirect.Stale, StravaApi.checkRedirect(null, "s", "c", null, "activity:write"))
        assertEquals(AuthRedirect.Denied, check(code = null, error = "access_denied", scope = null))
        assertEquals(AuthRedirect.MissingWriteScope, check(scope = "read"))
        assertEquals(AuthRedirect.MissingWriteScope, check(scope = "read,activity:write_all"))
        assertEquals(AuthRedirect.MissingWriteScope, check(scope = null))
        assertTrue(check(code = null) is AuthRedirect.Failed)
    }

    @Test
    fun `token forms`() {
        assertEquals(
            "client_id=12345&client_secret=test-secret&code=abc&grant_type=authorization_code",
            StravaApi.tokenExchangeForm("12345", "test-secret", "abc"),
        )
        assertEquals(
            "client_id=12345&client_secret=test-secret&grant_type=refresh_token&refresh_token=r%2B1",
            StravaApi.tokenRefreshForm("12345", "test-secret", "r+1"),
        )
    }

    @Test
    fun `token response parses including the rotated refresh token`() {
        val json = """
            {"token_type":"Bearer","expires_at":1759341600,"expires_in":21600,
             "refresh_token":"new-refresh","access_token":"new-access",
             "athlete":{"id":1,"firstname":"Test"}}
        """.trimIndent()
        assertEquals(StravaTokens("new-access", "new-refresh", 1_759_341_600L), StravaApi.parseTokens(json))
    }

    @Test(expected = org.json.JSONException::class)
    fun `token response without refresh token is an error`() {
        StravaApi.parseTokens("""{"access_token":"a","expires_at":1}""")
    }

    @Test
    fun `multipart body has the file first then fields in order`() {
        val fields = StravaApi.uploadFields(name = "Run & fun", description = "d", trainer = true, startEpochMs = 42L)
        val body = StravaApi.multipartBody("B0UND", StravaApi.tcxFilePart(42L, "<x/>"), fields)
        val expected =
            "--B0UND\r\n" +
                "Content-Disposition: form-data; name=\"file\"; filename=\"runstick-42.tcx\"\r\n" +
                "Content-Type: application/octet-stream\r\n" +
                "\r\n" +
                "<x/>\r\n" +
                "--B0UND\r\n" +
                "Content-Disposition: form-data; name=\"data_type\"\r\n" +
                "\r\n" +
                "tcx\r\n" +
                "--B0UND\r\n" +
                "Content-Disposition: form-data; name=\"sport_type\"\r\n" +
                "\r\n" +
                "Run\r\n" +
                "--B0UND\r\n" +
                "Content-Disposition: form-data; name=\"name\"\r\n" +
                "\r\n" +
                "Run & fun\r\n" +
                "--B0UND\r\n" +
                "Content-Disposition: form-data; name=\"description\"\r\n" +
                "\r\n" +
                "d\r\n" +
                "--B0UND\r\n" +
                "Content-Disposition: form-data; name=\"trainer\"\r\n" +
                "\r\n" +
                "1\r\n" +
                "--B0UND\r\n" +
                "Content-Disposition: form-data; name=\"external_id\"\r\n" +
                "\r\n" +
                "runstick-42\r\n" +
                "--B0UND--\r\n"
        assertEquals(expected, String(body, Charsets.UTF_8))
        assertEquals("multipart/form-data; boundary=B0UND", StravaApi.multipartContentType("B0UND"))
    }

    @Test
    fun `trainer is omitted for outdoor runs`() {
        val fields = StravaApi.uploadFields("Run", "", trainer = false, startEpochMs = 1L)
        assertEquals(listOf("data_type", "sport_type", "name", "description", "external_id"), fields.map { it.first })
    }

    @Test
    fun `upload status - processing`() {
        val s = StravaApi.parseUploadStatus(
            """{"id":123456789012,"id_str":"123456789012","external_id":"runstick-42.tcx",
               "error":null,"status":"Your activity is still being processed.","activity_id":null}"""
        )
        assertEquals(UploadStatus("123456789012", "Your activity is still being processed.", null, null), s)
        assertFalse(s.done)
    }

    @Test
    fun `upload status - ready`() {
        val s = StravaApi.parseUploadStatus(
            """{"id":123456789012,"id_str":"123456789012","external_id":"runstick-42.tcx",
               "error":null,"status":"Your activity is ready.","activity_id":987654321098}"""
        )
        assertEquals(987_654_321_098L, s.activityId)
        assertNull(s.error)
        assertTrue(s.done)
    }

    @Test
    fun `upload status - duplicate error has its html stripped`() {
        val s = StravaApi.parseUploadStatus(
            """{"id":5,"id_str":"5","external_id":null,
               "error":"runstick-42.tcx duplicate of <a href='/activities/555' target='_blank'>activity 555</a>",
               "status":"There was an error processing your activity.","activity_id":null}"""
        )
        assertEquals("runstick-42.tcx duplicate of activity 555", s.error)
        assertTrue(s.done)
    }

    @Test
    fun `upload status falls back to numeric id`() {
        val s = StravaApi.parseUploadStatus("""{"id":77,"status":"Your activity is still being processed."}""")
        assertEquals("77", s.idStr)
        assertNull(s.activityId)
    }

    @Test
    fun `fault bodies become readable text`() {
        assertEquals(
            "Bad Request: Upload file invalid",
            StravaApi.parseFault("""{"message":"Bad Request","errors":[{"resource":"Upload","field":"file","code":"invalid"}]}"""),
        )
        assertEquals("Authorization Error", StravaApi.parseFault("""{"message":"Authorization Error","errors":[]}"""))
        assertNull(StravaApi.parseFault("<html>502</html>"))
    }

    @Test
    fun `html stripping decodes entities`() {
        assertEquals("a & b <c>", StravaApi.stripHtml("<p>a &amp; b</p>\n &lt;c&gt;"))
    }

    // --- upload dialog defaults ---------------------------------------------

    private fun log(meters: Double, simulated: Boolean = false) = WorkoutLog(
        0L, simulated, listOf(WorkoutSample(0, 140, 0.0), WorkoutSample(600, 150, meters)),
    )

    @Test
    fun `default names and treadmill box`() {
        assertEquals("Treadmill run", UploadDefaults.name(log(0.0)))
        assertTrue(UploadDefaults.treadmill(log(0.0)))
        assertEquals("Run", UploadDefaults.name(log(1609.344)))
        assertFalse(UploadDefaults.treadmill(log(1609.344)))
        assertEquals("RunStick test (simulated)", UploadDefaults.name(log(1609.344, simulated = true)))
    }

    @Test
    fun `distance box parsing`() {
        val outdoor = log(1609.344 * 3.104)
        assertEquals("3.10", UploadDefaults.miles(outdoor))
        // Left alone: keep the recorded distance rather than rescale by rounding error.
        assertNull(UploadDefaults.overrideMeters(outdoor, "3.10"))
        assertEquals(1609.344 * 3.2, UploadDefaults.overrideMeters(outdoor, "3,2")!!, 1e-6)
        assertTrue(UploadDefaults.overrideMeters(outdoor, "0")!!.isNaN())
        assertTrue(UploadDefaults.overrideMeters(outdoor, "abc")!!.isNaN())

        val treadmill = log(0.0)
        assertEquals("0.00", UploadDefaults.miles(treadmill))
        assertTrue(UploadDefaults.overrideMeters(treadmill, "0.00")!!.isNaN())
        assertEquals(1609.344 * 4.0, UploadDefaults.overrideMeters(treadmill, " 4 ")!!, 1e-6)
    }

    @Test
    fun `description mentions heart rate and typed distance`() {
        assertEquals(
            "Recorded with RunStick. Avg HR 145 bpm, max 150 bpm. Distance entered by hand.",
            UploadDefaults.description(log(0.0), distanceTyped = true),
        )
    }
}
