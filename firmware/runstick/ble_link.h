#pragma once
//
// NimBLE peripheral: one service, DATA in / STATUS out. Written against
// NimBLE-Arduino 2.x, which differs from nearly every tutorial online:
//
//   * advertising does NOT restart itself after a disconnect
//     -> advertiseOnDisconnect(true), plus a watchdog in bleEnsureAdvertising()
//   * the device name is NOT put in the advertisement for you
//     -> we build NimBLEAdvertisementData by hand
//   * callbacks carry a NimBLEConnInfo& (and onDisconnect an int reason)
//   * the 0x2902 CCCD is created automatically for NOTIFY characteristics
//
// THREADING: NimBLE runs its own FreeRTOS host task, so onWrite() / onConnect()
// do NOT run on the Arduino loop task. The only state they touch is s_shared,
// and only inside a portMUX critical section (a 16-byte copy, so the radio task
// is never blocked for long). loop() takes a snapshot with bleSnapshot() and
// does every bit of drawing, logging and power management from there.
//

#include <Arduino.h>
#include <NimBLEDevice.h>

#include "config.h"
#include "protocol.h"

struct BleSnapshot {
  RunData  data;          // last accepted packet (kept across a disconnect)
  uint32_t lastPacketMs;  // millis() when it arrived
  uint32_t packets;       // accepted
  uint32_t rejects;       // wrong length / wrong version
  bool     connected;
  bool     haveData;      // at least one packet accepted since boot
};

// ------------------------------------------------- state shared across tasks

static portMUX_TYPE s_bleMux = portMUX_INITIALIZER_UNLOCKED;
static BleSnapshot  s_shared = {};

// Single writer (NimBLE task), single reader (loop) -- loop only ever compares
// these against its own last-seen copy, so a torn read would cost one extra log
// line and nothing else. No lock needed.
static volatile uint32_t s_connectEvents    = 0;
static volatile uint32_t s_disconnectEvents = 0;
static volatile int      s_lastDiscReason   = 0;

static NimBLECharacteristic* s_dataChr   = nullptr;
static NimBLECharacteristic* s_statusChr = nullptr;
static bool s_advStarted       = false;
static bool s_advNameInScanRsp = false;

// --------------------------------------------------------------- callbacks

class RunStickServerCallbacks : public NimBLEServerCallbacks {
  void onConnect(NimBLEServer* server, NimBLEConnInfo& info) override {
    // The phone writes once a second, so a 7.5 ms connection interval would
    // just burn radio slots on empty events. Ask for something lazy; the phone
    // is free to ignore it (docs/ble-protocol.md).
    server->updateConnParams(info.getConnHandle(),
                             kConnIntervalMinUnits, kConnIntervalMaxUnits,
                             kConnLatency, kConnTimeoutUnits);

    portENTER_CRITICAL(&s_bleMux);
    s_shared.connected = true;
    portEXIT_CRITICAL(&s_bleMux);
    s_connectEvents = s_connectEvents + 1;
  }

  void onDisconnect(NimBLEServer* server, NimBLEConnInfo& info, int reason) override {
    (void)server; (void)info;
    portENTER_CRITICAL(&s_bleMux);
    s_shared.connected = false;
    portEXIT_CRITICAL(&s_bleMux);
    s_lastDiscReason = reason;
    s_disconnectEvents = s_disconnectEvents + 1;
    // advertiseOnDisconnect(true) restarts advertising for us; bleEnsureAdvertising()
    // in loop() covers the case where it silently doesn't.
  }
};

class RunStickDataCallbacks : public NimBLECharacteristicCallbacks {
  void onWrite(NimBLECharacteristic* chr, NimBLEConnInfo& info) override {
    (void)info;
    // Copy the attribute value: depending on the build, getValue() may return by
    // value, so holding a pointer into a temporary would dangle.
    NimBLEAttValue value = chr->getValue();

    RunData parsed;
    const bool ok = parsePacket(value.data(), value.size(), parsed);
    const uint32_t now = millis();   // taken outside the critical section

    portENTER_CRITICAL(&s_bleMux);
    if (ok) {
      s_shared.data         = parsed;
      s_shared.lastPacketMs = now;
      s_shared.haveData     = true;
      s_shared.packets++;
    } else {
      // A malformed write must not look like a fresh reading, so the stale
      // timer is deliberately left alone here.
      s_shared.rejects++;
    }
    portEXIT_CRITICAL(&s_bleMux);
  }
};

