// Silicone sleeve for the M5Stack StickS3 with a cast-in PETG lug frame, so a
// standard 22 mm watch strap (Tropic etc.) attaches with spring bars.
// Same pocket as the band (hardware/band), same 16.6 mm thickness.
//
// Parts (set `part`, or use the Customizer):
//   "frame"        PETG, print flat as exported, 4 walls, 100% infill. Cast into the sleeve.
//   "core"         PLA, as exported (on its side); needs SUPPORTS (build plate only):
//                  the side ribs that form the button openings hold it off the bed.
//   "mold_bottom"  PLA, as exported; shallow tray the frame and core sit in.
//   "mold_top"     PLA, as exported (cavity opening down is NOT printable) -> exported
//                  cavity-up; print as exported. Has the side pour hole and top vents.
//   "sleeve"       preview of the finished silicone part (don't print).
//
// Coordinates: x along the Stick's length (USB-C end at -x), y across its width,
// z from the back (wrist side, z = 0) to the front. The mold parts at z = back_t.
//
// Casting: same as the band (docs/build-notes.md), except:
//   1. Drop the frame into the bottom tray, horns in their slots.
//   2. Stand the core in the frame's opening, back pad down, ribs toward the
//      long sides. Close the top half over it, 4x M3x30 + nuts.
//   3. Inject through the side pour hole (low on one long side) until silicone
//      shows at all 8 top vents. ~11 ml of silicone; mix 25 g total.

/* [Part] */
part = "sleeve"; // [frame, core, mold_bottom, mold_top, sleeve]

/* [Strap] */
// Inside gap between the lug horns (strap end is 21 mm)
lug_gap = 21.5;
// Spring-bar centre: this far out from the sleeve's end wall, this far up from the back
bar_out = 4.0;
bar_up = 3.0;
bar_hole_d = 1.0;

/* [Fit] */
// Stick is this much bigger than the pocket, per side (0.1 looser, 0.2 default, 0.3 tighter)
squeeze = 0.2;

/* [Hidden] */
$fn = 40;
eps = 0.01;

// ---- StickS3 (K150) ------------------------------------------------------
STICK_W = 24; STICK_L = 48; STICK_T = 14.08; STICK_R = 3;
BTN_XMINUS = [6.0, 11.0];     // power/reset side, from the USB-C end
BTN_XPLUS  = [19.0, 29.0];    // KEY2 side
BTN_Z = [3.6, 11.2];          // above the Stick's back

// ---- Pocket (identical to the band) --------------------------------------
wall = 2.0; front_lip = 2.5; front_t = 1.2; back_lip = 3.0; back_t = 1.5; btn_margin = 0.5;
NOM = 0.2;
CORE_L = STICK_L - 2 * squeeze;  CORE_W = STICK_W - 2 * squeeze;  CORE_T = STICK_T - squeeze;
CORE_R = STICK_R - squeeze;
CORE_L_NOM = STICK_L - 2 * NOM;  CORE_W_NOM = STICK_W - 2 * NOM;
POCKET_L = CORE_L_NOM + 2 * wall;  POCKET_W = CORE_W_NOM + 2 * wall;
POCKET_T = back_t + STICK_T - NOM + front_t;
POCKET_R = 1.0;                 // small corners so the lug horns clear them
Z_CORE0 = back_t;  Z_CORE1 = back_t + CORE_T;
FRONT_WIN = [CORE_L_NOM - 2 * front_lip, CORE_W_NOM - 2 * front_lip];
BACK_WIN  = [CORE_L_NOM - 2 * back_lip,  CORE_W_NOM - 2 * back_lip];

// ---- Frame ------------------------------------------------------------------
skin = 0.6;                     // silicone over the frame's outer edge
frame_t = back_t;               // frame is the whole back wall; bottom face exposed
frame_clear = 0.2;              // frame opening around the core's back pad
horn_t = 2.5;
horn_h = 5.5;
horn_len = bar_out + 2.5;       // beyond the sleeve end
horn_y = lug_gap / 2 + horn_t / 2;
HORN_X0 = POCKET_L / 2 - skin - 1.0;   // horn root starts inside the frame ring
HORN_X1 = POCKET_L / 2 + horn_len;
BAR_X = POCKET_L / 2 + bar_out;
assert(horn_y + horn_t / 2 <= POCKET_W / 2 - 0.4, "lug horns wider than the sleeve");

