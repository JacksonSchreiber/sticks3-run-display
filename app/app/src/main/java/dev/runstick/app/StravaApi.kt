package dev.runstick.app

import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject
import java.io.ByteArrayOutputStream
import java.net.URLEncoder

/** What the token endpoint hands back, for both the code exchange and a refresh. */
data class StravaTokens(
    val accessToken: String,
    val refreshToken: String,
    /** Epoch seconds. */
    val expiresAt: Long,
)

/** One poll of `GET /uploads/{id}` (also the shape of the `POST /uploads` reply). */
data class UploadStatus(
    val idStr: String,
    val status: String,
    /** Tag-stripped error text, or null. */
    val error: String?,
    val activityId: Long?,
) {
    val done: Boolean get() = error != null || activityId != null
}

/** Outcome of the OAuth redirect back into the app. */
sealed class AuthRedirect {
    data class Code(val code: String) : AuthRedirect()
    object Denied : AuthRedirect()
    object MissingWriteScope : AuthRedirect()
    /** State mismatch or a replayed intent: ignore quietly. */
    object Stale : AuthRedirect()
    data class Failed(val error: String) : AuthRedirect()
}

class FilePart(val name: String, val filename: String, val contentType: String, val bytes: ByteArray)

/**
 * Everything about the Strava API that doesn't touch the network: URLs, request bodies and
 * response parsing, kept pure so the JVM tests can pin them down.
 *
 * org.json caveat: the app runs Android's copy and the tests run org.json:json, which
 * disagree on edge cases (Android's optString(null) is "null"). So: isNull() first, then
 * getLong()/getString() on values of the right type only.
 */
object StravaApi {
    const val AUTHORIZE_URL = "https://www.strava.com/oauth/mobile/authorize"
    const val TOKEN_URL = "https://www.strava.com/api/v3/oauth/token"
    const val UPLOADS_URL = "https://www.strava.com/api/v3/uploads"
    const val REDIRECT_URI = "runstick://localhost/strava"
    const val SCOPE = "activity:write"

    /** Refresh when the access token has less than this left. */
    const val REFRESH_MARGIN_SEC = 5 * 60

    fun authorizeUrl(clientId: String, state: String): String =
        AUTHORIZE_URL + "?" + formEncode(
            listOf(
                "client_id" to clientId,
                "redirect_uri" to REDIRECT_URI,
                "response_type" to "code",
                "approval_prompt" to "auto",
                "scope" to SCOPE,
                "state" to state,
            )
        )

    fun activityUrl(activityId: Long) = "https://www.strava.com/activities/$activityId"

    fun uploadStatusUrl(idStr: String) = "$UPLOADS_URL/$idStr"

    /**
     * Checks the query parameters of `runstick://localhost/strava?...`. Strava reports the
     * granted scope as a comma list ("read,activity:write"); the user can untick upload.
     */
    fun checkRedirect(
        expectedState: String?,
        state: String?,
        code: String?,
        error: String?,
        scope: String?,
    ): AuthRedirect = when {
        expectedState.isNullOrEmpty() || state != expectedState -> AuthRedirect.Stale
        error == "access_denied" -> AuthRedirect.Denied
        error != null -> AuthRedirect.Failed(error)
        code.isNullOrEmpty() -> AuthRedirect.Failed("no code")
        scope?.split(',')?.map { it.trim() }?.contains(SCOPE) != true -> AuthRedirect.MissingWriteScope
        else -> AuthRedirect.Code(code)
    }

    fun tokenExchangeForm(clientId: String, clientSecret: String, code: String): String =
        formEncode(
            listOf(
                "client_id" to clientId,
                "client_secret" to clientSecret,
                "code" to code,
                "grant_type" to "authorization_code",
            )
        )

    fun tokenRefreshForm(clientId: String, clientSecret: String, refreshToken: String): String =
        formEncode(
            listOf(
                "client_id" to clientId,
                "client_secret" to clientSecret,
                "grant_type" to "refresh_token",
                "refresh_token" to refreshToken,
            )
        )

    fun formEncode(pairs: List<Pair<String, String>>): String =
        pairs.joinToString("&") { (k, v) -> enc(k) + "=" + enc(v) }

    private fun enc(s: String) = URLEncoder.encode(s, "UTF-8")

    /** @throws JSONException when a required field is missing. */
    fun parseTokens(json: String): StravaTokens {
        val o = JSONObject(json)
        return StravaTokens(
            accessToken = o.getString("access_token"),
            refreshToken = o.getString("refresh_token"),
            expiresAt = o.getLong("expires_at"),
        )
    }

