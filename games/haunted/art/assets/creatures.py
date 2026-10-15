"""Creature roster (TASK-0043). Origins sit at the server Root, so hover heights are unchanged:
Wisp 4, Hound 2.2, Gentleman 4.5, Bell Wraith 6 studs above the ground (Config/Monsters).

The Wisp lives in assets/wisp.py (approved lantern-perch design, 2026-10-14).

References: MIN-013-015 (dragon anatomy), MIN-031 (versus the box hound), MIN-037-044 (antlered creature,
skeleton: tapered limbs, depth), MIN-048-053 (rat, zombie: shaped features held on side/rear views),
MIN-011/012 (focal face). Rejected: MODEL-BAD-006-012 (box hound, sparkles over weak form).
Animated parts carry rbx_pivot (joint) and a logical rbx_part name read by client/Art/Creatures.
"""

import math
import random

from mathutils import Vector

from hcart import anatomy as A
from hcart import core, paint, shapes
from hcart import palette as P

GROUND_HOUND = -2.2

FUR_A = paint.hex3("7a5338")  # main dog: rusty brown
FUR_A_LIGHT = paint.hex3("b08a66")
FUR_B = paint.hex3("6f6f78")  # second dog: ash grey
FUR_C = paint.hex3("2f2a2c")  # foreleg donor: near-black
FUR_D = paint.hex3("c9b9a0")  # grafted head: pale cream
LEATHER = paint.hex3("4a2a1e")
THREAD = paint.hex3("c9bd9a")
NOSE = paint.hex3("1c1618")
GUM = paint.hex3("6e2a33")
TOOTH = paint.hex3("e9e1c8")


def _hound_fur(c, n, o):
    """Patchwork by region: rusty front dog, grey hindquarters, black left foreleg, pale belly/muzzle."""
    x, y, z = c
    part = o.get("rbx_part", "")
    if part == "LegFL":
        return FUR_C
    if part in ("LegBL", "LegBR") or (part == "Body" and y > 0.75):
        base = FUR_B
    elif part == "Head2":
        base = FUR_D
    else:
        base = FUR_A
    if n.z < -0.55 and part in ("Body", "Head", "Jaw"):
        base = paint.mix(base, FUR_A_LIGHT, 0.55)
    if part in ("Head", "Jaw") and y < -2.55:
        base = paint.mix(base, FUR_A_LIGHT, 0.4)
    return base


