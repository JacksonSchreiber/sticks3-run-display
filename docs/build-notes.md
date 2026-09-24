# Build notes

Everything dimensional comes from M5Stack's StickS3 (K150) drawing and official 3D model. Band sized for a 165 mm wrist.

## Files

| File | What | Print |
|---|---|---|
| `hardware/band/stl/band_mold_bottom.stl` | band mold, bottom half | PLA, as exported (parting face up), no supports, 0.12 mm layers |
| `hardware/band/stl/band_mold_top.stl` | top half (pour hole + vents) | same |
| `hardware/band/stl/band_core_default.stl` | forms the Stick pocket | PLA, as exported (on its side), 0.12 mm layers |
| `hardware/band/stl/band_core_tighter.stl`, `band_core_looser.stl` | pocket 0.1 mm tighter / looser per side | same; the mold halves never change |
| `hardware/band/stl/band_preview_not_for_printing.stl` | what the finished band looks like | don't print |
| `hardware/clip/stl/clip_mount_631.stl` | cradle for theclip.com MCS-631SS (stainless, recommended) | PETG, flat side down, no supports, 5 walls, 100% infill |
| `hardware/clip/stl/clip_mount_661.stl` | cradle for MCS-661 (coated steel, same length as the Stick) | same |
| `hardware/band/band_mold.scad`, `hardware/clip/clip_mount.scad` | editable sources (OpenSCAD) | |

## Hardware

All of it comes from one metric screw assortment (M2/M3, socket-cap or button head, with nuts and washers):

- 2 x M2x6 — hold the Stick in the clip cradle
- 2 x M3x4 or M3x5 — bolt the steel clip on (with M3x6, add a washer under each head)
- 8 x M3x30 + 8 nuts — clamp the mold
- 2 x M3 nuts — clip cradle

## Changing the design

Open a `.scad` in OpenSCAD, edit the values at the top, render (F6), export STL. Or from a shell:

```
openscad -o core.stl -D 'part="core"' -D 'squeeze=0.25' hardware/band/band_mold.scad
openscad -o clip.stl -D 'clip_model="661"' hardware/clip/clip_mount.scad
```

`squeeze` only affects the core, so tuning the grip never means reprinting the two big mold halves.

## Rendering without a GUI

The `tools/` folder is not in the repo. Either install OpenSCAD normally, or fetch the AppImage and M5Stack's reference model:

```
curl -L -o openscad.AppImage https://files.openscad.org/snapshots/OpenSCAD-2026.09.16-x86_64.AppImage
chmod +x openscad.AppImage && ./openscad.AppImage --appimage-extract    # runs without FUSE
curl -L -O https://raw.githubusercontent.com/m5stack/M5_Hardware/master/Products/K150_StickS3/Structures/StickS3.stl
```

## Band: casting

1. Sand both parting faces flat. Spray the halves and the core with Ease Release 200.
2. Lay the core in the bottom half: window pads against the cavity walls, side-button post in its side pocket. Close the top half. Bolt with 8 x M3x30 + nuts, snug. Heads and nuts drop into the pockets on the outer faces.
3. Vinyl gloves, never latex. The band needs ~18 ml, but cups, sticks and the syringe swallow a lot, so **mix at least 2x that: 20 g Part A + 20 g Part B** (Smooth-Sil 945 is 1A:1B by weight, 25 min pot life). For black, stir pigment into Part A first at **3% of total weight (about 1.2 g for 40 g)**, the maximum Smooth-On allows. The 945 base cures a strong purple; 1.5% black left it visibly purple, so use the full 3% and a concentrated pigment such as Silc Pig.
4. Inject slowly through the pour hole with a 60 ml syringe until silicone shows at every vent. Tap the mold on the table to free bubbles.
5. Wait 6 h (Smooth-Sil 945; SORTA-Clear 37 is 4 h). Unbolt, lift the band and core out, stretch the front lip over the core to pop it out. Trim the vent nubs and the seam.
6. Punch the 7 strap holes with a 3 mm leather punch, centred between the notches on the strap edges.

