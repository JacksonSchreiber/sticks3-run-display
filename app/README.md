# Android companion app (not started)

Bridges the chest strap and the phone's GPS to the StickS3, while Strava records the run normally.

## What it needs to do

- **Read the chest strap** over the standard Bluetooth Heart Rate service (0x180D), alongside Strava. Android shares one link to the strap between apps.
- **Compute pace** from fused location updates, smoothed over a rolling window (10-15 s) so the number doesn't jump.
- **Send both numbers to the Stick** about once a second over BLE.
- **Run in the background** as a foreground service with a notification, so it keeps working with the screen off and the phone in a pocket.
- **Reconnect** to both the strap and the Stick automatically after a dropout.

## Open questions

- **Milestone 1, before building anything else:** confirm Strava and this app can read the strap at the same time on this phone.
- Pace will not exactly match Strava's number, since each app smooths GPS differently.

## Constraints

- Permissions: `BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`, `ACCESS_FINE_LOCATION`, foreground service location.
- Build on Windows with Android Studio. Gradle builds are too memory-hungry for this WSL setup.
