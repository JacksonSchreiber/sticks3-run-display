// Sleeve v6: one-piece silicone band + sealed jacket for the M5Stack StickS3 (Fitbit / Huawei
// band style), closed by a classic tang buckle. The buckle is one PETG piece cast into the short
// strap's end: a plate buried in the strap (two holed anchors inside it), and from the plate a
// rounded frame with two lugs for the Tropic strap's 22 mm spring bar (24.5 tip to tip, 2.5 body,
// 0.8 tips) and a far bar with a scooped rest for the tongue. The tongue is a second PETG print
// (full-width sleeve on the spring bar + arm). The tail is held by a small silicone keeper loop,
// cast separately and slipped over the buckle onto the short strap, like any watch.
//
// Wear: long strap under the far bar, tongue out through a hole, tail over the sleeve and the
// plate, along the short strap and through the keeper.
//
// Parts (set `part`, or use the Customizer):
//   "buckle"      PETG x1. Print as exported (on its side): the spring-bar holes are vertical,
//                 one rail is on the bed, the other bridges 11 mm. Supports on, "on build plate
//                 only" (they only go under the two anchors). 100% solid, 250-255 C, fan 10-20%,
//                 slow outer walls, Arachne walls, brim.
//   "tongue"      PETG x1. Print as exported (sleeve standing): round bore, fine detail. Supports
//                 on, build plate only (under the arm).
//   "keeper_mold" PLA. Two ring cavities: fill with a syringe, scrape flush, cure, pull the rings out.
//   "core"        PLA, 0.16. Print as exported (back face down), no supports.
//   "cup"         PLA. One long open-top mold. Print DIAGONALLY on the 220 mm bed, brim.
//   "lid"         PLA, required. Forms the wrist face: fillet ridge, the clamp step over the
//                 buckle plate, the pins that cast the holes, vents. Diagonally too.
//   "band"        preview of the finished silicone part (don't print).
//
// Coordinates: x along the band (short strap toward +x, long strap toward -x), y across,
// z from the wrist face (0) toward the front. The cup's rim is z = 0.
//
// Casting (open pour, window face down):
//   1. Release on the PLA only (never on the buckle). Core on the cup floor, pad down, two M3x8
//      up through the cup. Buckle into its seat at the +x end: plate in the slot, anchors in the
//      strap trough, frame hanging free in the pocket.
//   2. Mix 22 g A + 22 g B (+ pigment). Syringe the lip layer, the front-button pocket and the
//      strap end around the anchors, then pour along the whole length to just above the rim. Tap.
//   3. Lid on, one end first, press down onto the rim. Excess bleeds from the vents.
//   4. Cure 24 h (or ~6 h at 45 C). Fill the keeper mold from the same mix.
//   5. Lid off, M3 screws out, card down the jacket's long sides, M4 screws into the jack holes
//      until the core and band rise. Peel the straps out, slide the core out through the window.
//      Trim the vent nubs, punch the hole skins, cut the port slit.
//   6. Sleeve on the spring bar, compress the bar into the two lug holes. Keeper over the buckle.

/* [Part] */
part = "band"; // [buckle, tongue, fixed_tongue, keeper_mold, core, cup, lid, band]

/* [Fit] */
squeeze = 0.0;           // pocket = Stick size; the silicone on every face grips it
wrist = 175;            // circumference at the middle hole minus fit_ease (v6: +10, the v5 holes sat too close to the jacket)
fit_ease = 5;           // middle hole = wrist + this
hole_count = 9; hole_pitch = 5; hole_x = 3.4; hole_y = 5.8;   // slots: rounded ends, wide enough for the 4.5 mm tongue

/* [Jacket] */
wall = 2.8; end_t = 2.2; lip_t = 1.4; back_t = 1.7; side_bump = 0.5; front_min = 1.4;   // v6: lip and back 0.2 thicker than v5
body_r = 2.0;           // plan corner radius
front_r = 2.5;          // round on the front perimeter
back_r = 0.8;           // round on the wrist-side edge (lid ridge)

/* [Straps] */
strap_w = 22; strap_t = 2.8;
root_len = 12;          // strap flares to the jacket's width over this length
hinge_t = 2.0;          // strap thickness at the jacket: a thin, wide hinge
hinge_len = 6;
root_t = hinge_t;
tail_r = 11;            // long strap's end is a full semicircle
fillet_r = 2.0;         // fillet between the hinge top and the end wall
short_len = 45;         // jacket end -> strap end (buckle plate)
tail = 30;              // long strap beyond the last hole

