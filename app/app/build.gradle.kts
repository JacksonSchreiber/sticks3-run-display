plugins {
    alias(libs.plugins.android.application)
    // AGP 9 has built-in Kotlin and REJECTS this plugin. Only uncomment together with
    // android.builtInKotlin=false in gradle.properties.
    // alias(libs.plugins.kotlin.android)
}

android {
    namespace = "dev.runstick.app"
    compileSdk = 36

    defaultConfig {
        applicationId = "dev.runstick.app"
        minSdk = 31
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"
    }

    buildTypes {
        release {
            // Sideloaded personal build: nothing to gain from shrinking, plenty to lose
            // (Nordic's BLE library and the reflection-free GATT callbacks).
            isMinifyEnabled = false
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }

    // With built-in Kotlin, kotlin's jvmTarget defaults to targetCompatibility, so this
    // is the only place the JDK level is set. No `kotlin { }` block is needed.
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildFeatures {
        viewBinding = true
    }

    lint {
        // Sideloaded app: the battery-optimisation prompt is intentional, and a lint
        // failure must never block a build we can only run on the other machine.
        abortOnError = false
    }
}

dependencies {
    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.appcompat)
    implementation(libs.material)
    implementation(libs.androidx.lifecycle.runtime.ktx)
    implementation(libs.kotlinx.coroutines.android)
    implementation(libs.nordic.ble)

    testImplementation(libs.junit)
}
