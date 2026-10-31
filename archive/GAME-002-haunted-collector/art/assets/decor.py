"""Habitat decor (TASK-0044): spider webs, cocoons, settlement walls and broken fences.

References: MIN-062 (remains/webbed props), MIN-066/067 (nature pack), MIN-069 (masonry, fencing).
"""

import math
import random

from mathutils import Vector, noise

from hcart import core, paint, shapes
from hcart import palette as P

from assets.graveyard import _chip, _finish_stone

SILK = paint.hex3("dcd8cf")
BRICK = paint.hex3("7a4a3a")
BRICK_D = paint.hex3("5a3328")
MORTAR = paint.hex3("8d857a")
TIMBER = paint.hex3("5c4634")


def web_sheet():
    """A torn web panel 8 wide and 6 tall, centred at the origin (stretched along X to each gap)."""
    rng = random.Random(5)
    strands = []
    centre = Vector((rng.uniform(-0.6, 0.6), 0, rng.uniform(-0.4, 0.6)))
    spokes = 11
    ends = []
    for k in range(spokes):
        a = k / spokes * math.tau + rng.uniform(-0.12, 0.12)
        d = Vector((math.cos(a) * 4.2, 0, math.sin(a) * 3.2))
        end = centre + d
        end.x = max(-4.0, min(4.0, end.x))
        end.z = max(-3.0, min(3.0, end.z))
        ends.append((a, end))
        mid = (centre + end) / 2 + Vector((0, rng.uniform(-0.05, 0.05), -0.12))
        strands.append(shapes.tube(f"Spoke{k}", [centre, mid, end], 0.022, 3, "SmoothPlastic", resample=2))
    for ring in range(1, 8):
        t = ring / 8
        pts = []
        for k in range(spokes + 1):
            a, end = ends[k % spokes]
            if rng.random() < 0.08 and ring > 4:  # torn gaps
                if len(pts) > 1:
                    strands.append(shapes.tube(f"Ring{ring}_{k}", pts, 0.016, 3, "SmoothPlastic"))
                pts = []
                continue
            p = centre.lerp(end, t)
            p.z -= 0.12 * math.sin(t * math.pi)  # sag
            pts.append(p)
        if len(pts) > 1:
            strands.append(shapes.tube(f"Ring{ring}", pts, 0.016, 3, "SmoothPlastic"))
    web = core.join(strands, "Silk")
    core.tag(web, "SmoothPlastic", alpha=0.25, lod=False)
    paint.solid([web], SILK)
    return {"Kind": "prop", "LodDistance": 80, "Cull": 160, "Length": 8.0}


def cocoon():
    """A silk-wrapped cocoon 1 stud across and 1.8 long (scaled per instance) with a hanging thread."""
    prof = [(0.0, 0.0), (0.25, 0.08), (0.46, 0.35), (0.5, 0.8), (0.44, 1.3), (0.28, 1.65), (0.08, 1.8), (0.0, 1.82)]
    body = shapes.lathe("Body", prof, 16, "Fabric", wobble=0.08, seed=3)
    for v in body.data.vertices:  # spiral wraps
        a = math.atan2(v.co.y, v.co.x)
        k = 1 + 0.07 * math.sin(a * 2 + v.co.z * 14)
        v.co.x *= k
        v.co.y *= k
    core.subdivide(body, 1)
    thread = shapes.tube("Thread", [(0, 0, 1.78), (0.02, 0, 2.6), (0, 0, 3.6)], 0.018, 3, "SmoothPlastic")
    wraps = []
    for w in range(2):
        pts = []
        for i in range(40):
            t = i / 39
            z = 0.12 + t * 1.6
            r = 0.02 + max(0.0, 0.5 * math.sin(math.pi * (z / 1.82)) ** 0.8)
            a = t * math.tau * 4 + w * math.pi
            pts.append((math.cos(a) * r * 1.04, math.sin(a) * r * 1.04, z))
        wraps.append(shapes.tube(f"Wrap{w}", pts, 0.03, 4, "Fabric"))
    silk = core.join([body, thread] + wraps, "Silk")
    core.tag(silk, "Fabric")
    core.uv_box(silk, 1.0)
    core.smooth(silk, 70)
    paint.paint([silk], lambda c, n, o: paint.mix(SILK, paint.hex3("a7a094"), 0.3 + 0.3 * noise.noise(c * 4)), ao=0.4, ground=None,
                edge=0.2, crease=0.5, mottle=0.06)
    return {"Kind": "prop", "LodDistance": 80, "Cull": 200}