/* [Buckle] */
bk_plate_t = 5.0;       // plate closing the strap's end (along the strap)
bk_h = 4.5;             // plate and frame height
bk_rail_w = 3.2; bk_far_t = 4.5;
bk_fillet = 2.0;        // inside fillets in plan (rail roots, far bar corners)
bk_round = 3.5;         // outside plan radius at the far corners
bk_r = 1.5;             // edge rounding everywhere (rails end up almost round in section)
bar_len = 24.5; bar_d = 2.5; bar_tip_d = 0.8; bar_hole_d = 1.0; tip_in = 0.95;   // tips go 0.95 into each lug, through 1.0 mm holes
bar_from_face = 4.0;    // plate's outer face -> bar centre
tongue_len = 13.5;      // bar centre -> tongue tip
anc_l = 16; anc_w = 7; anc_t = 1.6;   // anchors buried in the strap

/* [Tongue] */
arm_w = 4.5; arm_t = 2.2; sleeve_wall = 1.3; bore_clr = 0.5; tip_up = 1.2; scoop = 0.8;   // bore 3.0 for the 2.5 bar; sleeve OD 5.6

/* [Keeper] */
kp_in_w = 22.2; kp_in_h = 5.6; kp_wall = 2.0; kp_w = 5.0; kp_r = 1.5;   // ring: strap + tail inside, 2 mm section, 5 mm wide

/* [Texture] */
texture = true;         // diamond knurl on the straps' outer face (ridges on the cup's trough floor)
tex_pitch = 2.2; tex_angle = 35; tex_depth = 0.4; tex_w = 0.8;   // groove spacing, angle to the strap, depth, width at the surface
tex_border = 2.0;       // smooth margin along the strap edges and round tip
tex_slot_margin = 1.5;  // smooth lane around the slot row (no groove ends at a slot, where a tear would start)

/* [Charging port] */
port = true; port_w = 14.0; port_h = 7.5; port_from_face = 4.1; skin_t = 1.5;
fin_t = 0.5; fin_len = 10.0; fin_out = 1.0;   // v6: a 0.5 mm blade on the core casts the port slot through the skin (no slit to cut, rounded ends so it cannot spread)

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
win_margin = 1.5;
SCREEN = [[18.5, 39.1], [4.6, 19.4]];
WIN = [[sx(SCREEN[0][0] - win_margin), sx(SCREEN[0][1] + win_margin)], [-((SCREEN[1][1] - SCREEN[1][0]) / 2 + win_margin), (SCREEN[1][1] - SCREEN[1][0]) / 2 + win_margin]]; WIN_R = 4.0;
FRONT_BUMP = FRONT_BTN[2] + front_min - lip_t;

// ---- buckle layout ------------------------------------------------------------------------------
X0 = END_X + short_len;                      // plate's inner face = strap end
X_FACE = X0 + bk_plate_t;                    // plate's outer face
X_BAR = X_FACE + bar_from_face;              // spring bar
IW = bar_len - 2 * tip_in;                   // 22.6 between the lugs
BK_HW = IW / 2 + bk_rail_w;                  // 14.5: frame half width
X_FAR = X_BAR + tongue_len - 2.0 - bk_far_t / 2;   // far bar centre: tongue tip ends 2 mm past its outer face
X_END = X_FAR + bk_far_t / 2;
BAR_Z = bk_h / 2 + 0.35;                    // bar a touch high so the sleeve does not sit below the wrist face
ENGAGE_S = short_len + bk_plate_t + bar_from_face + 3.5;   // where the tongue crosses the tail, from the jacket's +x end

