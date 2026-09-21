# Android companion app

Bridges the chest strap and the phone's GPS to the StickS3, while Strava records the run normally.

Gradle project root is this folder; the single module is `app/`. Package / applicationId `dev.runstick.app`. Kotlin, plain Android Views, no Compose, no DI, no navigation library.

## What it does

While Strava records on the same phone, this app reads the strap over the standard Heart Rate service (0x180D), computes pace from GPS Doppler speed, and writes one 9-byte `DATA` packet per second to the RunStick, per `docs/ble-protocol.md`. A foreground service plus a partial wake lock keeps it going for 1-3 h with the screen off.

## Layout

| File | What |
|---|---|
| `app/src/main/java/dev/runstick/app/PacketEncoder.kt` | `RunData` -> 9 bytes LE, plus `StatusDecoder` for the 2-byte `STATUS` notification. Pure. |
| `HeartRateParser.kt` | 0x2A37 payload -> bpm (flags bit 0 picks u8 / u16 LE). Pure. |
| `PaceEstimator.kt` | time-aware EMA over `Location.getSpeed()` -> seconds per mile, or null. Pure. |
| `RunTracker.kt` | elapsed time + distance integrated from speed. Pure. |
| `StrapClient.kt` | raw `BluetoothGatt` client for the strap. |
| `StickClient.kt` | Nordic `BleManager` client for the RunStick. |
| `RunService.kt` | foreground service: owns both clients + GPS, ticks at 1 Hz, holds the `UiState` flow. |
| `MainActivity.kt` | permissions, device pickers, start/stop, live readout, battery help. |
| `DevicePicker.kt` | the "which device?" dialog (connected devices + filtered scan). |
| `Prefs.kt` | strap MAC, stick MAC, simulate flag. |
| `app/src/test/…` | JUnit4 tests for the four pure classes, including the protocol doc's golden vector. |

## Rules that are easy to break

- **Never write CCCD `0x0000` to the strap, and never touch its CCCD on teardown.** Android gives each app its own GATT client over one shared link, but the strap's CCCD is one value on the device. Disabling it would silently stop Strava's heart-rate stream mid-run. Subscribing writes `0x0001` (idempotent); stopping is `disconnect()` + `close()` on our own client and nothing else. A failed CCCD write is not an error — arriving notifications are the only proof that matters.
- **Connect to the strap by saved MAC, not by scanning.** A strap that Strava already holds has stopped advertising, so a scan will never find it; `connectGatt()` on the address works either way. Scanning is only used for first-time picking, alongside `getConnectedDevices(GATT)`.
- **The service is started from the visible activity only.** That is what lets it use location without `ACCESS_BACKGROUND_LOCATION`, which is deliberately not requested. `START_NOT_STICKY` for the same reason.
- **Foreground service types are computed at runtime.** `connectedDevice` always; `location` only when not simulating and fine location is granted — claiming `location` without the permission throws on Android 14+.

## Simulate mode

A persisted switch on the main screen. Ignores the strap and GPS and sends synthetic data (HR wandering 120-170, pace 7:30-9:30, elapsed and distance ticking), so the Stick can be tested indoors. Location permission is not requested in this mode; Bluetooth still is, because it is still writing to a real Stick.

## Versions

Set in `gradle/libs.versions.toml`, so one file changes them all.

| | |
|---|---|
| AGP | 9.4.1 (needs Gradle >= 9.6, JDK 17, build-tools 36) |
| Gradle wrapper | 9.7.1 |
| Kotlin | whatever AGP 9 bundles — see below |
| compileSdk / targetSdk / minSdk | 36 / 36 / 31 |
| Nordic BLE | `no.nordicsemi.android:ble:2.11.0` |

**AGP 9 compiles Kotlin itself.** The `org.jetbrains.kotlin.android` plugin is *rejected* by AGP 9 (`android.builtInKotlin` defaults to true), so it is not applied anywhere and no Kotlin version is declared. `kotlin.compilerOptions.jvmTarget` defaults to `android.compileOptions.targetCompatibility`, which is why JDK 17 is set only in the `compileOptions` block and there is no `kotlin { }` block. If that ever needs reverting: uncomment `android.builtInKotlin=false` in `gradle.properties`, the `kotlin` version + `kotlin-android` plugin lines in `gradle/libs.versions.toml`, and the plugin alias in `app/build.gradle.kts`.

androidx and coroutines versions are pinned conservatively — they are known to resolve and nothing here needs a newer API. Bump them in the catalog if you want.

## Building

There is no Gradle wrapper checked in yet. Generate it once on Windows (from an existing Gradle install or Android Studio), which creates `gradlew.bat` and `gradle/wrapper/gradle-wrapper.jar`; `gradle/wrapper/gradle-wrapper.properties` is already here and points at Gradle 9.7.1.

Gradle must run as a **Windows** process, never inside WSL — see `tools/env.sh`. It expects:

- `JAVA_HOME` = `C:\Program Files\Eclipse Adoptium\jdk-17*`
- `ANDROID_HOME` = `%LOCALAPPDATA%\Android\Sdk` — or create `app/local.properties` with `sdk.dir=C\:\\Users\\<you>\\AppData\\Local\\Android\\Sdk` (it is gitignored)
- `adb.exe` from the WinGet `Google.PlatformTools` package

From Windows, in this folder:

```
gradlew.bat test                 # JVM unit tests only, no device needed
gradlew.bat assembleDebug        # app/build/outputs/apk/debug/app-debug.apk
gradlew.bat installDebug         # build + install over adb
```

`tools/build-app.sh` and `tools/install-app.sh` are the WSL-side wrappers (not written yet — they belong outside this folder). They should source `tools/env.sh` and then:

```sh
# build-app.sh
cmd.exe /c "cd /d $REPO_WIN\\app && set JAVA_HOME=$JAVA_HOME_WIN&& gradlew.bat assembleDebug"

# install-app.sh
"$ADB" install -r "$REPO_WSL/app/app/build/outputs/apk/debug/app-debug.apk"
```

## First run on the phone

1. Grant permissions (Bluetooth, location, notifications).
2. **Pick RunStick** — scans for service `7a1c0001-…`; the Stick must be powered and advertising.
3. **Pick strap** — devices already connected (i.e. held by Strava) are listed first and labelled; otherwise it scans for 0x180D.
4. Open the **battery** card: tap *Ignore battery optimisation*, then on a Samsung set Settings → Apps → RunStick → Battery → **Unrestricted** and add the app to **Never auto sleeping apps**.
5. Start Strava, then Start here. Order does not matter, but step 3 is easiest with Strava already connected, since that proves both apps can read the strap at once.

## Still open

- **Milestone 1:** confirm Strava and this app read the strap at the same time on this phone. Everything above is written to make that possible, but it has not been tried.
- Pace will not match Strava's exactly — each app smooths GPS differently. This one uses a time-aware EMA with alpha 0.22 at 1 Hz (~8 s), rejects samples with speed accuracy worse than 1 m/s, and shows `--` below 0.5 m/s or after 10 s with no usable sample. Distance uses a tighter 4 s gap limit than pace's 10 s staleness window, so a dropout can't invent ground.
