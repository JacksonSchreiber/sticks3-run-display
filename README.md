# StickS3 band + clip

Designed around M5Stack's official StickS3 (K150) drawing and 3D model, sized for a 165 mm wrist.

## Files

| File | What | Print |
|---|---|---|
| `band_mold_bottom.stl` | silicone band mold, bottom half | PLA, as exported (parting face up), no supports, 0.12 mm layers |
| `band_mold_top.stl` | top half (pour hole + vents) | same |
| `band_core_default.stl` | forms the Stick pocket | PLA, as exported (on its side), 0.12 mm layers |
| `band_core_tighter.stl`, `band_core_looser.stl` | same pocket 0.1 mm tighter / looser per side, if the Stick is loose or hard to fit | same; the mold halves don't change |
| `band_preview_not_for_printing.stl` | what the finished band looks like | don't print |
| `clip_mount_631.stl` | clip cradle for theclip.com MCS-631SS (stainless, recommended) | PETG, flat side down, no supports, 5 walls, 100% infill |
| `clip_mount_661.stl` | clip cradle for theclip.com MCS-661 (coated steel, same length as the Stick) | same |
| `sticks3_band_mold.scad`, `sticks3_clip.scad` | editable sources (OpenSCAD) | |
| (not in git) `tools/` | local OpenSCAD build + M5Stack's StickS3 reference model, see below | |

To change wrist size, strap width or fit: open the `.scad` in OpenSCAD, edit the values at the top, render (F6), export STL. From WSL: `tools/scad.sh -o out.stl -D 'part="core"' -D 'squeeze=0.25' sticks3_band_mold.scad`.

## Rendering STLs without the GUI

The `tools/` folder isn't in the repo. Either install OpenSCAD normally, or grab the AppImage and M5Stack's reference model:

```
# OpenSCAD (Linux/WSL), extracted so it runs without FUSE
curl -L -o openscad.AppImage https://files.openscad.org/snapshots/OpenSCAD-2026.09.16-x86_64.AppImage
chmod +x openscad.AppImage && ./openscad.AppImage --appimage-extract
# M5Stack's StickS3 model, only needed for fit checks
curl -L -O https://raw.githubusercontent.com/m5stack/M5_Hardware/master/Products/K150_StickS3/Structures/StickS3.stl
```

## Band: casting

1. Sand both parting faces flat. Spray the halves and the core with Ease Release 200.
2. Lay the core in the bottom half: window pads against the cavity walls, side-button post in its side pocket. Close the top half. Bolt with 8 × **M3×30** + nuts, snug. The heads and nuts drop into the pockets on the outer faces.
3. Vinyl gloves. Mix ~28 ml Smooth-Sil 945, 1A:1B by weight, scrape the sides. 25 min pot life.
4. Inject slowly through the pour hole with a 60 ml syringe until silicone shows at every vent. Tap the mold on the table to free bubbles.
5. Wait 6 h. Unbolt, lift the band and core out, stretch the front lip over the core to pop it out. Trim the vent nubs and the seam.
6. Punch the 7 strap holes with a 3 mm leather punch, centred between the notches on the strap edges.

The band sits across the wrist. Hole 3 (of 7) ≈ 164 mm, hole 4 ≈ 170 mm, 6 mm per hole. USB-C is covered: pop the Stick out to charge.

## Hardware

All of it comes from one metric screw assortment (M2/M3 socket-cap or button head, with nuts and washers): 2 × M2×6, 2 × M3×4 or M3×5, 10 × M3 nuts, 8 × M3×30.

## Clip: assembly

1. Drop 2 M3 nuts into the hex pockets inside the cradle.
2. Tilt the Stick's USB-C end up a little, slide its top end under the lip against the end wall, lower the USB-C end, screw it down from underneath with 2 × **M2×6** socket-cap or button-head screws. They sit in counterbores, flush with the bottom. Never longer: the Stick's threaded holes are ~3 mm deep.
3. Bolt the clip on with 2 × **M3×4 or M3×5** socket-cap / button-head screws. With M3×6, add a washer under each head. Nothing may stick out past the nut, or it will press on the Stick.

USB-C stays open, so it charges on the clip.
