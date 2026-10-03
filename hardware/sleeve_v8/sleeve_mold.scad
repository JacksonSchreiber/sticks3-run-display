// Sleeve v8: one-piece silicone band + sealed jacket for the M5Stack StickS3, shaped like a Tropic
// strap so it takes a real metal Tropic buckle (18 mm between its lugs) on that buckle's own thin
// spring bar (21 mm tip to tip, ~1.4 mm body). Nothing printed stays in the band: no cast-in plate,
// no printed buckle or tongue.
//
// Short strap (70 mm): flares off the jacket, tapers to 17.6 mm, and thickens to 4.5 mm at its end,
// where a hole for the spring bar is cast across it and a 2 mm slot through the middle lets the
// buckle's tongue sit on the bar and swing. Long strap: flares off the jacket to 21.5 mm, one slow
// eased taper to 16 mm, then a quicker taper over the last 18 mm to a squared-off 12 mm tip; nine
// Tropic-style perforation on BOTH straps: a centre column of 2 mm holes at 5 mm pitch plus two side
// columns staggered half a step, 3 mm in from the edges, the whole length; every hole sits in a shallow
// diamond on the wrist face; the tongue uses the centre column. Both straps keep the thin 2 mm hinge at
// the jacket. The outer faces carry a smooth recessed panel inside a clean 0.7 mm raised outline (the
// v7 knurl was an air trap and is off). v8 also adds breather holes through the cup floor at the
// button recess and round the window lips, and twice the lid vents, after two casts with craters.
//
// Parts (set `part`, or use the Customizer), all PLA:
//   "core"        0.16 mm, as exported (back face down), supports on build plate only (port blade).
//   "cup"         one long open-top mold, 0.2 mm layers. Print DIAGONALLY on the 220 mm bed, brim.
//   "lid"         required: forms the wrist face, the fillet ridge, the hole pins, vents. Diagonally.
//   "keeper_mold" two ring cavities for the strap keepers.
//   "band"        preview of the finished silicone part (don't print).
//   "pin"         three printed pins (two spares), 0.16 mm, as exported. One lies across the cup at the
//                 short strap's end and casts the spring-bar hole; its handle fills a notch in the wall.
//
// Coordinates: x along the band (short strap toward +x, long strap toward -x), y across,
// z from the wrist face (0) toward the front. The cup's rim is z = 0.
//
// Casting (open pour, window face down), Smooth-Sil 950, 100A : 10B by weight:
//   1. Release on everything. Core on the cup floor, pad down, port blade down its relief in the end wall, two
//      M3x8 up through the cup. Lay the pin across the short strap's end: handle into the wide
//      notch, rod into the rib's seat and the narrow notch in the far wall.
//   2. Mix 45.5 g A + 4.5 g B (pigment into A first). Degas if you can. BRUSH a thin coat over the
//      whole cup floor, the button recess, the strap troughs and round the core's pad (this is what
//      stops the craters), then pour in a thin stream at ONE end so the front advances along the cup.
//   3. Tap the cup and leave it 10-15 min so bubbles rise and pop. Then the lid, one end first,
//      pressed down onto the rim. Excess bleeds from the vents; a bead weeps from the breather holes
//      under the cup, so stand it on parchment.
//   4. Cure 18 h at room temperature, or about 6 h at 45 C. Fill the keeper mold from the same mix.
//   5. Lid off, then pull the pin out sideways by its handle. M3 screws out, card down the jacket's long sides,
//      M4 screws into the jack holes until the core and band rise. Peel the straps out, lift the
//      top end of the core out of the window and slide it toward the top end (the port blade draws
//      out of its slot). Trim the vent nubs; wipe any film off the port slot's mouth.
//   6. Keepers over the short strap's end. Buckle: tongue into the 2 mm slot, spring bar through
//      the strap and the tongue's loop, tips into the buckle's lugs.

/* [Part] */
part = "band"; // [core, cup, lid, pin, keeper_mold, band]