// ------------------------------------------------------------------- API

inline BleSnapshot bleSnapshot() {
  BleSnapshot out;
  portENTER_CRITICAL(&s_bleMux);
  out = s_shared;
  portEXIT_CRITICAL(&s_bleMux);
  return out;
}

inline uint32_t bleConnectEvents()    { return s_connectEvents; }
inline uint32_t bleDisconnectEvents() { return s_disconnectEvents; }
inline int      bleLastDisconnectReason() { return s_lastDiscReason; }
inline bool     bleAdvertisingStarted()   { return s_advStarted; }
inline bool     bleNameInScanResponse()   { return s_advNameInScanRsp; }

// Sets the STATUS value (so a plain read is always current) and optionally
// notifies. docs: battery_pct, then bit 0 = charging.
inline void bleSetStatus(uint8_t batteryPct, bool charging, bool notify) {
  if (s_statusChr == nullptr) return;
  uint8_t buf[2];
  buildStatusPacket(batteryPct, charging, buf);
  s_statusChr->setValue(buf, sizeof(buf));
  if (notify) s_statusChr->notify();
}

// Watchdog for the 2.x "advertising does not come back" trap.
inline void bleEnsureAdvertising() {
  NimBLEServer* server = NimBLEDevice::getServer();
  if (server != nullptr && server->getConnectedCount() > 0) return;
  NimBLEAdvertising* adv = NimBLEDevice::getAdvertising();
  if (adv != nullptr && !adv->isAdvertising()) adv->start();
}

inline void bleBegin() {
  NimBLEDevice::init(RUNSTICK_DEVICE_NAME);      // GAP name (separate from adv data)
  NimBLEDevice::setPower(kBleTxPowerDbm);

  NimBLEServer* server = NimBLEDevice::createServer();
  server->setCallbacks(new RunStickServerCallbacks());

  NimBLEService* svc = server->createService(RUNSTICK_SVC_UUID);

  s_dataChr = svc->createCharacteristic(
      RUNSTICK_DATA_UUID,
      NIMBLE_PROPERTY::WRITE_NR | NIMBLE_PROPERTY::WRITE);
  s_dataChr->setCallbacks(new RunStickDataCallbacks());

  s_statusChr = svc->createCharacteristic(
      RUNSTICK_STATUS_UUID,
      NIMBLE_PROPERTY::READ | NIMBLE_PROPERTY::NOTIFY);   // 0x2902 added for us
  // Seed it so a read before the first battery change returns valid bytes.
  uint8_t seed[2] = { 0, 0 };
  s_statusChr->setValue(seed, sizeof(seed));

  // In NimBLE 2.x this lives on the server, and services start with the server.
  server->advertiseOnDisconnect(true);

  NimBLEAdvertising* adv = NimBLEDevice::getAdvertising();

  // The whole advertising budget is 31 bytes and this should fit exactly:
  //   flags 3 + 128-bit service UUID 18 + "RunStick" 10 = 31.
  // The protocol doc wants the name in the advertisement itself, so try that
  // first -- but if the stack refuses the payload, fall back to name-in-scan-
  // response rather than ending up with a Stick that never advertises. Which
  // path won is logged at boot, so a failure here is three seconds to diagnose.
  {
    NimBLEAdvertisementData advData;
    advData.setFlags(BLE_HS_ADV_F_DISC_GEN | BLE_HS_ADV_F_BREDR_UNSUP);
    advData.addServiceUUID(RUNSTICK_SVC_UUID);
    advData.setName(RUNSTICK_DEVICE_NAME);
    adv->setAdvertisementData(advData);
    adv->enableScanResponse(false);
    s_advNameInScanRsp = false;
    s_advStarted = adv->start();
  }

  if (!s_advStarted) {
    adv->stop();
    NimBLEAdvertisementData advData;
    advData.setFlags(BLE_HS_ADV_F_DISC_GEN | BLE_HS_ADV_F_BREDR_UNSUP);
    advData.addServiceUUID(RUNSTICK_SVC_UUID);
    NimBLEAdvertisementData scanData;
    scanData.setName(RUNSTICK_DEVICE_NAME);
    adv->setAdvertisementData(advData);
    adv->setScanResponseData(scanData);
    adv->enableScanResponse(true);
    s_advNameInScanRsp = true;
    s_advStarted = adv->start();
  }
}
