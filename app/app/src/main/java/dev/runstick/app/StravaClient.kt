package dev.runstick.app

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.withContext
import org.json.JSONException
import java.io.IOException
import java.net.HttpRetryException
import java.net.HttpURLConnection
import java.net.URL
import java.security.SecureRandom

/** Where the client id/secret and tokens live (the app's Prefs). */
interface StravaCredentials {
    val clientId: String?
    val clientSecret: String?
    val tokens: StravaTokens?
    fun saveTokens(tokens: StravaTokens)
    fun clearTokens()
}

/** Failures the UI words differently. Plain network trouble arrives as [IOException]. */
sealed class StravaException(message: String) : Exception(message) {
    class NotConnected : StravaException("not connected")
    /** The refresh token was refused: the user must authorise again. */
    class NeedsReconnect : StravaException("reconnect")
    class RateLimited : StravaException("rate limited")
    class Http(val code: Int, detail: String) : StravaException(detail)
    /** Strava accepted the file but rejected it, e.g. as a duplicate. Text as given. */
    class Rejected(detail: String) : StravaException(detail)
    /** Still processing after the poll window; the activity will most likely appear. */
    class StillProcessing : StravaException("still processing")
}

/**
 * The network half of the Strava integration: token exchange/refresh and upload + poll,
 * over HttpURLConnection on Dispatchers.IO. All formats live in [StravaApi].
 * Never log tokens, codes or the secret: this repo is public and logcat is not private.
 */
class StravaClient(private val creds: StravaCredentials) {

    private class Response(val code: Int, val body: String)

    /** Swaps the one-time authorisation code for tokens and stores them. */
    suspend fun exchangeCode(code: String): StravaTokens = withContext(Dispatchers.IO) {
        val (id, secret) = appCredentials()
        val r = post(StravaApi.TOKEN_URL, StravaApi.tokenExchangeForm(id, secret, code))
        if (r.code != 200) throw httpError(r)
        val tokens = parseTokensOrThrow(r)
        creds.saveTokens(tokens)
        tokens
    }

    /**
     * Uploads one TCX and polls until Strava has made an activity of it.
     * @return the activity id.
     */
    suspend fun upload(
        startEpochMs: Long,
        tcx: String,
        fields: List<Pair<String, String>>,
        onProcessing: () -> Unit,
    ): Long = withContext(Dispatchers.IO) {
        val boundary = "runstick" + randomHex(12)
        val body = StravaApi.multipartBody(boundary, StravaApi.tcxFilePart(startEpochMs, tcx), fields)
        val contentType = StravaApi.multipartContentType(boundary)

        val posted = authorised { token ->
            request("POST", StravaApi.UPLOADS_URL, token, body, contentType)
        }
        if (posted.code !in 200..299) throw httpError(posted)
        var status = parseStatusOrThrow(posted)
        withContext(Dispatchers.Main) { onProcessing() }

        var waitedMs = 0L
        while (!status.done) {
            if (waitedMs >= POLL_LIMIT_MS) throw StravaException.StillProcessing()
            delay(POLL_EVERY_MS)
            waitedMs += POLL_EVERY_MS
            val polled = authorised { token ->
                request("GET", StravaApi.uploadStatusUrl(status.idStr), token, null, null)
            }
            if (polled.code !in 200..299) throw httpError(polled)
            status = parseStatusOrThrow(polled)
        }
        status.error?.let { throw StravaException.Rejected(it) }
        status.activityId!!
    }

    // --- tokens -------------------------------------------------------------

    /** Runs [call] with a fresh token; on a 401 refreshes once and tries again. */
    private fun authorised(call: (String) -> Response): Response {
        val first = call(freshAccessToken(force = false))
        if (first.code != 401) return first
        return call(freshAccessToken(force = true))
    }

