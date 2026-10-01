package dev.runstick.app

import android.content.Context

/**
 * Devices, the simulate flag, and the Strava credentials. The Strava API app's id and
 * secret belong to the user and live only here, on the phone (allowBackup is false); they
 * are never in the repo.
 */
class Prefs(context: Context) : StravaCredentials {

    private val sp = context.applicationContext
        .getSharedPreferences("runstick", Context.MODE_PRIVATE)

    var strapMac: String?
        get() = sp.getString(KEY_STRAP_MAC, null)
        set(value) = sp.edit().putString(KEY_STRAP_MAC, value).apply()

    var strapName: String?
        get() = sp.getString(KEY_STRAP_NAME, null)
        set(value) = sp.edit().putString(KEY_STRAP_NAME, value).apply()

    var stickMac: String?
        get() = sp.getString(KEY_STICK_MAC, null)
        set(value) = sp.edit().putString(KEY_STICK_MAC, value).apply()

    var stickName: String?
        get() = sp.getString(KEY_STICK_NAME, null)
        set(value) = sp.edit().putString(KEY_STICK_NAME, value).apply()

    var simulate: Boolean
        get() = sp.getBoolean(KEY_SIMULATE, false)
        set(value) = sp.edit().putBoolean(KEY_SIMULATE, value).apply()

    /** Why the last run ended itself; shown on screen until the next run starts. */
    var autoStopNote: String?
        get() = sp.getString(KEY_AUTO_STOP_NOTE, null)
        set(value) = sp.edit().putString(KEY_AUTO_STOP_NOTE, value).apply()

    // --- Strava -------------------------------------------------------------

    override var clientId: String?
        get() = sp.getString(KEY_STRAVA_CLIENT_ID, null)
        set(value) = sp.edit().putString(KEY_STRAVA_CLIENT_ID, value).apply()

    override var clientSecret: String?
        get() = sp.getString(KEY_STRAVA_CLIENT_SECRET, null)
        set(value) = sp.edit().putString(KEY_STRAVA_CLIENT_SECRET, value).apply()

    /** The `state` sent with the authorise request, until the redirect comes back. */
    var oauthState: String?
        get() = sp.getString(KEY_STRAVA_OAUTH_STATE, null)
        set(value) = sp.edit().putString(KEY_STRAVA_OAUTH_STATE, value).apply()

    override val tokens: StravaTokens?
        get() {
            val access = sp.getString(KEY_STRAVA_ACCESS, null) ?: return null
            val refresh = sp.getString(KEY_STRAVA_REFRESH, null) ?: return null
            return StravaTokens(access, refresh, sp.getLong(KEY_STRAVA_EXPIRES_AT, 0L))
        }

    val stravaConnected: Boolean get() = tokens != null

    // commit(), not apply(): a refresh rotates the refresh token, and losing the new one
    // to a process death would log the user out. Only ever called off the main thread.
    override fun saveTokens(tokens: StravaTokens) {
        sp.edit()
            .putString(KEY_STRAVA_ACCESS, tokens.accessToken)
            .putString(KEY_STRAVA_REFRESH, tokens.refreshToken)
            .putLong(KEY_STRAVA_EXPIRES_AT, tokens.expiresAt)
            .commit()
    }

    override fun clearTokens() {
        sp.edit()
            .remove(KEY_STRAVA_ACCESS)
            .remove(KEY_STRAVA_REFRESH)
            .remove(KEY_STRAVA_EXPIRES_AT)
            .commit()
    }

    /** Strava activity id a workout was uploaded as, keyed by the workout's start time. */
    fun uploadedActivityId(startEpochMs: Long): Long? {
        val key = KEY_UPLOADED_PREFIX + startEpochMs
        return if (sp.contains(key)) sp.getLong(key, 0L) else null
    }

    fun setUploaded(startEpochMs: Long, activityId: Long) {
        sp.edit().putLong(KEY_UPLOADED_PREFIX + startEpochMs, activityId).apply()
    }

    private companion object {
        const val KEY_STRAP_MAC = "strap_mac"
        const val KEY_STRAP_NAME = "strap_name"
        const val KEY_STICK_MAC = "stick_mac"
        const val KEY_STICK_NAME = "stick_name"
        const val KEY_SIMULATE = "simulate"
        const val KEY_AUTO_STOP_NOTE = "auto_stop_note"
        const val KEY_STRAVA_CLIENT_ID = "strava_client_id"
        const val KEY_STRAVA_CLIENT_SECRET = "strava_client_secret"
        const val KEY_STRAVA_OAUTH_STATE = "strava_oauth_state"
        const val KEY_STRAVA_ACCESS = "strava_access_token"
        const val KEY_STRAVA_REFRESH = "strava_refresh_token"
        const val KEY_STRAVA_EXPIRES_AT = "strava_expires_at"
        const val KEY_UPLOADED_PREFIX = "strava_uploaded_"
    }
}
