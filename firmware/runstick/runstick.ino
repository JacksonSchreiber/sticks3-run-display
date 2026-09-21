//
// RunStick -- M5Stack StickS3 BLE run display.
//
//   phone app --BLE--> this Stick --> two big numbers on the wrist
//
// The Stick is a dumb peripheral: it never talks to the chest strap or the GPS,
// it just shows what the phone writes to it (docs/ble-protocol.md).
//
// Build: tools/build-firmware.sh  (see firmware/README.md)
//

#include <M5Unified.h>
#include <Preferences.h>

#include "config.h"
#include "protocol.h"
#include "ble_link.h"
#include "ui.h"

// ------------------------------------------------------------------- state

static Preferences g_prefs;

static uint8_t g_brightIdx = kBrightnessDefault;
static bool    g_flipped   = false;

static uint8_t  g_screen         = SCREEN_BOOT;
static bool     g_everConnected  = false;
static uint32_t g_extrasUntilMs  = 0;

static uint32_t g_btnBDownMs     = 0;
static bool     g_btnBLongFired  = false;

static uint32_t g_lastLinkMs     = 0;   // last time we had a phone (or boot)
static uint32_t g_lastDrawMs     = 0;
static bool     g_forceRedraw    = true;
static UiState  g_lastUi         = {};

static uint32_t g_lastLogMs      = 0;
static uint32_t g_seenConnects   = 0;
static uint32_t g_seenDisconnect = 0;

static int16_t  g_statusPct      = -1;  // -1 forces the first STATUS write
static bool     g_statusChg      = false;
static uint32_t g_statusSentMs   = 0;

// ------------------------------------------------------------- small helpers

static bool stickCharging() {
  // isCharging() is a tri-state (unknown / discharging / charging), so compare
  // against the enum rather than treating it as a bool.
  return M5.Power.isCharging() == m5::Power_Class::is_charging;
}

static int16_t stickBatteryPct() {
  const int32_t level = (int32_t)M5.Power.getBatteryLevel();
  if (level < 0)   return -1;              // unknown
  if (level > 100) return 100;
  return (int16_t)level;
}

static void applyRotation()   { M5.Display.setRotation(g_flipped ? 2 : 0); }
static void applyBrightness() { M5.Display.setBrightness(kBrightnessLevels[g_brightIdx]); }

// --------------------------------------------------------------- UI plumbing

static void buildUiState(UiState& st, uint32_t now, const BleSnapshot& snap) {
  // The 5 s rule is purely about packet age, not about the link: a phone that
  // is connected but silent goes stale, and a phone that just dropped keeps its
  // last numbers on screen for the remainder of the 5 s.
  const bool stale = !snap.haveData || (uint32_t)(now - snap.lastPacketMs) > kStaleMs;

  st.screen     = g_screen;
  st.connected  = snap.connected;
  st.stale      = stale;
  st.hrShown    = !stale && snap.data.hrValid();
  st.paceShown  = !stale && snap.data.paceValid();
  st.gpsOk      = snap.data.gpsOk();
  st.strapOk    = snap.data.strapOk();
  st.charging   = stickCharging();
  st.hr         = snap.data.hr_bpm;
  st.pace       = snap.data.pace_s_per_mile;
  st.elapsed    = snap.data.elapsed_s;
  st.distance   = snap.data.distance_cmi;
  st.batteryPct = stickBatteryPct();
}

static void render(uint32_t now, const BleSnapshot& snap) {
  UiState st;
  buildUiState(st, now, snap);

  const bool due = (uint32_t)(now - g_lastDrawMs) >= kRedrawIntervalMs;
  if (!g_forceRedraw && !due && st.sameAs(g_lastUi)) return;

  g_forceRedraw = false;
  g_lastUi      = st;
  g_lastDrawMs  = now;
  uiRender(st);
}

// ------------------------------------------------------------------ buttons

static void handleButtons(uint32_t now) {
  // BtnA (front, GPIO11): flick to the extras screen and back.
  if (M5.BtnA.wasPressed()) {
    // Refresh the deadline on every press, not just on the way in, so a stale
    // g_extrasUntilMs can never make the screen flash and vanish in one pass.
    g_extrasUntilMs = now + kExtrasTimeoutMs;
    g_screen = (g_screen == SCREEN_EXTRAS)
                 ? (g_everConnected ? SCREEN_MAIN : SCREEN_BOOT)
                 : SCREEN_EXTRAS;
    g_forceRedraw = true;
  }

  // BtnB (side KEY2, GPIO12): short press cycles the backlight, >= 1 s flips
  // the screen 180 for the other wrist.
  //
  // Done on raw press/release edges rather than wasClicked()/wasHold() so the
  // long-press threshold is exactly kLongPressMs and nothing depends on
  // M5Unified's internal click-count timing.
  if (M5.BtnB.wasPressed()) {
    g_btnBDownMs    = now;
    g_btnBLongFired = false;
  }
  if (M5.BtnB.isPressed() && !g_btnBLongFired &&
      (uint32_t)(now - g_btnBDownMs) >= kLongPressMs) {
    g_btnBLongFired = true;
    g_flipped = !g_flipped;
    g_prefs.putBool(RUNSTICK_NVS_FLIP, g_flipped);
    applyRotation();
    g_forceRedraw = true;
    Serial.printf("[ui] rotation=%d (saved)\n", g_flipped ? 2 : 0);
  }
  if (M5.BtnB.wasReleased() && !g_btnBLongFired) {
    g_brightIdx = (uint8_t)((g_brightIdx + 1) % 3);
    g_prefs.putUChar(RUNSTICK_NVS_BRIGHT, g_brightIdx);
    applyBrightness();
    Serial.printf("[ui] brightness=%u (saved)\n", (unsigned)kBrightnessLevels[g_brightIdx]);
  }
  // The sleep-notice loop in checkIdlePowerOff() runs its own M5.update() and
  // can swallow the release edge, so clear the latch on button state rather
  // than relying on wasReleased() ever being seen here.
  if (!M5.BtnB.isPressed()) g_btnBLongFired = false;
}

