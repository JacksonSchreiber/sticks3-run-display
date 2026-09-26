// Sleeve v5: one-piece silicone band + sealed jacket for the M5Stack StickS3, in the style
// of a Fitbit Charge / Huawei Band: the band flows straight out of the case, no lugs, no
// loops, no removable strap. Closure is a PETG peg buckle cast into the short strap: the
// long strap passes under the buckle's crossbar, the peg drops into one of its holes, and
// the tail tucks under the short strap. All silicone except the buckle; no frame.
//
// Parts (set `part`, or use the Customizer):
//   "buckle"  PETG x1, 100% infill. Print as exported (on its side), brim, no supports.
//   "core"    PLA. Print as exported (back face down), no supports.
//   "cup"     PLA. One long open-top mold: jacket pocket in the middle, strap troughs either
//             side, a seat for the buckle at the short strap's end, M3 clamp + M4 jack holes.
//             Print DIAGONALLY on the 220 mm bed (it is ~226 mm long), brim.
//   "lid"     PLA, required. Forms the wrist face: fillet ridge that rounds the edge, the
//             boss that lifts the short strap's end (the tail passes under it), and the pins
//             that cast the seven holes in the long strap. Print diagonally too.
//   "band"    preview of the finished silicone part (don't print).
//
// Coordinates: x along the band (short strap toward +x, long strap toward -x), y across,
// z from the wrist face (0) toward the front. The cup's rim is z = 0.
//
// Casting (open pour, window face down):
//   1. Release on everything. Core on the cup floor, pad down, two M3x8 up through the
//      cup. Buckle into its seat at the +x end, plate against the cavity end, tongues in.
//   2. Mix 20 g A + 20 g B (+ pigment). Syringe the lip layer and the front-button pocket,
//      then pour along the whole length to just above the rim. Tap.
//   3. Lid on, one end first, press down onto the rim. Excess bleeds from the vents.
//   4. Cure 24 h (or ~6 h at 45 C).
//   5. Lid off (cut the flash round it, lever). M3 screws out. Card down the jacket's long
//      sides, then M4 screws into the jack holes until the core and band rise. Peel the
//      straps out of their troughs, slide the core out through the window. Punch through
//      the thin skins at the bottom of the seven holes if any remain. Cut the port slit.

/* [Part] */
part = "band"; // [buckle, core, cup, lid, band]

/* [Fit] */
squeeze = 0.3;
wrist = 165;            // snug wrist circumference
fit_ease = 5;           // middle hole = wrist + this
hole_count = 7; hole_pitch = 5; hole_d = 3.0;

/* [Jacket] */
wall = 2.8; end_t = 2.2; lip_t = 0.8; back_t = 1.5; side_bump = 0.5; front_min = 0.8;
body_r = 4.5;           // plan corner radius (the pocket's R3 corners sit 1.6 inside)
front_r = 2.5;          // round on the front perimeter
back_r = 0.8;           // round on the wrist-side edge (lid ridge)

/* [Straps] */
strap_w = 22; strap_t = 2.8;
root_len = 12;          // strap flares to the jacket's width over this length
root_t = 5.0;           // strap thickness where it meets the jacket (gusset)
fillet_r = 3.0;         // fillet between the gusset top and the end wall
short_len = 45;         // jacket end -> strap end (buckle plate)
lift = 3.0;             // the short strap's end rises this much so the tail passes under it
lift_len = 12; ramp_len = 12;
tail = 25;              // long strap beyond the last hole

/* [Buckle] */
bk_plate_t = 1.5; bk_rail_w = 3.0; bk_len = 12; bk_bar_t = 3.0; bk_clear = 3.1;
peg_d = 2.4; peg_bump = 0.9; PEG_TIP = -1.2; tongue_l = 10; tongue_w = 6; tongue_t = 1.2;   // peg neck 2.4 with a one-sided 0.9 bump: the 3.0 hole snaps over it

/* [Charging port] */
port = true; port_w = 14.0; port_h = 7.5; port_from_face = 4.1; skin_t = 1.5; slit_len = 12.0;

