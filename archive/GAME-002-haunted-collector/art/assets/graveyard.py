"""Graveyard kit (TASK-0044): graves, pumpkins, candles, iron fencing, gate, ruined wall, edge stones.

References: MODEL-MIN-068 (graveyard pack: headstones, coffins, mounds), MIN-069 (architecture: pillars, iron
fencing, gates), MIN-063 (carved pumpkins), MIN-064 (candles). Rejected: MODEL-BAD-017 family (bare boxes).
Footprints match the server colliders in server/World/Props.luau.
"""

import math
import random

from mathutils import Vector, noise

from hcart import core, paint, shapes
from hcart import palette as P

STONE = P.STONE
STONE_D = P.STONE_DARK
CARVE = paint.hex3("3e3c44")
DIRT = paint.hex3("4a3a2e")
WAX = paint.hex3("ece2c6")
WAX_D = paint.hex3("c9b994")


def _stone_col(c, n, o):
    k = 0.5 + 0.5 * noise.noise(Vector((c.x * 1.3, c.y * 1.3, c.z * 1.3)) + Vector((o.get("seed", 0), 0, 0)))
    col = paint.mix(STONE, STONE_D, 0.25 + 0.35 * k)
    if n.z > 0.6:
        col = paint.mix(col, P.LICHEN, 0.35 * min(1.0, (n.z - 0.6) * 3))
    if c.z < 0.35:
        col = paint.mix(col, P.MOSS_DARK, 0.45 * (1 - c.z / 0.35))
    return col


def _chip(obj, amount=0.05, scale=0.35, seed=0):
    core.displace_noise(obj, amount, scale, seed)


def _finish_stone(objs, seed=0, angle=40, studs=2.0):
    for o in objs:
        o["seed"] = seed
        core.uv_box(o, studs, seed)
        core.smooth(o, angle)
    paint.paint(objs, _stone_col, ao=0.6, ao_distance=1.0, ground=0.0, edge=0.35, crease=0.5, mottle=0.1, mottle_scale=0.4, seed=seed)


def _engrave(obj, centre, half_w, half_h, depth, front_y):
    """Pushes front-facing vertices inside a rectangle back (a carved relief)."""
    for v in obj.data.vertices:
        if v.co.y < front_y + 0.02 and abs(v.co.x - centre[0]) < half_w and abs(v.co.z - centre[1]) < half_h:
            v.co.y += depth


def grave_headstone():
    slab = shapes.box("Stone", (2.3, 0.55, 2.4), (0, 0, 1.55), bevel=0.06, segments=2, material="Slate")
    core.subdivide(slab, 2, simple=True)
    # Round the top into an arch with shoulders.
    for v in slab.data.vertices:
        if v.co.z > 2.1:
            x = v.co.x / 1.15
            v.co.z = 2.1 + (v.co.z - 2.1) * 0.2 + 0.75 * math.sqrt(max(0.0, 1 - min(1.0, abs(x)) ** 2.2))
    _chip(slab, 0.04, 0.3, 3)
    _engrave(slab, (0, 2.35), 0.1, 0.42, 0.06, -0.27)
    _engrave(slab, (0, 2.45), 0.32, 0.08, 0.06, -0.27)
    for i, z in enumerate((1.45, 1.2, 0.95)):
        _engrave(slab, (0, z), 0.75 - i * 0.12, 0.04, 0.035, -0.27)
    base = shapes.box("Base", (2.7, 0.9, 0.5), (0, 0, 0.25), bevel=0.05, material="Slate")
    _chip(base, 0.04, 0.3, 4)
    # Raised moulded border following the arch.
    border = []
    for i in range(25):
        t = i / 24
        a = math.pi * t
        border.append((-math.cos(a) * 0.92, -0.3, 2.15 + 0.62 * math.sin(a)))
    frame = shapes.tube("Frame", [(-0.92, -0.3, 0.75)] + border + [(0.92, -0.3, 0.75)], 0.06, 5, "Slate", flatten=0.6)
    obj = core.join([slab, base, frame], "Stone")
    core.tag(obj, "Slate")
    _finish_stone([obj], 1)
    # Carved cross and epitaph lines as dark inlays just proud of the face.
    inlay = [shapes.box("CrossV", (0.14, 0.04, 0.7), (0, -0.295, 2.25)), shapes.box("CrossH", (0.46, 0.04, 0.13), (0, -0.295, 2.38))]
    for i, (z, w) in enumerate(((1.62, 1.2), (1.4, 0.95), (1.18, 1.05), (0.96, 0.7))):
        inlay.append(shapes.box(f"Line{i}", (w, 0.04, 0.07), (0, -0.295, z)))
    carve = core.join(inlay, "Carving")
    core.tag(carve, "Slate", part="Stone", lod=False, detail=True)
    paint.solid([carve], CARVE)
    return {"Kind": "prop", "LodDistance": 70}