// ------------------------------------------------------------------ STATUS

static void updateStatusCharacteristic(uint32_t now, bool connected) {
  const int16_t pct = stickBatteryPct();
  const bool    chg = stickCharging();

  const bool changed   = (pct != g_statusPct) || (chg != g_statusChg);
  const bool heartbeat = connected && (uint32_t)(now - g_statusSentMs) >= kStatusHeartbeatMs;
  if (!changed && !heartbeat) return;

  g_statusPct    = pct;
  g_statusChg    = chg;
  g_statusSentMs = now;
  // Always refresh the value (so a plain read is current); only notify when
  // someone is actually listening.
  bleSetStatus((uint8_t)(pct < 0 ? 0 : pct), chg, connected);
}

// ------------------------------------------------------------------ logging

static void logLinkEvents() {
  const uint32_t connects = bleConnectEvents();
  if (connects != g_seenConnects) {
    g_seenConnects = connects;
    Serial.printf("[ble] connected (#%u)\n", (unsigned)connects);
  }
  const uint32_t disconnects = bleDisconnectEvents();
  if (disconnects != g_seenDisconnect) {
    g_seenDisconnect = disconnects;
    const int reason = bleLastDisconnectReason();
    Serial.printf("[ble] disconnected (#%u) reason=%d 0x%02X\n",
                  (unsigned)disconnects, reason, (unsigned)(reason & 0xFF));
  }
}

// One line a second while connected. The mA figure is the whole point of this
// log: it is what the 2 h battery target gets tuned against.
static void logRun(uint32_t now, const BleSnapshot& snap) {
  if (!snap.connected) return;
  if ((uint32_t)(now - g_lastLogMs) < kSerialLogMs) return;
  g_lastLogMs = now;

  const bool     stale = !snap.haveData || (uint32_t)(now - snap.lastPacketMs) > kStaleMs;
  const uint32_t age   = snap.haveData ? (uint32_t)(now - snap.lastPacketMs) : 0;

  char hr[8], pace[8], elapsed[16], dist[16];
  formatHeartRate(snap.data.hr_bpm, hr, sizeof(hr));
  formatPace(snap.data.pace_s_per_mile, pace, sizeof(pace));
  formatElapsed(snap.data.elapsed_s, elapsed, sizeof(elapsed));
  formatDistance(snap.data.distance_cmi, dist, sizeof(dist));

  char flags[32];
  snprintf(flags, sizeof(flags), "%s%s%s%s%s",
           snap.data.hrValid()   ? " HR"    : "",
           snap.data.paceValid() ? " PACE"  : "",
           snap.data.runActive() ? " RUN"   : "",
           snap.data.gpsOk()     ? " GPS"   : "",
           snap.data.strapOk()   ? " STRAP" : "");

  Serial.printf("[run] hr=%-3s pace=%-5s t=%-8s d=%-8s flags=0x%02X%s age=%ums%s "
                "batt=%d%% %dmV %dmA%s pkt=%u bad=%u\n",
                snap.data.hrValid()   ? hr   : "--",
                snap.data.paceValid() ? pace : "--",
                elapsed, dist,
                (unsigned)snap.data.flags, flags,
                (unsigned)age, stale ? " STALE" : "",
                (int)stickBatteryPct(),
                (int)M5.Power.getBatteryVoltage(),
                (int)M5.Power.getBatteryCurrent(),
                stickCharging() ? " CHG" : "",
                (unsigned)snap.packets, (unsigned)snap.rejects);
}

// --------------------------------------------------------------- idle sleep