/* [Fit] */
squeeze = 0.0;          // pocket = Stick size; the silicone on every face grips it
size_min = 175;         // wrist circumference on the hole nearest the jacket; each hole adds hole_pitch
hole_pitch = 5;         // centre column pitch along the strap (tongue holes)
side_y = 4.0;           // side columns this far off centre (fixed, like the Tropic), staggered half a pitch; they stop where the strap gets too narrow
side_min_edge = 2.5;    // ... i.e. where less than this is left between a side hole and the strap's edge
hole_d = 2.0;           // on the outer face (the Tropic tongue is 1.8 mm at its tip)
pyr_w = 3.0; pyr_d = 0.3;   // on the wrist face each hole sits in a shallow diamond pyramid, Tropic style: diagonal, depth (hole_pitch - pyr_w = 1.8 mm of full-thickness strap between tips)
pyr_r = 0.6;            // the diamond's corners are rounded this much, so the pyramid's inside creases are smooth curves, not sharp valleys
hole_d_root = 2.2;      // the pin is this wide where it leaves the pyramid and tapers to hole_d (a straight 2 mm pin snaps)

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
bar_pin_w = 1.5;        // diameter of the printed pin that casts the spring-bar hole (the bar is ~1.4 mm)
rod_flat = 0.6;         // the rod is round with one small flat this far from its axis, so it prints lying on the bed
pin_clr = 0.1;          // clearance of the pin and its handle in their notches
handle_w = 4.0;         // the pin's handle fills a notch in one cup wall, flush with the rim
handle_grip = 5.0;      // ... and sticks out this far to pull on
grip_shoulder = 2.0;    // the grip is this much wider than the notch on each side
tongue_slot_w = 2.0;    // slot through the strap end for the buckle's tongue
tongue_slot_past = 2.5; // how far the slot runs past the bar

/* [Outline and texture] */
rim_w = 0.7;            // raised outline round each strap's outer face
panel_d = 0.35;         // the panel inside it is recessed this much
texture = true;         // diamond knurl in the panel
tex_mode = "tropic";    // [tropic, ridge, dimple] tropic: big diamond pits tiling the outer face, one hole at the centre of every pit in the three columns (self-venting in the cup). ridge: grooves in the silicone, raised diamonds (closed cells on the cup floor: brush a print coat). dimple: diamonds sunk into the silicone as shallow pyramids with a raised lattice between (the cup has bumps with connected channels: self-venting)
tex_channel = 0.6;      // dimple mode: width of the raised lattice between dimples, at the surface
tr_ridge = 0.7;         // tropic mode: width of the raised lattice between pits, at the surface
tr_depth = 0.6;         // tropic mode: pit depth
tr_run = 1.2;           // tropic mode: how far the pit's faces run inward over that depth (slope about 27 deg)
tex_pitch = 2.4; tex_angle = 35; tex_depth = 0.55; tex_w = 0.9;   // v8: deeper and a touch larger
node_gap = 0;           // > 0 cuts the cup's ridges at every crossing so the cells vent into each other (tried at 1.8: diamonds this small turn into dashes). 0 = closed diamonds; brush a print coat into them before pouring
tex_hole_margin = 0.5;  // ridge/dimple modes: smooth collar round every hole (tropic mode: the hole sits in the pit's floor, no collar)
breather_d = 0.6;       // breather holes through the cup floor at the dead-end pockets (button recess, window lips)

/* [Sleeve texture] */
front_tex = true;       // raised diamond lattice on the sleeve's front face round the window: ridges on the silicone = grooves in the cup floor, a connected channel network from the window pad's edge out to the walls (self-venting, like the straps). Adds nothing but material: the lips stay 1.4 mm.
ft_w = 0.6; ft_h = 0.4; ft_pitch = 2.0; ft_angle = 35;   // ridge width, height, line spacing, angle
ft_keep = 0.6;          // flat margin round the window pad (its rim must seat on bare floor) and the button bump

/* [Keeper] */
kp_in_w = 19.5; kp_in_h = 6.2; kp_wall = 2.0; kp_w = 5.0; kp_r = 1.5;