// ---- strap layout (s = distance from the jacket's end face along the strap) --------------------
function smooth(u) = let(v = min(max(u, 0), 1)) v * v * (3 - 2 * v);
function w_at(s) = strap_w + (2 * BODY_HW - strap_w) * (1 - smooth(s / root_len));
function t_at(s) = hinge_t + (strap_t - hinge_t) * smooth((s - hinge_len) / (root_len - hinge_len));
function w_end(s, L) = (s > L - tail_r) ? 2 * sqrt(max(tail_r * tail_r - (s - (L - tail_r)) * (s - (L - tail_r)), 0.01)) : 1e9;
mid_size = wrist + fit_ease;
function hole_s(i) = (mid_size - 2 * END_X - ENGAGE_S) + (i - (hole_count - 1) / 2) * hole_pitch;   // from the jacket's -x end
long_len = hole_s(hole_count - 1) + tail;
X_SHORT_END = X0; X_LONG_END = -(END_X + long_len);
echo(str("v6: jacket ", 2 * END_X, " x ", 2 * BODY_HW, " x ", TOP, " (+", FRONT_BUMP, "); short strap ", short_len, ", long strap ", long_len,
         ", buckle ", X_END - X0, " long x ", 2 * BK_HW, " wide, overall ", X_END - X_LONG_END, " mm; sizes ", [for (i = [0 : hole_count - 1]) 2 * END_X + ENGAGE_S + hole_s(i)]));

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

// ---- straps: chained cross-sections --------------------------------------------------------------
module xsec(x, w, t) { translate([x, 0, 0]) rotate([90, 0, 90]) linear_extrude(eps) translate([0, t / 2]) rrect(max(w, 0.4), t, min(1.2, t / 2 - eps, max(w, 0.4) / 2 - eps)); }
module strap(dir) {   // dir = +1 short, -1 long
    L = dir > 0 ? short_len : long_len;
    n = 60; s_start = -body_r - 0.5;   // starts inside the jacket so the root fills the plan corners
    for (k = [0 : n - 1]) {
        s0 = s_start + (L - s_start) * k / n; s1 = s_start + (L - s_start) * (k + 1) / n;
        w0 = min(w_at(max(s0, 0)), dir < 0 ? w_end(s0, L) : 1e9); w1 = min(w_at(max(s1, 0)), dir < 0 ? w_end(s1, L) : 1e9);
        hull() { xsec(dir * (END_X + s0), w0, t_at(max(s0, 0))); xsec(dir * (END_X + s1), w1, t_at(max(s1, 0))); }
    }
    // gusset fillet between the strap's top and the jacket's end wall
    translate([dir * END_X, 0, 0]) mirror([dir < 0 ? 1 : 0, 0, 0]) rotate([90, 0, 0]) linear_extrude(2 * BODY_HW - 2 * body_r - 1, center = true)
        difference() { translate([-eps, root_t - eps]) square([fillet_r + eps, fillet_r + eps]); translate([fillet_r, root_t + fillet_r]) circle(r = fillet_r); }
}
module slot(lx, ly, h) { hull() for (s = [-1, 1]) translate([0, s * (ly - lx) / 2, 0]) cylinder(d = lx, h = h); }   // stadium along y
module holes() { for (i = [0 : hole_count - 1]) translate([-(END_X + hole_s(i)), 0, -1]) slot(hole_x, hole_y, strap_t + 2); }

// ---- texture: two families of shallow grooves crossing at +-tex_angle, only where the strap is full thickness ----
module slot2d(lx, ly) { hull() for (s = [-1, 1]) translate([0, s * (ly - lx) / 2]) circle(d = lx); }
module hatch2d(w) { for (a = [tex_angle, -tex_angle]) rotate(a) for (k = [-48 : 48]) translate([0, k * tex_pitch]) square([440, w], center = true); }
module tex_region2d() {
    difference() {   // long strap: past the hinge, inset from the edges and the round tip, smooth lane along the slots
        offset(delta = -tex_border) hull() {
            translate([-(END_X + long_len - tail_r), 0]) circle(r = tail_r);
            translate([-(END_X + root_len + 1), -strap_w / 2]) square([eps, strap_w]);
        }
        hull() for (i = [0, hole_count - 1]) translate([-(END_X + hole_s(i)), 0]) offset(delta = tex_slot_margin) slot2d(hole_x, hole_y);
    }
    // short strap: between the hinge and the buried anchors (never over the anchors: only 0.6 mm of silicone covers them)
    translate([END_X + root_len + 3, -(strap_w / 2 - tex_border)]) square([short_len - anc_l - 1.5 - (root_len + 3), strap_w - 2 * tex_border]);
}
module texture() {   // the ridge volume: solid in the cup, empty in the band. Two steps so the groove is tapered, not square-cornered
    if (texture) {
        translate([0, 0, strap_t - tex_depth / 2]) linear_extrude(tex_depth / 2 + eps) intersection() { tex_region2d(); hatch2d(tex_w); }
        translate([0, 0, strap_t - tex_depth]) linear_extrude(tex_depth / 2 + eps) intersection() { tex_region2d(); hatch2d(tex_w / 2); }
    }
}

