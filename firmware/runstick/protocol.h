#pragma once
//
// RunStick wire format and display formatting.
//
// This header deliberately has NO Arduino / M5 / NimBLE dependency: only
// <stdint.h>, <stddef.h> and <stdio.h>. Everything that decides what a packet
// means lives here, so it can be reasoned about (and self-tested at boot, see
// runstickSelfTest below) without a radio or a screen in the loop.
//
// The contract is docs/ble-protocol.md. Change that file first.
//

#include <stdint.h>
#include <stddef.h>
#include <stdio.h>

// ---------------------------------------------------------------- DATA packet

static const uint8_t  kProtocolVersion = 1;
static const size_t   kDataPacketLen   = 9;
static const uint16_t kPaceInvalid     = 0xFFFF;

// flags bits (bits 5-7 are reserved: send 0, ignore on receive)
enum : uint8_t {
  FLAG_HR_VALID   = 1u << 0,
  FLAG_PACE_VALID = 1u << 1,
  FLAG_RUN_ACTIVE = 1u << 2,
  FLAG_GPS_OK     = 1u << 3,
  FLAG_STRAP_OK   = 1u << 4,
};

struct RunData {
  uint8_t  flags;
  uint8_t  hr_bpm;
  uint16_t pace_s_per_mile;
  uint16_t elapsed_s;
  uint16_t distance_cmi;

  bool hrValid()   const { return (flags & FLAG_HR_VALID) != 0 && hr_bpm != 0; }
  // Belt and braces: the doc says 0xFFFF means "not usable" *and* there is a
  // valid bit. Treat either one being unset as invalid.
  bool paceValid() const { return (flags & FLAG_PACE_VALID) != 0 && pace_s_per_mile != kPaceInvalid; }
  // Parsed but not displayed anywhere: the protocol defines the bit, the UI has
  // no use for it yet. Left here so the app side has somewhere to land.
  bool runActive() const { return (flags & FLAG_RUN_ACTIVE) != 0; }
  bool gpsOk()     const { return (flags & FLAG_GPS_OK) != 0; }
  bool strapOk()   const { return (flags & FLAG_STRAP_OK) != 0; }
};

// Returns false (and leaves `out` untouched) for anything that is not a
// well-formed v1 packet. The caller uses that to decide whether the 5 s stale
// timer gets reset, so a malformed write must never look like a fresh reading.
inline bool parsePacket(const uint8_t* data, size_t len, RunData& out) {
  if (data == nullptr) return false;
  if (len != kDataPacketLen) return false;
  if (data[0] != kProtocolVersion) return false;

  out.flags           = data[1];
  out.hr_bpm          = data[2];
  out.pace_s_per_mile = (uint16_t)((uint16_t)data[3] | ((uint16_t)data[4] << 8));
  out.elapsed_s       = (uint16_t)((uint16_t)data[5] | ((uint16_t)data[6] << 8));
  out.distance_cmi    = (uint16_t)((uint16_t)data[7] | ((uint16_t)data[8] << 8));
  return true;
}

// ------------------------------------------------------------ STATUS  (2 B)

inline void buildStatusPacket(uint8_t battery_pct, bool charging, uint8_t out[2]) {
  out[0] = (battery_pct > 100) ? 100 : battery_pct;
  out[1] = charging ? 0x01 : 0x00;
}

// ------------------------------------------------------- display formatting

static const char* const kNoValue = "--";

// Pace: "m:ss", minutes NOT zero-padded ("8:45"), capped at 59:59.
inline void formatPace(uint16_t pace_s_per_mile, char* out, size_t n) {
  if (out == nullptr || n == 0) return;
  uint32_t s = pace_s_per_mile;
  if (s > 3599u) s = 3599u;                       // cap, per docs/ble-protocol.md
  snprintf(out, n, "%u:%02u", (unsigned)(s / 60u), (unsigned)(s % 60u));
}

// Elapsed: "h:mm:ss", or "mm:ss" under an hour with the minutes zero-PADDED.
// That padding is deliberately different from formatPace above ("8:45" vs
// "08:45"); the protocol doc specifies the two formats separately, so please
// don't "tidy" them into one shared helper.
inline void formatElapsed(uint16_t elapsed_s, char* out, size_t n) {
  if (out == nullptr || n == 0) return;
  unsigned s = elapsed_s;
  unsigned h = s / 3600u; s %= 3600u;
  unsigned m = s / 60u;   s %= 60u;
  if (h > 0) snprintf(out, n, "%u:%02u:%02u", h, m, s);
  else       snprintf(out, n, "%02u:%02u", m, s);
}

// Distance: two decimals plus the unit, e.g. "7.12 mi".
inline void formatDistance(uint16_t distance_cmi, char* out, size_t n) {
  if (out == nullptr || n == 0) return;
  snprintf(out, n, "%u.%02u mi", (unsigned)(distance_cmi / 100u), (unsigned)(distance_cmi % 100u));
}

inline void formatHeartRate(uint8_t hr_bpm, char* out, size_t n) {
  if (out == nullptr || n == 0) return;
  snprintf(out, n, "%u", (unsigned)hr_bpm);
}

// --------------------------------------------------------- golden vector

// From docs/ble-protocol.md:
//
//   HR 152, pace 8:45 /mi (525 s), elapsed 1:02:03 (3723 s),
//   distance 7.12 mi (712), all five flags set
//
//   01 1F 98 0D 02 8B 0E C8 02
//    |  |  |  |__|  |__|  |__|
//    |  |  |  525   3723  712      (all u16 little-endian)
//    |  |  152 bpm
//    |  0b00011111 = HR|PACE|RUN|GPS|STRAP
//    version 1
//
static const uint8_t kGoldenPacket[kDataPacketLen] = {
  0x01, 0x1F, 0x98, 0x0D, 0x02, 0x8B, 0x0E, 0xC8, 0x02
};

