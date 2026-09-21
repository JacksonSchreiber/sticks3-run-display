# StickS3 firmware

Runs on the M5Stack StickS3 (ESP32-S3). Its whole job is to receive two numbers
over Bluetooth LE and display them large enough to read at a glance mid-stride.

The Stick is a dumb BLE peripheral: it never talks to the chest strap or the
GPS. The phone app writes one 9-byte packet about once a second and the Stick
draws it. The wire format is `docs/ble-protocol.md` — that file is the contract,
change it first.

## Files

| Path | What |
|---|---|
| `runstick/runstick.ino` | setup/loop, screen state machine, buttons, power management, serial log |
| `runstick/config.h` | UUIDs, timings, brightness steps, colours, portrait layout |
| `runstick/protocol.h` | `RunData` + `parsePacket()` + the format helpers — no Arduino/M5/NimBLE dependency |
| `runstick/ble_link.h` | NimBLE server, advertising, callbacks, thread-safe packet handoff, STATUS notify |
| `runstick/ui.h` | sprite drawing for the boot / main / extras / sleeping screens |

Header-only on purpose: the `.h` files are included from the `.ino` and compile
as one translation unit, so everything is `inline`/`static`.

## Building

```
tools/build-firmware.sh
```

That wrapper runs the Windows `arduino-cli.exe` through WSL interop (see
`tools/env.sh`) so the compile never uses WSL memory. What it does, in effect:

```
arduino-cli compile --fqbn m5stack:esp32:m5stack_sticks3 \
  --build-path 'C:\dev\.build\runstick' firmware/runstick
arduino-cli upload  --fqbn m5stack:esp32:m5stack_sticks3 -p COM7 firmware/runstick
```

Pinned versions this was written against:

| Thing | Version |
|---|---|
| core | `m5stack:esp32@3.3.9` (Arduino-ESP32 3.x) |
| `M5Unified` | 0.2.22 |
| `M5GFX` | 0.2.29 |
| `NimBLE-Arduino` | 2.5.1 |

The BLE code targets the **NimBLE 2.x** API, which is not the API in most
tutorials: advertising does not restart itself after a disconnect, the device
name is not added to the advertisement for you, and the callbacks carry a
`NimBLEConnInfo&`. See the comment block at the top of `ble_link.h`.

### Serial

115200 baud over native USB CDC. If the port enumerates but prints nothing, the
board menu option is not set to CDC — add it to the FQBN:

```
--fqbn m5stack:esp32:m5stack_sticks3:CDCOnBoot=cdc
```

### Self-test

`protocol.h` carries the golden vector from the protocol doc. Build with

```
--build-property "compiler.cpp.extra_flags=-DRUNSTICK_SELFTEST"
```

and the Stick parses it at boot and prints a PASS/FAIL line per check to Serial:
field decode, short/long/null/wrong-version rejection, and every display
format (`8:45`, `1:02:03`, `7.12 mi`). Leave the flag off for normal builds.

## Screen

Portrait, 135 wide x 240 tall — the Stick lies *across* the wrist.

```
 ┌─────────────────┐
 │ ● LINK      87% │  status strip: link dot + state, battery %
 ├─────────────────┤
 │                 │
 │      152        │  heart rate, white, as large as 135 px allows
 │       BPM       │  label red
 ├─────────────────┤
 │                 │
 │      8:45       │  pace, white
 │       /MI       │  label cyan
 └─────────────────┘
```

The link dot is green when a fresh packet arrived within 5 s, amber when the
data has gone stale, grey while waiting for a phone.

Digit size is **measured, not guessed**: `fitBigText()` in `ui.h` walks a short
list of fonts (the 75 px and 48 px 7-segment fonts first, then FreeSansBold as a
full-ASCII safety net), measures the actual string with `textWidth()`, and picks
whichever renders the tallest digits that still fit the box. So `99` gets more
height than `152`, and `12:34` more than `8:45` would need. At boot the
per-glyph width table for every candidate font is dumped to Serial, which is the
first place to look if a number ever comes out clipped or blank.

Everything is drawn into one 135x240 `M5Canvas` sprite and pushed in a single
blit, so nothing flickers. The screen is only repainted when something changed,
or once a second regardless.

### Stale rule

No valid DATA packet for 5 s → both numbers become a dark grey `--` and the
strip shows `STALE`. If the link drops, the last numbers stay on screen for the
remainder of those 5 s rather than blanking instantly. If a packet arrives with
a field's valid bit clear (or pace `0xFFFF`), just that field shows `--`.

### Extras screen

`BtnA` short press. Shows elapsed time, distance, the Stick's own battery
(`CHG` when charging) and the phone-side flags (`GPS ok` / `STRAP ok`). Returns
to the main screen after 5 s, or on another `BtnA` press.

## Buttons

`M5.BtnA` is the front button (GPIO11); `M5.BtnB` is the side KEY2 (GPIO12).
The other side button belongs to the PMIC and is not software-readable — hold it
for download mode, double-click it to power off.

| Button | Action | Effect |
|---|---|---|
| A | short press | toggle the extras screen (auto-returns after 5 s) |
| B | short press | cycle the backlight: 40 → 110 → 220 → 40 (saved in NVS, default 110) |
| B | hold ≥ 1 s | flip the screen 180° for the other wrist (saved in NVS) |

Both B actions are on raw press/release edges rather than M5Unified's
`wasClicked()`/`wasHold()`, so the 1 s threshold is exactly 1 s. The long press
fires the moment it is reached, and the release is then swallowed.

## Power

- CPU is dropped to 80 MHz once BLE is up (the floor with the radio on) and the
  loop idles at ~20 ms.
- Connection parameters are requested at 300–500 ms / latency 0 / 6 s timeout,
  since the phone only writes at 1 Hz.
- IMU, mic, speaker and the Grove 5 V output are disabled in `M5.config()`.
- **Idle power-off:** 10 minutes with no phone *and* not on USB → a 3 s
  "Sleeping" notice, then `M5.Power.powerOff()`. A button press, a phone
  connecting, or USB going in during those 3 s cancels it.

## Serial log

One line a second while connected, plus a line for every connect/disconnect
(with the NimBLE reason code):

```
[run] hr=152 pace=8:45  t=1:02:03 d=7.12 mi flags=0x1F HR PACE RUN GPS STRAP age=412ms batt=87% 4012mV -83mA pkt=123 bad=0
```

`mA` is signed (negative = discharging) and is there to tune the 2 h battery
target against. If it reads a constant `0`, this board has no current sense —
that is the hardware, not the logging.