module envelope() { body(); side_bumps(); front_bump(); strap(1); strap(-1); }
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
module tunnel_block() { hull() { port_core(skin_t, fin_len / 2 + 0.5); port_core(end_t, port_w / 2); } }
// blade from inside the tunnel, through the skin, 1 mm into the cup's end wall: the slot it leaves is 10 x 0.5 with round ends
module port_fin(g = 0) { translate([-(END_X - skin_t - 0.5), 0, PORT_Z]) rotate([0, -90, 0]) linear_extrude(skin_t + 0.5 + fin_out + g) rrect(fin_t + 2 * g, fin_len + 2 * g, fin_t / 2 + g - eps); }
SCREWS = [[-4, 0], [12.5, 0]]; JACKS = [[2, -4.5], [7.5, 4.5]];   // all four inside the window pad (x -7..16.6, y +-8.9) with >= 1 mm margin, so no hole edge is under the lip
screw_d = 3.0; screw_head_d = 6.5; screw_head_h = 3.0; jack_d = 3.3;
module core_part() {
    difference() {
        union() { core_full(); if (port) { tunnel_block(); port_fin(); } }
        for (p = SCREWS) translate([p[0], p[1], TOP - 8]) cylinder(d = screw_d - 0.4, h = 9);
    }
}

// ---- buckle: plate + anchors (cast in) + tang frame, one piece --------------------------------------
// Plan outline of plate + rails + far bar: a rounded ring (outer corners bk_round, window corners bk_fillet), grown by g.
module window2d() { WL = X_FAR - bk_far_t / 2 - X_FACE; translate([X_FACE + WL / 2, 0]) rrect(WL, IW, bk_fillet); }
module frame2d(g = 0) {
    L = X_END - X0;
    offset(delta = g) difference() { translate([X0 + L / 2, 0]) rrect(L, 2 * BK_HW, bk_round); window2d(); }
}
anc_r = 0.6;   // anchors fully rounded (1.6 thick), so they cannot cut the silicone
module anchors(grow = 0) {
    for (s = [-1, 1]) translate([X0 - anc_l - grow, s * (strap_w / 2 - 1.2 - anc_w / 2) - anc_w / 2 - grow, (strap_t - anc_t) / 2 - grow])
        difference() {
            if (grow == 0) minkowski() { translate([anc_r, anc_r, anc_r]) cube([anc_l + 1.0 - 2 * anc_r, anc_w - 2 * anc_r, anc_t - 2 * anc_r]); sphere(r = anc_r, $fn = 16); }
            else cube([anc_l + 1.0 + 2 * grow, anc_w + 2 * grow, anc_t + 2 * grow]);
            if (grow == 0) for (h = [3, 8, 13]) translate([h, anc_w / 2, 0]) {
                translate([0, 0, -1]) cylinder(d = 2.6, h = 10, $fn = 16);
                translate([0, 0, -eps]) cylinder(d1 = 3.4, d2 = 2.6, h = 0.4, $fn = 16);
                translate([0, 0, anc_t - 0.4 + eps]) cylinder(d1 = 2.6, d2 = 3.4, h = 0.4, $fn = 16);
            }
        }
}
module buckle(grow = 0) {
    if (grow == 0) {
        difference() {
            union() {
                intersection() {   // rounded everywhere, but flat on the plate's inner face (x = X0): it seals the strap cavity
                    minkowski() { translate([0, 0, bk_r]) linear_extrude(bk_h - 2 * bk_r) frame2d(-bk_r); sphere(r = bk_r, $fn = 24); }
                    translate([X0, -50, -50]) cube([100, 100, 100]);
                }
                // fill the rounded bottom-inner edge across the strap's width: flat wrist face where the lid clamps the plate
                translate([X0, -(strap_w / 2 + 0.5), 0]) cube([bk_r + eps, strap_w + 1, bk_r + eps]);
            }
            // spring bar: 1.0 mm holes straight through both lugs
            translate([X_BAR, 0, BAR_Z]) rotate([90, 0, 0]) cylinder(d = bar_hole_d, h = 2 * BK_HW + 2, center = true, $fn = 24);
            // scooped, tapered rest for the tongue on the far bar's top
            translate([X_FAR, 0, bk_h - scoop + 0.5 * (arm_w + 7.5) / 2]) scale([1, 1, 0.5]) rotate([0, 90, 0]) cylinder(d = arm_w + 7.5, h = bk_far_t + 2, center = true);   // broad shallow dish: the wide arm clears its sides
        }
        anchors();
    } else {
        translate([0, 0, -grow]) linear_extrude(bk_h + 2 * grow) frame2d(grow);
        anchors(grow);
    }
}
// tongue: full-width sleeve on the spring bar (hides it, centres the arm) + arm that rests in the scoop
module tongue() {
    bore = bar_d + bore_clr; od = bore + 2 * sleeve_wall;
    zc = BAR_Z; zr = bk_h - scoop + arm_t / 2 + 0.3;   // arm centre when resting in the scoop (0.3 clearance)
    difference() {
        union() {
            translate([X_BAR, 0, zc]) rotate([90, 0, 0]) cylinder(d = od, h = IW - 0.4, center = true, $fn = 96);
            xs = [X_BAR, X_BAR + 3.0, X_FAR - 3.5, X_FAR + bk_far_t / 2 + 0.3, X_FAR + bk_far_t / 2 + 2.0];
            zs = [zc, zc, zr, zr, zr + tip_up];
            ws = [arm_w, arm_w, arm_w - 0.3, arm_w - 0.6, arm_w - 1.0];   // 4.5 wide arm, 3.5 at the tip
            for (i = [0 : len(xs) - 2]) hull() {
                translate([xs[i], 0, zs[i]]) rotate([90, 0, 0]) cylinder(d = arm_t, h = ws[i], center = true);
                translate([xs[i + 1], 0, zs[i + 1]]) rotate([90, 0, 0]) cylinder(d = arm_t - (i == len(xs) - 2 ? 0.4 : 0), h = ws[i + 1], center = true);
            }
        }
        translate([X_BAR, 0, zc]) rotate([90, 0, 0]) cylinder(d = bore, h = 40, center = true, $fn = 96);
    }
}
// Temporary FIXED tongue (no spring bar): a block that drops into the frame's window against the plate,
// a saddle that sits on the plate's top and on the rail tops, and a short hooked tongue that stops
// ft_gap short of the far bar. Locked by one ~0.9 mm wire (a paperclip) through lug - block - lug.
// The wire takes the strap pull; the saddle and the block's back face stop it rotating.
ft_gap = 2.5; ft_tip_up = 1.8; ft_pin_d = 1.2; ft_top_t = 1.6; ft_wing_hw = 13.6; ft_block_l = 5.6;
module fixed_tongue() {
    xb1 = X_FACE + ft_block_l; x_tip = X_FAR - bk_far_t / 2 - ft_gap; zt = bk_h + 0.05;
    module block2d(i) { offset(r = 1.0) offset(delta = -1.0) intersection() { offset(delta = -i) window2d(); translate([X_FACE, -50]) square([ft_block_l - (i - 0.2), 100]); } }
    difference() {
        union() {
            hull() {   // block: 0.2 clear of the plate face and the rails, chamfered toward the wrist
                translate([0, 0, 0.3]) linear_extrude(eps) block2d(1.0);
                translate([0, 0, 1.1]) linear_extrude(zt + 0.5 - 1.1) block2d(0.2);
            }
            // saddle: over the plate's top, with two arms lying on the rail tops
            translate([0, 0, zt]) linear_extrude(ft_top_t) offset(r = 0.8) offset(delta = -0.8) union() {
                translate([X0 + 1.2, -ft_wing_hw]) square([xb1 - X0 - 1.2, 2 * ft_wing_hw]);
                for (s = [-1, 1]) translate([xb1 - 1, s > 0 ? IW / 2 + 0.3 : -ft_wing_hw]) square([X_FACE + 9.5 - xb1 + 1, ft_wing_hw - IW / 2 - 0.3]);
            }
            // hooked tongue
            xs = [X_BAR + 0.5, xb1 + 0.6, x_tip - 1.3, x_tip - 1.0];
            zs = [3.2, 3.9, 4.3, 4.3 + ft_tip_up];
            ds = [2.6, 2.6, 2.6, 2.0]; ws = [arm_w, arm_w, arm_w - 0.2, arm_w - 0.7];
            for (i = [0 : 2]) hull() {
                translate([xs[i], 0, zs[i]]) rotate([90, 0, 0]) cylinder(d = ds[i], h = ws[i], center = true);
                translate([xs[i + 1], 0, zs[i + 1]]) rotate([90, 0, 0]) cylinder(d = ds[i + 1], h = ws[i + 1], center = true);
            }
        }
        translate([X_BAR, 0, BAR_Z]) rotate([90, 0, 0]) cylinder(d = ft_pin_d, h = 60, center = true, $fn = 24);   // wire
    }
}
// keeper mold: two ring cavities, open top
module keeper_mold() {
    ow = kp_in_w + 2 * kp_wall; oh = kp_in_h + 2 * kp_wall; floor_t = 3; pitch = ow + 6;
    difference() {
        linear_extrude(floor_t + kp_w) rrect(2 * pitch, oh + 12, 4);
        for (i = [-1, 1]) translate([i * pitch / 2, 0, floor_t]) linear_extrude(kp_w + 1) difference() { rrect(ow, oh, kp_r + kp_wall); rrect(kp_in_w, kp_in_h, kp_r); }
    }
}