/* [Hidden] */
$fn = 48; eps = 0.01;
STICK_W = 24; STICK_L = 48; STICK_T = 14.08; STICK_R = 3;
FRONT_BTN = [[6.2, 17.8], [9.5, 11.5], 0.9];
BTN_XMINUS = [6.0, 11.0]; BTN_XPLUS = [19.0, 29.0]; BTN_Z = [3.6, 11.2];
CORE_L = STICK_L - 2 * squeeze; CORE_W = STICK_W - 2 * squeeze; CORE_T = STICK_T - squeeze; CORE_R = STICK_R - squeeze;
HL = CORE_L / 2; HW = CORE_W / 2;
Z0 = back_t; Z1 = back_t + CORE_T; TOP = Z1 + lip_t;
function sx(y_on_stick) = y_on_stick - STICK_L / 2;
function sy(x_on_stick) = STICK_W / 2 - x_on_stick;
BODY_HW = HW + wall; END_X = HL + end_t;
WIN = [[sx(14), sx(45.5)], [-9.5, 9.5]]; WIN_R = 3.0;
FRONT_BUMP = FRONT_BTN[2] + front_min - lip_t;

// ---- strap layout (s = distance from the jacket's end face along the strap) --------------------
PEG_S = short_len + bk_plate_t + bk_len - bk_bar_t / 2;             // peg centre, from the jacket's +x end
function smooth(u) = let(v = min(max(u, 0), 1)) v * v * (3 - 2 * v);
function w_at(s) = strap_w + (2 * BODY_HW - strap_w) * (1 - smooth(s / root_len));
function t_at(s) = strap_t + (root_t - strap_t) * (1 - smooth(s / root_len));
function lift_at(s) = lift * smooth((s - (short_len - lift_len - ramp_len)) / ramp_len);   // short strap only
mid_size = wrist + fit_ease;
function hole_s(i) = (mid_size - 2 * END_X - PEG_S) + (i - (hole_count - 1) / 2) * hole_pitch;   // from the jacket's -x end
long_len = hole_s(hole_count - 1) + tail;
X_SHORT_END = END_X + short_len; X_LONG_END = -(END_X + long_len);
echo(str("v5: jacket ", 2 * END_X, " x ", 2 * BODY_HW, " x ", TOP, " (+", FRONT_BUMP, "); short strap ", short_len, ", long strap ", long_len,
         ", overall ", X_SHORT_END + bk_plate_t + bk_len - X_LONG_END, " mm; sizes ", [for (i = [0 : hole_count - 1]) 2 * END_X + PEG_S + hole_s(i)]));

module rrect(l, w, r) { offset(r = r) square([l - 2 * r, w - 2 * r], center = true); }
module slab(l, w, r, z) { translate([0, 0, z]) linear_extrude(eps) rrect(l, w, r); }