def stitched_hound():
    G = GROUND_HOUND
    parts = []
    body = A.organic("Body", [
        A.ell((0, -0.7, 0.2), (1.0, 1.25, 1.35)),     # deep chest
        A.ell((0, 0.35, 0.28), (0.78, 1.0, 0.85)),    # waist, tucked
        A.ell((0, 1.25, 0.3), (0.95, 0.95, 1.05)),    # haunches
        A.ell((0, -1.55, 0.85), (0.6, 0.75, 0.85), rot=(-38, 0, 0)),  # neck
        A.ell((0.62, -0.85, -0.15), (0.42, 0.6, 0.85), rot=(0, 8, 0)),  # shoulders / upper arms
        A.ell((-0.62, -0.85, -0.15), (0.42, 0.6, 0.85), rot=(0, -8, 0)),
        A.ell((0.55, 1.3, -0.1), (0.48, 0.8, 0.9)),   # thighs
        A.ell((-0.55, 1.3, -0.1), (0.48, 0.8, 0.9)),
        A.ell((0, -0.5, 0.95), (0.45, 0.95, 0.4)),    # withers ridge
        A.ell((0, 0.55, -0.55), (0.6, 0.9, 0.45), negative=True, stiffness=1.2),  # belly tuck
    ], 1400, resolution=0.06, part="Body")
    parts.append(body)

    # Legs: shoulder/hip joint pivots; elbow and hock bends, paws with merged toe pads.
    def leg(name, x, y, hind, pivot_z):
        s = 1 if x > 0 else -1
        if hind:
            pts = [(x, y, pivot_z), (x + s * 0.04, y + 0.15, -0.55), (x + s * 0.03, y + 0.55, -1.05),
                   (x + s * 0.02, y + 0.42, -1.65), (x + s * 0.02, y + 0.3, G + 0.2)]
            radii = [0.36, 0.3, 0.17, 0.11, 0.1]
        else:
            pts = [(x, y, pivot_z), (x + s * 0.02, y + 0.12, -0.75), (x + s * 0.02, y + 0.02, -1.55),
                   (x + s * 0.02, y - 0.06, G + 0.2)]
            radii = [0.3, 0.19, 0.12, 0.1]
        l = A.limb(name + "Leg", pts, radii, 8, "Fabric")
        py = y + (0.3 if hind else -0.06)
        paw = A.organic(name + "Paw", [
            A.ell((x + s * 0.02, py - 0.12, G + 0.14), (0.24, 0.36, 0.2)),
            A.ell((x + s * 0.1, py - 0.36, G + 0.1), (0.1, 0.13, 0.1)),
            A.ell((x - s * 0.02, py - 0.4, G + 0.1), (0.1, 0.13, 0.1)),
            A.ell((x - s * 0.13, py - 0.34, G + 0.1), (0.09, 0.12, 0.09)),
        ], 150, resolution=0.03)
        obj = core.join([l, paw], name)
        core.tag(obj, "Fabric", part=name, pivot=(x, y, pivot_z))
        return obj

    parts.append(leg("LegFL", -0.5, -0.95, False, -0.2))
    parts.append(leg("LegFR", 0.5, -0.95, False, -0.2))
    parts.append(leg("LegBL", -0.5, 1.3, True, -0.1))
    parts.append(leg("LegBR", 0.5, 1.3, True, -0.1))

    # Main head: cranium, long muzzle, brow; the jaw is separate so it can snap.
    head = A.organic("Head", [
        A.ell((0, -2.05, 1.45), (0.68, 0.72, 0.66)),                    # cranium
        A.ell((0, -2.78, 1.27), (0.4, 0.8, 0.36), rot=(-8, 0, 0)),      # muzzle
        A.ell((0.28, -2.28, 1.78), (0.24, 0.38, 0.16), rot=(0, 15, 0)),  # brows
        A.ell((-0.28, -2.28, 1.78), (0.24, 0.38, 0.16), rot=(0, -15, 0)),
        A.ell((0.38, -1.95, 1.25), (0.3, 0.42, 0.42)),                  # cheeks
        A.ell((-0.38, -1.95, 1.25), (0.3, 0.42, 0.42)),
        A.ell((0.27, -2.5, 1.58), (0.16, 0.16, 0.14), negative=True, stiffness=1.5),  # eye sockets
        A.ell((-0.27, -2.5, 1.58), (0.16, 0.16, 0.14), negative=True, stiffness=1.5),
    ], 760, resolution=0.04, part="Head", pivot=(0, -1.6, 0.95))
    parts.append(head)
    nose = A.organic("Nose", [A.ell((0, -3.3, 1.38), (0.2, 0.16, 0.14))], 80, resolution=0.03, material="SmoothPlastic",
                     part="Head", lod=False)
    parts.append(nose)
    upper_teeth = A.teeth_row("TeethUp", (0, -3.02, 1.08), 0.5, 7, 0.16, True, 0.4, 0.04, part="Head", lod=False)
    core.transform(upper_teeth, (0, 0, 0), (0, 0, 0))
    parts.append(upper_teeth)
    jaw = A.organic("JawMesh", [
        A.ell((0, -2.65, 0.96), (0.34, 0.72, 0.17), rot=(10, 0, 0)),
        A.ell((0, -2.05, 1.02), (0.4, 0.42, 0.22)),
    ], 260, resolution=0.035, part="Jaw")
    low_teeth = A.teeth_row("TeethLow", (0, -2.95, 1.05), 0.44, 6, 0.12, False, 0.36, 0.035)
    jaw = core.join([jaw, low_teeth], "Jaw")
    core.tag(jaw, "Fabric", part="Jaw", pivot=(0, -1.95, 1.12))
    parts.append(jaw)
    # Eyes: one amber glowing eye, one black button with cross stitches.
    eye = shapes.sphere("EyeGlow", 0.12, (0.27, -2.57, 1.58), (1, 0.8, 0.9), 10, 6, "Neon", part="Head", lod=False)
    parts.append(eye)
    button = shapes.cylinder("Button", 0.16, 0.06, (-0.29, -2.6, 1.58), (90, 0, -25), 10, material="SmoothPlastic", part="Head",
                             lod=False)
    bx, by, bz = -0.29, -2.64, 1.58
    xs = [shapes.tube(f"X{k}", [(bx - 0.1 * d, by, bz - 0.1), (bx, by - 0.03, bz), (bx + 0.1 * d, by, bz + 0.1)], 0.022, 4, "Fabric")
          for k, d in enumerate((1, -1))]
    cross = core.join(xs, "ButtonStitch")
    core.tag(cross, "Fabric", part="Head", lod=False, detail=True)
    parts += [button, cross]
    # Ears: one pointed (main dog), one floppy torn ear.
    ear_r = A.limb("EarR", [(0.36, -1.9, 1.85), (0.48, -1.86, 2.2), (0.58, -1.8, 2.6)], [0.24, 0.16, 0.01], 6, flatten=0.3)
    core.tag(ear_r, "Fabric", part="EarR", pivot=(0.36, -1.9, 1.85))
    ear_l = A.limb("EarL", [(-0.36, -1.9, 1.85), (-0.62, -1.95, 1.9), (-0.8, -2.05, 1.62), (-0.84, -2.1, 1.28)], [0.22, 0.22, 0.17, 0.06],
                   6, flatten=0.28)
    core.tag(ear_l, "Fabric", part="EarL", pivot=(-0.36, -1.9, 1.85))
    parts += [ear_r, ear_l]

    # The grafted second head on the right shoulder: smaller, darker, snarling, its own pivot.
    h2 = A.organic("Head2Mesh", [
        A.ell((0.95, -1.15, 1.42), (0.48, 0.5, 0.45), rot=(0, 0, -30)),       # cranium
        A.ell((1.22, -1.72, 1.3), (0.27, 0.56, 0.25), rot=(-4, 0, -30)),      # muzzle
        A.ell((0.72, -0.85, 1.0), (0.4, 0.45, 0.5)),                          # neck stump into shoulder
        A.ell((1.2, -1.33, 1.58), (0.11, 0.11, 0.1), negative=True, stiffness=1.5),
        A.ell((0.85, -1.4, 1.62), (0.1, 0.1, 0.09), negative=True, stiffness=1.5),
    ], 400, resolution=0.035)
    h2_jaw = A.organic("H2Jaw", [A.ell((1.18, -1.65, 1.06), (0.22, 0.48, 0.1), rot=(14, 0, -30))], 140, resolution=0.03)
    h2_teeth = A.teeth_row("H2Teeth", (1.33, -1.98, 1.2), 0.26, 5, 0.12, True, 0.18, 0.032)
    core.transform(h2_teeth, rot=(0, 0, 0))
    h2_eye = shapes.sphere("H2Eye", 0.085, (1.2, -1.38, 1.58), (1, 1, 1), 8, 6, "Neon", part="Head2", lod=False)
    h2_eye2 = shapes.sphere("H2Eye2", 0.075, (0.85, -1.44, 1.62), (1, 1, 1), 8, 6, "Neon", part="Head2", lod=False)
    h2_ear = A.limb("H2Ear", [(1.1, -1.0, 1.78), (1.32, -0.92, 1.95), (1.55, -0.85, 1.9)], [0.15, 0.11, 0.01], 5, flatten=0.3)
    h2_nose = A.organic("H2Nose", [A.ell((1.38, -2.03, 1.33), (0.13, 0.1, 0.1))], 60, resolution=0.025, material="SmoothPlastic")
    head2 = core.join([h2, h2_jaw, h2_teeth, h2_ear, h2_nose], "Head2")
    core.tag(head2, "Fabric", part="Head2", pivot=(0.62, -0.85, 0.85))
    h2_eyes = core.join([h2_eye, h2_eye2], "Head2Eyes")
    core.tag(h2_eyes, "Neon", part="Head2", lod=False)
    parts += [head2, h2_eyes]
    h2_eye = h2_eyes

    # Bandaged tail.
    tail = A.limb("Tail", [(0, 1.95, 0.7), (0, 2.35, 1.05), (0, 2.75, 1.25), (0, 3.2, 1.2)], [0.26, 0.2, 0.13, 0.04], 7)
    core.tag(tail, "Fabric", part="Tail", pivot=(0, 1.9, 0.65))
    parts.append(tail)

    # Stitches along the patch seams, projected on the body surface.
    tree = A.surface_bvh([body])
    seams = []
    ring = [(2.0 * math.cos(a), 0.95 + 0.12 * math.sin(a * 2), 0.3 + 2.0 * math.sin(a)) for a in [i / 32 * math.tau for i in range(33)]]
    s1 = A.stitches("SeamHip", tree, ring, None, 26, length=0.2, radius=0.022, centre=(0, 0.95, 0.3), part="Body", lod=False, detail=True)
    s2 = None
    collar_pts = []
    for i in range(29):
        a = i / 28 * math.tau
        d = Vector((math.cos(a), 0.0, math.sin(a)))
        hit = A.project(tree, Vector((0, -1.62, 1.0)) + Vector((d.x, -0.55 * d.z, d.z)) * 2.5, -(Vector((d.x, -0.55 * d.z, d.z))))
        if hit:
            collar_pts.append(hit[0] + hit[1] * 0.06)
    collar = shapes.tube("Collar", collar_pts, 0.085, 6, "Fabric", cap_start=False, cap_end=False, flatten=0.55)
    core.tag(collar, "Fabric", part="Body", lod=False, detail=True)
    low = min(collar_pts, key=lambda q: q.z)
    tag = shapes.cylinder("Tag", 0.17, 0.05, (low.x, low.y - 0.08, low.z - 0.22), (90, 0, 0), 12, material="Metal", part="Body",
                          lod=False)
    ring_t = shapes.tube("TagRing", [(low.x + 0.06 * math.cos(a), low.y - 0.06, low.z - 0.05 + 0.06 * math.sin(a)) for a in
                                     [k / 8 * math.tau for k in range(9)]], 0.018, 4, "Metal", cap_start=False, cap_end=False)
    tagged = core.join([tag, ring_t], "CollarTag")
    core.tag(tagged, "Metal", part="Body", lod=False, detail=True)
    parts += [collar, tagged]
    back = [(0.15, y, 3.0) for y in (-1.2, -0.6, 0.0, 0.6)]
    s3 = A.stitches("SeamBack", tree, back, (0, 0, -1), 10, length=0.2, radius=0.022, part="Body", lod=False, detail=True)
    seams = [s for s in (s1, s2, s3) if s]
    stitch_obj = core.join(seams, "Stitches")
    core.tag(stitch_obj, "Fabric", part="Body", lod=False, detail=True)
    parts.append(stitch_obj)

    for o in parts:
        core.uv_box(o, 1.5)
    furry = [o for o in parts if o.get("rbx_material") == "Fabric" and o.name not in ("Stitches", "Collar")]
    paint.paint(furry + [stitch_obj, nose, upper_teeth], _hound_fur, ao=0.65, ao_distance=0.9, ground=G, edge=0.12, crease=0.35,
                mottle=0.12, mottle_scale=0.35, seed=11)
    paint.paint([stitch_obj], lambda c, n, o: THREAD, ao=0.3, ao_distance=0.5, ground=None, edge=0.1, mottle=0.05)
    paint.paint([nose], lambda c, n, o: NOSE, ao=0.3, ground=None, edge=0.4)
    paint.paint([collar], lambda c, n, o: LEATHER, ao=0.4, ao_distance=0.4, ground=None, edge=0.3, mottle=0.1, mottle_scale=0.2)
    paint.paint([tagged], lambda c, n, o: P.BRASS, ao=0.2, ground=None, edge=0.5)
    paint.paint([upper_teeth], lambda c, n, o: TOOTH, ao=0.4, ao_distance=0.3, ground=None, edge=0.2)

    def jaw_col(c, n, o):
        return TOOTH if n.z > 0.2 and c.z > 1.0 else _hound_fur(c, n, o)

    paint.paint([jaw], jaw_col, ao=0.55, ao_distance=0.5, ground=None, edge=0.1, mottle=0.1, mottle_scale=0.35)

    def h2_col(c, n, o):
        if c.y < -1.9 and c.z > 1.12 and c.z < 1.3 and abs(n.z) < 0.7:
            return TOOTH
        if c.y < -2.1:
            return NOSE
        if c.y < -1.6:
            return paint.mix(FUR_D, FUR_A, 0.35)
        return FUR_D

    paint.paint([head2], h2_col, ao=0.55, ao_distance=0.6, ground=None, edge=0.15, mottle=0.1, mottle_scale=0.3)
    paint.solid([eye], P.AMBER)
    paint.solid([h2_eyes], paint.hex3("ff4a3a"))
    paint.paint([button], lambda c, n, o: P.VOID, ao=0.2, ground=None, edge=0.15)
    paint.paint([cross], lambda c, n, o: THREAD, ao=0.1, ground=None, edge=0.1)
    ember = A.embers("Ember", [body, head], 26, seed=5, length=0.55)
    if ember:
        paint.solid([ember], P.EMBER)
    return {"Kind": "creature", "Species": "Hound", "LodDistance": 60}