// ---- Mold ----------------------------------------------------------------
slot_clear = 0.15;
bottom_t = 5.0;                 // bottom tray under the frame
top_floor = 4.0;                // material above the cavity ceiling
margin = 8.5;
MX = HORN_X1 + slot_clear + margin;          // mold half-length
MY = POCKET_W / 2 + margin;                  // mold half-width
TOP_H = POCKET_T - back_t + top_floor;
bolt_d = 3.4;
BOLTS = [[-(MX - 5), -(MY - 5)], [MX - 5, -(MY - 5)], [-(MX - 5), MY - 5], [MX - 5, MY - 5]];
PINS = [[-12, -(MY - 4)], [12, MY - 4]];   // diagonal, so the top only fits one way
VENTS = [[-(POCKET_L / 2 - 2.3), -(POCKET_W / 2 - 2.3)], [POCKET_L / 2 - 2.3, -(POCKET_W / 2 - 2.3)],
         [-(POCKET_L / 2 - 2.3), POCKET_W / 2 - 2.3], [POCKET_L / 2 - 2.3, POCKET_W / 2 - 2.3],
         [0, -(POCKET_W / 2 - 1.2)], [0, POCKET_W / 2 - 1.2],
         [-(POCKET_L / 2 - 1.2), 0], [POCKET_L / 2 - 1.2, 0]];
vent_d = 1.5;
sprue_d = 3.5;
SPRUE = [10, 3.5];              // x position and z height of the side pour hole (-y side)

echo(str("Sleeve ", POCKET_L, " x ", POCKET_W, " x ", POCKET_T, " mm; lug gap ", lug_gap,
         "; bar at ", bar_out, " out / ", bar_up, " up; mold ", 2 * MX, " x ", 2 * MY,
         ", bottom ", bottom_t, " + top ", TOP_H, " = ", bottom_t + TOP_H, " mm (M3x30)"));

module rrect(l, w, r) { offset(r = r) square([l - 2 * r, w - 2 * r], center = true); }
module rbox(l, w, r, z0, z1) { translate([0, 0, z0]) linear_extrude(z1 - z0) rrect(l, w, r); }

// ---- Pieces -----------------------------------------------------------------
module pocket_body() { rbox(POCKET_L, POCKET_W, POCKET_R, 0, POCKET_T); }

module core_block() {
    rbox(CORE_L, CORE_W, CORE_R, Z_CORE0, Z_CORE1);
    rbox(FRONT_WIN[0], FRONT_WIN[1], 1.0, Z_CORE1 - eps, POCKET_T);   // fills the screen window
    rbox(BACK_WIN[0],  BACK_WIN[1],  1.0, 0, Z_CORE0 + eps);          // fills the back window
}

// ribs on the core reach the cavity wall and leave the side-button openings
module core_ribs(grow = 0) {
    z0 = back_t + BTN_Z[0] - btn_margin - grow;
    z1 = back_t + BTN_Z[1] + btn_margin + grow;
    xm = [BTN_XMINUS[0] - STICK_L / 2 - btn_margin - grow, BTN_XMINUS[1] - STICK_L / 2 + btn_margin + grow];
    xp = [BTN_XPLUS[0]  - STICK_L / 2 - btn_margin - grow, BTN_XPLUS[1]  - STICK_L / 2 + btn_margin + grow];
    translate([xm[0], -POCKET_W / 2 - grow, z0]) cube([xm[1] - xm[0], POCKET_W / 2 - CORE_W / 2 + 1 + grow, z1 - z0]);
    translate([xp[0],  CORE_W / 2 - 1, z0])      cube([xp[1] - xp[0], POCKET_W / 2 - CORE_W / 2 + 1 + grow, z1 - z0]);
}