def _darken_relief(obj, front_y):
    me = obj.data
    col = me.color_attributes["Col"]
    for li, loop in enumerate(me.loops):
        v = me.vertices[loop.vertex_index]
        if v.co.y > front_y and v.co.y < 0.0 and abs(v.normal.y) > 0.5 and v.co.z > 0.6:
            c = col.data[li].color_srgb
            m = paint.mix((c[0], c[1], c[2]), CARVE, 0.6)
            col.data[li].color_srgb = (m[0], m[1], m[2], 1)


def grave_cross():
    post = shapes.box("Post", (0.55, 0.5, 3.6), (0, 0, 2.2), bevel=0.05, material="Slate")
    arm = shapes.box("Arm", (2.3, 0.5, 0.55), (0, 0, 3.05), bevel=0.05, material="Slate")
    ring = shapes.tube("Ring", [(0.62 * math.cos(a), 0, 3.05 + 0.62 * math.sin(a)) for a in [k / 24 * math.tau for k in range(25)]], 0.1, 6,
                       "Slate", cap_start=False, cap_end=False, flatten=1.6)
    base = shapes.lathe("Base", [(0.0, 0.0), (1.0, 0.0), (1.0, 0.25), (0.75, 0.32), (0.7, 0.55), (0.45, 0.6), (0.0, 0.6)], 4, "Slate")
    core.transform(base, rot=(0, 0, 45))
    for o in (post, arm):
        core.subdivide(o, 1, simple=True)
        _chip(o, 0.035, 0.25, 5)
    obj = core.join([post, arm, ring, base], "Stone")
    core.tag(obj, "Slate")
    _finish_stone([obj], 2, angle=35)
    return {"Kind": "prop", "LodDistance": 70}


def grave_obelisk():
    steps = shapes.lathe("Steps", [(0.0, 0.0), (1.3, 0.0), (1.3, 0.3), (1.1, 0.3), (1.1, 0.6), (0.95, 0.6), (0.95, 0.75), (0.0, 0.75)], 4,
                         "Marble")
    shaft = shapes.lathe("Shaft", [(0.82, 0.75), (0.82, 0.95), (0.72, 1.0), (0.6, 4.55), (0.66, 4.62), (0.0, 5.55)], 4, "Marble",
                         cap_bottom=False)
    for o in (steps, shaft):
        core.transform(o, rot=(0, 0, 45))
    core.subdivide(shaft, 1, simple=True)
    _chip(shaft, 0.02, 0.3, 6)
    _engrave(shaft, (0, 2.3), 0.22, 0.7, 0.04, -0.3)
    obj = core.join([steps, shaft], "Stone")
    core.tag(obj, "Marble")
    for o in [obj]:
        o["seed"] = 3
        core.uv_box(o, 2.0)
        core.smooth(o, 30)
    paint.paint([obj], lambda c, n, o: paint.mix(P.MARBLE, P.STONE, 0.15 + (0.3 if c.z < 0.4 else 0.0)), ao=0.6, ao_distance=1.0, ground=0.0,
                edge=0.3, crease=0.5, mottle=0.08, mottle_scale=0.6)
    return {"Kind": "prop", "LodDistance": 80}


