// Tang buckle for the v5 band, Tropic-style: caps the cast-in PETG plate at the short strap's end.
// Curved frame that follows the wrist, pivot = the Tropic strap's 22 mm spring bar (24.5 tip to
// tip, 2.5 body, 0.8 tips) hidden inside the tongue's full-width sleeve, printed tongue that
// rests in a scooped seat on the far bar and turns up at its tip, keeper bridge behind the cap.
//
// Prep the band: snip the old frame's rails and crossbar off flush with the plate's outer face,
// file flat. Fit: slide the cap over the plate, CA glue, optionally pin through the side holes.
// Slide the tongue's sleeve onto the spring bar, compress the bar into the two lug seats.
//
// Wear: long strap under the far bar, up through the opening, tongue out through a hole, tail
// over the sleeve and under the keeper bridge along the short strap. Like a watch.
//
// Print: buckle PETG on its side (as exported), supports on; tongue flat, no supports. 100% infill,
// 250-255 C, low fan, slow perimeters.

part_sel = "buckle"; // [buckle, tongue]

/* [Plate on the band (measure yours)] */
plate_w = 32.0; plate_t = 5.0; plate_h = 4.5; plate_z0 = 3.0; clr = 0.15;

/* [Band] */
strap_w = 22.0; strap_t = 2.8; strap_top = 5.8;

/* [Hardware: the Tropic strap's spring bar] */
bar_len = 24.5; bar_d = 2.5; bar_tip_d = 0.8; seat_depth = 0.9;

/* [Buckle] */
wall = 2.0; top = 2.0;
rail_w = 3.0; far_t = 4.5; fr_h = 4.5;   // far bar 4.5 thick: it prints with its layers across it and carries the scoop
bar_from_face = 4.0;
tongue_len = 13.5;          // bar centre to tongue tip
wrist_R = 35;               // frame curves to this radius
keeper_back = 9.0; keeper_t = 3.0; keeper_gap = 3.3;
r = 1.0; lip = 0.8;   // cap rounding; snap lips behind the plate's ends
/* [Tongue] */
tongue_w = 3.0; tongue_t = 2.2; sleeve_wall = 1.5; tip_up = 1.5; scoop = 0.8;   // scoop: how deep the tongue's rest is cut into the far bar

$fn = 48; eps = 0.01;
PW = plate_w + 2 * clr; PT = plate_t + clr; PH = plate_h + clr; OW = PW + 2 * wall;
LUG_IN = bar_len - 2 * (seat_depth - 0.2);   // 23.1: tips seat 0.7 deep with the bar extended
IW = LUG_IN; FW = IW + 2 * rail_w;
X_FACE = PT + wall; X_BAR = X_FACE + bar_from_face;
X_FAR = X_BAR + tongue_len - 2.0 - far_t / 2;   // tongue tip 2 mm past the far bar's outer face
ZT = PH + top;
function drop(x) = -(max(x - X_FACE, 0)) * (max(x - X_FACE, 0)) / (2 * wrist_R);   // the frame's curve

