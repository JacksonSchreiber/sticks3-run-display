// One-piece silicone watch band with a slip-in pocket for the M5Stack StickS3
// Cast in Smooth-On Smooth-Sil 945 (Shore 45A, skin safe) in a 3D-printed mold.
//
// Parts (set `part`, or use the Customizer):
//   "mold_bottom"  PLA, print as exported (parting face up), no supports
//   "mold_top"     PLA, print as exported (parting face up), no supports; has the pour hole + vents
//   "core"         PLA, print as exported (standing on its side); forms the Stick pocket + windows
//   "band"         preview of the finished band (don't print); console shows silicone volume
//
// The band is molded pre-curved so it fits a 220 mm bed and wraps the wrist.
// The Stick lies across the wrist; screen and front button stay exposed and the
// side buttons have openings. Closure: silicone stud through a punched hole, then
// tuck the tail under the band (like an Apple Sport Band). No hardware.
//
// Casting:
//   1. Sand the parting faces flat. Spray the halves and core with Ease Release 200.
//   2. Lay the core in the bottom half (window pads against the cavity walls,
//      side-button post in its side opening), close the top half, bolt with 8x M3x30
//      + nuts (heads and nuts drop into the pockets on the outer faces). Snug.
//   3. Mix ~27 ml Smooth-Sil 945 (1A:1B by weight), inject slowly through the pour
//      hole with a 60 ml syringe until silicone shows at every vent. Tap to free bubbles.
//   4. Wait 6 h. Unbolt, lift the band + core out, stretch the front lip over the
//      core to pop it out. Trim vent nubs and the seam.
//   5. Punch the 7 strap holes with a 3 mm leather punch, centred between the
//      little notches on the strap edges.

/* [Part] */
part = "band"; // [mold_bottom, mold_top, core, band]

/* [Sizing] */
// Snug wrist circumference, mm
wrist = 165;
// Middle hole = wrist + this. Holes step hole_pitch either side.
fit_ease = 5;
hole_count = 7;
hole_pitch = 6;

/* [Band] */
strap_w = 22;
strap_t = 3.0;
// Stick is this much bigger than the pocket, per side (grip). Only the core changes:
// 0.1 looser, 0.2 default, 0.3 tighter.
squeeze = 0.2;
// Molded curvature of the straps (inner surface)
R_mold = 40;

/* [Hidden] */
$fn = 40;
eps = 0.01;

// ---- StickS3 (K150), from M5Stack's drawing + official 3D model ------------
STICK_W = 24; STICK_L = 48; STICK_T = 14.08; STICK_R = 3;
// Side buttons measured on M5Stack's model: [y0, y1] from the USB-C end; BTN_Z from the back
BTN_XMINUS = [6.0, 11.0];     // power / reset side
BTN_XPLUS  = [19.0, 29.0];    // KEY2 side
BTN_Z = [3.6, 11.2];

// ---- Pocket ----------------------------------------------------------------
wall = 2.0;
front_lip = 2.5;   // how far the front lip covers the Stick's face
front_t = 1.2;
back_lip = 3.0;
back_t = 1.5;
btn_margin = 0.5;

// The mold halves are sized from a fixed nominal pocket so changing `squeeze`
// only changes the core: reprint the small core to tune grip, not the halves.
NOM_SQUEEZE = 0.2;
CORE_W_NOM = STICK_W - 2 * NOM_SQUEEZE;
POCKET_L = STICK_L - 2 * NOM_SQUEEZE + 2 * wall;
POCKET_W = CORE_W_NOM + 2 * wall;
POCKET_T = back_t + STICK_T - NOM_SQUEEZE + front_t;
POCKET_R = STICK_R - NOM_SQUEEZE + wall;
PL = POCKET_L / 2;
CORE_L = STICK_L - 2 * squeeze;
CORE_W = STICK_W - 2 * squeeze;
CORE_T = STICK_T - squeeze;
CORE_R = STICK_R - squeeze;
CORE_N0 = back_t;
CORE_N1 = back_t + CORE_T;

