// Silicone sleeve for the M5Stack StickS3 with a cast-in PETG lug frame, so a
// standard 22 mm watch strap (Tropic etc.) attaches with spring bars.
// Same pocket as the band (hardware/band), same 16.6 mm thickness.
//
// Parts (set `part`, or use the Customizer):
//   "frame"        PETG, print as exported: its flat top face is on the bed, the curved side
//                  is up, NO supports needed. 4 walls, 100% infill. Cast into the sleeve.
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
lug_gap = 21.4;
// Spring-bar centre, this far out from the sleeve's end wall
bar_out = 2.0;
// The back is flat in the middle, then curves down toward the wrist on an arc of this
// radius, starting this far from the centre. Starting under the Stick means the flat
// Stick rests on the middle and a silicone wedge fills under its ends; the sleeve,
// frame and horns all wrap the wrist. Horns must stay short of curve_start + curve_R.
curve_R = 15;
curve_start = 16.0;
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
horn_t = 3.0;                   // inside the sleeve's end wall
horn_flare = 1.0;               // extra thickness outward, only outside the sleeve
horn_h = back_t;                // horns never rise above the frame's flat top (prints support-free)
horn_tip_r = 2.2;               // material around the bar hole: 1.7 mm
horn_len = bar_out + horn_tip_r; // beyond the sleeve end
horn_y = lug_gap / 2 + horn_t / 2;
// The horn stands at full height from just past the core's rounded corner, so
// its root runs the whole end wall (about 2.3 mm) instead of a 1 mm stub.
HORN_X0 = curve_start + 5.0;    // horn root runs along the thick end of the ring
HORN_X1 = POCKET_L / 2 + horn_len;
BAR_X = POCKET_L / 2 + bar_out;
// how far the back surface has dropped below z = 0 at |x|
function drop(x) = abs(x) <= curve_start ? 0 : curve_R - sqrt(curve_R * curve_R - pow(abs(x) - curve_start, 2));
BAR_Z = -drop(BAR_X) + horn_tip_r;      // tip circle sits on the curve
assert(curve_start >= 8, "curve must leave a flat middle for the Stick to rest on");
// the tray must hold the sleeve's curved ends and the horn's lowest point (under the bar);
// beyond the bar the horn is its rounded tip, which stays above the arc
assert(drop(POCKET_L / 2) < bottom_t - back_t - 2, "sleeve ends reach through the bottom tray");
assert(BAR_Z - horn_tip_r - slot_clear > -(bottom_t - back_t) + 1, "horn tips reach through the bottom tray");
assert(curve_R + eps >= HORN_X1 - curve_start, "curve too tight: it turns vertical before the horn tips");
assert(horn_y + horn_t / 2 <= POCKET_W / 2 - 0.1, "lug horns wider than the sleeve");

// ---- Mold ----------------------------------------------------------------
slot_clear = 0.35;                 // per side; FDM horns come out fat and the first layers spread
bottom_t = 9.0;                 // bottom tray; deep enough for the down-turned horn tips
bolt_head_pocket = 2.5;         // recess for the bolt heads on the top half, so M3x30 reaches
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
         "; bar at ", bar_out, " out, z=", BAR_Z, "; curve R", curve_R, " from x=", curve_start, "; mold ", 2 * MX, " x ", 2 * MY,
         ", bottom ", bottom_t, " + top ", TOP_H, " = ", bottom_t + TOP_H, " mm, ",
         bottom_t + TOP_H - bolt_head_pocket, " mm through the bolts (M3x30)"));

module rrect(l, w, r) { offset(r = r) square([l - 2 * r, w - 2 * r], center = true); }
module rbox(l, w, r, z0, z1) { translate([0, 0, z0]) linear_extrude(z1 - z0) rrect(l, w, r); }

// ---- Pieces -----------------------------------------------------------------
// Solid region above the curved back surface (flat for |x| <= curve_start, then the arc).
// `r` and `z0` let the same shape describe the frame's top surface (offset inward).
// The curve is convex (a wrist): the arc is the top of a circle of radius curve_R whose
// centre is curve_R below the flat back, at x = +/-curve_start. "Above" it = outside that
// circle. A larger r (curve_R + t) gives the parallel surface t above it.
module above_curve(r = curve_R, z0 = 0) {
    translate([-curve_start, -100, z0]) cube([2 * curve_start, 200, 60]);
    for (sx = [-1, 1]) difference() {
        translate([sx > 0 ? curve_start : -curve_start - 60, -100, -curve_R]) cube([60, 200, 60 + curve_R]);
        translate([sx * curve_start, 0, -curve_R]) rotate([90, 0, 0]) cylinder(r = r, h = 201, center = true, $fn = 240);
    }
}
module pocket_body() { intersection() { rbox(POCKET_L, POCKET_W, POCKET_R, -10, POCKET_T); above_curve(); } }

