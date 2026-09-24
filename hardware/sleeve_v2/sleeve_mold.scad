// Sealed silicone sleeve for the M5Stack StickS3 with cast-in PETG lug staples for a
// standard 22 mm strap. No frame under the wrist, no holes except the screen window.
//
// Parts (set `part`, or use the Customizer):
//   "staple"  PETG x2. A bar that gets buried across each end block, with two lug
//             plates that sweep down under the nose to the spring bar, and two
//             break-off tabs that sit the staple in notches in the cup rim while the
//             silicone cures. Print as exported (upside down, bar on the bed), brim,
//             no supports, 100% infill.
//   "core"    PLA. The Stick's shape plus the pad that keeps the screen window open.
//             Print as exported (back face down), no supports.
//   "cup"     PLA. The one-piece mold: window face at the bottom, walls, noses, rim
//             notches for the staple tabs. Open top. Print as exported.
//   "sleeve"  preview of the silicone (don't print).
//
// Coordinates: x along the Stick (USB-C end at -x), y across, z from the back (0,
// wrist side) to the front. The cup's rim is the z = 0 plane: the sleeve's back is
// the top of the pour, scraped flat at the rim.
//
// Casting (open pour, window face down):
//   1. Spray release on the cup, core and staples. Stand the core on the cup floor,
//      pad down, on its two pins. Drop the staples into the rim notches, lugs up.
//   2. Mix 15 g A + 15 g B (+ pigment). With the syringe, fill from the bottom first:
//      tip down beside the core, into the lip layer and the front-button pocket, then
//      fill to above the rim. Tap the cup on the table, top up, and scrape the surface
//      flat with a card across the rim.
//   3. Cure overnight. Flex the cup and lift the sleeve out with the core inside.
//      Snip the four staple tabs flush with the lug tips and file them smooth. Work
//      one end of the core up through the window and slide the core out.
//   4. Fit the Stick: USB-C end in under the deep lip first, then stretch the short
//      lip over the top end. Spring bars through the lugs.

/* [Part] */
part = "sleeve"; // [staple, core, cup, sleeve]

/* [Fit] */
// Stick is this much bigger than the pocket, per side. 0.3 = tight.
squeeze = 0.3;

/* [Silicone] */
wall = 2.6;        // long sides
back_t = 2.5;
lip_t = 2.0;       // over the Stick's face
end_in = 2.5;      // Stick end -> staple bar
end_out = 3.5;     // staple bar -> nose tip
side_bump = 0.5;   // extra silicone over the side buttons
front_min = 2.0;   // silicone over the front button's top

/* [Strap] */
lug_gap = 21.4;
bar_x_off = 2.3;   // spring bar centre, this far out from the staple bar's inner face
bar_z = -3.4;      // spring bar centre below the sleeve's back
bar_hole_d = 1.0;
lug_tip_r = 2.5;

/* [Hidden] */
$fn = 48;
eps = 0.01;

// ---- StickS3 (K150) --------------------------------------------------------
STICK_W = 24; STICK_L = 48; STICK_T = 14.08; STICK_R = 3;
FRONT_BTN = [[6.2, 17.8], [9.5, 11.5], 0.9];  // x, y on the face (from left edge / USB-C end), height above it
BTN_XMINUS = [6.0, 11.0]; BTN_XPLUS = [19.0, 29.0]; BTN_Z = [3.6, 11.2];

// ---- Pocket (core) ------------------------------------------------------------
CORE_L = STICK_L - 2 * squeeze;  CORE_W = STICK_W - 2 * squeeze;  CORE_T = STICK_T - squeeze;
CORE_R = STICK_R - squeeze;
Z0 = back_t;  Z1 = back_t + CORE_T;         // Stick back / face planes
TOP = Z1 + lip_t;                          // front face of the sleeve
HL = CORE_L / 2;  HW = CORE_W / 2;
function sx(y_on_stick) = y_on_stick - STICK_L / 2;   // Stick's length coord -> sleeve x
function sy(x_on_stick) = x_on_stick - STICK_W / 2;   // Stick's width coord  -> sleeve y

// ---- Outer body ---------------------------------------------------------------
BODY_HW = HW + wall;                        // 14.3
BODY_HL = HL + lip_t;                       // where the flat front ends
STAPLE_T = 3.0;  STAPLE_H = 5.0;
STAPLE_X0 = HL + end_in;                    // bar inner face
STAPLE_X1 = STAPLE_X0 + STAPLE_T;
NOSE_HL = STAPLE_X1 + end_out;              // overall half-length
NOSE_TIP_Z = 10.5;                          // nose top at the tip
BAR_Z0 = back_t;  BAR_Z1 = back_t + STAPLE_H;
WIN = [[sx(14), sx(45.5)], [-9.5, 9.5]];   // screen window; starts above the front button
WIN_R = 3.0;           // generous corners: the core comes out through this window
BAR_X = STAPLE_X0 + bar_x_off;              // spring bar centre
LUG_T = BODY_HW - lug_gap / 2;              // lug plates fill from the strap gap to the side face
LUG_Y0 = lug_gap / 2;
FRONT_BUMP = FRONT_BTN[2] + front_min - lip_t;   // bump above the front face

