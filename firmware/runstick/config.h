#pragma once
//
// Everything tunable in one place: BLE identity, timings, brightness steps,
// colours and the portrait screen layout.
//

#include <stdint.h>

// ------------------------------------------------------------------ BLE ids
// Must match docs/ble-protocol.md exactly; the phone app finds us by the
// service UUID and remembers the MAC.

#define RUNSTICK_DEVICE_NAME  "RunStick"
#define RUNSTICK_SVC_UUID     "7a1c0001-5f3e-4b2a-9c6d-2f8e41d0b7a5"
#define RUNSTICK_DATA_UUID    "7a1c0002-5f3e-4b2a-9c6d-2f8e41d0b7a5"
#define RUNSTICK_STATUS_UUID  "7a1c0003-5f3e-4b2a-9c6d-2f8e41d0b7a5"

// Preferred connection parameters (docs: 300-500 ms, latency 0, 6 s timeout).
//
// NimBLE 2.x moved *timeouts* (scan/advertise/connect duration) to milliseconds,
// but NimBLEServer::updateConnParams() forwards straight to ble_gap_upd_params,
// which is still BLE-native: interval in 1.25 ms steps, supervision timeout in
// 10 ms steps. If a link comes up with an absurd interval, this is the one
// place to flip -- the numbers in the comments are the real-world values.
static const uint16_t kConnIntervalMinUnits = 240;  //  300 ms / 1.25 ms
static const uint16_t kConnIntervalMaxUnits = 400;  //  500 ms / 1.25 ms
static const uint16_t kConnLatency          = 0;
static const uint16_t kConnTimeoutUnits     = 600;  // 6000 ms / 10 ms

// Radio power. The phone is on the same wrist-to-pocket distance all run; the
// default (+9 dBm) is more than we need and costs battery.
static const int8_t kBleTxPowerDbm = 3;

// ----------------------------------------------------------------- timings

static const uint32_t kStaleMs           = 5000;             // docs: 5 s -> "--"
static const uint32_t kStatusHeartbeatMs = 60000;            // docs: notify >= 1/60 s
static const uint32_t kExtrasTimeoutMs   = 5000;             // extras screen auto-return
static const uint32_t kIdlePowerOffMs    = 10UL * 60UL * 1000UL;
static const uint32_t kSleepNoticeMs     = 3000;
static const uint32_t kSerialLogMs       = 1000;
static const uint32_t kRedrawIntervalMs  = 1000;             // forced repaint floor
static const uint32_t kLoopDelayMs       = 20;
static const uint32_t kLongPressMs       = 1000;             // BtnB hold -> flip 180

// -------------------------------------------------------------- brightness
// Real PWM on this board. Index 1 (middle) is the default.

static const uint8_t kBrightnessLevels[3] = { 40, 110, 220 };
static const uint8_t kBrightnessDefault   = 1;

// --------------------------------------------------------------------- NVS

#define RUNSTICK_NVS_NAMESPACE "runstick"
#define RUNSTICK_NVS_BRIGHT    "bright"
#define RUNSTICK_NVS_FLIP      "flip"

// ------------------------------------------------------------------ colours

static constexpr uint16_t rgb565(uint8_t r, uint8_t g, uint8_t b) {
  return (uint16_t)(((uint16_t)(r & 0xF8) << 8) | ((uint16_t)(g & 0xFC) << 3) | (uint16_t)(b >> 3));
}

static const uint16_t kColBg        = rgb565(  0,   0,   0);
static const uint16_t kColNumber    = rgb565(255, 255, 255);
static const uint16_t kColStaleNum  = rgb565( 70,  70,  70);  // the "--" grey
static const uint16_t kColHrLabel   = rgb565(255,  48,  48);
static const uint16_t kColPaceLabel = rgb565(  0, 216, 255);
static const uint16_t kColStripText = rgb565(160, 160, 160);
static const uint16_t kColRule      = rgb565( 40,  40,  40);
static const uint16_t kColLinkOk    = rgb565(  0, 224,  96);
static const uint16_t kColLinkStale = rgb565(255, 176,   0);
static const uint16_t kColLinkWait  = rgb565( 96,  96,  96);
static const uint16_t kColFlagOk    = rgb565(  0, 224,  96);
static const uint16_t kColFlagBad   = rgb565(110, 110, 110);

// ------------------------------------------------------------------ layout
// Portrait: the Stick lies across the wrist, so the panel is 135 wide x 240
// tall (rotation 0, or 2 when flipped for the other wrist).

static const int kScreenW = 135;
static const int kScreenH = 240;

static const int kStripH  = 20;                        // link / battery strip
static const int kHalfH   = (kScreenH - kStripH) / 2;  // 110 px per number block
static const int kHrTop   = kStripH;
static const int kPaceTop = kStripH + kHalfH;
static const int kLabelH  = 22;                        // "BPM" / "/MI" band

static const int kNumMarginX = 4;
static const int kNumMaxW    = kScreenW - 2 * kNumMarginX;          // 127
static const int kNumMaxH    = kHalfH - kLabelH - 4;                // 84
