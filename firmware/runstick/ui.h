#pragma once
//
// All drawing. Everything goes into one 135x240 off-screen sprite and is pushed
// in a single blit, so the numbers never tear or flicker mid-stride.
//
// Draw helpers take lgfx::LGFXBase& rather than M5Canvas&: if the sprite cannot
// be allocated at all, the same code can paint straight onto M5.Display (ugly,
// flickery, but still a working watch) instead of a blank screen.
//

#include <M5Unified.h>

#include "config.h"
#include "protocol.h"

enum Screen : uint8_t {
  SCREEN_BOOT = 0,
  SCREEN_MAIN,
  SCREEN_EXTRAS,
  SCREEN_SLEEPING,
};

// Everything that can change what is on the glass. loop() rebuilds this each
// pass and only repaints when it differs (or once a second regardless).
struct UiState {
  uint8_t  screen;
  bool     connected;
  bool     stale;
  bool     hrShown;      // fresh AND the HR_VALID bit is set
  bool     paceShown;
  bool     gpsOk;
  bool     strapOk;
  bool     charging;
  uint8_t  hr;
  uint16_t pace;
  uint16_t elapsed;
  uint16_t distance;
  int16_t  batteryPct;   // < 0 = unknown

  bool sameAs(const UiState& o) const {
    return screen == o.screen && connected == o.connected && stale == o.stale
        && hrShown == o.hrShown && paceShown == o.paceShown
        && gpsOk == o.gpsOk && strapOk == o.strapOk && charging == o.charging
        && hr == o.hr && pace == o.pace && elapsed == o.elapsed
        && distance == o.distance && batteryPct == o.batteryPct;
  }
};

// --------------------------------------------------------------- the canvas

static M5Canvas g_canvas(&M5.Display);
static bool     g_canvasReady = false;

inline void uiBegin() {
  g_canvas.setColorDepth(16);
  if (g_canvas.createSprite(kScreenW, kScreenH) != nullptr) {
    g_canvasReady = true;
    return;
  }
  // 135 x 240 x 2 B = 64.8 kB. If internal RAM is too tight next to the NimBLE
  // host, push the sprite into PSRAM (8 MB on this board) rather than dropping
  // to 8-bit colour: we blit once a second, so PSRAM is fast enough, and the
  // red / cyan / grey stay true.
  g_canvas.setPsram(true);
  g_canvasReady = (g_canvas.createSprite(kScreenW, kScreenH) != nullptr);
}

inline lgfx::LGFXBase& uiTarget() {
  if (g_canvasReady) return g_canvas;
  return M5.Display;
}

inline void uiPush() {
  if (g_canvasReady) g_canvas.pushSprite(0, 0);
}

// ----------------------------------------------------------- font fitting

struct BigFont {
  const lgfx::IFont* font;
  float              inkRatio;  // digit ink height / fontHeight(); ranking only
  const char*        name;
};

// Largest first. The two 7-segment fonts only carry "0123456789:.-" -- which is
// exactly the charset of a heart rate, a pace and a "--" -- so the FreeSans
// entries are both the safety net for a missing glyph and what draws the words
// on the boot / sleeping screens.
static const BigFont kBigFonts[] = {
  { &fonts::Font8,              1.00f, "Font8 (7seg 75px)" },
  { &fonts::Font7,              1.00f, "Font7 (7seg 48px)" },
  { &fonts::FreeSansBold24pt7b, 0.62f, "FreeSansBold24pt"  },
  { &fonts::FreeSansBold18pt7b, 0.62f, "FreeSansBold18pt"  },
  { &fonts::FreeSansBold12pt7b, 0.62f, "FreeSansBold12pt"  },
};
static const size_t kBigFontCount = sizeof(kBigFonts) / sizeof(kBigFonts[0]);

// Leaves `g` set to the font + text size that draws `s` with the tallest digits
// that still fit inside maxW x maxH.
//
// Clip safety comes from textWidth() alone, so the approximate inkRatio above
// can only ever cost a little height -- it can never produce a string that
// overflows the box. A candidate that cannot render some character of `s`
// measures zero width for it and is skipped.
inline void fitBigText(lgfx::LGFXBase& g, const char* s, int maxW, int maxH) {
  const lgfx::IFont* bestFont = kBigFonts[kBigFontCount - 1].font;
  float bestSize = 1.0f;
  float bestInk  = -1.0f;

  for (size_t i = 0; i < kBigFontCount; ++i) {
    g.setFont(kBigFonts[i].font);
    g.setTextSize(1.0f);

    bool complete = true;
    for (const char* p = s; *p != '\0'; ++p) {
      const char one[2] = { *p, '\0' };
      if (g.textWidth(one) <= 0) { complete = false; break; }
    }
    if (!complete) continue;

    const int w = g.textWidth(s);
    const int h = g.fontHeight();
    if (w <= 0 || h <= 0) continue;

    float size = (float)maxW / (float)w;
    const float vertical = (float)maxH / (float)h;
    if (vertical < size) size = vertical;

    const float ink = (float)h * size * kBigFonts[i].inkRatio;
    if (ink > bestInk) {
      bestInk  = ink;
      bestFont = kBigFonts[i].font;
      bestSize = size;
    }
  }

  g.setFont(bestFont);
  g.setTextSize(bestSize);
}