def settle_wall():
    """A ruined brick wall run 8 long and up to 6 high (stretched along X; server colliders follow its height)."""
    rng = random.Random(21)
    bricks = []
    rows = 14
    for r in range(rows):
        z = 0.1 + r * 0.42
        x = -4.0 + (0.45 if r % 2 else 0.0)
        top_limit = 6.0 - 2.6 * max(0.0, math.sin((r * 0.7) + 0.5)) * 0.0
        while x < 4.0:
            w = rng.uniform(0.75, 0.95)
            cut = 4.6 + 1.4 * math.sin(x * 0.7 + 1.2) + 0.5 * math.sin(x * 2.3)  # broken top profile
            if z < min(top_limit, cut):
                bw = min(w, 4.0 - x)
                if bw > 0.2:
                    bricks.append(shapes.box(f"B{r}_{len(bricks)}", (bw - 0.06, 0.9 + rng.uniform(-0.04, 0.04), 0.36),
                                             (x + bw / 2, rng.uniform(-0.03, 0.03), z + 0.18), bevel=0.04, segments=1, material="Brick"))
            x += w
    core_wall = shapes.box("Core", (7.9, 0.75, 4.2), (0, 0, 2.2), material="Brick")
    for v in core_wall.data.vertices:
        if v.co.z > 2.5:
            v.co.z = min(v.co.z, 4.1 + 1.1 * math.sin(v.co.x * 0.7 + 1.2))
    post = shapes.box("Post", (0.45, 0.5, 6.4), (-3.85, 0, 3.2), (0, 0, 4), bevel=0.05, material="Wood")
    wall = core.join(bricks + [core_wall], "Brick")
    core.tag(wall, "Brick")
    core.uv_box(wall, 3.0)
    core.smooth(wall, 35)

    def col(c, n, o):
        base = paint.mix(BRICK, BRICK_D, 0.5 + 0.5 * noise.noise(c * 1.7))
        if abs(n.y) < 0.4 and abs(c.y) < 0.4:
            base = MORTAR
        if c.z < 0.6:
            base = paint.mix(base, P.MOSS_DARK, 0.5)
        return base

    paint.paint([wall], col, ao=0.6, ao_distance=0.8, ground=0.0, edge=0.25, crease=0.6, mottle=0.1, mottle_scale=0.5)
    core.uv_box(post, 2.0)
    paint.paint([post], lambda c, n, o: TIMBER, ao=0.4, ground=0.0, edge=0.3, mottle=0.1)
    return {"Kind": "prop", "LodDistance": 100, "Length": 8.0}


def fence_wood():
    """A sagging, broken picket fence 10 long (posts every 2.5, one fallen)."""
    rng = random.Random(4)
    wood = []
    for i in range(5):
        x = -5 + i * 2.5
        if i == 3:
            wood.append(shapes.box(f"Fallen{i}", (0.42, 0.42, 3.4), (x + 0.6, -0.9, 0.22), (0, 80, 25), bevel=0.04, material="Wood"))
            continue
        tilt = rng.uniform(-10, 10)
        wood.append(shapes.box(f"Post{i}", (0.46, 0.46, 3.6), (x, 0, 1.75), (rng.uniform(-6, 6), tilt, 0), bevel=0.05, material="Wood"))
        cap = shapes.lathe(f"Cap{i}", [(0.0, 3.55), (0.32, 3.55), (0.0, 3.95)], 4, "Wood")
        core.transform(cap, (x, 0, 0), (0, tilt * 0.6, 45))
        wood.append(cap)
    for j, (z, sag) in enumerate(((1.2, 0.08), (2.5, 0.2))):
        pts = [(-5.2, -0.3, z), (-2.5, -0.3, z - sag), (0.0, -0.3, z - sag * 0.4), (2.4, -0.3, z - sag * 1.6)]
        wood.append(shapes.tube(f"Rail{j}", pts, 0.13, 5, "Wood", flatten=0.5, resample=2))
    for k in range(9):
        x = -4.6 + k * 1.05
        if rng.random() < 0.25:
            continue
        h = rng.uniform(1.8, 2.9)
        wood.append(shapes.box(f"Picket{k}", (0.36, 0.12, h), (x, -0.42, h / 2), (rng.uniform(-4, 4), rng.uniform(-8, 8), 0), bevel=0.03, material="Wood"))
        tip = shapes.lathe(f"Tip{k}", [(0.0, h), (0.2, h), (0.0, h + 0.3)], 4, "Wood")
        core.transform(tip, (x, -0.42, 0), (0, 0, 45))
        wood.append(tip)
    for w in wood:
        _chip(w, 0.02, 0.2, 1)
    obj = core.join(wood, "Wood")
    core.tag(obj, "Wood")
    core.uv_box(obj, 2.0)
    core.smooth(obj, 35)
    paint.paint([obj], lambda c, n, o: paint.mix(TIMBER, P.WOOD_GREY, 0.3 + 0.3 * noise.noise(c * 2)), ao=0.5, ground=0.0, edge=0.3,
                crease=0.4, mottle=0.12)
    return {"Kind": "prop", "LodDistance": 80}


ASSETS = {"web_sheet": web_sheet, "cocoon": cocoon, "settle_wall": settle_wall, "fence_wood": fence_wood}