// ------------------------------------------------------------- self-test

#ifdef RUNSTICK_SELFTEST

// Writes a PASS/FAIL report into `out` and returns the number of failures.
// It takes a buffer rather than printing, so this header stays free of Arduino
// (the sketch hands the text to Serial).
inline int runstickSelfTest(char* out, size_t n) {
  size_t used = 0;
  int fails = 0;
  if (out != nullptr && n > 0) out[0] = '\0';

  struct L {
    static void line(char* o, size_t cap, size_t& u, bool ok, const char* what) {
      if (o == nullptr || u >= cap) return;
      int w = snprintf(o + u, cap - u, "  [%s] %s\n", ok ? "PASS" : "FAIL", what);
      if (w > 0) { u += (size_t)w; if (u > cap) u = cap; }
    }
    static bool eq(const char* a, const char* b) {
      while (*a != '\0' && *a == *b) { ++a; ++b; }
      return *a == *b;
    }
  };

#define RS_CHECK(cond, name) do { bool ok_ = (cond); if (!ok_) ++fails; L::line(out, n, used, ok_, name); } while (0)

  RunData d;
  d.flags = 0; d.hr_bpm = 0; d.pace_s_per_mile = 0; d.elapsed_s = 0; d.distance_cmi = 0;

  RS_CHECK(parsePacket(kGoldenPacket, kDataPacketLen, d), "golden vector accepted");
  RS_CHECK(d.hr_bpm          == 152,  "hr_bpm == 152");
  RS_CHECK(d.pace_s_per_mile == 525,  "pace_s_per_mile == 525");
  RS_CHECK(d.elapsed_s       == 3723, "elapsed_s == 3723");
  RS_CHECK(d.distance_cmi    == 712,  "distance_cmi == 712");
  RS_CHECK(d.flags           == 0x1F, "flags == 0x1F");
  RS_CHECK(d.hrValid() && d.paceValid() && d.runActive() && d.gpsOk() && d.strapOk(),
           "all five flag accessors true");

  // rejections
  RunData junk = d;
  RS_CHECK(!parsePacket(kGoldenPacket, kDataPacketLen - 1, junk), "short packet rejected");
  RS_CHECK(!parsePacket(kGoldenPacket, kDataPacketLen + 1, junk), "long packet rejected");
  RS_CHECK(!parsePacket(nullptr, kDataPacketLen, junk),           "null packet rejected");
  uint8_t badver[kDataPacketLen];
  for (size_t i = 0; i < kDataPacketLen; ++i) badver[i] = kGoldenPacket[i];
  badver[0] = 2;
  RS_CHECK(!parsePacket(badver, kDataPacketLen, junk), "version != 1 rejected");
  RS_CHECK(junk.hr_bpm == 152, "rejected packets leave out untouched");

  // invalid-field handling
  RunData nf = d;
  nf.flags = 0;
  RS_CHECK(!nf.hrValid() && !nf.paceValid(), "cleared valid bits hide both fields");
  nf.flags = FLAG_PACE_VALID;
  nf.pace_s_per_mile = kPaceInvalid;
  RS_CHECK(!nf.paceValid(), "0xFFFF pace hidden even with the valid bit set");

  // formatting
  char b[24];
  formatHeartRate(152, b, sizeof(b));            RS_CHECK(L::eq(b, "152"),     "hr formats as \"152\"");
  formatPace(525, b, sizeof(b));                 RS_CHECK(L::eq(b, "8:45"),    "pace formats as \"8:45\"");
  formatPace(3599, b, sizeof(b));                RS_CHECK(L::eq(b, "59:59"),   "pace 3599 -> \"59:59\"");
  formatPace(65534, b, sizeof(b));               RS_CHECK(L::eq(b, "59:59"),   "pace caps at \"59:59\"");
  formatPace(600, b, sizeof(b));                 RS_CHECK(L::eq(b, "10:00"),   "pace 600 -> \"10:00\"");
  formatElapsed(3723, b, sizeof(b));             RS_CHECK(L::eq(b, "1:02:03"), "elapsed 3723 -> \"1:02:03\"");
  formatElapsed(123, b, sizeof(b));              RS_CHECK(L::eq(b, "02:03"),   "elapsed 123 -> \"02:03\"");
  formatElapsed(65535, b, sizeof(b));            RS_CHECK(L::eq(b, "18:12:15"),"elapsed 65535 -> \"18:12:15\"");
  formatDistance(712, b, sizeof(b));             RS_CHECK(L::eq(b, "7.12 mi"), "distance 712 -> \"7.12 mi\"");
  formatDistance(5, b, sizeof(b));               RS_CHECK(L::eq(b, "0.05 mi"), "distance 5 -> \"0.05 mi\"");

  // STATUS
  uint8_t st[2];
  buildStatusPacket(87, true, st);               RS_CHECK(st[0] == 87 && st[1] == 0x01, "status 87% charging");
  buildStatusPacket(200, false, st);             RS_CHECK(st[0] == 100 && st[1] == 0x00, "status clamps to 100%");

#undef RS_CHECK

  if (out != nullptr && used < n) {
    snprintf(out + used, n - used, "  %d failure(s)\n", fails);
  }
  return fails;
}

#endif  // RUNSTICK_SELFTEST