def grave_leaning():
    slab = shapes.box("Stone", (2.1, 0.45, 2.5), (0, 0, 1.25), bevel=0.05, material="Slate")
    core.subdivide(slab, 2, simple=True)
    rng = random.Random(3)
    for v in slab.data.vertices:  # broken, jagged top edge
        if v.co.z > 2.2:
            v.co.z -= 0.55 * max(0.0, math.sin(v.co.x * 2.4 + 1)) + 0.15 * rng.random()
    _chip(slab, 0.05, 0.3, 7)
    crack = []
    x, z = -0.3, 2.3
    for i in range(6):
        crack.append((x, -0.24, z))
        x += rng.uniform(-0.25, 0.3)
        z -= 0.35
    crack_obj = shapes.tube("Crack", crack, 0.03, 3, "Slate", flatten=0.4)
    obj = core.join([slab], "Stone")
    core.tag(obj, "Slate")
    _finish_stone([obj], 4)
    core.tag(crack_obj, "Slate", lod=False, detail=True)
    paint.solid([crack_obj], CARVE)
    return {"Kind": "prop", "LodDistance": 70}


def grave_mound():
    mound = shapes.sphere("Mound", 1.0, (0, 0, 0), (1.25, 2.45, 0.32), 16, 10, "Ground")
    for v in mound.data.vertices:
        if v.co.z < 0:
            v.co.z = 0
        v.co.z += 0.05 * noise.noise(v.co * 2)
    core.uv_box(mound, 3.0)
    core.smooth(mound, 60)
    stones = [shapes.sphere(f"Pebble{i}", 0.12 + 0.06 * (i % 3), (math.cos(i * 1.7) * 1.15, math.sin(i * 2.3) * 2.3, 0.08), (1.2, 1, 0.6), 6, 4,
                            "Slate") for i in range(6)]
    peb = core.join(stones, "Pebbles")
    core.tag(peb, "Slate", lod=False, detail=True)
    paint.paint([mound], lambda c, n, o: paint.mix(DIRT, P.MOSS_DARK, 0.25 + 0.25 * noise.noise(c * 1.5)), ao=0.4, ground=0.0, edge=0.1, mottle=0.12)
    paint.paint([peb], lambda c, n, o: STONE_D, ao=0.3, ground=0.0, edge=0.3)
    return {"Kind": "prop", "LodDistance": 60}


def pumpkin(lit):
    def make():
        lobes = 9
        prof = []
        for i in range(13):
            t = i / 12
            a = math.pi * (t - 0.5)
            prof.append((math.cos(a) * 1.0, 0.82 * (math.sin(a) + 1) * 0.6))
        body = shapes.lathe("Body", [(max(0.02, r), z) for r, z in prof], 36, "SmoothPlastic", cap_bottom=True, cap_top=True)
        for v in body.data.vertices:
            a = math.atan2(v.co.y, v.co.x)
            k = 1 - 0.09 * (0.5 - 0.5 * math.cos(a * lobes)) ** 0.6
            v.co.x *= k
            v.co.y *= k
            if v.co.z > 0.9:
                v.co.z -= 0.18 * (1 - math.hypot(v.co.x, v.co.y))
        core.subdivide(body, 1)
        # Carved face on the front (-Y): triangle eyes and a jagged grin pushed inward.
        face_holes = []
        for v in body.data.vertices:
            if v.co.y > -0.45:
                continue
            x, z = v.co.x, v.co.z
            hole = False
            for ex in (-0.33, 0.33):
                if z > 0.62 and z < 0.92 and abs(x - ex) < 0.2 * (0.92 - z) / 0.3 + 0.02:
                    hole = True
            if 0.25 < z < 0.52 and abs(x) < 0.55:
                teeth = 0.06 * math.cos(x * 22)
                if 0.32 + teeth < z < 0.48 - abs(x) * 0.12 - teeth:
                    hole = True
            if hole:
                v.co.y *= 0.72
                face_holes.append(v.index)
        core.smooth(body, 60)
        stem = shapes.tube("Stem", [(0, 0, 0.88), (0.05, 0.02, 1.15), (0.2, 0.05, 1.32)], lambda t: 0.12 * (1 - 0.4 * t), 6, "Wood", resample=2)
        inner = shapes.sphere("Glow", 0.55, (0, 0.05, 0.48), (1, 1, 0.7), 12, 8, "Neon" if lit else "SmoothPlastic", lod=False)
        core.uv_box(stem, 1.0)
        holes = set(face_holes)

        def col(c, n, o):
            return paint.mix(P.PUMPKIN, P.PUMPKIN_DARK, 0.35)

        paint.paint([body], col, ao=0.5, ao_distance=0.6, ground=0.0, edge=0.25, crease=0.6, mottle=0.08, mottle_scale=0.3)
        me = body.data
        cattr = me.color_attributes["Col"]
        for li, loop in enumerate(me.loops):
            if loop.vertex_index in holes:
                c = (1.0, 0.75, 0.3) if lit else (0.08, 0.05, 0.03)
                cattr.data[li].color_srgb = (c[0], c[1], c[2], 1)
        paint.paint([stem], lambda c, n, o: P.STEM, ao=0.3, ground=None, edge=0.3)
        paint.solid([inner], (1.0, 0.72, 0.28) if lit else (0.1, 0.06, 0.04))
        body.data.update()
        return {"Kind": "prop", "LodDistance": 60, "Nominal": 2.0}
    return make