// ---- jacket body (pebble: flat back, rounded front perimeter) ----------------------------------
module body() {
    hull() {
        slab(2 * END_X, 2 * BODY_HW, body_r, 0);
        for (a = [0 : 15 : 90]) { inset = front_r * (1 - cos(a)); slab(2 * END_X - 2 * inset, 2 * BODY_HW - 2 * inset, body_r - inset, TOP - front_r + front_r * sin(a)); }
    }
}
module side_bumps(extra = 0) {
    for (s = [[BTN_XMINUS, sign(sy(0))], [BTN_XPLUS, sign(sy(STICK_W))]]) {
        x0 = sx(s[0][0]) - 1.5; x1 = sx(s[0][1]) + 1.5; z0 = Z0 + BTN_Z[0] - 1.0; z1 = Z0 + BTN_Z[1] + 1.0;
        hull() {
            translate([(x0 + x1) / 2, s[1] * (BODY_HW - 0.5), (z0 + z1) / 2]) rotate([90, 0, 0]) linear_extrude(eps) rrect(x1 - x0 + 2 * extra, z1 - z0 + 2 * extra, 2.5);
            translate([(x0 + x1) / 2, s[1] * (BODY_HW + side_bump + extra), (z0 + z1) / 2]) rotate([90, 0, 0]) linear_extrude(eps) rrect(x1 - x0 - 2 + 2 * extra, z1 - z0 - 2 + 2 * extra, 1.5);
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

// ---- straps: chained cross-sections; z offset lifts the short strap's end ----------------------
module xsec(x, w, t, zoff) { translate([x, 0, zoff]) rotate([90, 0, 90]) linear_extrude(eps) translate([0, t / 2]) rrect(w, t, min(1.2, t / 2 - eps)); }
module strap(dir) {   // dir = +1 short, -1 long
    L = dir > 0 ? short_len : long_len;
    n = 40;
    for (k = [0 : n - 1]) {
        s0 = L * k / n; s1 = L * (k + 1) / n;
        hull() {
            xsec(dir * (END_X + s0), w_at(s0), t_at(s0), dir > 0 ? lift_at(s0) : 0);
            xsec(dir * (END_X + s1), w_at(s1), t_at(s1), dir > 0 ? lift_at(s1) : 0);
        }
    }
    // gusset fillet between the strap's top and the jacket's end wall
    translate([dir * END_X, 0, 0]) mirror([dir < 0 ? 1 : 0, 0, 0]) rotate([90, 0, 0]) linear_extrude(2 * BODY_HW - 6, center = true)
        difference() { translate([-eps, root_t - eps]) square([fillet_r + eps, fillet_r + eps]); translate([fillet_r, root_t + fillet_r]) circle(r = fillet_r); }
}
// plan outline of the short strap from the ramp start to the end of the buckle plate
S_A = short_len - lift_len - ramp_len;
module lift_outline2d(o = 0) {
    n = 24; s1 = short_len + bk_plate_t + 0.2;
    offset(r = o) polygon(concat([for (k = [0 : n]) let(s = S_A + (s1 - S_A) * k / n) [END_X + s, w_at(s) / 2]],
                                 [for (k = [n : -1 : 0]) let(s = S_A + (s1 - S_A) * k / n) [END_X + s, -w_at(s) / 2]]));
}
module holes() { for (i = [0 : hole_count - 1]) translate([-(END_X + hole_s(i)), 0, -1]) cylinder(d = hole_d, h = strap_t + 2); }

module envelope() { body(); side_bumps(); front_bump(); strap(1); strap(-1); }

// 2D outline of everything, for the lid ridge and the cup
module outline2d() { projection() envelope(); }

// ---- core ------------------------------------------------------------------------------------------
module core_full() {
    translate([0, 0, Z0]) linear_extrude(CORE_T) rrect(CORE_L, CORE_W, CORE_R);
    translate([(WIN[0][0] + WIN[0][1]) / 2, 0, Z1 - eps]) linear_extrude(TOP - Z1 + eps) rrect(WIN[0][1] - WIN[0][0], WIN[1][1] - WIN[1][0], WIN_R);
    translate([sx(FRONT_BTN[1][0]), min(sy(FRONT_BTN[0][0]), sy(FRONT_BTN[0][1])), Z1 - eps])
        cube([FRONT_BTN[1][1] - FRONT_BTN[1][0], FRONT_BTN[0][1] - FRONT_BTN[0][0], FRONT_BTN[2] + eps]);
}
PORT_Z = Z1 - port_from_face;
module port_core(t, half_w) {
    intersection() {
        translate([-(HL - 0.5), 0, PORT_Z]) rotate([0, -90, 0]) linear_extrude(10) rrect(port_h, 2 * half_w, 2);
        translate([-(END_X - t), -50, -50]) cube([100, 100, 100]);
    }
}
module tunnel_block() { hull() { port_core(skin_t, slit_len / 2 - 2.0); port_core(end_t, port_w / 2); } }
SCREWS = [[-6, 0], [13, 0]]; JACKS = [[3.5, 0], [18.0, 0]];
screw_d = 3.0; screw_head_d = 6.5; screw_head_h = 3.0; jack_d = 3.3;
module core_part() {
    difference() {
        union() { core_full(); if (port) tunnel_block(); }
        for (p = SCREWS) translate([p[0], p[1], TOP - 8]) cylinder(d = screw_d - 0.4, h = 9);
    }
}

// ---- buckle ---------------------------------------------------------------------------------------------
// Sits at the short strap's raised end: a plate closes the strap end (its outer face shows),
// two tongues anchor it in the strap, two rails carry a crossbar with the peg. The long strap
// passes under the crossbar and under the raised strap end; the peg drops into a hole.
BK_Z0 = lift; BK_Z1 = lift + strap_t;                 // the raised strap's thickness band
BK_HW = strap_w / 2 + bk_rail_w;                      // rails outside the strap's width
bk_r = 0.6;   // rounding on everything you touch: rails, crossbar, plate's outer edges. Plate's inner face and tongues stay square (they seal / are buried)
module buckle_frame_raw(grow = 0, shrink = 0) {
    x0 = X_SHORT_END;
    // plate (the part outside the cavity face gets rounded; the inner face is kept flat by the intersection below)
    translate([x0 - grow + shrink - 1, -(BK_HW + grow - shrink), BK_Z0 - grow + shrink]) cube([bk_plate_t + 2 * grow - 2 * shrink + 1, 2 * BK_HW + 2 * grow - 2 * shrink, strap_t + 2 * grow - 2 * shrink]);   // full frame width: closes the strap cavity and joins the rails
    for (s = [-1, 1]) translate([x0 - grow + shrink - 1, s * (BK_HW - bk_rail_w / 2) - bk_rail_w / 2 - grow + shrink, BK_Z0 - grow + shrink]) cube([bk_plate_t + bk_len + 2 * grow - 2 * shrink + 1, bk_rail_w + 2 * grow - 2 * shrink, strap_t + 2 * grow - 2 * shrink]);
    translate([x0 + bk_plate_t + bk_len - bk_bar_t - grow + shrink, -BK_HW - grow + shrink, BK_Z0 - grow + shrink]) cube([bk_bar_t + 2 * grow - 2 * shrink, 2 * BK_HW + 2 * grow - 2 * shrink, strap_t + 2 * grow - 2 * shrink]);
}
module buckle(grow = 0) {
    x0 = X_SHORT_END;
    if (grow == 0) {
        // rounded frame, cut flat at the plate's inner face (x = x0) so it seals the cavity end
        intersection() {
            minkowski() { buckle_frame_raw(0, bk_r); sphere(r = bk_r, $fn = 16); }
            translate([x0, -50, -50]) cube([100, 100, 100]);
        }
    } else {
        buckle_frame_raw(grow, 0);
    }
    // tongues into the strap, buried mid-thickness (square: they are buried, and the holes key the silicone)
    for (s = [-1, 1]) translate([x0 - tongue_l - grow, s * (strap_w / 2 - 1.5 - tongue_w / 2) - tongue_w / 2 - grow, BK_Z0 + (strap_t - tongue_t) / 2 - grow])
        difference() { cube([tongue_l + 0.5 + 2 * grow, tongue_w + 2 * grow, tongue_t + 2 * grow]);  /* runs 0.5 into the plate */ if (grow == 0) for (h = [3, 7]) translate([h, tongue_w / 2, -1]) cylinder(d = 2.2, h = 5, $fn = 16); }
    // peg, pointing at the wrist, rounded tip
    // peg: passes through the long strap (2.8) and 1.2 mm beyond its wrist face; a one-sided
    // bump on the +y edge (0.9 proud, 45-degree ramps) is what the 3.0 hole snaps over.
    // One-sided so it prints on its side (+y up) with no overhang or island.
    translate([END_X + PEG_S, 0, 0]) {
        translate([0, 0, PEG_TIP - grow]) cylinder(d1 = 1.4 + 2 * grow, d2 = peg_d + 2 * grow, h = 0.5 + grow);
        translate([0, 0, PEG_TIP + 0.5 - eps]) cylinder(d = peg_d + 2 * grow, h = BK_Z0 + 0.5 - (PEG_TIP + 0.5) + eps);
        hull() {
            translate([0, 0, PEG_TIP + 0.5]) cylinder(d = peg_d + 2 * grow, h = eps);
            translate([0, peg_bump, PEG_TIP + 0.5 + peg_bump]) cylinder(d = peg_d + 2 * grow, h = eps);
            translate([0, 0, PEG_TIP + 0.5 + 2 * peg_bump]) cylinder(d = peg_d + 2 * grow, h = eps);
        }
    }
}

// ---- silicone preview ------------------------------------------------------------------------------------
module band() {
    difference() {
        envelope();
        core_full(); if (port) tunnel_block();
        translate([(WIN[0][0] + WIN[0][1]) / 2, 0, TOP - 1]) linear_extrude(3) rrect(WIN[0][1] - WIN[0][0], WIN[1][1] - WIN[1][0], WIN_R);
        buckle(); holes(); lid_ridge();
    }
}

// ---- mold ---------------------------------------------------------------------------------------------------
margin = 6; cup_floor = 4;
CUP_H = TOP + FRONT_BUMP + cup_floor;
LID_T = 3.0; RIDGE_OVER = 0.15; REBATE_D = 0.9;
module footprint2d(o) { offset(r = o) outline2d(); }
module block(z0, h) { translate([0, 0, z0]) linear_extrude(h) offset(r = margin) offset(delta = 0) outline2d(); }
module lid_ridge() {
    steps = 6;
    for (i = [0 : steps - 1]) {
        h0 = back_r * i / steps; h1 = back_r * (i + 1) / steps;
        inset = back_r - sqrt(back_r * back_r - (back_r - h0) * (back_r - h0));
        translate([0, 0, h0 - eps]) linear_extrude(h1 - h0 + 2 * eps) difference() { footprint2d(RIDGE_OVER); footprint2d(-inset); }
    }
}
module cup() {
    difference() {
        block(0, CUP_H);
        envelope();
        translate([0, 0, -1]) linear_extrude(1 + REBATE_D) footprint2d(RIDGE_OVER + 0.1);   // rebate for the lid ridge
        buckle(0.2);                                                                     // seat for the buckle (plate seals the cavity end)
        translate([0, 0, -1]) linear_extrude(1 + lift + eps) lift_outline2d(0.1);       // room for the lid boss under the lifted strap end
        // open pocket round the buckle frame, from the plate's back face out, up to the seat's ceiling:
        // the plate (full strap width) is what closes the strap cavity; the rails beside it sit in the open
        translate([X_SHORT_END - 0.2, -BK_HW - 2, -1]) cube([bk_plate_t + bk_len + 4.2, 2 * BK_HW + 4, 1 + BK_Z1 + 0.2]);
        for (p = SCREWS) translate([p[0], p[1], 0]) { translate([0, 0, TOP - 1]) cylinder(d = screw_d + 0.4, h = 20); translate([0, 0, CUP_H - screw_head_h]) cylinder(d = screw_head_d, h = screw_head_h + 1); }
        for (p = JACKS) translate([p[0], p[1], TOP - 1]) cylinder(d = jack_d, h = 20);
        // shallow recesses under the hole pins so the holes cast through cleanly
        for (i = [0 : hole_count - 1]) translate([-(END_X + hole_s(i)), 0, strap_t - eps]) cylinder(d = hole_d + 0.6, h = 0.6);
    }
}
module lid() {
    difference() {
        union() {
            translate([0, 0, -LID_T]) linear_extrude(LID_T) offset(r = margin) outline2d();
            lid_ridge();
            // boss that forms the lifted underside of the short strap's end
            n = 24; s_end = short_len + bk_plate_t + 0.2;
            for (k = [0 : n - 1]) { s0 = S_A + (s_end - S_A) * k / n; s1 = S_A + (s_end - S_A) * (k + 1) / n;
                hull() { translate([END_X + s0, -w_at(s0) / 2, -eps]) cube([eps, w_at(s0), lift_at(s0) + eps]); translate([END_X + s1, -w_at(s1) / 2, -eps]) cube([eps, w_at(s1), lift_at(s1) + eps]); } }
            // pins for the holes
            for (i = [0 : hole_count - 1]) translate([-(END_X + hole_s(i)), 0, -eps]) cylinder(d = hole_d, h = strap_t + 0.5);
        }
        for (x = [-8, 8]) translate([x, 0, -LID_T - 1]) cylinder(d = 2.5, h = LID_T + 2);
        for (x = [-(END_X + 20), -(END_X + long_len - 12), END_X + 15]) translate([x, 0, -LID_T - 1]) cylinder(d = 2.0, h = LID_T + 2);
        translate([X_SHORT_END + bk_plate_t + 0.3, -BK_HW - 2.5, -LID_T - 1]) cube([bk_len + 3.5, 2 * BK_HW + 5, LID_T + 2]);   // clear the buckle frame
    }
}

// ---- exports ----------------------------------------------------------------------------------------------------
if (part == "buckle")      translate([0, 0, BK_HW]) rotate([90, 0, 0]) translate([-X_SHORT_END, 0, 0]) buckle();   // on its side
else if (part == "core")   translate([0, 0, -Z0]) core_part();
else if (part == "cup")    translate([0, 0, CUP_H]) rotate([180, 0, 0]) cup();
else if (part == "lid")    translate([0, 0, LID_T]) lid();
else if (part == "buckle_assy") buckle();
else if (part == "check_core")   intersection() { core_part(); cup(); }
else if (part == "check_lift")   intersection() { minkowski() { core_part(); translate([0, 0, -40]) cylinder(d = 0.02, h = 40); } cup(); }
else if (part == "check_buckle") intersection() { buckle(); union() { cup(); core_part(); } }
else if (part == "check_lid")    intersection() { lid(); union() { cup(); buckle(); core_part(); } }
else band();