// ---- Straps & closure ------------------------------------------------------
// Worn size at hole i  ~=  POCKET_L + L_stud + L_hole(i)
L_stud = 45;                 // pocket end -> stud centre (short strap)
short_len = L_stud + 10;
mid_size = wrist + fit_ease;
function L_hole(i) = (mid_size - POCKET_L - L_stud) + (i - (hole_count - 1) / 2) * hole_pitch;
function band_size(i) = POCKET_L + L_stud + L_hole(i);
long_len = L_hole(hole_count - 1) + 35;   // tail to tuck
root_len = 10;               // strap thickens / widens into the pocket
root_t = 6;
stud_shaft_d = 3.2;
stud_shaft_h = strap_t + 0.3;
stud_head_d = 6.0;
hole_d = 3.0;

// ---- Mold ------------------------------------------------------------------
mold_margin = 10;
mold_floor = 4;
HZ = POCKET_W / 2 + mold_floor;       // each half's thickness
bolt_d = 3.4;
bolt_pocket_d = 7.0;     // recess for the bolt head / nut on each outer face
bolt_pocket_h = 4.0;     // 2x4 mm recessed, so M3x30 spans the closed mold
vent_d = 1.6;
sprue_d = 6;
post_key = 1.0;                       // side-button posts sink this far into the core to locate it
post_clear = 0.15;

echo(str("Band size at each hole (mm): ", [for (i = [0 : hole_count - 1]) band_size(i)]));
echo(str("Short strap ", short_len, " mm, long strap ", long_len, " mm, total ", POCKET_L + short_len + long_len, " mm"));

// ---- Path: flat under the pocket, then arcs of R_mold ----------------------
// s < 0: short strap (USB-C end), s > 0: long strap (top end); n = outward from the skin side
function phi(s) = (abs(s) - PL) / R_mold * 180 / PI;
function frame(s) = abs(s) <= PL ? [s, 0, 0] :
    let(p = phi(s), g = sign(s))
    [g * (PL + R_mold * sin(p)), -R_mold + R_mold * cos(p), -g * p];
function pt(s, n) = let(f = frame(s)) [f[0] - n * sin(f[2]), f[1] + n * cos(f[2])];

module at(s, n = 0) {
    f = frame(s);
    translate([f[0] - n * sin(f[2]), f[1] + n * cos(f[2]), 0]) rotate([0, 0, f[2]]) children();
}

function smooth(x) = let(c = max(0, min(1, x))) c * c * (3 - 2 * c);
function w_at(s) =
    let(d = abs(s) - PL, L = s < 0 ? short_len : long_len, r = strap_w / 2,
        base = POCKET_W + (strap_w - POCKET_W) * smooth(d / root_len))
    d > L - r ? 2 * sqrt(max(0.25, r * r - pow(d - (L - r), 2))) : base;
function t_at(s) = let(d = abs(s) - PL) root_t + (strap_t - root_t) * smooth(d / root_len);

// thin cross-section (octagon, 0.6 mm edge chamfer) in the local n-w plane
module xsec(t, w, c = 0.6) {
    cc = min(c, w / 4, t / 4);
    rotate([0, 90, 0]) linear_extrude(eps, center = true)
        polygon([[-(w / 2 - cc), 0], [w / 2 - cc, 0], [w / 2, cc], [w / 2, t - cc],
                 [w / 2 - cc, t], [-(w / 2 - cc), t], [-w / 2, t - cc], [-w / 2, cc]]);
}

function stations(L, sg) = let(n = ceil(L / 2.5)) concat([sg * (PL - POCKET_R)], [for (i = [0 : n]) sg * (PL + L * i / n)]);

module strap(sg) {
    st = stations(sg < 0 ? short_len : long_len, sg);
    for (i = [0 : len(st) - 2]) hull() {
        at(st[i]) xsec(t_at(st[i]), w_at(st[i]));
        at(st[i + 1]) xsec(t_at(st[i + 1]), w_at(st[i + 1]));
    }
}

// rounded rectangle in the s-w plane, extruded along n from n0 to n1
module sw_block(hl, hw, r, n0, n1) {
    translate([0, n0, 0]) rotate([-90, 0, 0]) linear_extrude(n1 - n0)
        offset(r = r) square([2 * (hl - r), 2 * (hw - r)], center = true);
}