# ---------------------------------------------------------------------------------------------------------
# ---------------------------------------------------------------------------------------------------------
COAT = paint.hex3("23202b")
COAT_EDGE = paint.hex3("3a3445")
VEST = paint.hex3("5a1f2b")
GLOVE = paint.hex3("ece7dc")
SILVER = paint.hex3("b9bcc4")


def hollow_gentleman():
    """Tall Victorian figure in a tailcoat with no head: a top hat floats above an empty collar.
    Origin = server Root (hover 4.5): shoes rest at -4.5."""
    G = -4.5
    # Tailored coat: an elliptical loft (width, depth per height), cut away in front below the waist.
    sections = [(-1.45, 1.02, 0.66), (-0.85, 0.94, 0.6), (-0.25, 0.7, 0.48), (0.35, 0.8, 0.52), (1.0, 1.05, 0.6), (1.55, 1.22, 0.62),
                (1.9, 1.18, 0.6), (2.12, 0.72, 0.48), (2.28, 0.5, 0.42)]
    torso = shapes.lathe("CoatBody", [(1.0, z) for z, _, _ in sections], 24, "Fabric", cap_bottom=False, cap_top=True)

    def tailor(v):
        z = v.z
        for i in range(len(sections) - 1):
            z0, w0, d0 = sections[i]
            z1, w1, d1 = sections[i + 1]
            if z0 <= z <= z1 + 1e-6:
                t = (z - z0) / (z1 - z0)
                w, d = w0 + (w1 - w0) * t, d0 + (d1 - d0) * t
                break
        else:
            w, d = sections[-1][1], sections[-1][2]
        x, y = v.x * w, v.y * d
        if y < 0 and z < -0.2:  # cut-away front skirt
            k = min(1.0, (-0.2 - z) / 1.0)
            y *= 1 - 0.75 * k
            x *= 1 - 0.15 * k
        return Vector((x, y, z))

    shapes.deform(torso, tailor)
    core.subdivide(torso, 1)
    core.smooth(torso, 180)
    tails = []
    for side in (-1, 1):
        t = A.limb(f"Tail{side}", [(0.3 * side, 0.45, -1.2), (0.42 * side, 0.68, -2.0), (0.5 * side, 0.85, -2.8), (0.46 * side, 0.98, -3.4)],
                   [0.44, 0.42, 0.36, 0.05], 8, "Fabric", flatten=0.22)
        tails.append(t)
    lapels = []
    for side in (-1, 1):
        lap = A.limb(f"Lapel{side}", [(0.12 * side, -0.62, 2.0), (0.38 * side, -0.66, 1.45), (0.3 * side, -0.62, 0.55)], [0.18, 0.2, 0.05], 6,
                     "Fabric", flatten=0.25)
        lapels.append(lap)
    coat = core.join([torso] + tails + lapels, "Coat")
    core.tag(coat, "Fabric", part="Body")
    collar = shapes.lathe("Collar", [(0.48, 2.05), (0.5, 2.3), (0.46, 2.55), (0.4, 2.6), (0.36, 2.35), (0.34, 2.1)], 16, "Fabric",
                          cap_bottom=False, cap_top=False, wobble=0.02, seed=2)
    core.transform(collar, (0, -0.12, 0))
    core.tag(collar, "Fabric", part="Body")
    void = shapes.lathe("Void", [(0.0, 2.15), (0.36, 2.18), (0.33, 2.28), (0.0, 2.3)], 16, "SmoothPlastic")
    core.transform(void, (0, -0.12, 0))
    core.tag(void, "SmoothPlastic", part="Body", lod=False)
    cravat = A.organic("Cravat", [A.ell((0, -0.5, 2.0), (0.22, 0.14, 0.2)), A.ell((0.1, -0.55, 1.75), (0.12, 0.1, 0.25), rot=(0, 15, 0)),
                                  A.ell((-0.1, -0.55, 1.72), (0.12, 0.1, 0.25), rot=(0, -15, 0))], 220, resolution=0.03,
                        material="Fabric", part="Body", lod=False)
    buttons = core.join([shapes.sphere(f"Btn{i}", 0.06, (0.02, -0.66, 1.3 - i * 0.3), (1, 0.6, 1), 8, 5, "Metal") for i in range(4)], "Buttons")
    core.tag(buttons, "Metal", part="Body", lod=False, detail=True)
    hat = shapes.lathe("Hat", [(0.0, 0.0), (0.82, 0.0), (0.86, 0.04), (0.78, 0.09), (0.5, 0.1), (0.48, 0.25), (0.5, 0.42), (0.47, 0.9),
                               (0.52, 1.22), (0.5, 1.28), (0.0, 1.29)], 18, "Fabric")
    band = shapes.lathe("Band", [(0.495, 0.22), (0.52, 0.24), (0.52, 0.42), (0.495, 0.44)], 18, "Fabric", cap_bottom=False, cap_top=False)
    hat = core.join([hat, band], "Hat")
    core.transform(hat, (0, 0.0, 3.35), (-6, 8, 0))
    core.tag(hat, "Fabric", part="Hat", pivot=(0, 0, 3.4))
    legs = []
    for side, name in ((-1, "LegL"), (1, "LegR")):
        leg = A.limb(name + "Mesh", [(0.32 * side, 0.08, -1.0), (0.3 * side, 0.02, -2.6), (0.28 * side, 0.08, -4.15)], [0.25, 0.18, 0.14], 8, "Fabric")
        shoe = A.organic(name + "Shoe", [A.ell((0.28 * side, -0.2, G + 0.17), (0.22, 0.5, 0.18)), A.ell((0.28 * side, -0.62, G + 0.1), (0.1, 0.25, 0.08))],
                         180, resolution=0.03, material="SmoothPlastic")
        lg = core.join([leg, shoe], name)
        core.tag(lg, "Fabric", part=name, pivot=(0.3 * side, 0.05, -0.9))
        legs.append(lg)
    arms = []
    for side, name in ((-1, "ArmL"), (1, "ArmR")):
        sx = side
        hand_z = -1.55
        if side < 0:  # left arm: elbow out, gloved hand raised in a slow beckon
            sleeve = A.limb(name + "Sleeve", [(-1.18, 0.1, 1.85), (-1.5, 0.2, 0.75), (-1.45, -0.5, 0.15), (-1.25, -1.05, 0.4)],
                            [0.32, 0.26, 0.21, 0.23], 8, "Fabric")
        else:
            sleeve = A.limb(name + "Sleeve", [(1.18, 0.1, 1.85), (1.38, 0.15, 0.7), (1.3, -0.05, -0.35), (1.12, -0.22, -1.1)],
                            [0.32, 0.26, 0.21, 0.23], 8, "Fabric")
        cuff = shapes.lathe(name + "Cuff", [(0.2, 0), (0.23, 0.02), (0.23, 0.2), (0.19, 0.22)], 10, "Fabric", cap_bottom=False, cap_top=False)
        core.transform(cuff, (1.08 * sx, -0.24, -1.33))
        if side < 0:
            core.transform(cuff, (0, 0, 0), (0, 0, 0))
            for v in cuff.data.vertices:
                v.co = v.co - Vector((-1.08, -0.24, -1.33))
            cuff.rotation_euler = (math.radians(-70), 0, 0)
            cuff.location = (-1.25, -1.05, 0.4)
            core.apply_transform(cuff)
        palm = A.organic(name + "Palm", [A.ell((1.08 * sx, -0.26, hand_z + 0.1), (0.17, 0.11, 0.2))], 100, resolution=0.025, material="Fabric")
        fingers = []
        for f in range(4):
            fx = 1.08 * sx + (f - 1.5) * 0.08 * sx
            fingers.append(A.limb(f"{name}F{f}", [(fx, -0.27, hand_z - 0.02), (fx + 0.01 * sx, -0.32, hand_z - 0.35 - 0.06 * (f % 2)),
                                                   (fx + 0.02 * sx, -0.4, hand_z - 0.62 - 0.05 * (f % 2))], [0.045, 0.04, 0.03], 5, "Fabric", resample=2))
        thumb = A.limb(f"{name}Th", [(1.0 * sx, -0.3, hand_z + 0.05), (0.94 * sx, -0.45, hand_z - 0.15), (0.92 * sx, -0.52, hand_z - 0.32)],
                       [0.045, 0.04, 0.03], 5, "Fabric", resample=2)
        glove = core.join([palm, thumb] + fingers, name + "Glove")
        core.tag(glove, "Fabric", part=name)
        if side < 0:  # move the left hand up to the raised cuff, palm forward, fingers curled up
            for v in glove.data.vertices:
                v.co = v.co - Vector((-1.08, -0.26, hand_z + 0.1))
            glove.rotation_euler = (math.radians(-115), 0, math.radians(10))
            glove.location = (-1.24, -1.25, 0.55)
            core.apply_transform(glove)
        arm = core.join([sleeve, cuff], name)
        core.tag(arm, "Fabric", part=name, pivot=(1.18 * sx, 0.1, 1.85))
        arms.append((arm, glove))
    cane = A.limb("CaneShaft", [(1.16, -0.45, -1.3), (1.2, -0.55, -2.9), (1.24, -0.62, G + 0.05)], [0.05, 0.045, 0.04], 6, "Wood", resample=0)
    skull = A.organic("CaneSkull", [A.ell((1.15, -0.42, -1.18), (0.16, 0.16, 0.15)), A.ell((1.15, -0.53, -1.27), (0.1, 0.08, 0.07)),
                                    A.ell((1.09, -0.55, -1.15), (0.04, 0.03, 0.04), negative=True, stiffness=1.2),
                                    A.ell((1.21, -0.55, -1.15), (0.04, 0.03, 0.04), negative=True, stiffness=1.2)], 160, resolution=0.018,
                        material="Metal")
    cane = core.join([cane, skull], "Cane")
    core.tag(cane, "Metal", part="ArmR")
    parts = [coat, collar, void, cravat, buttons, hat] + legs + [a for pair in arms for a in pair] + [cane]
    for o in parts:
        if o.get("rbx_part") not in ("LegL", "LegR"):
            o.rotation_euler = (math.radians(-7), 0, 0)  # unsettling forward lean from the hips
            o.location = (0, -0.05, -0.9 * math.sin(math.radians(7)))
            core.apply_transform(o)
            if "rbx_pivot" in o.keys():
                pv = Vector(o["rbx_pivot"])
                from mathutils import Matrix
                pv = Matrix.Rotation(math.radians(-7), 3, "X") @ pv + Vector((0, -0.05, -0.9 * math.sin(math.radians(7))))
                o["rbx_pivot"] = tuple(pv)
    for o in parts:
        core.uv_box(o, 1.5)

    def suit(c, n, o):
        part = o.get("rbx_part", "")
        if o.name in ("Collar", "Cravat"):
            return P.CLOTH_WHITE
        if o.name.endswith("Glove"):
            return GLOVE
        if o.name == "Hat":
            return VEST if 3.5 < c.z < 3.85 else COAT
        if part == "Body" and n.y < -0.35 and abs(c.x) < 0.32 and 0.0 < c.z < 1.85:
            return VEST
        if part.startswith("Leg") and c.z < -4.1:
            return paint.hex3("151318")
        return COAT

    paint.paint(parts, suit, ao=0.55, ao_distance=1.0, ground=G, edge=0.18, crease=0.3, mottle=0.06, mottle_scale=0.5, seed=4)
    paint.paint([cane], lambda c, n, o: SILVER if c.z > -1.4 else P.WOOD_DARK, ao=0.3, ground=None, edge=0.4)
    paint.paint([buttons], lambda c, n, o: P.BRASS, ao=0.1, ground=None, edge=0.5)
    paint.solid([void], P.VOID)
    ember = A.embers("Ember", [coat], 22, seed=9, length=0.6)
    if ember:
        paint.solid([ember], P.EMBER)
    return {"Kind": "creature", "Species": "Gentleman", "LodDistance": 70}


