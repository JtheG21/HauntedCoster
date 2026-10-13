"""Creature roster (TASK-0043). Origins sit at the server Root, so hover heights are unchanged:
Wisp 4, Hound 2.2, Gentleman 4.5, Bell Wraith 6 studs above the ground (Config/Monsters).

References: MIN-013-015 (dragon anatomy), MIN-031 (versus the box hound), MIN-037-044 (antlered creature,
skeleton: tapered limbs, depth), MIN-048-053 (rat, zombie: shaped features held on side/rear views),
MIN-011/012 (focal face). Rejected: MODEL-BAD-006-012 (box hound, sparkles over weak form).
Animated parts carry rbx_pivot (joint) and a logical rbx_part name read by client/Art/Creatures.
"""

import math

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
    core.tag(cross, "Fabric", part="Head", lod=False)
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
    s1 = A.stitches("SeamHip", tree, ring, None, 26, length=0.2, radius=0.022, centre=(0, 0.95, 0.3), part="Body", lod=False)
    s2 = None
    collar_pts = []
    for i in range(29):
        a = i / 28 * math.tau
        d = Vector((math.cos(a), 0.0, math.sin(a)))
        hit = A.project(tree, Vector((0, -1.62, 1.0)) + Vector((d.x, -0.55 * d.z, d.z)) * 2.5, -(Vector((d.x, -0.55 * d.z, d.z))))
        if hit:
            collar_pts.append(hit[0] + hit[1] * 0.06)
    collar = shapes.tube("Collar", collar_pts, 0.085, 6, "Fabric", cap_start=False, cap_end=False, flatten=0.55)
    core.tag(collar, "Fabric", part="Body", lod=False)
    low = min(collar_pts, key=lambda q: q.z)
    tag = shapes.cylinder("Tag", 0.17, 0.05, (low.x, low.y - 0.08, low.z - 0.22), (90, 0, 0), 12, material="Metal", part="Body",
                          lod=False)
    ring_t = shapes.tube("TagRing", [(low.x + 0.06 * math.cos(a), low.y - 0.06, low.z - 0.05 + 0.06 * math.sin(a)) for a in
                                     [k / 8 * math.tau for k in range(9)]], 0.018, 4, "Metal", cap_start=False, cap_end=False)
    tagged = core.join([tag, ring_t], "CollarTag")
    core.tag(tagged, "Metal", part="Body", lod=False)
    parts += [collar, tagged]
    back = [(0.15, y, 3.0) for y in (-1.2, -0.6, 0.0, 0.6)]
    s3 = A.stitches("SeamBack", tree, back, (0, 0, -1), 10, length=0.2, radius=0.022, part="Body", lod=False)
    seams = [s for s in (s1, s2, s3) if s]
    stitch_obj = core.join(seams, "Stitches")
    core.tag(stitch_obj, "Fabric", part="Body", lod=False)
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
    return {"Kind": "creature", "Species": "Hound", "LodDistance": 60}


ASSETS = {"creature_hound": stitched_hound}
