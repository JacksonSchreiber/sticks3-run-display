// Sleeve v3: sealed silicone jacket for the M5Stack StickS3 with the strap lugs UNDER the
// ends instead of past them. A PETG chassis plate is buried in the back layer; four fins
// grow down from it inside the sleeve's footprint and carry the spring bars, so the strap
// loop sits under each end of the sleeve, in the gap between a straight sleeve and a
// curved wrist. Overall length is the Stick plus two thin end walls.
//
// Parts (set `part`, or use the Customizer):
//   "chassis"  PETG x1, 100% infill. Plate + 4 fins + 4 twist-off locating tabs. Print as
//              exported (plate on the bed, fins up), brim, no supports.
//   "core"     PLA. The Stick's shape, the window pad, the port pocket. Print as exported
//              (back face down), no supports. Held down by two M3x8 screws through the cup.
//   "cup"      PLA. One-piece open-top mold with four posts on the rim that the chassis
//              tabs rest on. Print as exported (open top up), no supports.
//   "lid"      PLA, optional. Plate that sits on the rim after the pour for a flat back;
//              openings clear the fins, tabs and posts.
//   "sleeve"   preview of the silicone (don't print).
//
// Coordinates: x along the Stick (USB-C end at -x), y across, z from the back (0, wrist
// side) toward the front. The cup's rim is the z = 0 plane; the back is the pour surface.
//
// Casting (open pour, window face down):
//   1. Release on cup, core, chassis, lid. Core on the floor, pad down, two M3x8 screws up
//      through the cup underside into it.
//   2. Mix 17 g A + 17 g B (+ pigment). Syringe the lip layer and the front-button pocket
//      first, then pour until the core's back is covered by about a millimetre.
//   3. Lower the chassis in, fins up, one end first so air runs out from under the plate,
//      until its tabs sit on the rim posts. Push down gently: the tabs slide down the
//      sloped post seats until they touch the outer walls, which centres it.
//   4. Top up to just above the rim, tap, then either scrape the middle flat with a card or
//      press the lid on. Cure 24 h (or ~6 h at 45 C on the printer bed).
//   5. Screws out. Lift the sleeve by the fins, core inside. Peel the short-lip end off the
//      core, slide the core out through the window. Twist the tabs off at their necks and
//      shave the stubs with a blade flat on the fin. Cut the port slit. Spring bars in.

/* [Part] */
part = "sleeve"; // [chassis, core, cup, lid, sleeve]

/* [Fit] */
squeeze = 0.3;          // Stick is this much bigger than the pocket, per side

/* [Silicone] */
wall = 2.6;             // long sides
end_t = 2.2;            // end walls (Stick end -> outside)
lip_t = 1.6;            // over the Stick's face
over_plate = 0.5;       // silicone between the Stick's back and the chassis plate
under_plate = 1.0;      // silicone between the chassis plate and the wrist
side_bump = 0.5;        // extra over the side buttons
front_min = 1.6;        // silicone over the front button's top
front_chamfer = 1.0;

/* [Chassis] */
plate_t = 1.2;
lug_gap = 21.4;         // between the fins (strap 21 mm)
fin_t = 2.2;
fin_l = 9.0;            // along the Stick
fin_drop = 5.1;         // below the back surface
bar_in = 2.5;           // spring bar centre, in from the fin's outer end
bar_z = -3.5;           // spring bar centre below the back
bar_hole_d = 1.0; bar_hole_depth = 1.4;
edge_r = 0.6;           // every convex PETG edge is rounded to this radius (plate edges fully round)

/* [Charging port] */
port = true;
port_w = 14.0; port_h = 7.5;
port_from_face = 4.1;   // USB-C centre below the Stick's front face (measured on the M5Stack model)
skin_t = 1.5;           // end wall thickness over the port, where you cut the slit
slit_len = 12.0;

/* [Hidden] */
$fn = 48; eps = 0.01;

