// Tang buckle for the v5 band: caps the cast-in PETG plate at the short strap's end and gives the
// band a normal watch buckle sized for its 22 mm width. Pivot = the Tropic strap's
// 22 mm spring bar (24.5 tip to tip, 2.5 body); tongue printed. A fixed keeper bridge behind the cap holds the tail.
//
// Prep the band: snip the frame's rails and crossbar off flush with the plate's outer face, file
// the stubs flat. Fit: slide the cap over the plate, CA glue, optionally pin through the side holes.
// Then hook the tongue's loop over the spring bar, compress the bar into the two lug holes.
//
// Wear: long strap comes round under the wrist, goes UNDER the far bar, UP through the frame
// opening, the tongue goes out through a hole, and the tail runs over the pivot bar, under the
// keeper bridge and along the top of the short strap. Like a watch.
//
// Print: PETG, as exported (on its side), 100% infill, 250-255 C, low fan, supports on.

/* [Plate on the band (measure yours)] */
plate_w = 32.0; plate_t = 5.0; plate_h = 4.5; plate_z0 = 3.0; clr = 0.15;

/* [Band] */
strap_w = 22.0; strap_t = 2.8; strap_top = 5.8;   // strap_top: top of the lifted strap end above the wrist face

/* [Hardware] */
tongue_len = 12.0;   // printed tongue, bar centre to tip (sets the far bar too)
bar_tip_d = 0.8; bar_hole_depth = 0.9; bar_d = 2.5;   // the Tropic's STRAP spring bar: 24.5 tip to tip extended, 2.5 body, 0.8 tips
bar_len = 24.5;
LUG_IN = bar_len - 2 * (bar_hole_depth - 0.2);         // lug inner faces 23.1 apart: tips seat 0.7 deep when the bar is extended
tongue_w = 3.0; tongue_t = 2.0; ring_wall = 1.6;        // printed tongue

/* [Buckle] */
wall = 2.0; top = 2.0;          // cap walls
lug_t = 3.0; rail_w = 3.0; far_t = 3.0; fr_h = 4.5;   // frame section
bar_from_face = 4.0;            // pivot bar centre beyond the cap's outer face
keeper_back = 9.0; keeper_t = 3.0; keeper_gap = 3.3;
r = 0.8;

$fn = 40; eps = 0.01;
PW = plate_w + 2 * clr; PT = plate_t + clr; PH = plate_h + clr; OW = PW + 2 * wall;
IW = LUG_IN;                              // frame inner width = lug spacing (23.1, clears the 22 strap)
FW = IW + 2 * rail_w;                     // frame outer width
X_FACE = PT + wall;                       // cap's outer face
X_BAR = X_FACE + bar_from_face;           // pivot bar
X_FAR = X_BAR + tongue_len - far_t / 2 - 0.5;   // far bar: the tongue tip reaches 0.5 past its outer face
Z0 = 0; ZT = PH + top;                    // frame occupies z 0..PH (like the plate), cap top to ZT
module cap_raw() {
    translate([0, -OW / 2, PH]) cube([X_FACE, OW, top]);                                   // top wall
    translate([PT, -OW / 2, 0]) cube([wall, OW, PH + top]);                                // outer face wall
    for (s = [-1, 1]) translate([0, s * (OW / 2 - wall / 2) - wall / 2, 0]) cube([X_FACE, wall, PH + top]);   // side walls
}
module frame_raw() {
    for (s = [-1, 1]) translate([X_FACE - eps, s * (FW / 2 - rail_w / 2) - rail_w / 2, 0]) cube([X_FAR + far_t / 2 - X_FACE + eps, rail_w, fr_h]);   // rails
    translate([X_FAR - far_t / 2, -FW / 2, 0]) cube([far_t, FW, fr_h]);                    // far bar
}
module keeper_raw() {
    // arms back along the strap's edges from the cap's top wall, and a bridge over the strap
    for (s = [-1, 1]) translate([-keeper_back - keeper_t, s * (strap_w / 2 + 0.5 + keeper_t / 2) - keeper_t / 2, strap_top - plate_z0 + 0.5]) cube([keeper_back + keeper_t + eps, keeper_t, ZT - (strap_top - plate_z0 + 0.5)]);
    translate([-keeper_back - keeper_t, -(strap_w / 2 + 0.5 + keeper_t), strap_top - plate_z0 + keeper_gap]) cube([keeper_t, strap_w + 1 + 2 * keeper_t, ZT - (strap_top - plate_z0 + keeper_gap)]);
}
module part() {
    difference() {
        minkowski() { union() { cap_raw(); frame_raw(); keeper_raw(); } sphere(r = r, $fn = 16); }
        translate([-1, -PW / 2, -1]) cube([PT + 1, PW, PH + 1]);                            // plate pocket (open toward the strap and below)
        translate([-50, -50, -50]) cube([100, 100, 50 - r]);                                 // nothing below the frame's underside plane (keeps the tail passage)
        translate([-50, -(strap_w / 2 + 0.5), -1]) cube([50 + PT, strap_w + 1, 1 + strap_top - plate_z0 + keeper_gap]);   // strap + keeper passage behind the cap
        translate([X_FACE, -IW / 2, -1]) cube([X_FAR - far_t / 2 - X_FACE, IW, 60]);              // frame opening, full inner width; bar free between the lugs
        translate([-50, -50, -50]) cube([50 - keeper_back - keeper_t - r - eps, 100, 100]);  // trim
        // spring bar seats: blind holes in the lugs' inner faces
        for (s = [-1, 1]) translate([X_BAR, s * (LUG_IN / 2 + bar_hole_depth / 2 - eps), fr_h / 2]) rotate([90, 0, 0]) cylinder(d = bar_tip_d + 0.25, h = bar_hole_depth + 2 * eps, center = true, $fn = 16);
        // pin holes through the cap's side walls into the plate ends
        for (s = [-1, 1]) translate([PT / 2, s * (OW / 2 + 1), PH / 2]) rotate([90, 0, 0]) cylinder(d = 1.7, h = wall + 2.5, center = true, $fn = 20);
        // round the far bar's top edge where the strap bends over it
    }
}
// printed tongue: ring on the bar, tapered arm to just past the far bar, rounded tip
module tongue() {
    ring_od = bar_d + 0.3 + 2 * ring_wall;
    difference() {
        union() {
            rotate([90, 0, 0]) cylinder(d = ring_od, h = tongue_w, center = true);
            hull() {
                rotate([90, 0, 0]) cylinder(d = tongue_t, h = tongue_w, center = true);
                translate([tongue_len - 1.0, 0, -0.3]) rotate([90, 0, 0]) cylinder(d = tongue_t - 0.4, h = tongue_w - 0.8, center = true);
            }
        }
        rotate([90, 0, 0]) cylinder(d = bar_d + 0.3, h = 10, center = true);
    }
}
part_sel = "buckle"; // [buckle, tongue]
if (part_sel == "tongue") rotate([90, 0, 0]) tongue();                       // flat: ring axis vertical
else translate([0, 0, OW / 2 + r]) rotate([90, 0, 0]) part();              // buckle on its side; supports on