// ---- silicone preview ------------------------------------------------------------------------------------
module band() {
    difference() {
        envelope();
        core_full(); if (port) { tunnel_block(); port_fin(); }
        translate([(WIN[0][0] + WIN[0][1]) / 2, 0, TOP - 1]) linear_extrude(3) rrect(WIN[0][1] - WIN[0][0], WIN[1][1] - WIN[1][0], WIN_R);
        buckle(); holes(); lid_ridge(); texture();
    }
}

// ---- mold ---------------------------------------------------------------------------------------------------
margin = 6; cup_floor = 4;
CUP_H = TOP + FRONT_BUMP + cup_floor;
LID_T = 3.0; RIDGE_OVER = 0.15; REBATE_D = 0.9;
seat_wall = 1.5;        // cup wall outside the plate that takes the pour pressure (between the rail-root fillets only)
POCKET_Z = bk_h + 1.5;  // frame pocket depth: nothing touches the frame
VENTS = [[-8, 0, 2.5], [8, 0, 2.5], [-18, 8, 2.0], [-18, -8, 2.0], [18, 8, 2.0], [18, -8, 2.0],
         [END_X + 14, 0, 2.0], [END_X + 30, 0, 2.0],
         [-(END_X + 18), 0, 2.0], [-(END_X + 42), 0, 2.0], [-(END_X + 66), 0, 2.0], [-(END_X + 90), 0, 2.0], [-(END_X + long_len - 12), 0, 2.0]];
