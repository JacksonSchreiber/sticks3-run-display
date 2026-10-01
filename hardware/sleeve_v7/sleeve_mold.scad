// Sleeve v7: one-piece silicone band + sealed jacket for the M5Stack StickS3, shaped like a Tropic
// strap so it takes a real metal Tropic buckle (18 mm between its lugs) on that buckle's own thin
// spring bar (21 mm tip to tip, ~1.4 mm body). Nothing printed stays in the band: no cast-in plate,
// no printed buckle or tongue.
//
// Short strap (70 mm): flares off the jacket, tapers to 17.6 mm, and thickens to 4.5 mm at its end,
// where a hole for the spring bar is cast across it and a 2 mm slot through the middle lets the
// buckle's tongue sit on the bar and swing. Long strap: flares off the jacket to 21.5 mm, one slow
// eased taper to 16 mm, then a quicker taper over the last 18 mm to a squared-off 12 mm tip; nine
// round 2 mm holes. Both straps keep the thin 2 mm hinge at the jacket. The outer faces carry a
// recessed panel of diamond knurl inside a clean 0.7 mm raised outline.
//
// Parts (set `part`, or use the Customizer), all PLA:
//   "core"        0.16 mm, as exported (back face down), supports on build plate only (port blade).
//   "cup"         one long open-top mold, 0.2 mm layers. Print DIAGONALLY on the 220 mm bed, brim.
//   "lid"         required: forms the wrist face, the fillet ridge, the hole pins, vents. Diagonally.
//   "keeper_mold" two ring cavities for the strap keepers.
//   "band"        preview of the finished silicone part (don't print).
// You also need one 1.5 mm steel pin about 45 mm long (a 1.5 mm drill bit): it casts the bar hole.
//
// Coordinates: x along the band (short strap toward +x, long strap toward -x), y across,
// z from the wrist face (0) toward the front. The cup's rim is z = 0.
//
// Casting (open pour, window face down), Smooth-Sil 950, 100A : 10B by weight:
//   1. Release on everything. Core on the cup floor, pad down, port blade into its channel, two
//      M3x8 up through the cup. Push the 1.5 mm pin through the hole in one cup wall at the short
//      strap's end, through the rib, and out through the other wall.
//   2. Mix 44 g A + 4.4 g B (pigment into A first). Degas if you can. Syringe the lip layer, the
//      front-button pocket and the thick strap end around the pin, then pour along the whole length
//      to just above the rim. Tap.
//   3. Lid on, one end first, press down onto the rim. Excess bleeds from the vents.
//   4. Cure 18 h at room temperature, or about 6 h at 45 C. Fill the keeper mold from the same mix.
//   5. Pull the pin out sideways FIRST. Lid off, M3 screws out, card down the jacket's long sides,
//      M4 screws into the jack holes until the core and band rise. Peel the straps out, lift the
//      top end of the core out of the window and slide it toward the top end (the port blade draws
//      out of its slot). Trim the vent nubs and the port tab.
//   6. Keepers over the short strap's end. Buckle: tongue into the 2 mm slot, spring bar through
//      the strap and the tongue's loop, tips into the buckle's lugs.

/* [Part] */
part = "band"; // [core, cup, lid, keeper_mold, band]

/* [Fit] */
squeeze = 0.0;          // pocket = Stick size; the silicone on every face grips it
size_min = 175;         // wrist circumference on the hole nearest the jacket; each hole adds hole_pitch
hole_count = 9; hole_pitch = 5;
hole_d = 2.0;           // on the outer face (the Tropic tongue is 1.8 mm at its tip)
hole_d_wrist = 3.0;     // the hole widens toward the wrist: a tapered pin survives demolding, a 2 mm one snaps

/* [Jacket] */
wall = 2.8; end_t = 2.2; lip_t = 1.4; back_t = 1.7; side_bump = 0.5; front_min = 1.4;
body_r = 2.0;           // plan corner radius
front_r = 2.5;          // round on the front perimeter
back_r = 0.8;           // round on the wrist-side edge (lid ridge)
pad_rim_w = 0.6; pad_rim_h = 0.3;   // pinch-off rim round the window pad's face: seals on the cup floor, flash parts at the window edge