// ---- StickS3 (K150) ----------------------------------------------------------------
STICK_W = 24; STICK_L = 48; STICK_T = 14.08; STICK_R = 3;
FRONT_BTN = [[6.2, 17.8], [9.5, 11.5], 0.9];
BTN_XMINUS = [6.0, 11.0]; BTN_XPLUS = [19.0, 29.0]; BTN_Z = [3.6, 11.2];

// ---- Pocket --------------------------------------------------------------------------
CORE_L = STICK_L - 2 * squeeze; CORE_W = STICK_W - 2 * squeeze; CORE_T = STICK_T - squeeze; CORE_R = STICK_R - squeeze;
HL = CORE_L / 2; HW = CORE_W / 2;
back_t = under_plate + plate_t + over_plate;     // 2.7
Z0 = back_t; Z1 = back_t + CORE_T; TOP = Z1 + lip_t;
function sx(y_on_stick) = y_on_stick - STICK_L / 2;
function sy(x_on_stick) = STICK_W / 2 - x_on_stick;   // the Stick's x runs the other way (seen screen-up, USB-C down)

// ---- Outer body ------------------------------------------------------------------------
BODY_HW = HW + wall;            // 14.3
END_X = HL + end_t;             // 25.9
BODY_R = 3.0;
WIN = [[sx(14), sx(45.5)], [-9.5, 9.5]]; WIN_R = 3.0;
FRONT_BUMP = FRONT_BTN[2] + front_min - lip_t;

// ---- Chassis ---------------------------------------------------------------------------
CH_Z0 = under_plate; CH_Z1 = under_plate + plate_t;
LUG_Y0 = lug_gap / 2; CH_HW = LUG_Y0 + fin_t;         // 12.9: plate spans to the fins' outer faces
CH_HL = END_X - 2.0;                                  // 23.9: 2 mm of silicone past the plate and fin ends (>1 mm at the rounded corner)
FIN_X0 = CH_HL - fin_l;                               // 15.9
FIN_Z = -fin_drop;
BAR_X = CH_HL - bar_in;                               // 22.4
TAB_X = FIN_X0 + 6.1;                                 // tab centre along x (whole root lands on the fin)
TAB_W = 4.0; TAB_T = 2.0; TAB_Z0 = -1.5;              // tab root: this far above the pour surface
TAB_RUN = 4.0;                                        // tab reaches this far out from the fin face
TAB_RISE = TAB_RUN + 0.3;                             // ... rising this much: exactly 45 deg from its root 0.3 inside the fin
TAB_NECK = 0.6; TAB_GROOVE_Y = 0.1;
POST_Y0 = CH_HW + 2.5;                                // post seat starts here (rim starts at BODY_HW)
POST_Y1 = CH_HW + TAB_RUN + 0.2;                      // outer stop wall: 0.2 play
POST_WALL = 0.8;
POST_H = -(TAB_Z0 - TAB_T - TAB_RISE - 0.2) + 0.5;     // tall enough that the stop wall covers the whole tab tip

assert(BODY_HW - CH_HW >= 1.0, "not enough silicone outside the fins");
FIN_CORNER_COVER = BODY_R - norm([CH_HL - (END_X - BODY_R), CH_HW - (BODY_HW - BODY_R)]);
assert(FIN_CORNER_COVER >= 1.0, str("fin corner too close to the sleeve's rounded corner: ", FIN_CORNER_COVER));
assert(FRONT_BUMP >= 0, "front bump negative");
assert(bar_z - bar_hole_d / 2 - FIN_Z >= 1.0, "bar hole too close to the fin bottom");
assert(POST_Y0 > BODY_HW + 0.5, "posts must sit on the rim, clear of the cavity edge");

echo(str("Sleeve ", 2 * END_X, " x ", 2 * BODY_HW, " x ", TOP, " mm (+", FRONT_BUMP, " button bump); fins ", fin_drop,
         " below the back, spring bar at x=", BAR_X, " z=", bar_z, ", lug gap ", lug_gap));

