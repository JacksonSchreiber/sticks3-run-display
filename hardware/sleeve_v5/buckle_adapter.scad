// End-link adapter: turns the cast-in PETG buckle plate on a v5 band into a lug for a normal
// two-piece strap buckle (the Tropic's: 18 mm between its lugs, 21 mm spring bar, 0.7 mm tips).
//
// Prep the band: snip the frame's two rails and crossbar off flush with the plate's outer face
// and file the stubs flat, leaving the bare plate at the strap's end.
// Fit: slide the adapter over the plate (it grips the plate's top, ends and outer face; the
// passage under the plate stays open). Glue with CA on the plate faces, and/or drill the two
// side holes 1.6 mm on into the plate's ends and pin with 8 mm of 1.6 mm wire.
// Then the Tropic buckle goes on the nose with its own spring bar, like on a strap loop.
//
// Print: PETG, as exported (nose up), 100% infill, no supports, 250-255 C, low fan.

/* [Plate on the band (measure yours)] */
plate_w = 32.0;     // across the strap (y)
plate_t = 5.0;      // along the strap (x)
plate_h = 4.5;      // tall (z)
plate_z0 = 3.0;     // plate's underside above the wrist face
clr = 0.15;

/* [Buckle] */
lug_gap = 18.0;     // between the buckle's lugs
bar_hole = 2.0;     // through the nose, for the spring bar's body
nose_len = 6.0;     // nose beyond the adapter's face
bar_from_face = 3.2;

/* [Adapter] */
wall = 2.0; top = 2.0; r = 0.8;
pin_d = 1.6;

$fn = 40; eps = 0.01;
PW = plate_w + 2 * clr; PT = plate_t + clr; PH = plate_h + clr;
OW = PW + 2 * wall;                 // overall width
module body_raw() {
    // top wall over the plate
    translate([0, -OW / 2, PH]) cube([PT + wall, OW, top]);
    // outer face wall
    translate([PT, -OW / 2, 0]) cube([wall, OW, PH + top]);
    // side walls
    for (s = [-1, 1]) translate([0, s * (OW / 2 - wall / 2) - wall / 2, 0]) cube([PT + wall, wall, PH + top]);
    // nose
    translate([PT + wall - eps, -(lug_gap - 0.4) / 2, 0]) cube([nose_len + eps, lug_gap - 0.4, PH]);
}
module adapter() {
    difference() {
        minkowski() {
            difference() { translate([r, 0, 0]) resize([0, 0, 0]) children(); }
            sphere(r = r, $fn = 16);
        }
    }
}
module part() {
    difference() {
        // rounded outer shape
        minkowski() {
            intersection() { body_raw(); translate([r, -50, r]) cube([100, 100, 100]); }   // keep the plate-side face and underside flat
            sphere(r = r, $fn = 16);
        }
        // the pocket the plate sits in (open toward -x and open below)
        translate([-1, -PW / 2, -1]) cube([PT + 1, PW, PH + 1]);
        // spring bar hole through the nose
        translate([PT + wall + bar_from_face, 0, PH / 2]) rotate([90, 0, 0]) cylinder(d = bar_hole, h = 40, center = true, $fn = 24);
        // pin holes through the side walls into the plate's ends (drill on into the plate)
        for (s = [-1, 1]) translate([PT / 2, s * (OW / 2 + 1), PH / 2]) rotate([90, 0, 0]) cylinder(d = pin_d + 0.1, h = wall + 2.5, center = true, $fn = 20);
        // trim below the wrist plane and behind the plate face
        translate([-50, -50, -50]) cube([100, 100, 50]);
        translate([-50, -50, -50]) cube([50 - eps, 100, 100]);
    }
}
// export: nose up (outer face wall on the bed)
rotate([0, -90, 0]) part();   // plate-side edges on the bed, nose at the top