/* [Straps] */
strap_t = 3.0;
edge_r = 0.6;           // outer-face edge radius (small, so the outline reads crisp)
hinge_t = 2.0;          // thickness at the jacket: a thin, wide hinge so the band bends right at the sleeve
hinge_len = 6; root_len = 12;   // hinge for this far, blended up to strap_t by root_len
root_t = hinge_t;
fillet_r = 2.0;         // fillet between the hinge top and the end wall
flare_len = 15;         // jacket width -> base_w over this length
base_w = 21.5;
short_len = 70;
short_end_w = 17.6;     // fits the 18 mm buckle
bk_end_t = 4.5;         // thickness at the spring bar
end_ramp = 12;          // strap_t -> bk_end_t over this length before the bar
short_corner_r = 1.5;
buckle_w = 18;          // the long strap is this wide or narrower wherever it sits in the buckle
buckle_reach = 14;      // ... which starts this far toward the jacket from the hole in use
mid_w = 16;             // long strap: end of the slow taper
tip_w = 12; tip_len = 18;   // long strap: quicker taper over the last tip_len to a squared-off tip
tip_corner_r = 1.0;
tail = 25;              // long strap beyond the last hole

/* [Buckle end] */
bar_pin_d = 1.5;        // the steel pin that casts the spring-bar hole
bar_pin_hole = 1.7;     // its holes through the cup walls and the rib
tongue_slot_w = 2.0;    // slot through the strap end for the buckle's tongue
tongue_slot_past = 2.5; // how far the slot runs past the bar

/* [Outline and texture] */
rim_w = 0.7;            // raised outline round each strap's outer face
panel_d = 0.35;         // the panel inside it is recessed this much
texture = true;         // diamond knurl in the panel
tex_pitch = 2.2; tex_angle = 35; tex_depth = 0.4; tex_w = 0.8;
tex_hole_margin = 1.5;  // smooth lane round the hole row

/* [Keeper] */
kp_in_w = 19.5; kp_in_h = 6.2; kp_wall = 2.0; kp_w = 5.0; kp_r = 1.5;

/* [Charging port] */
port = true; port_w = 14.0; port_h = 7.5; port_from_face = 4.1; skin_t = 1.5;
fin_t = 0.5; fin_len = 10.0; fin_out = 1.0;   // 0.5 mm blade on the core casts the port slot through the skin

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

// ---- strap layout (s = distance from the jacket's end face along the strap) --------------------
function smooth(u) = let(v = min(max(u, 0), 1)) v * v * (3 - 2 * v);
function hole_s(i) = size_min - 2 * END_X - short_len + i * hole_pitch;   // from the jacket's -x end; the tongue sits at the short strap's end
long_len = hole_s(hole_count - 1) + tail;
X_SE = END_X + short_len;                 // short strap's end
S_BAR = short_len - bk_end_t / 2;         // spring bar axis, along the short strap
X_BAR = END_X + S_BAR; BAR_Z = bk_end_t / 2;
ZP = strap_t - panel_d;                   // panel level
// slow taper of the long strap: an eased curve from base_w to mid_w that is already down to
// buckle_w where the strap first sits in the buckle (buckle_reach before the first hole)
S_SLOW = long_len - tip_len;
taper_p = ln((buckle_w - mid_w) / (base_w - mid_w)) / ln(1 - (hole_s(0) - buckle_reach - flare_len) / (S_SLOW - flare_len));
function w_flare(s) = base_w + (2 * BODY_HW - base_w) * (1 - smooth(s / flare_len));
function corner_cut(s, L, r) = s > L - r ? 2 * (r - sqrt(max(r * r - (s - (L - r)) * (s - (L - r)), 0))) : 0;   // plan corner radius at a squared end
function w_long(s) = let(c = min(max(s, 0), long_len))
    (c < flare_len ? w_flare(c)
     : c <= S_SLOW ? mid_w + (base_w - mid_w) * pow(1 - (c - flare_len) / (S_SLOW - flare_len), taper_p)
     : mid_w + (tip_w - mid_w) * (c - S_SLOW) / tip_len) - corner_cut(c, long_len, tip_corner_r);
function w_short(s) = let(c = min(max(s, 0), short_len))
    (c < flare_len ? w_flare(c) : base_w + (short_end_w - base_w) * (c - flare_len) / (short_len - flare_len)) - corner_cut(c, short_len, short_corner_r);