Test first: cure a 10 g cup with your pigment in it. If it sets firm overnight, cast the band.

The band sits across the wrist. Hole 3 of 7 is about 164 mm, hole 4 about 170 mm, 6 mm per hole. USB-C is covered, so pop the Stick out to charge.

## Clip: assembly

1. Drop 2 M3 nuts into the hex pockets inside the cradle.
2. Tilt the Stick's USB-C end up a little, slide its top end under the lip against the end wall, lower it, then screw it down from underneath with 2 x M2x6 socket-cap or button-head screws. They sit in counterbores, flush with the bottom. Never longer: the Stick's threaded holes are only ~3 mm deep with electronics behind them.
3. Bolt the clip on with 2 x M3x4 or M3x5 screws through the clip's own holes. The slots allow +/-3 mm, since the clip drawings don't dimension where the holes sit along its length.

USB-C stays open, so it charges on the clip.

## Sleeve (`hardware/sleeve/`)

![Sealed sleeve with the lug staples, and one staple alone](images/sleeve-preview.png)

A sealed silicone jacket around the Stick (2.6 mm walls, 2.5 mm back, 2.0 mm over the face) with two PETG **staples** cast into its thick end blocks: each is a 3 x 5 mm bar buried across the full width, with two lug plates flush with the sleeve's sides that sweep down under the nose to the spring bar. The strap tucks under the nose. The only opening is the screen window (19 x 31.5 mm); the buttons are covered, with a 0.5 mm pad over each side button and 2 mm of silicone over the front button. 65.4 x 28.6 x 18.3 mm, lug gap 21.4 mm. Fit is tight (0.3 mm squeeze per side). Silicone does not bond to PETG, so the staples hold by being buried: pulling one out means tearing through 8.5 mm of silicone.

| File | What | Print |
|---|---|---|
| `stl/sleeve_staple.stl` | lug staple, print **two** | **PETG**, as exported (upside down, bar on the bed), brim, no supports, 100% infill, elephant-foot compensation 0.15 mm |
| `stl/sleeve_core_a.stl` | USB-C-end half of the core | PLA, as exported, no supports, 3 walls |
| `stl/sleeve_core_b.stl` | top-end half of the core | PLA, as exported, no supports, 3 walls |
| `stl/sleeve_cup.stl` | front half of the mold: window face, walls, noses, pour hole, core pins | PLA, as exported (opening up), no supports, 0.16 mm |
| `stl/sleeve_backplate.stl` | back half: flat back, lug slots, vents | PLA, as exported (parting face up), no supports, 0.16 mm |
| `stl/sleeve_preview_not_for_printing.stl` | the finished silicone part | don't print |

**Casting** (cup on the table, window face down): spray release on everything. Stand core A and core B on the cup floor, window pads down, each on its pin (they meet in the middle). Clip both staples into the back plate's slots, lugs down, and tape across the lug tips on the outside so they can't fall out. Lower the plate onto the cup (diagonal pins), 4 x M3x30 + nuts, snug. Inject through the side pour hole until silicone shows at every vent: the six around the body and the two at the nose tips. Needs ~15 ml; **mix 15 g A + 15 g B**, 3-4% pigment. Cure overnight. Lift the plate off (the staples stay in the silicone), lift the sleeve with the cores out of the cup. Tilt core B's outer end up through the window and slide it out; slide core A toward the middle and lift it out. Trim the vent nubs and the thin skirt around each lug root.

**Fitting the Stick:** USB-C end first, under the deep lip, then stretch the short lip over the top end. Spring bars (0.8 mm tips) through the lugs; open the holes with a 1.0 mm bit if a print closed them. To charge, pull the top end out from under the short lip.

`hardware/sleeve/old/` keeps the earlier frame-based design for reference.