    private fun freshAccessToken(force: Boolean): String {
        val tokens = creds.tokens ?: throw StravaException.NotConnected()
        val nowSec = System.currentTimeMillis() / 1000L
        if (!force && tokens.expiresAt - nowSec > StravaApi.REFRESH_MARGIN_SEC) return tokens.accessToken

        val (id, secret) = appCredentials()
        val r = post(StravaApi.TOKEN_URL, StravaApi.tokenRefreshForm(id, secret, tokens.refreshToken))
        if (r.code in 400..499 && r.code != 429) {
            // Refresh token revoked or app credentials changed. A network failure throws
            // IOException before we get here, so a dead signal never logs the user out.
            creds.clearTokens()
            throw StravaException.NeedsReconnect()
        }
        if (r.code != 200) throw httpError(r)
        // The reply carries a NEW refresh token; the old one may stop working.
        val fresh = parseTokensOrThrow(r)
        creds.saveTokens(fresh)
        return fresh.accessToken
    }

    private fun appCredentials(): Pair<String, String> {
        val id = creds.clientId?.takeIf { it.isNotBlank() } ?: throw StravaException.NotConnected()
        val secret = creds.clientSecret?.takeIf { it.isNotBlank() } ?: throw StravaException.NotConnected()
        return id to secret
    }

    private fun parseTokensOrThrow(r: Response): StravaTokens = try {
        StravaApi.parseTokens(r.body)
    } catch (e: JSONException) {
        throw StravaException.Http(r.code, "unexpected token response")
    }

    private fun parseStatusOrThrow(r: Response): UploadStatus = try {
        StravaApi.parseUploadStatus(r.body)
    } catch (e: JSONException) {
        throw StravaException.Http(r.code, "unexpected upload response")
    }

    private fun httpError(r: Response): StravaException =
        if (r.code == 429) StravaException.RateLimited()
        else StravaException.Http(r.code, StravaApi.parseFault(r.body) ?: "HTTP ${r.code}")

    // --- HTTP ---------------------------------------------------------------

    private fun post(url: String, form: String): Response =
        request("POST", url, null, form.toByteArray(), "application/x-www-form-urlencoded")

    private fun request(
        method: String,
        url: String,
        bearer: String?,
        body: ByteArray?,
        contentType: String?,
    ): Response {
        val conn = URL(url).openConnection() as HttpURLConnection
        try {
            conn.requestMethod = method
            conn.connectTimeout = CONNECT_TIMEOUT_MS
            conn.readTimeout = READ_TIMEOUT_MS
            conn.setRequestProperty("Accept", "application/json")
            bearer?.let { conn.setRequestProperty("Authorization", "Bearer $it") }
            if (body != null) {
                conn.doOutput = true
                contentType?.let { conn.setRequestProperty("Content-Type", it) }
                // Known length: no chunked encoding, and the whole TCX isn't buffered twice.
                conn.setFixedLengthStreamingMode(body.size)
                conn.outputStream.use { it.write(body) }
            }
            val code = try {
                conn.responseCode
            } catch (e: HttpRetryException) {
                // Some stacks report a 401 to a fixed-length POST this way instead of
                // returning it; turn it back into a code so the refresh-and-retry runs.
                return Response(e.responseCode(), "")
            }
            val stream = if (code >= 400) conn.errorStream else conn.inputStream
            val text = stream?.use { it.readBytes().toString(Charsets.UTF_8) } ?: ""
            return Response(code, text)
        } finally {
            conn.disconnect()
        }
    }

    companion object {
        const val CONNECT_TIMEOUT_MS = 15_000
        const val READ_TIMEOUT_MS = 30_000
        const val POLL_EVERY_MS = 2_000L
        const val POLL_LIMIT_MS = 40_000L

        private val random = SecureRandom()

        fun randomHex(bytes: Int): String {
            val b = ByteArray(bytes)
            random.nextBytes(b)
            return b.joinToString("") { "%02x".format(it) }
        }
    }
}