function t_base(s) = hinge_t + (strap_t - hinge_t) * smooth((s - hinge_len) / (root_len - hinge_len));
function t_long(s) = t_base(max(s, 0));
function t_short(s) = let(c = min(max(s, 0), short_len))
    c <= S_BAR - end_ramp ? t_base(c)
    : c <= S_BAR ? strap_t + (bk_end_t - strap_t) * smooth((c - (S_BAR - end_ramp)) / end_ramp)
    : bk_end_t / 2 + sqrt(max(bk_end_t * bk_end_t / 4 - (c - S_BAR) * (c - S_BAR), 0));   // quarter-round over the bar
function w_of(dir, s) = dir > 0 ? w_short(s) : w_long(s);
function t_of(dir, s) = dir > 0 ? t_short(s) : t_long(s);
S_START = -body_r - 0.5;                  // the strap starts inside the jacket so the root fills the plan corners
function s_list(L, r, n) = concat([for (k = [0 : n]) S_START + (L - r - S_START) * k / n], [for (a = [10 : 10 : 90]) L - r + r * sin(a)]);
echo(str("v7: jacket ", 2 * END_X, " x ", 2 * BODY_HW, " x ", TOP, " (+", FRONT_BUMP, "); short strap ", short_len, ", long strap ", long_len,
         ", overall ", 2 * END_X + short_len + long_len, " mm; sizes ", [for (i = [0 : hole_count - 1]) size_min + i * hole_pitch],
         "; taper exponent ", taper_p, "; long strap width at holes ", [for (i = [0 : hole_count - 1]) round(w_long(hole_s(i)) * 10) / 10],
         ", at buckle reach ", w_long(hole_s(0) - buckle_reach)));

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
module xsec(x, w, t) { translate([x, 0, 0]) rotate([90, 0, 90]) linear_extrude(eps) translate([0, t / 2]) rrect(max(w, 0.4), t, min(edge_r, t / 2 - eps, max(w, 0.4) / 2 - eps)); }
module strap(dir) {   // dir = +1 short, -1 long
    L = dir > 0 ? short_len : long_len;
    S = dir > 0 ? s_list(L, bk_end_t / 2, 70) : s_list(L, tip_corner_r, 110);
    for (k = [0 : len(S) - 2])
        hull() { xsec(dir * (END_X + S[k]), w_of(dir, S[k]), t_of(dir, S[k])); xsec(dir * (END_X + S[k + 1]), w_of(dir, S[k + 1]), t_of(dir, S[k + 1])); }
    // gusset fillet between the strap's top and the jacket's end wall
    translate([dir * END_X, 0, 0]) mirror([dir < 0 ? 1 : 0, 0, 0]) rotate([90, 0, 0]) linear_extrude(2 * BODY_HW - 2 * body_r - 1, center = true)
        difference() { translate([-eps, root_t - eps]) square([fillet_r + eps, fillet_r + eps]); translate([fillet_r, root_t + fillet_r]) circle(r = fillet_r); }
}
// plan outline of a strap between sa and sb
module strap_plan2d(dir, sa, sb) {
    n = ceil((sb - sa) / 0.5);
    S = [for (k = [0 : n]) sa + (sb - sa) * k / n];
    polygon(concat([for (s = S) [dir * (END_X + s), w_of(dir, s) / 2]], [for (k = [n : -1 : 0]) [dir * (END_X + S[k]), -w_of(dir, S[k]) / 2]]));
}

// ---- holes: round, hole_d on the outer face, widening to hole_d_wrist on the wrist face ------------
module hole_pin() {
    cylinder(d1 = hole_d_wrist, d2 = hole_d, h = ZP + eps, $fn = 32);
    translate([0, 0, ZP]) cylinder(d = hole_d, h = panel_d + 0.6, $fn = 32);
}
module holes() { for (i = [0 : hole_count - 1]) translate([-(END_X + hole_s(i)), 0, -eps]) hole_pin(); }