assert(FRONT_BUMP >= 0 && FRONT_BUMP <= 1.5, "front bump out of range");
assert(WIN[0][0] > sx(FRONT_BTN[1][1]) + 2.0, "window must stay clear of the front button");
assert(LUG_T >= 3.0, "lug plates too thin");

echo(str("Sleeve ", 2 * NOSE_HL, " x ", 2 * BODY_HW, " x ", TOP, " mm (+", FRONT_BUMP, " button bump); window ",
         WIN[0][1] - WIN[0][0], " x ", WIN[1][1] - WIN[1][0], "; spring bar at x=", BAR_X, " z=", bar_z,
         "; lug gap ", lug_gap, ", lug plates ", LUG_T, " thick"));

module rrect(l, w, r) { offset(r = r) square([l - 2 * r, w - 2 * r], center = true); }
module slab(l, w, r, z) { translate([0, 0, z]) linear_extrude(eps) rrect(l, w, r); }

// flat back, vertical sides, flat front over the Stick with a 1 mm chamfer, nose tops
// sloping from the front edge down to the tips
module body() {
    hull() {
        slab(2 * NOSE_HL, 2 * BODY_HW, 6, 0);
        slab(2 * NOSE_HL, 2 * BODY_HW, 6, NOSE_TIP_Z);
        slab(2 * BODY_HL, 2 * BODY_HW, 5, TOP - 1);
        slab(2 * BODY_HL - 2, 2 * BODY_HW - 2, 4, TOP);
    }
}

// shallow pads over the side buttons: side_bump proud of the wall, soft-edged
module side_bumps(extra = 0) {
    for (s = [[BTN_XMINUS, -1], [BTN_XPLUS, 1]]) {
        x0 = sx(s[0][0]) - 1.5; x1 = sx(s[0][1]) + 1.5;
        z0 = Z0 + BTN_Z[0] - 1.0; z1 = Z0 + BTN_Z[1] + 1.0;
        hull() {
            translate([(x0 + x1) / 2, s[1] * (BODY_HW - 0.5), (z0 + z1) / 2]) rotate([90, 0, 0])
                linear_extrude(eps) rrect(x1 - x0 + 2 * extra, z1 - z0 + 2 * extra, 2.5);
            translate([(x0 + x1) / 2, s[1] * (BODY_HW + side_bump + extra), (z0 + z1) / 2]) rotate([90, 0, 0])
                linear_extrude(eps) rrect(x1 - x0 - 2 + 2 * extra, z1 - z0 - 2 + 2 * extra, 1.5);
        }
    }
}
module front_bump(extra = 0) {
    x0 = sx(FRONT_BTN[1][0]) - 1.5; x1 = sx(FRONT_BTN[1][1]) + 1.5;
    y0 = sy(FRONT_BTN[0][0]) - 1.5; y1 = sy(FRONT_BTN[0][1]) + 1.5;
    hull() {
        translate([(x0 + x1) / 2, (y0 + y1) / 2, TOP - 0.5]) linear_extrude(eps) rrect(x1 - x0 + 2 * extra, y1 - y0 + 2 * extra, 1.5);
        translate([(x0 + x1) / 2, (y0 + y1) / 2, TOP + FRONT_BUMP + extra]) linear_extrude(eps) rrect(x1 - x0 - 2 + 2 * extra, y1 - y0 - 2 + 2 * extra, 1.0);
    }
}

module envelope() { body(); side_bumps(); front_bump(); }

// ---- Core (the Stick's shape, in two halves) --------------------------------------
module core_full() {
    translate([0, 0, Z0]) linear_extrude(CORE_T) rrect(CORE_L, CORE_W, CORE_R);
    // pad filling the screen window, flush with the front face
    translate([(WIN[0][0] + WIN[0][1]) / 2, 0, Z1 - eps]) linear_extrude(TOP - Z1 + eps)
        rrect(WIN[0][1] - WIN[0][0], WIN[1][1] - WIN[1][0], WIN_R);
    // the front button, so the silicone sits right on it
    translate([sx(FRONT_BTN[1][0]), sy(FRONT_BTN[0][0]), Z1 - eps])
        cube([FRONT_BTN[1][1] - FRONT_BTN[1][0], FRONT_BTN[0][1] - FRONT_BTN[0][0], FRONT_BTN[2] + eps]);
}
PINS = [[-6, 0], [13, 0]];                  // inside the window, so they leave no mark
pin_d = 3.0; pin_h = 1.6;
module core_part() {
    difference() {
        core_full();
        for (p = PINS) translate([p[0], p[1], TOP - pin_h]) cylinder(d = pin_d + 0.3, h = pin_h + 1);
    }
}