/* [Charging port] */
port = true; port_w = 14.0; port_h = 7.5; port_from_face = 4.1; skin_t = 1.5;
fin_t = 0.5; fin_len = 10.0;   // 0.5 mm blade on the core casts the port slot through the skin
pad_h = 0.5; pad_m = 1.8;      // raised border round the slot on the outside: this proud, this far beyond the slot, edges rounded

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
function hole_s(i) = size_min - 2 * END_X - short_len + i * hole_pitch;   // the former 9-size row; row 0 anchors the pattern
long_len = hole_s(8) + tail;
X_SE = END_X + short_len;                 // short strap's end
S_BAR = short_len - bk_end_t / 2;         // spring bar axis, along the short strap
X_BAR = END_X + S_BAR; BAR_Z = bk_end_t / 2;
ZP = strap_t - panel_d;                   // panel level
// slow taper of the long strap: an eased curve from base_w to mid_w that is already down to
// buckle_w where the strap first sits in the buckle (buckle_reach before the first hole)
S_SLOW = long_len - tip_len;
taper_p = ln((buckle_w - mid_w) / (base_w - mid_w)) / ln(1 - (hole_s(0) - buckle_reach - flare_len) / (S_SLOW - flare_len));
// perforation: centre rows every hole_pitch from just past the flare to 5 mm from the tip (long) or the thick end (short);
// side holes half a pitch on, side_edge in from the edge (so the columns taper with the strap)
S_H0 = hole_s(0) - 7 * hole_pitch;
LONG_END = long_len - 5; SHORT_END = S_BAR - end_ramp - 2;
LONG_ROWS = [for (k = [0 : 60]) if (S_H0 + k * hole_pitch <= LONG_END) S_H0 + k * hole_pitch];
SHORT_ROWS = [for (k = [0 : 60]) if (S_H0 + k * hole_pitch <= SHORT_END) S_H0 + k * hole_pitch];
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
function side_ok(dir, s) = w_of(dir, s) / 2 - side_y - hole_d / 2 >= side_min_edge;
HOLES = concat(
    [for (s = LONG_ROWS) [-(END_X + s), 0]],
    [for (s = LONG_ROWS) if (s + hole_pitch / 2 <= LONG_END && side_ok(-1, s + hole_pitch / 2)) for (sg = [-1, 1]) [-(END_X + s + hole_pitch / 2), sg * side_y]],
    [for (s = SHORT_ROWS) [END_X + s, 0]],
    [for (s = SHORT_ROWS) if (s + hole_pitch / 2 <= SHORT_END && side_ok(1, s + hole_pitch / 2)) for (sg = [-1, 1]) [END_X + s + hole_pitch / 2, sg * side_y]]);