// ---- buckle end: tongue slot rib and spring-bar pin ---------------------------------------------------
// plan of the 2 mm slot: from tongue_slot_past beyond the bar, out through the strap's end (and 1 mm into the cup's end wall)
module tongue_slot2d(g = 0) {
    x0 = X_BAR - tongue_slot_past;
    offset(delta = g) hull() { translate([x0 + tongue_slot_w / 2, 0]) circle(d = tongue_slot_w, $fn = 24); translate([X_SE, -tongue_slot_w / 2]) square([1.0, tongue_slot_w]); }
}
module tongue_rib(g = 0) { translate([0, 0, -g]) linear_extrude(bk_end_t + 1.0 + g) tongue_slot2d(g); }   // rim to below the trough floor
module bar_pin(d) { translate([X_BAR, 0, BAR_Z]) rotate([90, 0, 0]) cylinder(d = d, h = 80, center = true, $fn = 24); }

// ---- outline + texture on the outer faces -----------------------------------------------------------------
// The panel is the strap's plan inset by the edge radius plus the 0.7 mm outline; it is recessed panel_d,
// and the diamond grooves are cut into it. In the cup the panel is a plateau and the grooves are ridges.
S_PANEL0 = root_len + 1;                 // past the hinge
module panel2d() {
    offset(delta = -(edge_r + rim_w)) strap_plan2d(-1, S_PANEL0, long_len);
    offset(delta = -(edge_r + rim_w)) strap_plan2d(1, S_PANEL0, S_BAR - end_ramp);
}
module hatch2d(w) { for (a = [tex_angle, -tex_angle]) rotate(a) for (k = [-48 : 48]) translate([0, k * tex_pitch]) square([440, w], center = true); }
module tex_region2d() {
    difference() {
        panel2d();
        hull() for (i = [0, hole_count - 1]) translate([-(END_X + hole_s(i)), 0]) circle(d = hole_d + 2 * tex_hole_margin);   // smooth lane round the holes
    }
}
module panel() { translate([0, 0, ZP]) linear_extrude(panel_d + eps) panel2d(); }
module texture() {   // two steps, so the groove is tapered rather than square-cornered
    if (texture) {
        translate([0, 0, ZP - tex_depth / 2]) linear_extrude(tex_depth / 2 + eps) intersection() { tex_region2d(); hatch2d(tex_w); }
        translate([0, 0, ZP - tex_depth]) linear_extrude(tex_depth / 2 + eps) intersection() { tex_region2d(); hatch2d(tex_w / 2); }
    }
}

module envelope() { body(); side_bumps(); front_bump(); strap(1); strap(-1); }
module outline2d() { projection() envelope(); }

