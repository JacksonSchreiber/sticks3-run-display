# StickS3 run display

A wrist display that shows two numbers while running: **heart rate** from a Bluetooth chest strap, and **pace** from the phone's GPS. Built on an [M5Stack StickS3](https://docs.m5stack.com/en/core/StickS3) in a cast silicone band, with a clip mount as an alternative to the band.

The point is to keep Strava recording on the phone, untouched, and still see live numbers without buying a running watch.

![The silicone band with the StickS3 in its pocket, and the band's side profile](docs/images/band-preview.png)

*The one-piece silicone band (grey) with the StickS3 (orange) in its pocket; right, the molded side profile. Rendered from `hardware/band/stl/band_preview_not_for_printing.stl`.*

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
| `hardware/sleeve/` | earlier sleeve with a cast-in lug frame; superseded, kept for reference |
| `firmware/` | StickS3 firmware — not started |
| `app/` | Android companion app — not started |
| `docs/build-notes.md` | print settings, casting steps, assembly, tuning the fit |
| `docs/shopping-list.md` | everything to buy, with part numbers |

## Status

- **Hardware:** done and fit-checked against M5Stack's official StickS3 model. Not yet printed or cast.
- **Firmware and app:** not started. See the READMEs in those folders for what they need to do.

## Design decisions worth knowing

- **Dimensions** come from M5Stack's K150 drawing and official 3D model, not from measurements.
- **The Stick slips in and out of the band** — the silicone lip holds it, and the pocket covers USB-C, so charging means popping it out.
- **The clip keeps USB-C reachable,** so it charges in place.
- **All fasteners** come from one M2/M3 metric screw assortment.
