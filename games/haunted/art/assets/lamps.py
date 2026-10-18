"""Lamp family: the gothic iron lamp post used along every path (replaces MODEL-BAD-015/016).

References: MODEL-MIN-064 (lighting pack: lantern cage, candles), MODEL-MIN-069 (finished architectural iron).
Rejected: MODEL-BAD-015/016 (plain post + box lantern, glow hiding the form).
Gameplay: the server keeps its invisible post collider and PointLight at the lantern head (0, 6.6, +1.3 in
Roblox space); this mesh only dresses it.
"""

import math

from mathutils import Vector

from hcart import core, paint, shapes
from hcart import palette as P


def _iron(objs):
    def col(c, n, o):
        return P.IRON

    paint.paint(objs, col, ao=0.6, ao_distance=1.2, edge=0.55, crease=0.35, mottle=0.08, mottle_scale=0.6, seed=3)


def lantern_head(cx=0.0, cy=0.0, cz=0.0, scale=1.0, name="Lantern"):
    """Hexagonal hanging lantern centred on its glass. Returns (iron_parts, glass, flame, wax)."""
    s = scale
    iron = []
    cap = shapes.lathe(name + "Cap", [(0.56 * s, 0), (0.64 * s, 0.07 * s), (0.6 * s, 0.12 * s), (0.18 * s, 0.5 * s),
                                     (0.1 * s, 0.62 * s), (0.13 * s, 0.68 * s), (0.06 * s, 0.78 * s), (0.0, 0.8 * s)],
                       6, "Metal")
    core.transform(cap, (cx, cy, cz + 0.5 * s), (0, 0, 30))
    iron.append(cap)
    ring = shapes.tube(name + "Ring", [(cx, cy - 0.16 * s * math.cos(a), cz + 1.42 * s + 0.16 * s * math.sin(a)) for a in
                                       [i / 10 * math.tau for i in range(11)]], 0.035 * s, 6, "Metal", cap_start=False, cap_end=False)
    iron.append(ring)
    for k in range(6):
        a = math.radians(30 + 60 * k)
        x, y = cx + math.cos(a) * 0.47 * s, cy + math.sin(a) * 0.47 * s
        bar = shapes.tube(name + f"Bar{k}", [(x, y, cz - 0.62 * s), (x, y, cz + 0.52 * s)], 0.04 * s, 5, "Metal")
        iron.append(bar)
    top = shapes.lathe(name + "Band", [(0.5 * s, -0.04 * s), (0.55 * s, 0), (0.55 * s, 0.05 * s), (0.5 * s, 0.09 * s)], 6, "Metal",
                       cap_bottom=False, cap_top=False)
    core.transform(top, (cx, cy, cz + 0.44 * s), (0, 0, 30))
    bot = shapes.lathe(name + "Dish", [(0.0, -0.95 * s), (0.08 * s, -0.92 * s), (0.06 * s, -0.84 * s), (0.2 * s, -0.78 * s),
                                     (0.5 * s, -0.66 * s), (0.56 * s, -0.6 * s), (0.5 * s, -0.56 * s)], 6, "Metal")
    core.transform(bot, (cx, cy, cz), (0, 0, 30))
    iron += [top, bot]
    glass = shapes.lathe(name + "Glass", [(0.43 * s, -0.56 * s), (0.45 * s, 0.0), (0.43 * s, 0.46 * s)], 6, "Neon", alpha=0.35, lod=False)
    core.transform(glass, (cx, cy, cz), (0, 0, 30))
    wax = shapes.lathe(name + "Wax", [(0.0, -0.56 * s), (0.11 * s, -0.56 * s), (0.11 * s, -0.25 * s), (0.08 * s, -0.2 * s),
                                     (0.05 * s, -0.22 * s), (0.0, -0.2 * s)], 10, "SmoothPlastic", wobble=0.05)
    core.transform(wax, (cx, cy, cz))
    flame = shapes.lathe(name + "Flame", [(0.0, -0.2 * s), (0.07 * s, -0.16 * s), (0.1 * s, -0.06 * s), (0.08 * s, 0.05 * s),
                                         (0.03 * s, 0.17 * s), (0.0, 0.24 * s)], 10, "Neon", lod=False)
    core.transform(flame, (cx, cy, cz))
    for o in [flame, glass, wax]:
        core.smooth(o, 80)
    return iron, glass, flame, wax