static void checkIdlePowerOff(uint32_t now, const BleSnapshot& snap) {
  if (snap.connected) return;
  if (stickCharging()) return;                                  // on USB: stay up
  if ((uint32_t)(now - g_lastLinkMs) < kIdlePowerOffMs) return;

  Serial.println("[power] 10 min with no phone -> powering off");

  UiState st;
  buildUiState(st, now, snap);
  st.screen = SCREEN_SLEEPING;
  uiRender(st);

  const uint32_t start = millis();
  bool cancelled = false;
  while ((uint32_t)(millis() - start) < kSleepNoticeMs) {
    M5.update();
    if (M5.BtnA.wasPressed() || M5.BtnB.wasPressed()) { cancelled = true; break; }
    if (bleSnapshot().connected)                      { cancelled = true; break; }
    delay(25);
  }

  // A phone turning up, or USB going in, during the 3 s notice is the realistic
  // case -- re-check rather than powering off through it.
  if (cancelled || bleSnapshot().connected || stickCharging()) {
    Serial.println("[power] power-off cancelled");
    g_lastLinkMs  = millis();
    g_forceRedraw = true;
    return;
  }

  M5.Power.powerOff();

  // Only reached if the rail could not actually be cut (USB attached). Re-arm
  // so we don't sit spinning on the notice screen.
  g_lastLinkMs  = millis();
  g_forceRedraw = true;
}

// --------------------------------------------------------------------- boot

void setup() {
  auto cfg = M5.config();
  cfg.serial_baudrate = 115200;
  cfg.clear_display   = true;
  cfg.internal_imu    = false;   // nothing here reads motion
  cfg.internal_spk    = false;   // no sound: leave the amp unpowered
  cfg.internal_mic    = false;
  cfg.output_power    = false;   // don't push 5 V out of the Grove port
  M5.begin(cfg);

  g_prefs.begin(RUNSTICK_NVS_NAMESPACE, false);
  g_brightIdx = g_prefs.getUChar(RUNSTICK_NVS_BRIGHT, kBrightnessDefault);
  if (g_brightIdx > 2) g_brightIdx = kBrightnessDefault;
  g_flipped = g_prefs.getBool(RUNSTICK_NVS_FLIP, false);

  applyRotation();
  applyBrightness();
  uiBegin();

  // Light the boot screen before anything slow, so the Stick looks alive.
  {
    UiState st;
    BleSnapshot empty = {};
    buildUiState(st, millis(), empty);
    st.screen = SCREEN_BOOT;
    uiRender(st);
    g_lastUi = st;
  }

  // Native USB CDC only enumerates once the host opens the port; give it a
  // moment so the boot diagnostics below are not lost. Bounded, so running on
  // battery costs at most ~1.2 s.
  const uint32_t serialWaitStart = millis();
  while (!Serial && (uint32_t)(millis() - serialWaitStart) < 1200) { delay(10); }

  Serial.println();
  Serial.println("[boot] RunStick  built " __DATE__ " " __TIME__);
  Serial.printf("[boot] sprite=%s rotation=%d brightness=%u\n",
                g_canvasReady ? "135x240 ok" : "FAILED (drawing direct to LCD)",
                g_flipped ? 2 : 0, (unsigned)kBrightnessLevels[g_brightIdx]);
  uiLogFontTable();

#ifdef RUNSTICK_SELFTEST
  {
    char report[1600];
    const int fails = runstickSelfTest(report, sizeof(report));
    Serial.println("[selftest] protocol.h golden vector");
    Serial.print(report);
    Serial.printf("[selftest] %s\n", fails == 0 ? "PASS" : "FAIL");
  }
#endif

  bleBegin();
  Serial.printf("[ble] advertising=%s, name is %s\n",
                bleAdvertisingStarted() ? "yes" : "NO -- NOTHING TO CONNECT TO",
                bleNameInScanResponse() ? "in the scan response (adv payload was full)"
                                        : "in the advertising data");

  // 80 MHz is the floor with the radio on. Set it after the stack is up so
  // NimBLE initialises at full speed.
  setCpuFrequencyMhz(80);
  Serial.printf("[boot] cpu=%uMHz heap=%u\n",
                (unsigned)getCpuFrequencyMhz(), (unsigned)ESP.getFreeHeap());

  g_lastLinkMs  = millis();
  g_lastDrawMs  = millis();
  g_forceRedraw = true;
}

// --------------------------------------------------------------------- loop

void loop() {
  M5.update();
  const uint32_t now = millis();

  handleButtons(now);

  const BleSnapshot snap = bleSnapshot();
  if (snap.connected) {
    g_lastLinkMs = now;
    if (!g_everConnected) {
      g_everConnected = true;
      if (g_screen == SCREEN_BOOT) g_screen = SCREEN_MAIN;
    }
  }

  logLinkEvents();
  bleEnsureAdvertising();
  updateStatusCharacteristic(now, snap.connected);
  logRun(now, snap);

  if (g_screen == SCREEN_EXTRAS && (int32_t)(now - g_extrasUntilMs) >= 0) {
    g_screen      = g_everConnected ? SCREEN_MAIN : SCREEN_BOOT;
    g_forceRedraw = true;
  }

  checkIdlePowerOff(now, snap);
  render(now, snap);

  delay(kLoopDelayMs);
}