module footprint2d(o) { offset(r = o) outline2d(); }
module block(z0, h) { translate([0, 0, z0]) linear_extrude(h) offset(r = margin) outline2d(); }
module lid_ridge() { difference() { lid_ridge_full(); translate([X0 - 1.0, -(strap_w / 2 + 1), -1]) cube([bk_plate_t + 2, strap_w + 2, 3]); } }   // no ridge across the strap's end: the plate is there
module lid_ridge_full() {
    steps = 6;
    for (i = [0 : steps - 1]) {
        h0 = back_r * i / steps; h1 = back_r * (i + 1) / steps;
        inset = back_r - sqrt(back_r * back_r - (back_r - h0) * (back_r - h0));
        translate([0, 0, h0 - eps]) linear_extrude(h1 - h0 + 2 * eps) difference() { footprint2d(RIDGE_OVER); footprint2d(-inset); }
    }
}
module cup() { cup_plain(); texture(); }   // texture ridges stand on the strap troughs' floor
module cup_plain() {
    difference() {
        block(0, CUP_H);
        envelope();
        translate([0, 0, -1]) linear_extrude(1 + REBATE_D) footprint2d(RIDGE_OVER + 0.1);   // rebate for the lid ridge
        // channel in the end wall for the port blade: open from the rim so the core drops in; the silicone tab it casts above the blade is cut off flush
        if (port) translate([-(END_X + fin_out + 0.05), -(fin_len / 2 + 0.05), -1]) cube([fin_out + 0.05 + 0.5, fin_len + 0.1, 1 + PORT_Z + fin_t / 2 + 0.05]);
        intersection() { buckle(0.2); translate([X0, -50, -50]) cube([100, 100, 100]); }   // seat: plate slot flush with the strap's end, 0.2 in front; anchors are in the trough
        // open pocket for the frame beyond a seat wall that exists only between the rail-root fillets,
        // plus the regions beside the plate's wings where the rails root
        translate([X_FACE + 0.2 + seat_wall, -BK_HW - 2, -1]) cube([X_END - X_FACE + 4, 2 * BK_HW + 4, 1 + POCKET_Z]);
        for (s = [-1, 1]) translate([X0, s > 0 ? IW / 2 - bk_fillet - 0.1 : -(BK_HW + 2), -1]) cube([bk_plate_t + 0.2 + seat_wall + 0.2, BK_HW + 2 - (IW / 2 - bk_fillet - 0.1), 1 + POCKET_Z]);
        for (p = SCREWS) translate([p[0], p[1], 0]) { translate([0, 0, TOP - 1]) cylinder(d = screw_d + 0.4, h = 20); translate([0, 0, CUP_H - screw_head_h]) cylinder(d = screw_head_d, h = screw_head_h + 1); }
        for (p = JACKS) translate([p[0], p[1], TOP - 1]) cylinder(d = jack_d, h = 20);
        for (i = [0 : hole_count - 1]) translate([-(END_X + hole_s(i)), 0, strap_t - eps]) slot(hole_x + 0.6, hole_y + 0.6, 0.6);   // recesses under the pins
    }
}
module lid() {
    difference() {
        union() {
            translate([0, 0, -LID_T]) linear_extrude(LID_T) offset(r = margin) outline2d();
            lid_ridge();
            translate([X0 - 0.5, -(strap_w / 2 - 0.2), -eps]) cube([bk_plate_t + 0.7, strap_w - 0.4, 0.2 + eps]);   // 0.2 clamp step: presses the plate onto its seat floor
            for (i = [0 : hole_count - 1]) translate([-(END_X + hole_s(i)), 0, -eps]) slot(hole_x, hole_y, strap_t + 0.5);   // pins
        }
        for (v = VENTS) translate([v[0], v[1], -LID_T - 1]) cylinder(d = v[2], h = LID_T + 2);
        translate([X_FACE + 0.3, -BK_HW - 2.5, -LID_T - 1]) cube([X_END - X_FACE + 3.5, 2 * BK_HW + 5, LID_T + 2]);   // window over the frame
        for (s = [-1, 1]) translate([X0 - 0.7, s > 0 ? strap_w / 2 + 0.3 : -(BK_HW + 2.5), -LID_T - 1]) cube([bk_plate_t + 1.0, BK_HW + 2.5 - (strap_w / 2 + 0.3), LID_T + 2]);   // clear the plate's wings
    }
}