module rrect(l, w, r) { offset(r = r) square([l - 2 * r, w - 2 * r], center = true); }
module slab(l, w, r, z) { translate([0, 0, z]) linear_extrude(eps) rrect(l, w, r); }

module body() {
    hull() {
        slab(2 * END_X, 2 * BODY_HW, BODY_R, 0);
        slab(2 * END_X, 2 * BODY_HW, BODY_R, TOP - front_chamfer);
        slab(2 * END_X - 2 * front_chamfer, 2 * BODY_HW - 2 * front_chamfer, BODY_R - front_chamfer, TOP);
    }
}
module side_bumps(extra = 0) {
    for (s = [[BTN_XMINUS, sign(sy(0))], [BTN_XPLUS, sign(sy(STICK_W))]]) {
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
    y0 = min(sy(FRONT_BTN[0][0]), sy(FRONT_BTN[0][1])) - 1.5; y1 = max(sy(FRONT_BTN[0][0]), sy(FRONT_BTN[0][1])) + 1.5;
    hull() {
        translate([(x0 + x1) / 2, (y0 + y1) / 2, TOP - 0.5]) linear_extrude(eps) rrect(x1 - x0 + 2 * extra, y1 - y0 + 2 * extra, 1.5);
        translate([(x0 + x1) / 2, (y0 + y1) / 2, TOP + FRONT_BUMP + extra]) linear_extrude(eps) rrect(x1 - x0 - 2 + 2 * extra, y1 - y0 - 2 + 2 * extra, 1.0);
    }
}
module envelope() { body(); side_bumps(); front_bump(); }

// ---- Core ---------------------------------------------------------------------------------
module core_full() {
    translate([0, 0, Z0]) linear_extrude(CORE_T) rrect(CORE_L, CORE_W, CORE_R);
    translate([(WIN[0][0] + WIN[0][1]) / 2, 0, Z1 - eps]) linear_extrude(TOP - Z1 + eps) rrect(WIN[0][1] - WIN[0][0], WIN[1][1] - WIN[1][0], WIN_R);
    translate([sx(FRONT_BTN[1][0]), min(sy(FRONT_BTN[0][0]), sy(FRONT_BTN[0][1])), Z1 - eps])
        cube([FRONT_BTN[1][1] - FRONT_BTN[1][0], FRONT_BTN[0][1] - FRONT_BTN[0][0], FRONT_BTN[2] + eps]);
}
// port pocket: a block off the core's USB-C end that reaches to within skin_t of the end
// face in the middle, full wall thickness at the slit ends
PORT_Z = Z1 - port_from_face;
assert(!port || PORT_Z - port_h / 2 > Z0 + 0.5 && PORT_Z + port_h / 2 < Z1, "port pocket out of range");
module port_core(t, half_w) {
    intersection() {
        translate([-(HL - 0.5), 0, PORT_Z]) rotate([0, -90, 0]) linear_extrude(10) rrect(port_h, 2 * half_w, 2);
        translate([-(END_X - t), -50, -50]) cube([100, 100, 100]);
    }
}
module tunnel_block() { hull() { port_core(skin_t, slit_len / 2 - 2.0); port_core(end_t, port_w / 2); } }

SCREWS = [[-6, 0], [13, 0]];
screw_d = 3.0; screw_head_d = 6.5; screw_head_h = 3.0;
module core_part() {
    difference() {
        union() { core_full(); if (port) tunnel_block(); }
        for (p = SCREWS) translate([p[0], p[1], TOP - 8]) cylinder(d = screw_d - 0.4, h = 9);
    }
}

// ---- Chassis --------------------------------------------------------------------------------
module fin_profile() {   // x-z, +x end
    hull() {
        translate([FIN_X0, CH_Z0]) square([fin_l, 0.5]);   // overlaps into the plate
        translate([CH_HL - 1.5, FIN_Z + 1.5]) circle(r = 1.5);
        translate([FIN_X0 + 4.0, FIN_Z + 1.5]) circle(r = 1.5);   // fuller fin: flat bottom from here to the outer end
    }
}
// gw grows the tab's width (x), gz its thickness (z), gy extends its outer end along the
// slope; the post seat uses gw and gy only, so it meets the tab's underside exactly
module tab(s, gw = 0, gz = 0, gy = 0) {
    hull() {
        translate([TAB_X - TAB_W / 2 - gw, s > 0 ? CH_HW - 0.3 : -(CH_HW - 0.3) - eps, TAB_Z0 - TAB_T - gz]) cube([TAB_W + 2 * gw, eps, TAB_T + 2 * gz]);
        translate([TAB_X - TAB_W / 2 - gw, s > 0 ? CH_HW + TAB_RUN + gy : -(CH_HW + TAB_RUN + gy) - eps, TAB_Z0 - TAB_T - TAB_RISE - gy - gz]) cube([TAB_W + 2 * gw, eps, TAB_T + 2 * gz]);
    }
}
module tab_grooves() {
    zoff = (0.3 + TAB_GROOVE_Y);   // 45 deg: the tab has risen this much at the groove
    depth = (TAB_T - TAB_NECK) / 2; d = depth * sqrt(2);
    for (s = [-1, 1]) for (zc = [TAB_Z0 - TAB_T - zoff, TAB_Z0 - zoff])
        intersection() {   // clipped so the groove never cuts into the fin's own face
            translate([TAB_X, s * (CH_HW + TAB_GROOVE_Y), zc]) rotate([45, 0, 0]) cube([TAB_W + 2, d, d], center = true);
            translate([TAB_X - 5, s > 0 ? CH_HW : -CH_HW - 10, zc - 5]) cube([10, 10, 10]);
        }
}
// The plate and fins are built undersize and grown by a sphere, so every outside edge of
// the PETG is rounded (silicone wears where it rubs a sharp edge). The tabs are added
// afterwards; they come off.
module chassis_body() {
    minkowski() {
        union() {
            translate([0, 0, CH_Z0 + edge_r]) linear_extrude(max(plate_t - 2 * edge_r, eps)) rrect(2 * CH_HL - 2 * edge_r, 2 * CH_HW - 2 * edge_r, 3 - edge_r);
            for (m = [0, 1]) mirror([m, 0, 0]) for (s = [-1, 1])
                translate([0, s * (LUG_Y0 + fin_t / 2), 0]) rotate([90, 0, 0]) translate([0, 0, -(fin_t - 2 * edge_r) / 2])
                    linear_extrude(fin_t - 2 * edge_r) offset(r = -edge_r) fin_profile();
        }
        sphere(r = edge_r, $fn = 20);
    }
}
module chassis(tabs = true) {
    difference() {
        union() {
            chassis_body();
            if (tabs) for (m = [0, 1]) mirror([m, 0, 0]) for (s = [-1, 1]) tab(s);
        }
        // blind spring bar holes from the slot side, with a small lead-in
        for (m = [0, 1]) mirror([m, 0, 0]) for (s = [-1, 1])
            translate([BAR_X, s * LUG_Y0, bar_z]) rotate([s > 0 ? -90 : 90, 0, 0]) {
                translate([0, 0, -eps]) cylinder(d = bar_hole_d, h = bar_hole_depth + eps, $fn = 16);
                translate([0, 0, -eps]) cylinder(d1 = bar_hole_d + 0.6, d2 = bar_hole_d, h = 0.3 + eps, $fn = 16);
            }
        if (tabs) for (m = [0, 1]) mirror([m, 0, 0]) tab_grooves();
    }
}

// ---- Silicone preview -------------------------------------------------------------------------
module silicone() {
    difference() {
        envelope();
        core_full();
        if (port) tunnel_block();
        translate([(WIN[0][0] + WIN[0][1]) / 2, 0, TOP - 1]) linear_extrude(3) rrect(WIN[0][1] - WIN[0][0], WIN[1][1] - WIN[1][0], WIN_R);
        chassis(tabs = false);
    }
}

// ---- Mold ------------------------------------------------------------------------------------------
margin = 6; MX = END_X + margin; MY = BODY_HW + margin;
cup_floor = 4; CUP_H = TOP + FRONT_BUMP + cup_floor;
module block(z0, h) { translate([0, 0, z0]) linear_extrude(h) rrect(2 * MX, 2 * MY, 4); }

// posts on the rim: a 45 deg seat matching the tab's underside, and an outer stop wall
module posts() {
    for (m = [0, 1]) mirror([m, 0, 0]) for (s = [-1, 1]) mirror([0, s < 0 ? 1 : 0, 0]) {
        difference() {
            translate([TAB_X - TAB_W / 2 - 1.5, POST_Y0, -POST_H]) cube([TAB_W + 3, POST_Y1 - POST_Y0 + POST_WALL, POST_H + eps]);
            // the seat: everything above the tab's underside plane, over the tab's width (+play), inside the stop wall
            hull() { tab(1, 0.2, 0, 0.2); translate([0, 0, -20]) tab(1, 0.2, 0, 0.2); }
        }
    }
}
module cup_body() {
    difference() {
        block(0, CUP_H);
        envelope();
    }
    posts();
}
module cup() {
    difference() {
        cup_body();
        for (p = SCREWS) translate([p[0], p[1], 0]) {
            translate([0, 0, TOP - 1]) cylinder(d = screw_d + 0.4, h = 20);
            translate([0, 0, CUP_H - screw_head_h]) cylinder(d = screw_head_d, h = screw_head_h + 1);
        }
    }
}

// ---- Lid (optional) -----------------------------------------------------------------------------------
LID_T = 3.0; LID_GAP = 0.3;
module lid() {
    difference() {
        union() {
            translate([0, 0, -(LID_T + LID_GAP)]) linear_extrude(LID_T) rrect(2 * MX, 2 * MY, 4);
            for (sx_ = [-1, 1], sy_ = [-1, 1]) translate([sx_ * (MX - 3), sy_ * (MY - 3), -LID_GAP - eps]) cylinder(d = 4, h = LID_GAP + eps);
        }
        // openings around each fin + tab + post
        for (m = [0, 1]) mirror([m, 0, 0]) for (s = [-1, 1])
            translate([FIN_X0 - 0.6, s > 0 ? LUG_Y0 - 0.6 : -(POST_Y1 + POST_WALL + 0.6), -LID_T - LID_GAP - 1])
                cube([fin_l + 1.2, POST_Y1 + POST_WALL + 0.6 - (LUG_Y0 - 0.6), LID_T + 3]);
        for (x = [-8, 8]) translate([x, 0, -LID_T - LID_GAP - 1]) cylinder(d = 2.5, h = LID_T + 3);
    }
}

// ---- Exports ---------------------------------------------------------------------------------------------
if (part == "chassis")      translate([0, 0, -CH_Z0]) chassis();                          // plate on the bed, fins up
else if (part == "core")    translate([0, 0, -Z0]) core_part();
else if (part == "cup")     translate([0, 0, CUP_H]) rotate([180, 0, 0]) cup();          // open top up
else if (part == "lid")     translate([0, 0, LID_T + LID_GAP]) lid();                    // flat, feet up
else if (part == "chassis_assy") chassis();
else if (part == "check_chassis") intersection() { chassis(); union() { cup(); core_part(); } }   // must be empty
else if (part == "check_core")    intersection() { core_part(); cup(); }                          // must be empty
else if (part == "check_lift")    intersection() { minkowski() { core_part(); translate([0, 0, -40]) cylinder(d = 0.02, h = 40); } cup(); }
else if (part == "check_chlift")  intersection() { minkowski() { chassis(); translate([0, 0, -40]) cylinder(d = 0.02, h = 40); } cup(); }
else if (part == "check_lid")     intersection() { lid(); union() { cup(); chassis(); } }
else silicone();