module pocket_body() {
    hull() {
        sw_block(PL, POCKET_W / 2, POCKET_R, 0, POCKET_T - 0.8);
        sw_block(PL - 0.8, POCKET_W / 2 - 0.8, POCKET_R - 0.8, 0, POCKET_T);
    }
}

module stud() {
    at(-(PL + L_stud), strap_t - 0.5) {
        rotate([-90, 0, 0]) cylinder(d = stud_shaft_d, h = stud_shaft_h + 0.5);
        translate([0, stud_shaft_h + 0.5, 0]) rotate([-90, 0, 0]) {
            cylinder(d = stud_head_d, h = 1.0);
            translate([0, 0, 1.0]) cylinder(d1 = stud_head_d, d2 = 4.0, h = 0.8);
        }
    }
}

// the band's outer shape with the pocket filled in
module envelope() {
    pocket_body();
    strap(-1);
    strap(1);
    stud();
}

WIN_L = STICK_L / 2 - NOM_SQUEEZE;
module front_window(n0, n1) { sw_block(WIN_L - front_lip, CORE_W_NOM / 2 - front_lip, 1.0, n0, n1); }
module back_window(n0, n1)  { sw_block(WIN_L - back_lip,  CORE_W_NOM / 2 - back_lip,  1.0, n0, n1); }

// side-button openings: [s0, s1, side]
BTN_OPENINGS = [
    [BTN_XMINUS[0] - STICK_L / 2 - btn_margin, BTN_XMINUS[1] - STICK_L / 2 + btn_margin, -1],
    [BTN_XPLUS[0]  - STICK_L / 2 - btn_margin, BTN_XPLUS[1]  - STICK_L / 2 + btn_margin,  1]];
module side_opening(o, z_in, z_out, grow = 0) {
    n0 = CORE_N0 + BTN_Z[0] - btn_margin - grow;
    n1 = CORE_N0 + BTN_Z[1] + btn_margin + grow;
    translate([o[0] - grow, n0, o[2] > 0 ? z_in : -z_out]) cube([o[1] - o[0] + 2 * grow, n1 - n0, z_out - z_in]);
}

// core = Stick-shaped block + pads that fill the front/back windows.
// The side-button posts from each mold half drop into shallow pockets on its
// sides, which locates it; everything releases with a straight pull.
module core_part() {
    difference() {
        union() {
            sw_block(CORE_L / 2, CORE_W / 2, CORE_R, CORE_N0, CORE_N1);
            front_window(CORE_N1 - eps, POCKET_T);
            back_window(0, CORE_N0 + eps);
        }
        for (o = BTN_OPENINGS) side_opening(o, CORE_W_NOM / 2 - post_key - post_clear, CORE_W / 2 + 1, post_clear);
    }
}

// little notches on both strap edges show where to punch each hole
// (on the edges so the mold still pulls straight off)
module punch_marks() {
    for (i = [0 : hole_count - 1], side = [-1, 1]) at(PL + L_hole(i), strap_t / 2)
        translate([0, 0, side * (strap_w / 2 + 0.2)]) rotate([side > 0 ? 180 : 0, 0, 0])
            cylinder(d1 = 1.6, d2 = 0.4, h = 0.8, $fn = 16);
}

module silicone() {
    difference() {
        envelope();
        core_part();
        for (o = BTN_OPENINGS) side_opening(o, CORE_W_NOM / 2 - 1, POCKET_W / 2 + 1);
        punch_marks();
        // holes as punched
        for (i = [0 : hole_count - 1]) at(PL + L_hole(i), -1) rotate([-90, 0, 0]) cylinder(d = hole_d, h = strap_t + 2);
    }
}

// ---- Mold ------------------------------------------------------------------
module band_2d() {
    translate([-PL, 0]) square([POCKET_L, POCKET_T]);
    for (sg = [-1, 1]) {
        st = stations(sg < 0 ? short_len : long_len, sg);
        for (i = [0 : len(st) - 2]) hull()
            for (s = [st[i], st[i + 1]]) {
                translate(pt(s, 0)) circle(d = 0.1);
                translate(pt(s, t_at(s))) circle(d = 0.1);
            }
    }
    translate(pt(-(PL + L_stud), strap_t + stud_shaft_h + 1)) circle(d = stud_head_d + 1);
}

