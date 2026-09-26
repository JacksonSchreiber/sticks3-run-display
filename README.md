# StickS3 run display

A wrist display that shows two numbers while running: **heart rate** from a Bluetooth chest strap, and **pace** from the phone's GPS. Built on an [M5Stack StickS3](https://docs.m5stack.com/en/core/StickS3) in a cast silicone band, with a clip mount as an alternative to the band.

The point is to keep Strava recording on the phone, untouched, and still see live numbers without buying a running watch.

![Band v5: one-piece silicone band with the sealed jacket and a PETG peg buckle, from the front and the wrist side; the single open-top mold; the buckle as printed](docs/images/sleeve-v5-preview.png)

*Band v5, the current design: a one-piece silicone band (grey) that flows out of a sealed jacket around the Stick, 16 mm tall, closed by a PETG peg buckle (orange) cast into the short strap. Top row from the front and from the wrist side; bottom left the single open-top mold with the core screwed down and the buckle seated; bottom right the buckle as printed. Rendered from `hardware/sleeve_v5/`.*

The earlier one-piece silicone band (a pocket in a cast band, no strap hardware) is still in `hardware/band/`:

![The silicone band with the StickS3 in its pocket, and the band's side profile](docs/images/band-preview.png)

## How it fits together

```
chest strap ──BLE──▶ phone ──BLE──▶ StickS3
                      │
              Strava (records the run, reads the strap itself)
              companion app (reads the strap, computes GPS pace,
                             sends both numbers ~1x/second)
```

The Stick never talks to the strap. It receives two numbers and displays them.

## Layout

| Path | What |
|---|---|
| `hardware/band/` | one-piece silicone band: 3-part mold (OpenSCAD source + STLs) |
| `hardware/clip/` | printed cradle that bolts to a steel spring clip (source + STLs) |
| `hardware/sleeve_v2/` | sealed silicone sleeve with cast-in lug staples for a standard 22 mm watch strap (source + STLs) |
| `hardware/sleeve_v3/` | sealed sleeve with the lugs under the ends (buried PETG frame with fins), 52 mm long (source + STLs) |
| `hardware/sleeve_v4/` | v3 with the frame flush in the back, 16 mm tall (source + STLs) |
| `hardware/sleeve_v5/` | current: one-piece silicone band + sealed jacket with a PETG peg buckle, Fitbit-style (source + STLs) |
| `hardware/sleeve/` | earlier sleeve with a cast-in lug frame; superseded, kept for reference |
| `firmware/` | StickS3 firmware — not started |
| `app/` | Android companion app — not started |
| `docs/build-notes.md` | print settings, casting steps, assembly, tuning the fit |
| `docs/shopping-list.md` | everything to buy, with part numbers |

## Status

- **Band:** printed, cast and worn; fits well.
- **Sleeve:** v2 printed and cast, fits the Stick and the strap. v3 (lugs under the ends, 13 mm shorter) cast once: fit and strap work, but it sat 1 mm higher than the band and the first mold locked. v4 (frame flush with the back, 16 mm tall) is designed and verified. v5 drops the separate strap altogether: a one-piece band with the sealed jacket and a PETG peg buckle, designed and verified, not yet printed.
- **Clip mount:** designed, not printed.
- **Firmware and app:** working. Real chest-strap heart rate reaches the Stick over BLE while Strava records the same strap; GPS pace is implemented but the outdoor walk test and the Stick battery run-down are still to do.

## Design decisions worth knowing

- **Dimensions** come from M5Stack's K150 drawing and official 3D model, not from measurements.
- **The Stick slips in and out of the band** — the silicone lip holds it, and the pocket covers USB-C, so charging means popping it out.
- **The clip keeps USB-C reachable,** so it charges in place.
- **All fasteners** come from one M2/M3 metric screw assortment.