// ---- Staple ---------------------------------------------------------------------
// lug plate profile in x-z (for the +x end): embedded top part down to the swept tip
module lug_profile(grow = 0) {
    hull() {
        translate([STAPLE_X0 - grow, -grow]) square([NOSE_HL - STAPLE_X0 + 2 * grow, back_t + 2 * grow]);
        translate([BAR_X, bar_z]) circle(r = lug_tip_r + grow);
    }
}
// break-off tabs: from each lug plate's outer face at the rim, out over the cup rim,
// sloping 45 degrees down into it (so they print support-free upside down). They sit
// in matching notches, which fixes the staple's position and height while curing.
TAB_W = 4.0; TAB_T = 2.0; TAB_L = 6.0;
module tab(s, grow = 0) {
    hull() {
        translate([BAR_X - TAB_W / 2 - grow, s > 0 ? BODY_HW - 0.3 : -(BODY_HW - 0.3) - eps, -grow]) cube([TAB_W + 2 * grow, eps, TAB_T + 2 * grow]);
        translate([BAR_X - TAB_W / 2 - grow, s > 0 ? BODY_HW + TAB_L + grow : -(BODY_HW + TAB_L + grow) - eps, TAB_L - grow]) cube([TAB_W + 2 * grow, eps, TAB_T + 2 * grow]);
    }
}
module staple_tabs(grow = 0) { for (s = [-1, 1]) tab(s, grow); }
// the notch is the tab's slot swept upward, so the staple drops in and lifts straight out
module tab_notches(grow = 0) {
    for (m = [0, 1]) mirror([m, 0, 0]) for (s = [-1, 1]) hull() { tab(s, grow); translate([0, 0, -12]) tab(s, grow); }
}
module staple(end = 1, grow = 0, hole = true, tabs = true) {
    mirror([end < 0 ? 1 : 0, 0, 0]) difference() {
        union() {
        if (tabs) staple_tabs(grow);
        intersection() {
        // keep the staple inside the nose's rounded footprint (the lug tips get rounded too)
        translate([0, 0, -50]) linear_extrude(100) rrect(2 * NOSE_HL - 0.1 + 2 * grow, 2 * BODY_HW - 0.1 + 2 * grow, 6 + grow);
        union() {
            // bar across the full width, buried in the end block
            translate([STAPLE_X0 - grow, -BODY_HW + 0.05, BAR_Z0 - grow]) cube([STAPLE_T + 2 * grow, 2 * BODY_HW - 0.1, STAPLE_H + 2 * grow]);
            // lug plates from the strap gap out to the side face (0.05 in from it)
            for (s = [-1, 1]) translate([0, s * (LUG_Y0 + (LUG_T - 0.05) / 2), 0]) rotate([90, 0, 0])
                translate([0, 0, -(LUG_T - 0.05) / 2 - grow]) linear_extrude(LUG_T - 0.05 + 2 * grow) lug_profile(grow);
        }
        }
        }
        if (hole) translate([BAR_X, 0, bar_z]) rotate([90, 0, 0]) cylinder(d = bar_hole_d, h = 100, center = true, $fn = 16);
    }
}
module staples(grow = 0, hole = true, tabs = true) { staple(1, grow, hole, tabs); staple(-1, grow, hole, tabs); }

// ---- Silicone preview --------------------------------------------------------------
module silicone() {
    difference() {
        envelope();
        core_full();
        // cut the window clear through (the pad's top is coplanar with the face)
        translate([(WIN[0][0] + WIN[0][1]) / 2, 0, TOP - 1]) linear_extrude(3) rrect(WIN[0][1] - WIN[0][0], WIN[1][1] - WIN[1][0], WIN_R);
        staples();
    }
}

// ---- Mold (one piece, open top) -----------------------------------------------------
margin = 6;
MX = NOSE_HL + margin;  MY = BODY_HW + margin;
cup_floor = 4;
notch_clear = 0.2;
CUP_H = TOP + FRONT_BUMP + cup_floor;

module block(z0, h) { translate([0, 0, z0]) linear_extrude(h) rrect(2 * MX, 2 * MY, 4); }

module cup() {
    difference() {
        block(0, CUP_H);
        envelope();
        // notches in the rim for the staple tabs: they rest on the sloped notch floors,
        // which sets the staple's height, and the notch sides set its position
        tab_notches(notch_clear);
    }
    // core pins, inside the window, rooted 1 mm into the cup floor
    for (p = PINS) translate([p[0], p[1], TOP - pin_h]) cylinder(d = pin_d, h = pin_h + 1);
}

if (part == "staple")      translate([0, 0, BAR_Z1]) rotate([180, 0, 0]) staple(1);   // upside down: bar top on the bed, lugs and tabs rise from it
else if (part == "core")   translate([0, 0, -Z0]) core_part();
else if (part == "cup")    translate([0, 0, CUP_H]) rotate([180, 0, 0]) cup();          // open top up
else silicone();