module core_part() { core_block(); core_ribs(); }

// one lug horn: a plate in the x-z plane, rounded around the spring-bar hole
module horn(sx, sy, grow = 0) {
    translate([0, sy * horn_y, 0]) rotate([90, 0, 0]) translate([0, 0, -(horn_t / 2 + grow)])
        linear_extrude(horn_t + 2 * grow) hull() {
            translate([sx > 0 ? HORN_X0 : -BAR_X, -grow]) square([BAR_X - HORN_X0, horn_h + 2 * grow]);
            translate([sx * BAR_X, bar_up]) circle(r = 2.5 + grow);
        }
}
module horns(grow = 0) { for (sx = [-1, 1], sy = [-1, 1]) horn(sx, sy, grow); }

module frame_part() {
    difference() {
        union() {
            difference() {
                rbox(POCKET_L - 2 * skin, POCKET_W - 2 * skin, max(POCKET_R - skin, 0.4), 0, frame_t);
                rbox(BACK_WIN[0] + 2 * frame_clear, BACK_WIN[1] + 2 * frame_clear, 1.0 + frame_clear, -1, frame_t + 1);
            }
            horns();
        }
        for (sx = [-1, 1]) translate([sx * BAR_X, 0, bar_up]) rotate([90, 0, 0]) cylinder(d = bar_hole_d, h = 100, center = true, $fn = 16);
    }
}

// everything the silicone fills
module silicone() {
    difference() {
        pocket_body();
        core_part();
        frame_part();
        horns(0.001);
    }
}

// ---- Mold halves -------------------------------------------------------------
module mold_bottom() {
    difference() {
        translate([0, 0, back_t - bottom_t]) linear_extrude(bottom_t) rrect(2 * MX, 2 * MY, 4);
        // tray: pocket outline, back_t deep (frame + core back pad + skin sit in it)
        rbox(POCKET_L, POCKET_W, POCKET_R, -eps, back_t + 1);
        // lower part of the horn slots
        horns(slot_clear);
        for (b = BOLTS) translate([b[0], b[1], -10]) cylinder(d = bolt_d, h = 40);
        for (p = PINS) translate([p[0], p[1], back_t - 4.5]) cylinder(d = 5.4, h = 4.5 + eps);
    }
    // alignment pins go on the top half so the bottom stays a flat, easy print
}

module mold_top() {
    difference() {
        translate([0, 0, back_t]) linear_extrude(TOP_H) rrect(2 * MX, 2 * MY, 4);
        // cavity above the parting plane
        rbox(POCKET_L, POCKET_W, POCKET_R, back_t - eps, POCKET_T);
        // upper part of the horn slots, open to the parting face
        horns(slot_clear);
        for (b = BOLTS) translate([b[0], b[1], -10]) cylinder(d = bolt_d, h = 60);
        // vents from the top face down into the lip ring
        for (v = VENTS) translate([v[0], v[1], POCKET_T - 0.3]) cylinder(d = vent_d, h = top_floor + 1, $fn = 12);
        // side pour hole, low on the -y long side, with a funnel
        translate([SPRUE[0], -(POCKET_W / 2) + 0.3, SPRUE[1]]) rotate([90, 0, 0]) cylinder(d = sprue_d, h = MY);
        translate([SPRUE[0], -MY - eps, SPRUE[1]]) rotate([-90, 0, 0]) cylinder(d1 = sprue_d + 5, d2 = sprue_d, h = 2.5);
    }
    for (p = PINS) translate([p[0], p[1], back_t + eps]) mirror([0, 0, 1]) cylinder(d1 = 5, d2 = 4, h = 4);
}

if (part == "frame") frame_part();
else if (part == "core") translate([0, 0, POCKET_W / 2]) rotate([90, 0, 0]) core_part();    // -y face down
else if (part == "mold_bottom") translate([0, 0, bottom_t - back_t]) mold_bottom();          // flat face down
else if (part == "mold_top") translate([0, 0, TOP_H + back_t]) rotate([180, 0, 0]) mold_top(); // parting face up
else silicone();