# ---------------------------------------------------------------------------------------------------------
BELL = paint.hex3("9a6a32")
BELL_HI = paint.hex3("d1a45a")
PATINA = paint.hex3("4f8a78")


def bell_wraith():
    """A cracked funeral bell that rings itself: patinated bronze bell head with a glowing crack and eyes,
    a clapper heart, tattered shroud ribbons and skeletal arms. Origin = server Root (hover 6)."""
    rng = random.Random(21)
    prof = [(1.75, -1.0), (1.82, -0.92), (1.78, -0.82), (1.55, -0.6), (1.32, -0.2), (1.22, 0.3), (1.18, 0.9), (1.2, 1.25),
            (1.12, 1.55), (0.95, 1.8), (0.6, 1.98), (0.0, 2.02)]
    outer = shapes.lathe("BellOuter", prof, 28, "Metal", cap_bottom=False)
    inner = shapes.lathe("BellInner", [(r - 0.14, z) for r, z in prof[:-2]] + [(0.5, 1.82), (0.0, 1.86)], 28, "Metal", cap_bottom=False)
    for p in inner.data.polygons:
        p.flip()
    rim = shapes.lathe("Rim", [(1.66, -1.0), (1.82, -1.0)], 28, "Metal", cap_bottom=False, cap_top=False)
    bands = [shapes.lathe(f"Band{i}", [(r - 0.01, z - 0.05), (r + 0.06, z - 0.03), (r + 0.06, z + 0.03), (r - 0.01, z + 0.05)], 28, "Metal",
                          cap_bottom=False, cap_top=False) for i, (r, z) in enumerate([(1.31, -0.18), (1.2, 1.2)])]
    loop = shapes.tube("Crown", [(0.38 * math.cos(a), 0, 2.4 + 0.38 * math.sin(a)) for a in [k / 14 * math.tau for k in range(15)]], 0.12, 8,
                       "Metal", cap_start=False, cap_end=False)
    bell = core.join([outer, inner, rim, loop] + bands, "Bell")
    core.tag(bell, "Metal", part="Body")
    yoke = shapes.box("Yoke", (2.0, 0.32, 0.32), (0.25, 0, 2.85), (0, 8, 0), bevel=0.05)
    splinter = A.cone("Splinter", (1.2, 0, 2.95), (1.65, 0.05, 3.05), 0.13, 5, "Wood")
    yoke = core.join([yoke, splinter], "Yoke")
    core.tag(yoke, "Wood", part="Body")
    # Glowing crack and eye slits laid on the bell's front (-Y) surface.
    tree = A.surface_bvh([outer])
    crack_pts = []
    x, z = 0.15, 1.75
    for i in range(9):
        hit = A.project(tree, Vector((x, -3, z)), Vector((0, 1, 0)))
        if hit:
            crack_pts.append(hit[0] + hit[1] * 0.02)
        x += (rng.random() - 0.5) * 0.35
        z -= 0.33
    crack = shapes.tube("Crack", crack_pts, lambda t: 0.07 * (1 - 0.6 * t) + 0.02, 4, "Neon", flatten=0.3)
    eyes = []
    for side in (-1, 1):
        pts = []
        for i in range(5):
            t = i / 4
            hit = A.project(tree, Vector((side * (0.35 + 0.35 * t), -3, 0.75 - 0.18 * math.sin(t * math.pi) - 0.08 * t)), Vector((0, 1, 0)))
            if hit:
                pts.append(hit[0] + hit[1] * 0.02)
        eyes.append(shapes.tube(f"Eye{side}", pts, lambda t: 0.11 * math.sin(t * math.pi) + 0.02, 5, "Neon", flatten=0.4))
    glow = core.join([crack] + eyes, "Glow")
    core.tag(glow, "Neon", part="Body", lod=False)
    clapper = A.organic("Clapper", [A.ell((0, 0, -0.95), (0.42, 0.42, 0.5)), A.ell((0, -0.12, -1.25), (0.22, 0.2, 0.18))], 300,
                        resolution=0.03, material="Neon", part="Clapper", pivot=(0, 0, 1.6))
    chain = shapes.tube("ClapperRod", [(0, 0, 1.6), (0, 0, -0.5)], 0.06, 6, "Metal")
    core.tag(chain, "Metal", part="Clapper", pivot=(0, 0, 1.6))
    # Shroud: an inner ragged skirt and long torn ribbons hanging from under the lip.
    skirt = shapes.lathe("Skirt", [(1.62, -0.95), (1.6, -1.6), (1.62, -2.4), (1.75, -3.2), (1.95, -3.9), (2.05, -4.3)], 26, "Fabric",
                         cap_bottom=False, cap_top=False, wobble=0.16, seed=4)
    for v in skirt.data.vertices:
        ang = math.atan2(v.co.y, v.co.x)
        f = 1 + 0.09 * math.sin(ang * 9 + v.co.z * 0.7) * min(1.0, (-0.95 - v.co.z) / 1.2)
        v.co.x *= f
        v.co.y *= f
    # Ragged hem: push alternating bottom vertices down into torn points.
    for v in skirt.data.vertices:
        if v.co.z < -4.2:
            ang = math.atan2(v.co.y, v.co.x)
            v.co.z -= 0.55 * max(0.0, math.sin(ang * 7)) + 0.25 * max(0.0, math.sin(ang * 13 + 1))
    for p in skirt.data.polygons:
        p.flip()
    core.tag(skirt, "Fabric", part="Body", alpha=0.0)
    ribbons = []
    for k in range(8):
        a = k / 8 * math.tau + rng.random() * 0.35
        r0 = 1.72
        length = 3.4 + rng.random() * 1.8
        pts = []
        for i in range(6):
            t = i / 5
            rr = r0 + 0.45 * t + 0.12 * math.sin(t * 3 + k)
            pts.append((math.cos(a) * rr + 0.25 * math.sin(t * 4 + k), math.sin(a) * rr, -0.95 - t * length))
        rb = A.limb(f"Ribbon{k}", pts, lambda t: 0.5 * (1 - 0.7 * t) + 0.03, 6, "Fabric", flatten=0.12)
        rot = math.degrees(a)
        core.tag(rb, "Fabric", part=f"Ribbon{k % 4}", pivot=(math.cos(a) * r0, math.sin(a) * r0, -0.9))
        ribbons.append(rb)
    arms = []
    for side, name in ((-1, "ArmL"), (1, "ArmR")):
        sx = side
        bones = [A.limb(name + "Up", [(1.35 * sx, -0.2, -0.7), (2.25 * sx, -0.7, -1.7)], [0.14, 0.1], 6, "SmoothPlastic", resample=0),
                 A.limb(name + "Fore", [(2.25 * sx, -0.7, -1.7), (2.2 * sx, -1.75, -1.9)], [0.1, 0.08], 6, "SmoothPlastic", resample=0),
                 A.organic(name + "Joint", [A.ball((2.25 * sx, -0.7, -1.7), 0.22), A.ell((2.2 * sx, -1.85, -1.92), (0.16, 0.14, 0.08))], 120,
                           resolution=0.03, material="SmoothPlastic")]
        for f in range(4):
            spread = (f - 1.5) * 0.14
            bones.append(A.limb(f"{name}F{f}", [(2.2 * sx + spread * 0.6 * sx, -1.95, -1.92), (2.2 * sx + spread * sx, -2.3, -2.0 + spread * 0.4),
                                                (2.18 * sx + spread * sx * 1.3, -2.5, -2.35 + spread * 0.5)], [0.05, 0.042, 0.022], 5,
                                "SmoothPlastic", resample=2))
        arm = core.join(bones, name)
        core.tag(arm, "SmoothPlastic", part=name, pivot=(1.25 * sx, -0.2, -0.6))
        arms.append(arm)
    parts = [bell, yoke, skirt, chain] + ribbons + arms
    for o in parts:
        core.uv_box(o, 1.5)

    def bronze(c, n, o):
        if o.name == "Yoke":
            return P.WOOD_GREY
        if o.name == "ClapperRod":
            return P.IRON
        t = max(0.0, min(1.0, (c.z + 1.0) / 3.0))
        return paint.mix(BELL, BELL_HI, 0.35 * t)

    paint.paint([bell, yoke, chain], bronze, ao=0.6, ao_distance=1.0, ground=None, edge=0.35, crease=0.5, mottle=0.12, mottle_scale=0.5,
                seed=8)
    # Patina in the creases: re-tint dark corners teal.
    me = bell.data
    col = me.color_attributes["Col"]
    for li in range(len(col.data)):
        c = col.data[li].color_srgb
        lum = (c[0] + c[1] + c[2]) / 3
        if lum < 0.32:
            k = min(1.0, (0.32 - lum) * 4)
            m = paint.mix((c[0], c[1], c[2]), PATINA, k * 0.7)
            col.data[li].color_srgb = (m[0], m[1], m[2], 1)
    paint.paint([skirt] + ribbons, lambda c, n, o: paint.mix(P.SHROUD, P.FABRIC_DARK, max(0.0, min(1.0, -(c.z + 1) / 4))), ao=0.5,
                ao_distance=0.8, ground=None, edge=0.1, mottle=0.12, mottle_scale=0.6, seed=2)
    paint.paint(arms, lambda c, n, o: P.BONE, ao=0.4, ao_distance=0.4, ground=None, edge=0.3, crease=0.3, mottle=0.05)
    paint.solid([glow], paint.hex3("ffcf6a"))
    paint.solid([clapper], paint.hex3("ffb84a"))
    ember = A.embers("Ember", [outer], 18, seed=12, length=0.6)
    if ember:
        paint.solid([ember], P.EMBER)
    return {"Kind": "creature", "Species": "BellWraith", "LodDistance": 80}


ASSETS = {"creature_hound": stitched_hound, "creature_gentleman": hollow_gentleman,
          "creature_bellwraith": bell_wraith}