// One-shot boot diagnostic: turns "I think Font7 has a colon" into a fact on
// the first flash. Cheap, and it is the first thing to look at if a number
// comes out blank or clipped.
inline void uiLogFontTable() {
  lgfx::LGFXBase& g = uiTarget();
  Serial.println("[font] per-glyph widths at size 1 (0 = glyph missing)");
  for (size_t i = 0; i < kBigFontCount; ++i) {
    g.setFont(kBigFonts[i].font);
    g.setTextSize(1.0f);
    Serial.printf("[font] %-18s h=%3d ", kBigFonts[i].name, g.fontHeight());
    const char* probe = "0123456789:-.";
    for (const char* p = probe; *p != '\0'; ++p) {
      const char one[2] = { *p, '\0' };
      Serial.printf("%c=%d ", *p, g.textWidth(one));
    }
    Serial.printf("| \"152\"=%d \"8:45\"=%d \"88:88\"=%d \"--\"=%d\n",
                  g.textWidth("152"), g.textWidth("8:45"),
                  g.textWidth("88:88"), g.textWidth("--"));
  }
}

// --------------------------------------------------------------- the screens

inline void uiDrawStrip(lgfx::LGFXBase& g, const UiState& st) {
  const char* label;
  uint16_t    dot;
  if (!st.connected)  { label = "WAITING"; dot = kColLinkWait;  }
  else if (st.stale)  { label = "STALE";   dot = kColLinkStale; }
  else                { label = "LINK";    dot = kColLinkOk;    }

  g.fillCircle(8, kStripH / 2, 4, dot);

  g.setFont(&fonts::Font2);
  g.setTextSize(1.0f);
  g.setTextDatum(textdatum_t::middle_left);
  g.setTextColor(kColStripText, kColBg);
  g.drawString(label, 17, kStripH / 2);

  char batt[10];
  if (st.batteryPct < 0) snprintf(batt, sizeof(batt), "--%%");
  else                   snprintf(batt, sizeof(batt), "%d%%", (int)st.batteryPct);
  g.setTextDatum(textdatum_t::middle_right);
  g.setTextColor(st.charging ? kColLinkOk : kColStripText, kColBg);
  g.drawString(batt, kScreenW - 3, kStripH / 2);

  g.drawFastHLine(0, kStripH - 1, kScreenW, kColRule);
}

// One half of the main screen: a number as big as the 135 px will take, with a
// small coloured label underneath.
inline void uiDrawNumberBlock(lgfx::LGFXBase& g, int top, const char* value, bool valid,
                              const char* label, uint16_t labelColor) {
  const char* text = valid ? value : kNoValue;

  fitBigText(g, text, kNumMaxW, kNumMaxH);
  g.setTextDatum(textdatum_t::middle_center);
  g.setTextColor(valid ? kColNumber : kColStaleNum, kColBg);
  g.drawString(text, kScreenW / 2, top + 2 + kNumMaxH / 2);

  g.setFont(&fonts::Font2);
  g.setTextSize(1.0f);
  g.setTextDatum(textdatum_t::middle_center);
  g.setTextColor(labelColor, kColBg);
  g.drawString(label, kScreenW / 2, top + kHalfH - kLabelH / 2);
}

inline void uiDrawMain(lgfx::LGFXBase& g, const UiState& st) {
  g.fillScreen(kColBg);
  uiDrawStrip(g, st);

  char hrText[8];
  char paceText[8];
  formatHeartRate(st.hr, hrText, sizeof(hrText));
  formatPace(st.pace, paceText, sizeof(paceText));

  uiDrawNumberBlock(g, kHrTop, hrText, st.hrShown, "BPM", kColHrLabel);
  g.drawFastHLine(0, kPaceTop, kScreenW, kColRule);
  uiDrawNumberBlock(g, kPaceTop, paceText, st.paceShown, "/MI", kColPaceLabel);
}