    /** Upload fields, in the order they go on the wire. */
    fun uploadFields(
        name: String,
        description: String,
        trainer: Boolean,
        startEpochMs: Long,
    ): List<Pair<String, String>> = buildList {
        add("data_type" to "tcx")
        add("sport_type" to "Run")
        add("name" to name)
        add("description" to description)
        if (trainer) add("trainer" to "1")
        // Lets Strava (and us) recognise a second upload of the same run.
        add("external_id" to "runstick-$startEpochMs")
    }

    fun tcxFilePart(startEpochMs: Long, tcx: String) =
        FilePart("file", "runstick-$startEpochMs.tcx", "application/octet-stream", tcx.toByteArray())

    fun multipartContentType(boundary: String) = "multipart/form-data; boundary=$boundary"

    /** RFC 7578 body: the file part first, then the text fields, CRLF line ends throughout. */
    fun multipartBody(boundary: String, file: FilePart, fields: List<Pair<String, String>>): ByteArray {
        val out = ByteArrayOutputStream()
        fun line(s: String = "") = out.write((s + "\r\n").toByteArray())

        line("--$boundary")
        line("Content-Disposition: form-data; name=\"${file.name}\"; filename=\"${file.filename}\"")
        line("Content-Type: ${file.contentType}")
        line()
        out.write(file.bytes)
        line()
        for ((k, v) in fields) {
            line("--$boundary")
            line("Content-Disposition: form-data; name=\"$k\"")
            line()
            line(v)
        }
        line("--$boundary--")
        return out.toByteArray()
    }

    /** @throws JSONException on a body that isn't an upload object. */
    fun parseUploadStatus(json: String): UploadStatus {
        val o = JSONObject(json)
        val idStr = if (!o.isNull("id_str")) o.getString("id_str") else o.getLong("id").toString()
        return UploadStatus(
            idStr = idStr,
            status = if (o.isNull("status")) "" else o.getString("status"),
            error = if (o.isNull("error")) null else stripHtml(o.getString("error")).ifEmpty { null },
            activityId = if (o.isNull("activity_id")) null else o.getLong("activity_id"),
        )
    }

    /**
     * Readable text from a Strava error body (`{"message": ..., "errors": [...]}`), or
     * null if it isn't one.
     */
    fun parseFault(json: String): String? = try {
        val o = JSONObject(json)
        val message = if (o.isNull("message")) null else o.getString("message")
        val details = (if (o.isNull("errors")) JSONArray() else o.getJSONArray("errors")).let { arr ->
            (0 until arr.length()).mapNotNull { i ->
                val e = arr.optJSONObject(i) ?: return@mapNotNull null
                listOf("resource", "field", "code")
                    .mapNotNull { k -> if (e.isNull(k)) null else e.getString(k) }
                    .joinToString(" ")
                    .ifEmpty { null }
            }
        }
        when {
            message == null && details.isEmpty() -> null
            details.isEmpty() -> message
            else -> "${message ?: "Error"}: ${details.joinToString("; ")}"
        }
    } catch (e: JSONException) {
        null
    }

    /** Upload errors can contain markup, e.g. a link to the activity it duplicates. */
    fun stripHtml(s: String): String =
        s.replace(Regex("<[^>]*>"), "")
            .replace("&lt;", "<")
            .replace("&gt;", ">")
            .replace("&quot;", "\"")
            .replace("&#39;", "'")
            .replace("&amp;", "&")
            .replace(Regex("\\s+"), " ")
            .trim()
}

/** What the upload dialog starts with. */
object UploadDefaults {
    fun name(log: WorkoutLog): String = when {
        log.simulated -> "RunStick test (simulated)"
        log.hasNoDistance -> "Treadmill run"
        else -> "Run"
    }

    fun treadmill(log: WorkoutLog): Boolean = log.hasNoDistance

    /** Recorded miles as shown in the distance box (2 dp, Locale.US). */
    fun miles(log: WorkoutLog): String =
        String.format(java.util.Locale.US, "%.2f", log.totalDistanceM / PaceEstimator.METERS_PER_MILE)

    /**
     * The distance override in metres from what the user typed, or null to keep the
     * recorded distance (box left at its prefill: no point rescaling by rounding error).
     * Accepts a comma decimal separator. Returns NaN for unusable input.
     */
    fun overrideMeters(log: WorkoutLog, typed: String): Double? {
        val text = typed.trim().replace(',', '.')
        if (text == miles(log) && !log.hasNoDistance) return null
        val mi = text.toDoubleOrNull()
        if (mi == null || mi.isNaN() || mi.isInfinite() || mi <= 0.0) return Double.NaN
        return mi * PaceEstimator.METERS_PER_MILE
    }

    fun description(log: WorkoutLog, distanceTyped: Boolean): String = buildString {
        append("Recorded with RunStick.")
        if (log.avgHr != null) append(" Avg HR ${log.avgHr} bpm, max ${log.maxHr} bpm.")
        if (distanceTyped) append(" Distance entered by hand.")
    }
}
