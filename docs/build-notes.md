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

## Sleeve v2 (`hardware/sleeve_v2/`)

![Sealed sleeve with the lug staples and the charging port; the cup with the core; the core as printed](images/sleeve-preview.png)

A sealed silicone jacket around the Stick (2.6 mm walls, 2.5 mm back, 2.0 mm over the face) with two PETG **staples** cast into its thick end blocks: each is a 3 x 5 mm bar buried across the width, with two lug plates that sweep down under the nose to the spring bar. The plates' outer faces sit 0.3 mm inside the sleeve's sides, pressed against matching pads on the cup wall, so they cast as crisp recessed black rectangles either side of each nose (no thin film of silicone to wear through); the bar's ends are buried 1.3 mm. The strap tucks under the nose. The only opening is the screen window (19 x 31.5 mm); the buttons are covered, with a 0.5 mm pad over each side button and 2 mm of silicone over the front button. A 14 x 7.5 mm **charging tunnel** runs through the USB-C end block to the port, closed at the nose by a 2 mm skin (3.5 mm at the ends) that you slit after curing: the plug pushes through, the slit closes behind it. The tunnel floor clears the staple bar by 0.9 mm. 65.4 x 28.6 x 18.3 mm, lug gap 21.4 mm. Fit is tight (0.3 mm squeeze per side). Silicone does not bond to PETG, so the staples hold by being buried: pulling one out means tearing through 8.5 mm of silicone.

One mold piece, one core, two staples:

| File | What | Print |
|---|---|---|
| `stl/sleeve_staple.stl` | lug staple with break-off locating tabs, print **two** | **PETG**, as exported (upside down, bar on the bed), brim, no supports, 100% infill, elephant-foot compensation 0.15 mm |
| `stl/sleeve_core.stl` | the Stick's shape + the window pad + the tunnel block | PLA, as exported, 3 walls, **supports on, build plate only** (only the tunnel block gets one, a 6 mm pad beside the core that snaps off) |
| `stl/sleeve_cup.stl` | the mold: window face at the bottom, walls, noses, rim notches, two M3 holes in the floor; open top | PLA, as exported, no supports, 0.16 mm |
| `stl/sleeve_cup_fused.stl` | **alternative to cup + core:** the same cup with the core grown out of the floor through the window | PLA, as exported (**rim down**), supports on **build plate only**, threshold 50°, 0.16 mm |
| `stl/sleeve_lid.stl` | optional lid: a plate with lug slots and two vents that sits on the rim on 0.3 mm feet, for a flat back instead of a card-scraped one | PLA, as exported (flat, feet up), no supports |
| `stl/sleeve_preview_not_for_printing.stl` | the finished silicone part | don't print |

**Casting** (open pour, window face down): spray release on the cup, core and staples. Stand the core on the cup floor, pad down, tunnel block toward the deeper nose, and drive **two M3 x 8 screws** up through the holes in the cup's underside into the core (they self-tap; the heads sit in recesses so the cup still stands flat). Without them the core floats: printed PLA is about half the density of the silicone. Drop the staples into the rim notches, lugs up, and push them down so the plates seat between the pads on the cup wall (light push fit; if one binds, sand the plate's outer face, not the cup). The tabs rest on the notch floors and set the height. **Mix 15 g A + 15 g B** with 3-4% pigment. Fill with the syringe from the bottom up: tip down beside the core into the lip layer and the front-button pocket first, then fill to just above the rim. Tap the cup on the table, top up, scrape the surface flat with a card across the rim. Cure overnight. **With the lid:** overfill by 1-2 mm instead of scraping, tap, then within a few minutes of mixing lower the sprayed lid over the lugs and press it onto the rim; excess bleeds out at the edges, the slots and the two vents. Wipe the squeeze-out. After curing, snip the two vent nubs off the back. Card-scraping leaves faint ripples where the film relevels unevenly; the lid or a plain unscraped overfill (self-levels, trim the flash) both avoid that. It is the wrist side either way. Flex the cup and lift the sleeve out with the core inside. Take the two screws out, work one end of the core up through the window and slide it out. **Tabs:** each has a 0.6 mm neck just outside the silicone; grip the tab with pliers and twist, it parts at the neck. Shave any burr with a razor blade lying flat on the lug plate (the plate is flush with the sleeve's side, so the blade rides on PETG, not silicone). Don't sand near the silicone. **Cut the port slit:** lay the sleeve on its side, and with a fresh blade make one straight cut across the middle of the skin at the USB-C end, about 12 mm long, in a single stroke. Never saw at it. The slit ends land in the thick part of the skin; the tunnel behind is rounded, so there is no corner for a tear to start from.

**Fused cup (no loose core).** `sleeve_cup_fused.stl` is the cup and core in one piece, so the only things to place are the two staples. It prints rim down: the core then stands on a 2.5 mm slab of slicer support that sits on the bed under it (the space that becomes the sleeve's back), and the front face of the mold is bridged over the 2 mm lip gap (the longest bridge is 15 mm at the USB-C end). In the slicer turn supports on, "on build plate only", threshold angle 50° so the sloped noses are left alone, and normal (not tree) support so the slab comes out in one piece; if it also wants to support the bridged floor, add a support blocker there. After printing, pull the slab out from the open top. The front face of the sleeve comes out with a light bridge texture instead of the glossy bed finish, and the walls will be slightly rougher on the 46° nose slopes. Casting is the same, minus placing the core. **Demolding is harder:** the sleeve has to come off the core while it is still in the rigid cup, the same stretch as fitting the Stick but with less room to work. Let it cure the full 24 h, then lift one end by its two lugs so the end block peels its lip out from under the core (start with the USB-C end, the deep lip), then the other end, then the sides. A drop of soapy water at the ends helps. With the loose core you lift core and sleeve out together and peel the core out in your hand, which is why the two-piece version is still the default.

**Fitting the Stick:** USB-C end first, under the deep lip, then stretch the short lip over the top end. Spring bars (0.8 mm tips) through the lugs; open the holes with a 1.0 mm bit if a print closed them. To charge, push the cable straight into the slit at the USB-C end; the tunnel guides it onto the port. Set `port = false` in the .scad for a sleeve without the tunnel.

`hardware/sleeve/` is the earlier design: a thinner sleeve with a PETG lug frame cast into its back. Kept with its STLs for reference.
