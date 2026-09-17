// M5Stack StickS3 (K150) clip mount: a printed cradle bolted to a tempered
// spring-steel belt clip. Clips to a shirt, pocket, waistband or watch band.
//
// Clips (theclip.com, both US-made tempered spring steel):
//   "631"  MCS-631SS, 2.72" x 1" stainless: sweat-proof, overhangs the top end by ~14 mm
//   "661"  MCS-661, 2.15" x 1" powder-coated/nickel spring steel: same length as the Stick
//
// Assembly:
//   1. Drop 2 M3 nuts into the hex pockets inside the cradle.
//   2. Tilt the Stick's USB-C end up, slide its top end under the lip, lower it, and
//      screw it down from underneath with 2x M2x6 socket-cap or button-head screws
//      (they sit in counterbores, flush with the bottom). No longer than 6 mm: the
//      Stick's threaded bosses are only ~3 mm deep with electronics right behind them.
//   3. Bolt the clip on with 2x M3x4 or M3x5 socket-cap / button-head screws through
//      the clip's own holes. With M3x6, add a washer under each head; nothing may
//      stick out past the nut or it will press on the Stick.
// USB-C stays open, so it charges on the clip.
//
// Print: PETG, flat side down, no supports. 0.2 mm layers, 5 walls, 100% infill.

/* [Clip] */
clip_model = "631"; // [631, 661]

/* [Fit tuning] */
// Gap around the Stick, per side. 0.2 if it rattles, 0.4 if it won't go in.
clearance = 0.3;

/* [Hidden] */
$fn = 48;
eps = 0.01;

// ---- StickS3 (from M5Stack's K150 drawing + official STL) -----------------
STICK_W = 24;
STICK_L = 48;
STICK_T = 14.08;
STICK_R = 3;
SCREW_POS = [[3, 8.5], [21, 8.5]];    // M2 threaded holes, from the Stick's left edge / USB-C end
SIDE_BUTTON_Z = 3.6;                  // side buttons start this far above the Stick's back

// ---- Cradle ---------------------------------------------------------------
wall = 2.2;
floor_t = 5.0;          // holds M3 nuts, and M2x6 cap screws engage 2.4 mm
rail_h = 3.0;
usb_curb = 1.2;
lip_overhang = 1.2;
lip_t = 1.6;
bottom_chamfer = 0.6;

W = STICK_W + 2 * (wall + clearance);
X0 = wall + clearance;
Y0 = -clearance - usb_curb;
Y_WALL = STICK_L + clearance;
Y1 = Y_WALL + wall;
LIP_Z = floor_t + STICK_T + clearance;
TOP_Z = LIP_Z + lip_t;
R_OUT = STICK_R + clearance + wall;

// ---- Clip hardware ----------------------------------------------------------
// Hole positions along the cradle (y). Hole spacing is dimensioned on theclip.com's
// drawings (1.000" and 0.50"); where the pair sits along the clip is scaled off the
// drawing, so the slots let the clip slide +/-3 mm to wherever its holes really are.
CLIP_631 = [Y0 + 3 + 5.2, Y0 + 3 + 5.2 + 25.4];   // open end ~3 mm past the USB-C end, bend at the top
CLIP_661 = [Y1 - 11.4, Y1 - 11.4 - 12.7];         // bend end at the top end
CLIP_HOLES_Y = clip_model == "661" ? CLIP_661 : CLIP_631;
slot = 6;
m3_clear = 3.4;
m3_nut_af = 5.5;
nut_h = 2.4;
nut_pocket = nut_h + 0.2;

assert(rail_h < SIDE_BUTTON_Z - 0.5, "rails would cover the side buttons");
assert(floor_t - nut_pocket >= 1.2, "floor too thin under the nuts");
assert(6 - (floor_t - m2_head_pocket) <= 2.6, "M2x6 would bottom out in the Stick's boss");
for (y = CLIP_HOLES_Y) assert(y - slot / 2 - m3_nut_af / cos(30) / 2 > Y0 + 1.2 && y + slot / 2 < Y1 - 3,
                              "clip slot falls outside the cradle");

module rrect(x0, y0, x1, y1, r) {
    translate([x0 + r, y0 + r]) offset(r = r) square([x1 - x0 - 2 * r, y1 - y0 - 2 * r]);
}

module chamfered_slab(x0, y0, x1, y1, r, z0, z1, c) {
    hull() {
        translate([0, 0, z0]) linear_extrude(eps) rrect(x0 + c, y0 + c, x1 - c, y1 - c, max(r - c, 0.5));
        translate([0, 0, z0 + c]) linear_extrude(z1 - z0 - c) rrect(x0, y0, x1, y1, r);
    }
}

module stick_pocket_2d() {
    offset(r = clearance) rrect(X0, 0, X0 + STICK_W, STICK_L, STICK_R);
}

// counterbore for an M2 socket-cap or button head (head sits flush with the bottom)
m2_head_d = 4.4;
m2_head_pocket = 1.4;
module counterbored_m2() {
    translate([0, 0, -1]) cylinder(d = 2.3, h = floor_t + 2);
    translate([0, 0, -1]) cylinder(d = m2_head_d, h = 1 + m2_head_pocket);
}

module stadium(d, len, h) {
    hull() for (dy = [-len / 2, len / 2]) translate([0, dy, 0]) cylinder(d = d, h = h);
}

// the nut pocket opens into the Stick pocket so nuts drop in from above; a seated
// nut's top is 0.2 mm below the floor, under the Stick
module m3_nut_slot() {
    translate([0, 0, -1]) stadium(m3_clear, slot, floor_t + 2);
    translate([0, 0, floor_t - nut_pocket]) hull() for (dy = [-slot / 2, slot / 2])
        translate([0, dy, 0]) cylinder(d = m3_nut_af / cos(30) + 0.3, h = nut_pocket + 1, $fn = 6);
}

module clip_mount() {
    difference() {
        union() {
            chamfered_slab(0, Y0, W, Y1, R_OUT, 0, floor_t + rail_h, bottom_chamfer);
            intersection() {
                chamfered_slab(0, Y0, W, Y1, R_OUT, 0, TOP_Z, bottom_chamfer);
                translate([-1, Y_WALL - lip_overhang, -1]) cube([W + 2, Y1 - Y_WALL + lip_overhang + 1, TOP_Z + 2]);
            }
        }
        translate([0, 0, floor_t]) linear_extrude(LIP_Z - floor_t) stick_pocket_2d();
        for (p = SCREW_POS) translate([X0 + p[0], p[1], 0]) counterbored_m2();
        for (y = CLIP_HOLES_Y) translate([W / 2, y, 0]) m3_nut_slot();
    }
}

clip_mount();