// ---- exports ----------------------------------------------------------------------------------------------------
if (part == "buckle")      translate([0, 0, BK_HW]) rotate([90, 0, 0]) translate([-X0 - 6, 0, 0]) buckle();          // on its side: bar holes vertical
else if (part == "tongue") translate([0, 0, (IW - 0.4) / 2]) rotate([90, 0, 0]) translate([-X_BAR, 0, -BAR_Z]) tongue();   // sleeve standing
else if (part == "keeper_mold") keeper_mold();
else if (part == "fixed_tongue") translate([0, 0, ft_wing_hw]) rotate([90, 0, 0]) translate([-X_FACE, 0, 0]) fixed_tongue();   // standing: wire hole vertical
else if (part == "check_fixed") intersection() { fixed_tongue(); buckle(); }
else if (part == "fixed_assy") { buckle(); fixed_tongue(); }
else if (part == "core")   translate([0, 0, -Z0]) core_part();
else if (part == "cup")    translate([0, 0, CUP_H]) rotate([180, 0, 0]) cup();
else if (part == "lid")    translate([0, 0, LID_T]) lid();
else if (part == "buckle_assy") { buckle(); tongue(); }
else if (part == "check_core")   intersection() { core_part(); cup(); }
else if (part == "check_buckle") intersection() { buckle(); union() { cup(); core_part(); } }
else if (part == "check_tongue") intersection() { tongue(); buckle(); }
else if (part == "check_lid")    intersection() { lid(); union() { cup(); buckle(); core_part(); } }
else band();