def candles():
    rng = random.Random(8)
    parts, flames = [], []
    pool = shapes.lathe("Pool", [(0.0, 0.0), (0.75, 0.0), (0.7, 0.05), (0.3, 0.09), (0.0, 0.1)], 14, "SmoothPlastic", wobble=0.15, seed=2)
    parts.append(pool)
    for i, (x, y, h) in enumerate(((0.0, 0.0, 1.3), (0.38, 0.2, 0.85), (-0.3, 0.28, 0.6), (0.15, -0.35, 0.45))):
        c = shapes.lathe(f"Candle{i}", [(0.15, 0.0), (0.15, h - 0.08), (0.12, h), (0.04, h - 0.03), (0.0, h - 0.02)], 10, "SmoothPlastic",
                         wobble=0.06, seed=i)
        core.transform(c, (x, y, 0))
        parts.append(c)
        for k in range(2):
            a = rng.uniform(0, math.tau)
            dz = rng.uniform(0.15, 0.45)
            drip = shapes.tube(f"Drip{i}{k}", [(x + math.cos(a) * 0.15, y + math.sin(a) * 0.15, h - 0.05),
                                              (x + math.cos(a) * 0.16, y + math.sin(a) * 0.16, h - dz)], lambda t: 0.045 * (1 - 0.3 * t), 4,
                               "SmoothPlastic")
            parts.append(drip)
        wick = shapes.tube(f"Wick{i}", [(x, y, h - 0.03), (x, y, h + 0.07)], 0.015, 3, "SmoothPlastic")
        parts.append(wick)
        flames.append(shapes.lathe(f"Flame{i}", [(0.0, h + 0.05), (0.05, h + 0.1), (0.065, h + 0.17), (0.03, h + 0.28), (0.0, h + 0.33)], 8,
                                   "Neon"))
    wax = core.join(parts, "Wax")
    core.tag(wax, "SmoothPlastic")
    fl = core.join(flames, "Flames")
    core.tag(fl, "Neon", lod=False)
    core.smooth(wax, 60)
    paint.paint([wax], lambda c, n, o: paint.mix(WAX, WAX_D, 0.4 if c.z < 0.12 else 0.1), ao=0.4, ao_distance=0.4, ground=0.0, edge=0.2, mottle=0.04)
    paint.solid([fl], P.FLAME)
    return {"Kind": "prop", "LodDistance": 50, "Cull": 160}