module core_block() {
    rbox(CORE_L, CORE_W, CORE_R, Z_CORE0, Z_CORE1);
    rbox(FRONT_WIN[0], FRONT_WIN[1], 1.0, Z_CORE1 - eps, POCKET_T);   // fills the screen window
    intersection() {                                                   // fills the back window,
        rbox(BACK_WIN[0], BACK_WIN[1], 1.0, -10, Z_CORE0 + eps);        // down to the curved back
        above_curve();
    }
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

// one lug horn: a plate in the x-z plane, rounded around the spring-bar hole.
// Outside the sleeve it thickens outward (away from the strap) for strength.
// Flat top level with the frame's top all the way to the tip, underside cut to the wrist
// curve, rounded lower corner around the bar. A flat top means the tray slot is an
// open-topped pocket the frame drops into, and the top mold half seals it flat.
module horn_profile(sx, grow, x0) {
    intersection() {
        hull() {
            translate([sx > 0 ? x0 : -HORN_X1, BAR_Z - grow]) square([HORN_X1 - x0, horn_h - BAR_Z + 2 * grow]);
            translate([sx * BAR_X, BAR_Z]) circle(r = horn_tip_r + grow);   // rounds the lower outer corner
        }
        // start square at x0: the circle must not poke back past it, or the flared section
        // gets a rounded inner edge that jams when the frame is lifted out of the tray
        if (sx > 0) translate([x0 - grow, -100]) square([200, 200]);
        else        translate([-200, -100]) square([200 - x0 + grow, 200]);
    }
}
module horn(sx, sy, grow = 0) {
    intersection() {
        union() {
            translate([0, sy * horn_y, 0]) rotate([90, 0, 0]) translate([0, 0, -(horn_t / 2 + grow)])
                linear_extrude(horn_t + 2 * grow) horn_profile(sx, grow, HORN_X0);
            // flared section, starts 0.2 mm past the sleeve's end so it never sits in the silicone
            translate([0, sy * (horn_y + horn_flare / 2), 0]) rotate([90, 0, 0]) translate([0, 0, -(horn_t / 2 + horn_flare / 2 + grow)])
                linear_extrude(horn_t + horn_flare + 2 * grow) horn_profile(sx, grow, POCKET_L / 2 + 0.2);
        }
        translate([0, 0, -grow]) above_curve();
    }
}
module horns(grow = 0) { for (sx = [-1, 1], sy = [-1, 1]) horn(sx, sy, grow); }

module frame_part() {
    difference() {
        union() {
            intersection() {
                difference() {
                    rbox(POCKET_L - 2 * skin, POCKET_W - 2 * skin, max(POCKET_R - skin, 0.4), -10, frame_t);
                    rbox(BACK_WIN[0] + 2 * frame_clear, BACK_WIN[1] + 2 * frame_clear, 1.0 + frame_clear, -11, 11);
                }
                // flat top at frame_t (the Stick's back plane), curved underside: the ring
                // thickens toward the ends, so it prints upside down without supports
                above_curve();
            }
            horns();
        }
        for (sx = [-1, 1]) translate([sx * BAR_X, 0, BAR_Z]) rotate([90, 0, 0]) cylinder(d = bar_hole_d, h = 100, center = true, $fn = 16);
    }
}

// everything the silicone fills
module silicone() {
    difference() {
        pocket_body();
        // the core's back plane and the frame's top coincide; nudge the core so the
        // preview mesh stays a clean solid instead of growing zero-thickness slivers
        translate([0, 0, -0.02]) core_part();
        frame_part();
        horns(0.001);
    }
}

// ---- Mold halves -------------------------------------------------------------
module mold_bottom() {
    difference() {
        translate([0, 0, back_t - bottom_t]) linear_extrude(bottom_t) rrect(2 * MX, 2 * MY, 4);
        // tray: pocket outline down to the curved back surface (frame, core back pad and skin sit in it)
        intersection() { rbox(POCKET_L, POCKET_W, POCKET_R, -10, back_t + 1); above_curve(); }
        // horn slots, only outside the sleeve outline: inside it the tray floor already
        // follows the curve the horns sit on, and clearance there would let a film of
        // silicone creep under the horn roots
        // Horn slots with clearance, from 1.5 mm inside the sleeve's end outward. Inside
        // the outline the horns already rest on the curved tray floor; the slot only needs
        // to cover the rounded outline corners the horns pass through. (An exact-fit cut
        // would put coincident faces in the mesh; a 0.15 mm film under 1.5 mm of horn root
        // trims off in a second.)
        intersection() {
            horns(slot_clear);
            union() {
                translate([POCKET_L / 2 - 1.5, -50, -50]) cube([50, 100, 100]);
                translate([-POCKET_L / 2 + 1.5 - 50, -50, -50]) cube([50, 100, 100]);
            }
        }
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
        for (b = BOLTS) {
            translate([b[0], b[1], -10]) cylinder(d = bolt_d, h = 60);
            translate([b[0], b[1], back_t + TOP_H - bolt_head_pocket]) cylinder(d = 6.6, h = bolt_head_pocket + 1);
        }
        // vents from the top face down into the lip ring
        for (v = VENTS) translate([v[0], v[1], POCKET_T - 0.3]) cylinder(d = vent_d, h = top_floor + 1, $fn = 12);
        // side pour hole, low on the -y long side, with a funnel
        translate([SPRUE[0], -(POCKET_W / 2) + 0.3, SPRUE[1]]) rotate([90, 0, 0]) cylinder(d = sprue_d, h = MY);
        translate([SPRUE[0], -MY - eps, SPRUE[1]]) rotate([-90, 0, 0]) cylinder(d1 = sprue_d + 5, d2 = sprue_d, h = 2.5);
    }
    for (p = PINS) translate([p[0], p[1], back_t + eps]) mirror([0, 0, 1]) cylinder(d1 = 5, d2 = 4, h = 4);
}

if (part == "frame") translate([0, 0, back_t]) rotate([180, 0, 0]) frame_part();   // flat top face down
else if (part == "core") translate([0, 0, POCKET_W / 2]) rotate([90, 0, 0]) core_part();    // -y face down
else if (part == "mold_bottom") translate([0, 0, bottom_t - back_t]) mold_bottom();          // flat face down
else if (part == "mold_top") translate([0, 0, TOP_H + back_t]) rotate([180, 0, 0]) mold_top(); // parting face up
else silicone();