def lamp_post():
    iron = []
    base = shapes.lathe("Base", [(0.86, 0), (0.86, 0.1), (0.78, 0.16), (0.7, 0.2), (0.66, 0.34), (0.5, 0.42), (0.42, 0.56),
                                 (0.3, 0.66), (0.27, 0.8), (0.33, 0.86), (0.33, 0.92), (0.22, 0.98)], 8, "Metal")
    core.transform(base, rot=(0, 0, 22.5))
    core.bevel(base, 0.025, 1, 35)
    iron.append(base)
    shaft = shapes.lathe("Shaft", [(0.2, 0.95), (0.17, 2.4), (0.24, 2.48), (0.24, 2.6), (0.17, 2.68), (0.17, 3.9), (0.24, 3.98),
                                   (0.24, 4.08), (0.16, 4.16), (0.15, 6.75), (0.21, 6.83), (0.23, 7.0), (0.16, 7.1), (0.14, 7.42)],
                         8, "Metal", cap_bottom=False)
    core.transform(shaft, rot=(0, 0, 22.5))
    iron.append(shaft)
    # Wrought twist between the lower collars: four bars spiralling round the shaft.
    for k in range(4):
        pts = []
        for i in range(25):
            t = i / 24
            a = k * math.pi / 2 + t * math.pi * 1.5
            r = 0.2 + 0.07 * math.sin(t * math.pi)
            pts.append((math.cos(a) * r, math.sin(a) * r, 2.66 + t * 1.26))
        iron.append(shapes.tube(f"Twist{k}", pts, 0.045, 5, "Metal"))
    knob = shapes.lathe("Finial", [(0.0, 7.36), (0.22, 7.42), (0.26, 7.56), (0.2, 7.72), (0.07, 7.82), (0.09, 7.9), (0.03, 8.24),
                                   (0.0, 8.28)], 8, "Metal")
    iron.append(knob)
    # Scroll arm: a main bar out to the hook, a curl under it, and a spiral end.
    arm = shapes.tube("Arm", [(0, 0.1, 7.38), (0, 0.6, 7.44), (0, 1.05, 7.43), (0, 1.4, 7.36), (0, 1.62, 7.24)], 0.07, 6, "Metal",
                      resample=4)
    iron.append(arm)
    curl_pts = []
    for i in range(23):
        t = i / 22
        ang = -math.pi * 0.5 + t * math.pi * 2.6
        r = 0.46 * (1 - t * 0.78)
        curl_pts.append((0, 0.6 + math.cos(ang) * r * 0.9, 6.92 + math.sin(ang) * r))
    curl = shapes.tube("Curl", [(0, 0.12, 6.7)] + curl_pts, lambda t: 0.055 * (1 - 0.5 * t), 6, "Metal")
    iron.append(curl)
    spiral = []
    for i in range(17):
        t = i / 16
        ang = t * math.pi * 1.8
        r = 0.17 * (1 - t * 0.7)
        spiral.append((0, 1.62 + math.sin(ang) * r, 7.24 + 0.17 - math.cos(ang) * r))
    iron.append(shapes.tube("ArmTip", spiral, lambda t: 0.055 * (1 - 0.6 * t), 6, "Metal"))
    hook = shapes.tube("Hook", [(0, 1.4, 7.36), (0, 1.4, 7.2), (0, 1.4, 7.08)], 0.035, 5, "Metal")
    iron.append(hook)
    lant_iron, glass, flame, wax = lantern_head(0, 1.4, 5.1, 1.25)
    iron += lant_iron
    body = core.join(iron, "Iron")
    core.uv_box(body, 2.0)
    core.smooth(body, 35)
    _iron([body, glass, wax])
    paint.solid([flame], P.FLAME)
    paint.gradient_solid(glass, P.AMBER, P.GLASS, 4.4, 5.7)
    paint.paint([wax], lambda c, n, o: P.CLOTH_WHITE, ao=0.3, edge=0.1, mottle=0.02)
    return {"Kind": "prop", "LightX": 0.0, "LightY": 5.1, "LightZ": 1.4}


def _finish(iron, glass, flame, wax):
    body = core.join(iron, "Iron")
    core.uv_box(body, 2.0)
    core.smooth(body, 35)
    _iron([body, glass, wax])
    paint.solid([flame], P.FLAME)
    lo = min((glass.matrix_world @ v.co).z for v in glass.data.vertices)
    hi = max((glass.matrix_world @ v.co).z for v in glass.data.vertices)
    paint.gradient_solid(glass, P.AMBER, P.GLASS, lo, hi)
    paint.paint([wax], lambda c, n, o: P.CLOTH_WHITE, ao=0.3, edge=0.1, mottle=0.02)


def lantern_wall():
    """Bracket lantern for pillars and walls. Origin = wall face at mount height 0; the lantern hangs in
    front (-Y, Roblox front). Mount the anchor on the wall surface facing outwards."""
    iron = []
    plate = shapes.box("Plate", (0.5, 0.12, 0.9), (0, 0.06, 0.1), bevel=0.03)
    iron.append(plate)
    arm = shapes.tube("Arm", [(0, 0.05, 0.35), (0, -0.4, 0.42), (0, -0.85, 0.4), (0, -1.05, 0.3)], 0.06, 6, "Metal", resample=4)
    iron.append(arm)
    brace = []
    for i in range(19):
        t = i / 18
        a = math.pi * (0.5 + 1.4 * t)
        r = 0.32 * (1 - 0.65 * t)
        brace.append((0, -0.42 + math.cos(a) * r * 1.1, 0.02 + math.sin(a) * r))
    iron.append(shapes.tube("Brace", [(0, 0.05, -0.25)] + brace, lambda t: 0.045 * (1 - 0.5 * t), 6, "Metal"))
    iron.append(shapes.tube("Hook", [(0, -0.85, 0.4), (0, -0.85, 0.22)], 0.03, 5, "Metal"))
    lant_iron, glass, flame, wax = lantern_head(0, -0.85, -0.9, 0.9)
    iron += lant_iron
    _finish(iron, glass, flame, wax)
    return {"Kind": "prop", "LightX": 0.0, "LightY": -0.9, "LightZ": -0.85}


def lantern_hanging():
    """Lantern on a short chain for canopies and arches. Origin = the ceiling hook (top), body hangs below."""
    iron = []
    for i in range(5):
        z = -0.18 - i * 0.26
        rot = 90 if i % 2 else 0
        link = shapes.tube(f"Link{i}", [(0.07 * math.cos(a), 0, z + 0.12 * math.sin(a)) for a in [k / 10 * math.tau for k in range(11)]],
                           0.025, 5, "Metal", cap_start=False, cap_end=False)
        core.transform(link, rot=(0, 0, rot))
        iron.append(link)
    lant_iron, glass, flame, wax = lantern_head(0, 0, -2.75, 1.0)
    iron += lant_iron
    _finish(iron, glass, flame, wax)
    return {"Kind": "prop", "LightX": 0.0, "LightY": -2.75, "LightZ": 0.0}


ASSETS = {"lamp_post": lamp_post, "lantern_wall": lantern_wall, "lantern_hanging": lantern_hanging}