BOLTS = [pt(-14, POCKET_T + 5.5), pt(14, POCKET_T + 5.5),
         pt(-(PL + 22), -5.5), pt(-(PL + short_len - 4), -5.5),
         pt(PL + 25, strap_t + 5.5), pt(PL + 62, -5.5), pt(PL + 100, strap_t + 5.5),
         pt(PL + long_len - 4, -5.5)];
PINS = [pt(0, -5.5), pt(-(PL + 30), strap_t + 5.5), pt(PL + 82, -5.5)];

// [s, n] vents, drilled from the top face down into the top of the cavity
VENTS = [[-22, 2], [-22, POCKET_T - 1], [22, 2], [22, POCKET_T - 1],
         [0, 0.75], [0, POCKET_T - 0.6], [-12, POCKET_T - 0.6], [12, 0.75],
         [-(PL + 5), 1.5], [PL + 5, 1.5],
         [-(PL + 25), 1.5], [-(PL + short_len - 3), 1.5],
         [PL + 25, 1.5], [PL + 45, 1.5], [PL + L_hole(0) + hole_pitch / 2, 1.5],
         [PL + L_hole(hole_count - 1) + 8, 1.5], [PL + long_len - 3, 1.5]];
SPRUE = [15, 8];

function cavity_top_z(s) = abs(s) <= PL - POCKET_R ? POCKET_W / 2 : w_at(s) / 2;

module mold_half(top) {
    difference() {
        intersection() {
            union() {
                difference() {
                    translate([0, 0, -HZ]) linear_extrude(2 * HZ) offset(r = mold_margin) band_2d();
                    envelope();
                }
                // posts that form the side-button openings and key into the core
                for (o = BTN_OPENINGS) side_opening(o, CORE_W_NOM / 2 - post_key, POCKET_W / 2 + 0.5);
                punch_marks();
            }
            translate([-500, -500, top ? 0 : -500]) cube([1000, 1000, 500]);
        }
        for (b = BOLTS) {
            translate([b[0], b[1], -HZ - 1]) cylinder(d = bolt_d, h = 2 * HZ + 2);
            // bolt head pocket on the top half's outer face, nut pocket on the bottom's
            if (top) translate([b[0], b[1], HZ - bolt_pocket_h]) cylinder(d = bolt_pocket_d, h = bolt_pocket_h + 1);
            else translate([b[0], b[1], -HZ - 1]) cylinder(d = bolt_pocket_d, h = bolt_pocket_h + 1, $fn = 6);
        }
        if (top) {
            for (p = PINS) translate([p[0], p[1], -eps]) cylinder(d = 5.4, h = 4.5);
            for (v = VENTS) {
                p = pt(v[0], v[1]);
                translate([p[0], p[1], cavity_top_z(v[0]) - 0.3]) cylinder(d = vent_d, h = HZ + 1, $fn = 12);
            }
            sp = pt(-(PL + L_stud), strap_t + stud_shaft_h + 1.2);
            translate([sp[0], sp[1], stud_head_d / 2 - 0.3]) cylinder(d = vent_d, h = HZ, $fn = 12);
            p = pt(SPRUE[0], SPRUE[1]);
            translate([p[0], p[1], CORE_W_NOM / 2 + 0.3]) cylinder(d = sprue_d, h = HZ);
            translate([p[0], p[1], HZ - 3]) cylinder(d1 = sprue_d, d2 = sprue_d + 6, h = 3 + eps);
        }
    }
    if (!top) for (p = PINS) translate([p[0], p[1], -eps]) cylinder(d1 = 5, d2 = 4, h = 4);
}

if (part == "band") {
    silicone();
} else if (part == "mold_bottom") {
    translate([0, 0, HZ]) mold_half(false);
} else if (part == "mold_top") {
    translate([0, 0, HZ]) rotate([180, 0, 0]) mold_half(true);
} else if (part == "core") {
    // as modeled the core stands on its side: pads face sideways, no bridges
    translate([0, 0, CORE_W_NOM / 2]) core_part();
}
