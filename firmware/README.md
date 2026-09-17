# StickS3 firmware (not started)

Runs on the M5Stack StickS3 (ESP32-S3). Its whole job is to receive two numbers over Bluetooth LE and display them large enough to read at a glance mid-stride.

## What it needs to do

- **Advertise as a BLE peripheral** with a custom service: one characteristic the phone writes heart rate and pace into, roughly once a second.
- **Display** heart rate and pace stacked, in the biggest digits that fit the 240x135 screen, plus a marker when data goes stale (no update for ~5 s).
- **Survive a dropped connection:** keep showing the last values, dimmed or marked stale, and re-advertise.
- **Manage power:** dim or sleep the backlight when idle; the battery is 250 mAh and the screen is the main draw. Target: a 2 h run.
- **Buttons:** one to toggle backlight brightness, one to reset/re-pair.

## Constraints

- Board: `m5stack-sticks3`, ESP32-S3, 8 MB flash / 8 MB PSRAM.
- Likely libraries: M5Unified for display/buttons, NimBLE-Arduino for BLE.
- Build on Windows with Arduino IDE 2 or PlatformIO. Building inside WSL is memory-hungry.