function s_list(L, r, n) = concat([for (k = [0 : n]) S_START + (L - r - S_START) * k / n], [for (a = [10 : 10 : 90]) L - r + r * sin(a)]);
echo(str("v8: jacket ", 2 * END_X, " x ", 2 * BODY_HW, " x ", TOP, " (+", FRONT_BUMP, "); short strap ", short_len, ", long strap ", long_len,
         ", overall ", 2 * END_X + short_len + long_len, " mm; ", len(HOLES), " holes; sizes (centre column) ", 2 * END_X + short_len + LONG_ROWS[0], "-", 2 * END_X + short_len + LONG_ROWS[len(LONG_ROWS) - 1], " step ", hole_pitch,
         "; taper exponent ", taper_p, "; long strap width at the old 9 holes ", [for (i = [0 : 8]) round(w_long(hole_s(i)) * 10) / 10],
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

// ---- holes: round, hole_d on the outer face; on the wrist face each sits in a shallow diamond pyramid ------------
// The pyramid is smooth inside: its diamond outline has rounded corners (no sharp valleys between faces), and
// the faces curve over into the hole instead of meeting it at an edge, and the rim rolls over from the wrist
// face instead of starting at an edge. Each level is a blend between the rounded diamond at the wrist face and
// the pin's round root: fast at the rim (the surface leaves the face tangentially), easing out at the bottom.
pyr_rim = 0.7;          // 1 = crisp rim, 0.5 = fully rounded (quarter ellipse); in between keeps some flat face
function pyr_blend(u) = pow(1 - (1 - u) * (1 - u), pyr_rim);
module pyr_level(u) {
    l = pyr_blend(u);
    translate([0, 0, pyr_d * u]) linear_extrude(eps) rotate(45)
        offset(r = (1 - l) * pyr_r + l * hole_d_root / 2, $fn = 32) square(max((1 - l) * (pyr_w - 2 * pyr_r) / sqrt(2), 0.002), center = true);
}
module hole_pin() {
    n = 12;   // levels crowd toward the rim, where the surface turns fastest
    for (k = [0 : n - 1]) hull() { pyr_level(pow(k / n, 2)); pyr_level(pow((k + 1) / n, 2)); }
    translate([0, 0, pyr_d]) cylinder(d1 = hole_d_root, d2 = hole_d, h = ZP - pyr_d + eps, $fn = 32);
    translate([0, 0, ZP]) cylinder(d = hole_d, h = panel_d + 0.6, $fn = 32);
}
module holes() { for (h = HOLES) translate([h[0], h[1], -eps]) hole_pin(); }

// ---- buckle end: tongue slot rib and spring-bar pin ---------------------------------------------------
// plan of the 2 mm slot: from tongue_slot_past beyond the bar, out through the strap's end (and 1 mm into the cup's end wall)
module tongue_slot2d(g = 0) {
    x0 = X_BAR - tongue_slot_past;
    offset(delta = g) hull() { translate([x0 + tongue_slot_w / 2, 0]) circle(d = tongue_slot_w, $fn = 24); translate([X_SE, -tongue_slot_w / 2]) square([1.0, tongue_slot_w]); }
}
module tongue_slot_solid() { translate([0, 0, -eps]) linear_extrude(bk_end_t + 1.0) tongue_slot2d(); }   // the whole slot (band preview)
// The pin is printed and DROPS IN from the rim: it lies in a notch in each cup wall and in a seat in the
// rib. The slot former is split at the pin: the cup's rib below it, a boss on the lid above it.
PIN_Z0 = BAR_Z - bar_pin_w / 2; PIN_Z1 = BAR_Z + rod_flat;        // 1.5 .. 2.85 below the rim (flat side toward the outer face)
HWB = w_short(S_BAR) / 2;                                         // cavity half width at the bar
module pin_box(hw, y0, y1, z0, z1) { translate([X_BAR - hw, y0, z0]) cube([2 * hw, y1 - y0, z1 - z0]); }
module rod_round(d, y0, y1) { translate([X_BAR, (y0 + y1) / 2, BAR_Z]) rotate([90, 0, 0]) cylinder(d = d, h = y1 - y0, center = true, $fn = 32); }
module rod() { intersection() { rod_round(bar_pin_w, -(HWB + margin + 0.5), HWB + 1); pin_box(bar_pin_w, -100, 100, PIN_Z0 - 1, PIN_Z1); } }   // round, no corners for a tear to start from; 0.5 proud of the far wall, to push on
// seat for the rod: straight-sided from the rim, round at the bottom to match it
module rod_seat(y0, y1) { intersection() { union() { pin_box(bar_pin_w / 2 + pin_clr, y0, y1, -1, BAR_Z); rod_round(bar_pin_w + 2 * pin_clr, y0, y1); } pin_box(bar_pin_w, y0, y1, -1, PIN_Z1 + 0.05); } }
module pin_part() {
    intersection() { pin_box(handle_w / 2 - pin_clr, HWB - 1, 60, 0, PIN_Z1); cup_plain(); }   // handle = the piece of wall the notch removes (keeps the rim rebate)
    pin_box(handle_w / 2 - pin_clr, HWB + margin - 1, HWB + margin + 0.2, 0, PIN_Z1);   // neck through the wall
    pin_box(handle_w / 2 + grip_shoulder, HWB + margin + 0.2, HWB + margin + 0.2 + handle_grip, 0, PIN_Z1);   // grip, wider than the notch: its shoulder stops against the cup's outer wall, which sets how far in the pin goes
    rod();
}
module pin_notches() {   // cut from the cup: handle notch in the +y wall, rod notch in the -y wall, both open from the rim
    pin_box(handle_w / 2, HWB - 1, 60, -1, PIN_Z1 + 0.05);
    rod_seat(-60, -(HWB - 1));
}
module tongue_rib() {   // cup: the slot former below the pin, with a seat the pin drops into
    difference() {
        translate([0, 0, PIN_Z0]) linear_extrude(bk_end_t + 1.0 - PIN_Z0) tongue_slot2d();
        rod_seat(-5, 5);
    }
}
module lid_bosses() {   // lid: the slot former above the pin, and the fill above the rod in the far wall's notch
    intersection() { translate([0, 0, -eps]) linear_extrude(PIN_Z0 - 0.05 + eps) tongue_slot2d(-0.05); translate([0, -5, -1]) cube([X_SE, 10, 10]); }   // stops at the strap's end; the ridge covers the rebate beyond
    intersection() { pin_box(bar_pin_w / 2 + pin_clr - 0.05, -60, -(HWB - 1), -eps, PIN_Z0 - 0.05); cup_plain(); }
}

// ---- outline + texture on the outer faces -----------------------------------------------------------------
// The panel is the strap's plan inset by the edge radius plus the 0.7 mm outline; it is recessed panel_d,
// and the diamond grooves are cut into it. In the cup the panel is a plateau and the grooves are ridges.
S_PANEL0 = root_len + 1;                 // past the hinge
module panel_side2d(dir) { offset(delta = -(edge_r + rim_w)) strap_plan2d(dir, S_PANEL0, dir > 0 ? S_BAR - end_ramp : long_len); }
module panel2d() { panel_side2d(-1); panel_side2d(1); }
module hatch_lines2d(w) { for (a = [tex_angle, -tex_angle]) rotate(a) for (k = [-48 : 48]) translate([0, k * tex_pitch]) square([440, w], center = true); }
// crossings of the two families: x = i p / (2 sin a), y = j p / (2 cos a) with i + j even
module hatch_nodes2d(d) { for (i = [-80 : 80], j = [-12 : 12]) if ((i + j) % 2 == 0) translate([i * tex_pitch / (2 * sin(tex_angle)), j * tex_pitch / (2 * cos(tex_angle))]) circle(d = d, $fn = 16); }
module hatch2d(w) { if (node_gap > 0) difference() { hatch_lines2d(w); hatch_nodes2d(node_gap); } else hatch_lines2d(w); }
module tex_region2d() {
    difference() {
        panel2d();
        for (h = HOLES) translate([h[0], h[1]]) circle(d = hole_d + 2 * tex_hole_margin);   // smooth margin round every hole
    }
}
module panel() { translate([0, 0, ZP]) linear_extrude(panel_d + eps) panel2d(); }
// dimple mode: one shallow pyramid (frustum) per lattice cell, standing on the cup's plateau; the channels between them connect everywhere
module cell2d(i) { dx = tex_pitch / sin(tex_angle); dy = tex_pitch / cos(tex_angle); offset(delta = -i) polygon([[dx / 2, 0], [0, dy / 2], [-dx / 2, 0], [0, -dy / 2]]); }
module dimples() {
    dx = tex_pitch / sin(tex_angle); dy = tex_pitch / cos(tex_angle);
    for (i = [-80 : 80], j = [-12 : 12]) if ((i + j) % 2 != 0) translate([i * dx / 2, j * dy / 2, 0])
        hull() { linear_extrude(eps) cell2d(tex_channel / 2 + tex_depth * 1.1); translate([0, 0, tex_depth]) linear_extrude(eps) cell2d(tex_channel / 2); }   // small top toward the wrist, wide base on the plateau; faces about 42 deg
}
// tropic mode: diamond cells 2*hole_pitch/2 long and 2*side_y wide, centred on the hole lattice (centre column and side columns),
// each a shallow inverted pyramid in the silicone = a flat-topped bump in the cup, with connected channels between
module tr_cell2d(i) { offset(delta = -i) polygon([[hole_pitch / 2, 0], [0, side_y], [-hole_pitch / 2, 0], [0, -side_y]]); }
module tr_cells(dir) {
    x0 = dir * (END_X + S_H0);
    for (i = [-70 : 70], j = [-4 : 4]) if ((i + j) % 2 == 0) translate([x0 + i * hole_pitch / 2, j * side_y, 0])
        hull() { linear_extrude(eps) tr_cell2d(tr_ridge / 2 + tr_run); translate([0, 0, tr_depth]) linear_extrude(eps) tr_cell2d(tr_ridge / 2); }   // small flat toward the wrist, full cell at the plateau
}
module texture() {   // the ridge/bump volume: solid in the cup, empty in the band
    if (texture && tex_mode == "tropic") {
        for (dir = [-1, 1]) intersection() {
            translate([0, 0, ZP - tr_depth - eps]) linear_extrude(tr_depth + 2 * eps) offset(delta = -tr_ridge / 2) panel_side2d(dir);   // half a ridge stays at the panel's edge
            translate([0, 0, ZP - tr_depth]) tr_cells(dir);
        }
    } else if (texture && tex_mode == "dimple") {
        intersection() { translate([0, 0, ZP - tex_depth - eps]) linear_extrude(tex_depth + 2 * eps) tex_region2d(); translate([0, 0, ZP - tex_depth]) dimples(); }
    } else if (texture) {
        translate([0, 0, ZP - tex_depth / 2]) linear_extrude(tex_depth / 2 + eps) intersection() { tex_region2d(); hatch2d(tex_w); }
        translate([0, 0, ZP - tex_depth]) linear_extrude(tex_depth / 2 + eps) intersection() { tex_region2d(); hatch2d(tex_w / 2); }
    }
}

// front-face lattice: lines in plan, kept off the window pad and the button bump, applied as a 0.4 mm shell over the
// front face and its rounded perimeter (so the grooves in the cup run right down to the vertical walls)
module front_lattice2d() {
    x0 = sx(FRONT_BTN[1][0]) - 1.5; x1 = sx(FRONT_BTN[1][1]) + 1.5;
    y0 = min(sy(FRONT_BTN[0][0]), sy(FRONT_BTN[0][1])) - 1.5; y1 = max(sy(FRONT_BTN[0][0]), sy(FRONT_BTN[0][1])) + 1.5;
    difference() {
        intersection() {
            for (a = [ft_angle, -ft_angle]) rotate(a) for (k = [-30 : 30]) translate([0, k * ft_pitch]) square([140, ft_w], center = true);
            difference() {   // 0.8 inside the plan (the last 0.8 mm of the perimeter round is nearly vertical anyway) and off the four plan corners
                rrect(2 * END_X - 1.6, 2 * BODY_HW - 1.6, body_r);
                for (sx_ = [-1, 1], sy_ = [-1, 1]) translate([sx_ * (END_X - 2), sy_ * (BODY_HW - 2)]) circle(r = 3.5);
            }
        }
        win2d(-ft_keep);
        translate([(x0 + x1) / 2, (y0 + y1) / 2]) rrect(x1 - x0 + 2 * ft_keep, y1 - y0 + 2 * ft_keep, 1.5 + ft_keep);
    }
}
module front_lattice() {
    if (front_tex) difference() {
        intersection() {
            translate([0, 0, TOP - front_r - 0.3]) linear_extrude(front_r + 0.3 + ft_h + 0.1) front_lattice2d();
            minkowski() { body(); sphere(r = ft_h, $fn = 12); }
        }
        body();
    }
}
module envelope() { body(); side_bumps(); front_bump(); strap(1); strap(-1); if (port) port_pad(); }
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
// blade from inside the tunnel, through the skin and the raised border, ending flush with the border's face (it touches the cup there)
module port_fin() { translate([-(END_X - skin_t - 0.5), 0, PORT_Z]) rotate([0, -90, 0]) linear_extrude(skin_t + 0.5 + pad_h) rrect(fin_t, fin_len, fin_t / 2 - eps); }
// Raised border round the slot. The blade reaches its face, and the core drops in from the rim, so the same 0.5 mm
// relief has to run from the border to the rim: the border continues toward the strap as a raised strip. Nothing to cut off.
module port_pad2d(i = 0) { offset(delta = -i) hull() { translate([PORT_Z, 0]) rrect(fin_t + 2 * pad_m, fin_len + 2 * pad_m, fin_t / 2 + pad_m - eps); translate([-2, -(fin_len / 2 + pad_m)]) square([1, fin_len + 2 * pad_m]); } }
module port_pad() {
    steps = 5;
    intersection() {
        for (k = [0 : steps - 1]) { h0 = pad_h * k / steps; h1 = pad_h * (k + 1) / steps;
            translate([-(END_X - eps) - h0, 0, 0]) rotate([0, -90, 0]) linear_extrude(h1 - h0 + eps) port_pad2d(pad_h - sqrt(pad_h * pad_h - h0 * h0)); }
        translate([-100, -50, 0]) cube([200, 100, 100]);
    }
}
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
    front_lattice();
    difference() {
        envelope();
        core_full(); if (port) { tunnel_block(); port_fin(); }
        window_through();
        holes(); lid_ridge(); panel(); texture(); tongue_slot_solid(); rod();
    }
}

// ---- mold ---------------------------------------------------------------------------------------------------
margin = 6; cup_floor = 4;
CUP_H = TOP + FRONT_BUMP + cup_floor;
LID_T = 3.0; RIDGE_OVER = 0.15; REBATE_D = 0.9;
// vents: [x, y, d]. Along the long strap they sit off the centreline, clear of the hole pins.
// vents: [x, y, d]. Ten over the jacket; along the straps one every 10 mm, between the hole columns (2.5 mm off centre,
// half a pitch from the centre holes), alternating sides; plus the thick end and the tip.
VENTS = concat(
    [[-8, 0, 2.5], [8, 0, 2.5], [-18, 8, 2.0], [-18, -8, 2.0], [18, 8, 2.0], [18, -8, 2.0], [0, 10, 1.6], [0, -10, 1.6], [-22, 0, 1.6], [22, 0, 1.6]],
    [for (k = [0 : len(LONG_ROWS) - 1]) if (k % 2 == 0) [-(END_X + LONG_ROWS[k] + hole_pitch / 2), (k % 4 == 0 ? 2.5 : -2.5), 1.5]],
    [for (k = [0 : len(SHORT_ROWS) - 1]) if (k % 2 == 0) [END_X + SHORT_ROWS[k] + hole_pitch / 2, (k % 4 == 0 ? 2.5 : -2.5), 1.5]],
    [[END_X + 8, 0, 1.5], [END_X + S_BAR - 2, 5, 1.5], [END_X + S_BAR - 2, -5, 1.5], [-(END_X + 8), 0, 1.5], [-(END_X + long_len - 2.5), 0, 1.5]]);
// breather holes through the cup floor (4 mm) wherever the cavity has a dead end pointing at the floor:
// the front-button recess (the deepest point of the whole mold) and the window lips round the core's pad
// Under the core, silicone flows in from the gaps round its sides and pushes the air toward the window pad, whose rim
// is sealed: the air ends up in a ring against the pad's edge. So the lip breathers sit 1.2 mm outside that edge.
PAD_GAP = 1.2;
BREATHERS = concat(
    [[sx((FRONT_BTN[1][0] + FRONT_BTN[1][1]) / 2), (sy(FRONT_BTN[0][0]) + sy(FRONT_BTN[0][1])) / 2, 0.8]],   // button recess: the deepest point of the mold
    [for (y = [-5.5, 0, 5.5]) [WIN[0][0] - PAD_GAP, y, breather_d]],      // USB-side edge of the pad (under the 17 mm lip)
    [for (y = [-5.5, 0, 5.5]) [WIN[0][1] + PAD_GAP, y, breather_d]],      // top-side edge (under the 7 mm lip)
    [for (x = [0, 10], sg = [-1, 1]) [x, sg * (WIN[1][1] + PAD_GAP), breather_d]]);   // long sides
module breathers() { for (b = BREATHERS) translate([b[0], b[1], TOP - 2]) cylinder(d = b[2], h = CUP_H + 1, $fn = 12); }
module footprint2d(o) { offset(r = o) outline2d(); }
module block(z0, h) { translate([0, 0, z0]) linear_extrude(h) offset(r = margin) outline2d(); }
module lid_ridge() {
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
        for (p = SCREWS) translate([p[0], p[1], 0]) { translate([0, 0, TOP - 1]) cylinder(d = screw_d + 0.4, h = 20); translate([0, 0, CUP_H - screw_head_h]) cylinder(d = screw_head_d, h = screw_head_h + 1); }
        for (p = JACKS) translate([p[0], p[1], TOP - 1]) cylinder(d = jack_d, h = 20);
    }
}
module cup() {
    difference() {
        union() { cup_plain(); tongue_rib(); panel(); texture(); }   // rib for the tongue slot; panel plateau and knurl ridges on the trough floors
        for (h = HOLES) translate([h[0], h[1], ZP - tr_depth - 1]) cylinder(d = hole_d + 0.3, h = 1 + tr_depth + panel_d + 0.8, $fn = 32);   // sockets for the hole pins: through the texture bumps and the plateau into the floor
        breathers();
        front_lattice();   // grooves in the floor round the window: the venting channels
        pin_notches();
    }
}
module lid() {
    difference() {
        union() {
            translate([0, 0, -LID_T]) linear_extrude(LID_T) offset(r = margin) outline2d();
            lid_ridge();
            holes();   // tapered pins
            lid_bosses();
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
else if (part == "pin")         for (i = [-1 : 1]) translate([i * 12, 0, PIN_Z1]) rotate([180, 0, 0]) translate([-X_BAR, 0, 0]) pin_part();   // three (two spares), rod on the bed
else if (part == "check_pin")   intersection() { pin_part(); union() { cup(); lid(); } }
else band();
