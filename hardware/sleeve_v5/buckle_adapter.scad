// Tang buckle for the v5 band: caps the cast-in PETG plate at the short strap's end and gives the
// band a normal watch buckle sized for its 22 mm width. Pivot and tongue = the Tropic buckle's own
// 21 mm spring bar and tongue. A fixed keeper bridge behind the cap holds the tail.
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
tongue_len = 14.0;   // Tropic tongue, loop centre to tip: MEASURE
bar_tip_d = 0.7; bar_hole_depth = 0.9;   // the Tropic's own bar: 21 mm tip to tip, 1.4 body, 0.7 tips
bar_len = 21.0;                             // tip to tip, extended
LUG_IN = bar_len - 2 * (bar_hole_depth - 0.2);   // pivot lug inner faces: 19.6 apart, tips seat 0.7 deep

/* [Buckle] */
wall = 2.0; top = 2.0;          // cap walls
lug_t = 3.0; rail_w = 3.0; far_t = 3.0; fr_h = 4.5;   // frame section
bar_from_face = 4.0;            // pivot bar centre beyond the cap's outer face
keeper_back = 9.0; keeper_t = 3.0; keeper_gap = 3.3;
r = 0.8;

$fn = 40; eps = 0.01;
PW = plate_w + 2 * clr; PT = plate_t + clr; PH = plate_h + clr; OW = PW + 2 * wall;
IW = strap_w + 0.6;                       // frame inner width
FW = IW + 2 * rail_w;                     // frame outer width
X_FACE = PT + wall;                       // cap's outer face
X_BAR = X_FACE + bar_from_face;           // pivot bar
X_FAR = X_BAR + tongue_len - 1.5;         // far bar centre: the tongue tip rests 1.5 past it
Z0 = 0; ZT = PH + top;                    // frame occupies z 0..PH (like the plate), cap top to ZT
module cap_raw() {
    translate([0, -OW / 2, PH]) cube([X_FACE, OW, top]);                                   // top wall
    translate([PT, -OW / 2, 0]) cube([wall, OW, PH + top]);                                // outer face wall
    for (s = [-1, 1]) translate([0, s * (OW / 2 - wall / 2) - wall / 2, 0]) cube([X_FACE, wall, PH + top]);   // side walls
}
module frame_raw() {
    for (s = [-1, 1]) translate([X_FACE - eps, s * (FW / 2 - rail_w / 2) - rail_w / 2, 0]) cube([X_FAR + far_t / 2 - X_FACE + eps, rail_w, fr_h]);   // rails
    for (s = [-1, 1]) translate([X_FACE - eps, s > 0 ? LUG_IN / 2 : -FW / 2, 0]) cube([X_BAR + 2.5 - X_FACE + eps, FW / 2 - LUG_IN / 2, fr_h]);        // pivot lugs, in to the bar
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
        translate([X_FACE, -LUG_IN / 2, -1]) cube([X_FAR - far_t / 2 - X_FACE, LUG_IN, 60]);      // between the pivot lugs: bar free, tongue room
        translate([X_BAR + 2.5, -IW / 2, -1]) cube([X_FAR - far_t / 2 - X_BAR - 2.5, IW, 60]);      // strap opening beyond the pivot: full 22.6 width
        translate([-50, -50, -50]) cube([50 - keeper_back - keeper_t - r - eps, 100, 100]);  // trim
        // spring bar seats: blind holes in the lugs' inner faces
        for (s = [-1, 1]) translate([X_BAR, s * (LUG_IN / 2 + bar_hole_depth / 2 - eps), fr_h / 2]) rotate([90, 0, 0]) cylinder(d = bar_tip_d + 0.25, h = bar_hole_depth + 2 * eps, center = true, $fn = 16);
        // pin holes through the cap's side walls into the plate ends
        for (s = [-1, 1]) translate([PT / 2, s * (OW / 2 + 1), PH / 2]) rotate([90, 0, 0]) cylinder(d = 1.7, h = wall + 2.5, center = true, $fn = 20);
        // round the far bar's top edge where the strap bends over it
    }
}
// export on its side (one rail on the bed); supports on
translate([0, 0, OW / 2 + r]) rotate([90, 0, 0]) part();