inline void uiDrawBoot(lgfx::LGFXBase& g, const UiState& st) {
  g.fillScreen(kColBg);
  uiDrawStrip(g, st);

  fitBigText(g, "RunStick", kNumMaxW, 48);
  g.setTextDatum(textdatum_t::middle_center);
  g.setTextColor(kColNumber, kColBg);
  g.drawString("RunStick", kScreenW / 2, 104);

  g.setFont(&fonts::Font2);
  g.setTextSize(1.0f);
  g.setTextColor(kColStripText, kColBg);
  g.drawString("waiting for",  kScreenW / 2, 160);
  g.drawString("phone",        kScreenW / 2, 180);

  g.setTextColor(kColLinkWait, kColBg);
  g.drawString("A  extras",    kScreenW / 2, 210);
  g.drawString("B  backlight", kScreenW / 2, 228);
}

inline void uiDrawExtrasRow(lgfx::LGFXBase& g, int y, const char* label,
                            const char* value, uint16_t valueColor) {
  g.setFont(&fonts::Font2);
  g.setTextSize(1.0f);
  g.setTextDatum(textdatum_t::top_left);
  g.setTextColor(kColStripText, kColBg);
  g.drawString(label, 5, y);

  g.setFont(&fonts::Font4);
  g.setTextSize(1.0f);
  g.setTextColor(valueColor, kColBg);
  g.drawString(value, 5, y + 17);
}

inline void uiDrawExtras(lgfx::LGFXBase& g, const UiState& st) {
  g.fillScreen(kColBg);
  uiDrawStrip(g, st);

  const bool fresh = st.connected && !st.stale;
  char buf[24];

  if (fresh) formatElapsed(st.elapsed, buf, sizeof(buf));
  else       snprintf(buf, sizeof(buf), "%s", kNoValue);
  uiDrawExtrasRow(g, 26, "TIME", buf, kColNumber);

  if (fresh) formatDistance(st.distance, buf, sizeof(buf));
  else       snprintf(buf, sizeof(buf), "%s", kNoValue);
  uiDrawExtrasRow(g, 75, "DIST", buf, kColNumber);

  if (st.batteryPct < 0)     snprintf(buf, sizeof(buf), "%s", kNoValue);
  else if (st.charging)      snprintf(buf, sizeof(buf), "%d%% CHG", (int)st.batteryPct);
  else                       snprintf(buf, sizeof(buf), "%d%%", (int)st.batteryPct);
  uiDrawExtrasRow(g, 124, "STICK", buf, st.charging ? kColFlagOk : kColNumber);

  g.drawFastHLine(6, 178, kScreenW - 12, kColRule);

  // Phone-side health, straight off the flags byte.
  g.setFont(&fonts::Font2);
  g.setTextSize(1.0f);
  g.setTextDatum(textdatum_t::top_left);
  g.setTextColor(fresh && st.gpsOk ? kColFlagOk : kColFlagBad, kColBg);
  g.drawString(fresh && st.gpsOk ? "GPS    ok" : "GPS    --", 5, 188);
  g.setTextColor(fresh && st.strapOk ? kColFlagOk : kColFlagBad, kColBg);
  g.drawString(fresh && st.strapOk ? "STRAP  ok" : "STRAP  --", 5, 212);
}

inline void uiDrawSleeping(lgfx::LGFXBase& g) {
  g.fillScreen(kColBg);

  fitBigText(g, "Sleeping", kNumMaxW, 44);
  g.setTextDatum(textdatum_t::middle_center);
  g.setTextColor(kColLinkStale, kColBg);
  g.drawString("Sleeping", kScreenW / 2, 96);

  g.setFont(&fonts::Font2);
  g.setTextSize(1.0f);
  g.setTextColor(kColStripText, kColBg);
  g.drawString("no phone for", kScreenW / 2, 140);
  g.drawString("10 minutes",   kScreenW / 2, 160);
  g.setTextColor(kColLinkWait, kColBg);
  g.drawString("press to stay", kScreenW / 2, 196);
}

inline void uiRender(const UiState& st) {
  lgfx::LGFXBase& g = uiTarget();
  switch (st.screen) {
    case SCREEN_BOOT:     uiDrawBoot(g, st);     break;
    case SCREEN_EXTRAS:   uiDrawExtras(g, st);   break;
    case SCREEN_SLEEPING: uiDrawSleeping(g);     break;
    default:              uiDrawMain(g, st);     break;
  }
  uiPush();
}
