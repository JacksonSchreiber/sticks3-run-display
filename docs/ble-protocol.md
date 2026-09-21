# BLE protocol: phone → RunStick

This file is the contract between `firmware/` and `app/`. Change it first, then both sides.

## Roles

- **Stick = BLE peripheral / GATT server.** It only displays what it is sent.
- **Phone app = BLE central / GATT client.** It reads the chest strap and GPS and writes one packet about once a second.

## Advertising

| Field | Value |
|---|---|
| Local name | `RunStick` (in the advertising data itself, not only the scan response) |
| Service UUID | `7a1c0001-5f3e-4b2a-9c6d-2f8e41d0b7a5` (advertised) |
| Connectable | yes; restarts advertising on every disconnect |

The app finds the Stick by service UUID, then remembers its MAC address.

## GATT

Service `7a1c0001-5f3e-4b2a-9c6d-2f8e41d0b7a5`

| Characteristic | UUID | Properties | Direction |
|---|---|---|---|
| `DATA` | `7a1c0002-5f3e-4b2a-9c6d-2f8e41d0b7a5` | write without response (also accepts write) | phone → Stick |
| `STATUS` | `7a1c0003-5f3e-4b2a-9c6d-2f8e41d0b7a5` | read, notify | Stick → phone |

No pairing or bonding. Default MTU is enough.

### DATA — 9 bytes, little-endian

| Offset | Type | Field | Notes |
|---|---|---|---|
| 0 | u8 | `version` | `1`. The Stick ignores packets with an unknown version or the wrong length. |
| 1 | u8 | `flags` | see below |
| 2 | u8 | `hr_bpm` | heart rate; `0` when not valid |
| 3 | u16 | `pace_s_per_mile` | seconds per mile; `0xFFFF` when not valid (stopped, no GPS) |
| 5 | u16 | `elapsed_s` | seconds since the run started (wraps after 18.2 h) |
| 7 | u16 | `distance_cmi` | distance in 0.01 mile units |

`flags` bits:

| Bit | Name | Meaning |
|---|---|---|
| 0 | `HR_VALID` | `hr_bpm` is a fresh reading from the strap |
| 1 | `PACE_VALID` | `pace_s_per_mile` is usable |
| 2 | `RUN_ACTIVE` | the run timer is running |
| 3 | `GPS_OK` | the phone has a usable GPS fix |
| 4 | `STRAP_OK` | the phone is connected to the chest strap |
| 5–7 | reserved | send `0`, ignore on receive |

A field is shown only if its valid bit is set; otherwise the Stick shows `--`.

**Golden test vector** (both sides unit-test against it):

```
HR 152, pace 8:45 /mi (525 s), elapsed 1:02:03 (3723 s), distance 7.12 mi (712), all five flags set

01 1F 98 0D 02 8B 0E C8 02
```

### STATUS — 2 bytes

| Offset | Type | Field | Notes |
|---|---|---|---|
| 0 | u8 | `battery_pct` | 0–100 |
| 1 | u8 | `status_flags` | bit 0 = charging |

Notified when either byte changes, and at least every 60 s while connected.

## Timing

- The phone writes `DATA` at **1 Hz**, including when values are invalid, so the Stick can tell "connected but no data" from "link lost".
- **Stale rule:** if the Stick gets no valid `DATA` packet for **5 s**, it greys out the numbers to `--` and shows a no-link indicator. It keeps advertising / waiting and recovers on the next packet.
- Preferred connection parameters requested by the Stick: interval 300–500 ms, latency 0, supervision timeout 6 s. The phone may ignore these.

## Display formats (Stick)

| Value | Format | Example |
|---|---|---|
| heart rate | integer | `152` |
| pace | `m:ss`, capped at `59:59` | `8:45` |
| elapsed | `h:mm:ss` (or `mm:ss` under an hour) | `1:02:03` |
| distance | two decimals + `mi` | `7.12 mi` |
