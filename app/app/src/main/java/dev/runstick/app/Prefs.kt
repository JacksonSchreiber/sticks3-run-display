package dev.runstick.app

import android.content.Context

/** The three things worth remembering between runs. */
class Prefs(context: Context) {

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

    private companion object {
        const val KEY_STRAP_MAC = "strap_mac"
        const val KEY_STRAP_NAME = "strap_name"
        const val KEY_STICK_MAC = "stick_mac"
        const val KEY_STICK_NAME = "stick_name"
        const val KEY_SIMULATE = "simulate"
    }
}
