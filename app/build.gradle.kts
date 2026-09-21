// Root project. AGP 9 brings its own Kotlin compiler (built-in Kotlin), so there is
// deliberately no `org.jetbrains.kotlin.android` plugin here or in the module.
// See gradle.properties for the escape hatch if that turns out to be a problem.
plugins {
    alias(libs.plugins.android.application) apply false
}