def fence_panel():
    """A 4-stud wrought-iron panel (server fence lines stretch it with ArtStretchX), rails at 2 and 5."""
    iron = []
    for z in (1.8, 4.9):
        iron.append(shapes.box(f"Rail{z}", (4.0, 0.14, 0.16), (0, 0, z), bevel=0.02, material="Metal"))
    for i in range(9):
        x = -1.78 + i * 0.445
        top = 5.6 + 0.25 * math.cos(i / 8 * math.pi * 2)
        iron.append(shapes.cylinder(f"Picket{i}", 0.05, top - 0.4, (x, 0, 0.2 + (top - 0.4) / 2), segments=6, material="Metal"))
        iron.append(shapes.lathe(f"Spear{i}", [(0.0, top - 0.02), (0.11, top + 0.12), (0.03, top + 0.4), (0.0, top + 0.45)], 4, "Metal"))
        core.transform(iron[-1], (x, 0, 0))
    for k in range(4):
        cx = -1.335 + k * 0.89
        curl = [(cx + 0.2 * math.cos(a), 0, 3.35 + 0.35 * math.sin(a)) for a in [j / 16 * math.tau for j in range(17)]]
        iron.append(shapes.tube(f"Curl{k}", curl, 0.035, 4, "Metal", cap_start=False, cap_end=False))
    obj = core.join(iron, "Iron")
    core.tag(obj, "Metal")
    core.uv_box(obj, 2.0)
    core.smooth(obj, 35)
    paint.paint([obj], lambda c, n, o: P.IRON, ao=0.5, ao_distance=0.6, ground=0.0, edge=0.5, crease=0.3, mottle=0.1)
    return {"Kind": "prop", "LodDistance": 70, "Length": 4.0}


def fence_post():
    post = shapes.lathe("Post", [(0.32, 0.0), (0.32, 0.3), (0.22, 0.4), (0.2, 5.6), (0.26, 5.7), (0.26, 5.85), (0.12, 6.0), (0.18, 6.2),
                                 (0.03, 6.75), (0.0, 6.8)], 4, "Metal")
    core.transform(post, rot=(0, 0, 45))
    core.uv_box(post, 2.0)
    core.smooth(post, 30)
    paint.paint([post], lambda c, n, o: P.IRON, ao=0.4, ground=0.0, edge=0.55, mottle=0.08)
    return {"Kind": "prop", "LodDistance": 70}


def gate_pillar():
    """Stone gate pillar 2 x 9 with a moulded cap and a stone ball finial (server collider 2 x 9 x 2)."""
    shaft = shapes.box("Shaft", (2.0, 2.0, 8.2), (0, 0, 4.4), bevel=0.06, material="Slate")
    core.subdivide(shaft, 2, simple=True)
    for v in shaft.data.vertices:  # stone courses: shallow grooves every 1.1 studs
        k = (v.co.z % 1.1)
        if k < 0.07 and 0.4 < v.co.z < 8.2:
            v.co.x *= 0.97
            v.co.y *= 0.97
    _chip(shaft, 0.05, 0.4, 9)
    plinth = shapes.lathe("Plinth", [(0.0, 0.0), (1.55, 0.0), (1.55, 0.45), (1.25, 0.6), (0.0, 0.6)], 4, "Slate")
    cap = shapes.lathe("Cap", [(0.0, 8.4), (1.2, 8.4), (1.62, 8.6), (1.62, 8.95), (1.3, 9.1), (0.6, 9.15), (0.0, 9.15)], 4, "Slate")
    for o in (plinth, cap):
        core.transform(o, rot=(0, 0, 45))
    ball = shapes.sphere("Ball", 0.55, (0, 0, 9.75), (1, 1, 1), 14, 10, "Slate")
    neck = shapes.cylinder("Neck", 0.28, 0.3, (0, 0, 9.25), segments=10, material="Slate")
    obj = core.join([shaft, plinth, cap, ball, neck], "Stone")
    core.tag(obj, "Slate")
    _finish_stone([obj], 5, angle=35, studs=3.0)
    return {"Kind": "prop", "LodDistance": 110}