// ---- core ------------------------------------------------------------------------------------------
module win2d(i = 0) { translate([(WIN[0][0] + WIN[0][1]) / 2, 0]) offset(delta = -i) rrect(WIN[0][1] - WIN[0][0], WIN[1][1] - WIN[1][0], WIN_R); }
module core_full() {
    translate([0, 0, Z0]) linear_extrude(CORE_T) rrect(CORE_L, CORE_W, CORE_R);
    // window pad: its face is relieved pad_rim_h except for a narrow rim at the edge, which is what touches the cup floor
    difference() {
        translate([0, 0, Z1 - eps]) linear_extrude(TOP - Z1 + eps) win2d();
        translate([0, 0, TOP - pad_rim_h]) linear_extrude(pad_rim_h + 1) win2d(pad_rim_w);
    }
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
module port_fin(g = 0) { translate([-(END_X - skin_t - 0.5), 0, PORT_Z]) rotate([0, -90, 0]) linear_extrude(skin_t + 0.5 + fin_out + g) rrect(fin_t + 2 * g, fin_len + 2 * g, fin_t / 2 + g - eps); }
SCREWS = [[-4, 0], [12.5, 0]]; JACKS = [[2, -4.5], [7.5, 4.5]];   // all inside the window pad
screw_d = 3.0; screw_head_d = 6.5; screw_head_h = 3.0; jack_d = 3.3;
module core_part() {
    difference() {
        union() { core_full(); if (port) { tunnel_block(); port_fin(); } }
        for (p = SCREWS) translate([p[0], p[1], TOP - 8]) cylinder(d = screw_d - 0.4, h = 9);
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
module window_through() { translate([0, 0, TOP - 1.5]) linear_extrude(4) win2d(); }
module band() {
    difference() {
        envelope();
        core_full(); if (port) { tunnel_block(); port_fin(); }
        window_through();
        holes(); lid_ridge(); panel(); texture(); tongue_rib(); bar_pin(bar_pin_d);
    }
}

// ---- mold ---------------------------------------------------------------------------------------------------
margin = 6; cup_floor = 4;
CUP_H = TOP + FRONT_BUMP + cup_floor;
LID_T = 3.0; RIDGE_OVER = 0.15; REBATE_D = 0.9;
// vents: [x, y, d]. Along the long strap they sit off the centreline, clear of the hole pins.
VENTS = [[-8, 0, 2.5], [8, 0, 2.5], [-18, 8, 2.0], [-18, -8, 2.0], [18, 8, 2.0], [18, -8, 2.0],
         [END_X + 16, 0, 2.0], [END_X + 36, 0, 2.0], [END_X + 54, 0, 2.0], [END_X + S_BAR - 2, 5, 2.0], [END_X + S_BAR - 2, -5, 2.0],
         [-(END_X + 18), 0, 2.0], [-(END_X + 40), 0, 2.0], [-(END_X + hole_s(2) + 2.5), 5, 2.0], [-(END_X + hole_s(5) + 2.5), -5, 2.0],
         [-(END_X + hole_s(hole_count - 1) + 9), 0, 2.0], [-(END_X + long_len - 4), 0, 2.0]];
module footprint2d(o) { offset(r = o) outline2d(); }
module block(z0, h) { translate([0, 0, z0]) linear_extrude(h) offset(r = margin) outline2d(); }
module lid_ridge() { difference() { lid_ridge_full(); tongue_rib(0.2); } }   // gap where the tongue-slot rib reaches the rim
module lid_ridge_full() {
    steps = 6;
    for (i = [0 : steps - 1]) {
        h0 = back_r * i / steps; h1 = back_r * (i + 1) / steps;
        inset = back_r - sqrt(back_r * back_r - (back_r - h0) * (back_r - h0));
        translate([0, 0, h0 - eps]) linear_extrude(h1 - h0 + 2 * eps) difference() { footprint2d(RIDGE_OVER); footprint2d(-inset); }
    }
}
module cup_plain() {
    difference() {
        block(0, CUP_H);
        envelope();
        translate([0, 0, -1]) linear_extrude(1 + REBATE_D) footprint2d(RIDGE_OVER + 0.1);   // rebate for the lid ridge
        // channel in the end wall for the port blade: open from the rim so the core drops in; the tab it casts above the blade is cut off
        if (port) translate([-(END_X + fin_out + 0.05), -(fin_len / 2 + 0.05), -1]) cube([fin_out + 0.05 + 0.5, fin_len + 0.1, 1 + PORT_Z + fin_t / 2 + 0.05]);
        for (p = SCREWS) translate([p[0], p[1], 0]) { translate([0, 0, TOP - 1]) cylinder(d = screw_d + 0.4, h = 20); translate([0, 0, CUP_H - screw_head_h]) cylinder(d = screw_head_d, h = screw_head_h + 1); }
        for (p = JACKS) translate([p[0], p[1], TOP - 1]) cylinder(d = jack_d, h = 20);
    }
}
module cup() {
    difference() {
        union() { cup_plain(); tongue_rib(); panel(); texture(); }   // rib for the tongue slot; panel plateau and knurl ridges on the trough floors
        for (i = [0 : hole_count - 1]) translate([-(END_X + hole_s(i)), 0, ZP - eps]) cylinder(d = hole_d + 0.3, h = panel_d + 0.8, $fn = 32);   // sockets for the hole pins' tips
        bar_pin(bar_pin_hole);   // through both walls and the rib
    }
}
module lid() {
    difference() {
        union() {
            translate([0, 0, -LID_T]) linear_extrude(LID_T) offset(r = margin) outline2d();
            lid_ridge();
            holes();   // tapered pins
        }
        for (v = VENTS) translate([v[0], v[1], -LID_T - 1]) cylinder(d = v[2], h = LID_T + 2);
    }
}

// ---- exports ----------------------------------------------------------------------------------------------------
if (part == "core")             translate([0, 0, -Z0]) core_part();
else if (part == "cup")         translate([0, 0, CUP_H]) rotate([180, 0, 0]) cup();
else if (part == "lid")         translate([0, 0, LID_T]) lid();
else if (part == "keeper_mold") keeper_mold();
else if (part == "check_core")  intersection() { core_part(); cup(); }
else if (part == "check_lid")   intersection() { lid(); union() { cup(); core_part(); } }
else if (part == "check_pin")   intersection() { bar_pin(bar_pin_d); cup(); }
else band();