module rrect(l, w, rr) { offset(r = rr) square([l - 2 * rr, w - 2 * rr], center = true); }
module yz_slice(x, y, w, h, zc) { translate([x, y, zc]) rotate([90, 0, 90]) linear_extrude(eps) rrect(w, h, min(r, w / 2 - eps)); }
module rail(s) {   // curved rail from the cap face to the far bar
    xs = [X_FACE - eps, X_BAR, X_BAR + 4, X_FAR - far_t / 2, X_FAR + far_t / 2];
    for (i = [0 : len(xs) - 2]) hull() {
        yz_slice(xs[i], s * (FW / 2 - rail_w / 2), rail_w, fr_h, fr_h / 2 + drop(xs[i]));
        yz_slice(xs[i + 1], s * (FW / 2 - rail_w / 2), rail_w, fr_h, fr_h / 2 + drop(xs[i + 1]));
    }
}
module far_bar() { hull() { yz_slice(X_FAR - far_t / 2, 0, FW, fr_h, fr_h / 2 + drop(X_FAR - far_t / 2)); yz_slice(X_FAR + far_t / 2, 0, FW, fr_h, fr_h / 2 + drop(X_FAR + far_t / 2)); } }
module cap_raw() {
    translate([0, -OW / 2, PH]) cube([X_FACE, OW, top]);
    translate([PT, -OW / 2, 0]) cube([wall, OW, PH + top]);
    for (s = [-1, 1]) translate([0, s * (OW / 2 - wall / 2) - wall / 2, 0]) cube([X_FACE, wall, PH + top]);
    // snap lips behind the plate's ends (beyond the strap's width): the cap is captured in the pull direction
    for (s = [-1, 1]) hull() {
        translate([-lip, s > 0 ? strap_w / 2 + 0.6 : -(OW / 2), 0]) cube([lip + eps, OW / 2 - strap_w / 2 - 0.6, PH]);
        translate([-lip - 0.8, s > 0 ? strap_w / 2 + 0.6 : -(OW / 2), 0]) cube([eps, OW / 2 - strap_w / 2 - 0.6, PH - 0.8]);   // 45-degree ramp so it snaps on
    }
}
module keeper_raw() {
    for (s = [-1, 1]) translate([-keeper_back - keeper_t, s * (strap_w / 2 + 0.5 + keeper_t / 2) - keeper_t / 2, strap_top - plate_z0 + 0.5]) cube([keeper_back + keeper_t + eps, keeper_t, ZT - (strap_top - plate_z0 + 0.5)]);
    translate([-keeper_back - keeper_t, -(strap_w / 2 + 0.5 + keeper_t), strap_top - plate_z0 + keeper_gap]) cube([keeper_t, strap_w + 1 + 2 * keeper_t, ZT - (strap_top - plate_z0 + keeper_gap)]);
}
module buckle() {
    difference() {
        union() {
            minkowski() { union() { cap_raw(); keeper_raw(); } sphere(r = r, $fn = 16); }
            for (s = [-1, 1]) rail(s);
            far_bar();
        }
        translate([0, -PW / 2, -1]) cube([PT, PW, PH + 1]);                                                        // plate pocket (the lips sit behind the plate's ends)
        translate([-50, -(strap_w / 2 + 0.5), -1]) cube([50 + PT, strap_w + 1, 1 + strap_top - plate_z0 + keeper_gap]);   // strap + keeper passage
        translate([-50, -50, -50]) cube([50 - keeper_back - keeper_t - r - eps, 100, 100]);                          // trim behind the keeper
        translate([-50, -50, -50]) cube([100, 100, 50 - r]);                                                        // nothing below the plate plane behind the face
        // spring bar seats, blind, in the rails' inner faces
        for (s = [-1, 1]) translate([X_BAR, s * (IW / 2 + seat_depth / 2 - eps), fr_h / 2 + drop(X_BAR)]) rotate([90, 0, 0]) cylinder(d = bar_tip_d + 0.25, h = seat_depth + 2 * eps, center = true, $fn = 16);
        // scooped, tapered rest for the tongue on the far bar's top
        translate([X_FAR, 0, fr_h + drop(X_FAR) - scoop + 0.5 * (tongue_w + 4.0) / 2]) scale([1, 1, 0.5]) rotate([0, 90, 0]) cylinder(d = tongue_w + 4.0, h = far_t + 2, center = true);
        // pin holes through the cap's side walls into the plate ends
        for (s = [-1, 1]) translate([PT / 2, s * (OW / 2 + 1), PH / 2]) rotate([90, 0, 0]) cylinder(d = 1.7, h = wall + 2.5, center = true, $fn = 20);
    }
}
module tongue() {
    sleeve_od = bar_d + 0.3 + 2 * sleeve_wall;
    zc = fr_h / 2 + drop(X_BAR);
    difference() {
        union() {
            translate([X_BAR, 0, zc]) rotate([90, 0, 0]) cylinder(d = sleeve_od, h = IW - 0.3, center = true);   // full-width sleeve: hides the bar, centres the tongue
            // arm: droops with the frame, rests on the far bar, tip turns up
            xs = [X_BAR, X_BAR + 4, X_FAR - 1.0, X_FAR + far_t / 2 + 0.3, X_FAR + far_t / 2 + 2.0];
            zr = fr_h + drop(X_FAR) - scoop + tongue_t / 2 + 0.2;   // arm centre when resting in the scoop (0.2 clearance)
            zs = [zc, zc - 0.05, zr, zr, zr + tip_up];
            ws = [tongue_w, tongue_w, tongue_w - 0.4, tongue_w - 0.6, tongue_w - 1.0];
            for (i = [0 : len(xs) - 2]) hull() {
                translate([xs[i], 0, zs[i]]) rotate([90, 0, 0]) cylinder(d = tongue_t, h = ws[i], center = true);
                translate([xs[i + 1], 0, zs[i + 1]]) rotate([90, 0, 0]) cylinder(d = tongue_t - (i == len(xs) - 2 ? 0.4 : 0), h = ws[i + 1], center = true);
            }
        }
        translate([X_BAR, 0, zc]) rotate([90, 0, 0]) cylinder(d = bar_d + 0.3, h = 40, center = true);
    }
}
if (part_sel == "tongue") translate([0, 0, 0]) mirror([0, 0, 0]) translate([-X_BAR, 0, -(fr_h / 2 + drop(X_BAR)) + (bar_d + 0.3) / 2 + sleeve_wall]) tongue();   // sleeve lying on the bed, arm flat, tip up
else translate([0, 0, OW / 2 + r]) rotate([90, 0, 0]) buckle();