def gate_arch():
    """Wrought-iron arch spanning 8 studs between pillar tops (stretched to the gate width by ArtStretchX)."""
    iron = []
    pts = [(-4 + 8 * t, 0, 0.25 + 1.3 * math.sin(math.pi * t)) for t in [k / 20 for k in range(21)]]
    iron.append(shapes.tube("Top", pts, 0.09, 6, "Metal", resample=0))
    iron.append(shapes.box("Bar", (8.0, 0.16, 0.16), (0, 0, 0.0), material="Metal"))
    for k in range(9):
        t = k / 8
        x = -4 + 8 * t
        h = 0.25 + 1.3 * math.sin(math.pi * t)
        iron.append(shapes.cylinder(f"Spoke{k}", 0.04, h + 0.5, (x, 0, (h + 0.5) / 2 - 0.1), segments=5, material="Metal"))
        iron.append(shapes.lathe(f"Tip{k}", [(0.0, h + 0.3), (0.1, h + 0.42), (0.02, h + 0.72), (0.0, h + 0.76)], 4, "Metal"))
        core.transform(iron[-1], (x, 0, 0))
    for side in (-1, 1):
        curl = [(side * (2.2 + 0.45 * math.cos(a)), 0, 0.65 + 0.45 * math.sin(a)) for a in [j / 18 * math.tau * 1.4 for j in range(19)]]
        iron.append(shapes.tube(f"Scroll{side}", curl, 0.04, 4, "Metal", cap_start=False))
    obj = core.join(iron, "Iron")
    core.tag(obj, "Metal")
    core.uv_box(obj, 2.0)
    core.smooth(obj, 35)
    paint.paint([obj], lambda c, n, o: P.IRON, ao=0.4, ao_distance=0.6, ground=None, edge=0.55, mottle=0.1)
    return {"Kind": "prop", "LodDistance": 110, "Length": 8.0}


def ruin_wall():
    """A broken masonry run 10.2 studs long (server colliders: five 2 x h x 1.4 blocks) with a fallen block."""
    rng = random.Random(12)
    blocks = []
    tops = [rng.uniform(1.6, 4.8) for _ in range(5)]
    for i in range(5):
        x0 = -5.1 + i * 2.05
        z = 0.0
        row = 0
        while z < tops[i]:
            hgt = rng.uniform(0.45, 0.7)
            hgt = min(hgt, tops[i] - z) if tops[i] - z > 0.25 else hgt
            off = 0.5 if row % 2 else 0.0
            w = 2.05
            b = shapes.box(f"B{i}_{row}", (w * rng.uniform(0.92, 0.99), 1.35 * rng.uniform(0.95, 1.05), hgt * 0.94),
                           (x0 + w / 2 + rng.uniform(-0.05, 0.05) - off * 0.2, rng.uniform(-0.04, 0.04), z + hgt / 2), bevel=0.06,
                           material="Slate")
            blocks.append(b)
            z += hgt
            row += 1
    fallen = shapes.box("Fallen", (1.9, 1.3, 1.1), (rng.uniform(-2, 2), -2.3, 0.55), (0, 0, 35), bevel=0.08, material="Slate")
    blocks.append(fallen)
    for k in range(5):
        blocks.append(shapes.box(f"Rubble{k}", (0.5, 0.45, 0.35), (rng.uniform(-4, 4), rng.uniform(-1.6, -0.9), 0.17), (rng.uniform(0, 40), 0, rng.uniform(0, 90)),
                                 bevel=0.05, material="Slate"))
    for b in blocks:
        _chip(b, 0.04, 0.3, rng.randint(0, 50))
    obj = core.join(blocks, "Stone")
    core.tag(obj, "Slate")
    _finish_stone([obj], 6, angle=35)
    return {"Kind": "prop", "LodDistance": 90}


def edge_stone(seed):
    def make():
        import bmesh
        rng = random.Random(seed)
        bm = bmesh.new()
        bmesh.ops.create_icosphere(bm, subdivisions=2, radius=1.0)
        s = core.obj_from_bmesh("Stone", bm, "Slate")
        for v in s.data.vertices:
            d = 1 + 0.18 * noise.noise(v.co * 1.6 + Vector((seed, 0, 0)))
            v.co = Vector((v.co.x * 0.55 * d, v.co.y * 0.85 * d, max(-0.05, v.co.z * 0.32 * d) + 0.1))
        _finish_stone([s], seed, angle=40, studs=2.0)
        return {"Kind": "prop", "LodDistance": 40, "Cull": 140}
    return make


ASSETS = {
    "grave_headstone": grave_headstone, "grave_cross": grave_cross, "grave_obelisk": grave_obelisk, "grave_leaning": grave_leaning,
    "grave_mound": grave_mound, "pumpkin": pumpkin(False), "pumpkin_lit": pumpkin(True), "candles": candles,
    "fence_panel": fence_panel, "fence_post": fence_post, "gate_pillar": gate_pillar, "gate_arch": gate_arch, "ruin_wall": ruin_wall,
    "edge_stone_a": edge_stone(1), "edge_stone_b": edge_stone(2),
}
