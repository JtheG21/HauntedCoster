"""Habitat landmarks (TASK-0045): set pieces readable from 80+ studs, built to the server footprints in
server/World/Props.luau and the habitat builders. Front = -Y (Roblox LookVector); servers orient anchors.

References: MODEL-MIN-067-070 (graveyard architecture: mausoleums, gates, chapels, layered stone), MIN-062
(remains), MIN-066 (gnarled nature), MIN-057-059 (vehicle construction finish, for the hearse).
"""

import math
import random

from mathutils import Vector, noise

from hcart import anatomy as A
from hcart import core, paint, shapes
from hcart import palette as P

from assets.graveyard import _chip, _finish_stone
from assets.trees import _bark_color, _finish_wood, gnarled, roots

MARBLE = P.MARBLE
GOLD = paint.hex3("b8953f")
LACQUER = paint.hex3("16131a")


def _courses(name, w, d, z0, z1, course=1.2, bevel=0.07, seed=0, material="Slate"):
    """A square shaft built from stone courses (visible joints, slight offsets)."""
    rng = random.Random(seed)
    blocks = []
    z = z0
    k = 0
    while z < z1 - 0.05:
        h = min(course, z1 - z)
        blocks.append(shapes.box(f"{name}{k}", (w + rng.uniform(-0.05, 0.05) - (0.06 if k % 2 else 0), d + rng.uniform(-0.05, 0.05), h - 0.05),
                                 (rng.uniform(-0.03, 0.03), rng.uniform(-0.03, 0.03), z + h / 2), bevel=bevel, segments=1, material=material))
        z += h
        k += 1
    return blocks


def _arch(name, width, spring, rise, depth, thick=0.35, seg=12, y=0.0, x=0.0, material="Slate"):
    pts = [(x - width / 2 * math.cos(a), y, spring + rise * math.sin(a)) for a in [i / seg * math.pi for i in range(seg + 1)]]
    return shapes.tube(name, pts, thick, 6, material, cap_start=False, cap_end=False, flatten=depth / thick / 2)


# --------------------------------------------------------------------------------------------------------
def weeping_angel():
    """Weeping Angel on a stepped pedestal (8 x 8 base): a robed figure bowed with both hands over her face and
    tall folded wings. ~13.5 studs high."""
    stone = []
    stone.append(shapes.box("Pedestal", (8, 8, 1.2), (0, 0, 0.6), bevel=0.1, material="Slate"))
    stone.append(shapes.box("Step", (6, 6, 1.2), (0, 0, 1.8), bevel=0.08, material="Slate"))
    plinth = shapes.box("Plinth", (4, 4, 2.6), (0, 0, 3.7), bevel=0.08, material="Marble")
    core.subdivide(plinth, 2, simple=True)
    _chip(plinth, 0.04, 0.3, 3)
    stone.append(plinth)
    for s in stone[:2]:
        core.subdivide(s, 1, simple=True)
        _chip(s, 0.05, 0.4, 2)
    base = core.join(stone, "Base")
    core.tag(base, "Slate")
    _finish_stone([base], 3, angle=35)
    z0 = 5.0
    body = A.organic("Figure", [
        A.ell((0, 0.55, z0 + 4.4), (0.9, 0.5, 1.2)),            # back, wing roots
        A.ell((0, 0, z0 + 0.9), (1.55, 1.25, 1.2)),            # hem
        A.ell((0, 0.05, z0 + 2.6), (1.25, 1.0, 1.9)),           # robe
        A.ell((0, -0.15, z0 + 4.5), (1.15, 0.9, 1.2), rot=(-14, 0, 0)),   # chest, bowing
        A.ell((0, -0.55, z0 + 5.55), (0.6, 0.6, 0.7), rot=(-25, 0, 0)),   # bowed head
        A.ell((0.55, -0.75, z0 + 5.35), (0.25, 0.55, 0.42), rot=(-30, 0, -20)),  # hands over face
        A.ell((-0.55, -0.75, z0 + 5.35), (0.25, 0.55, 0.42), rot=(-30, 0, 20)),
        A.ell((0.85, -0.45, z0 + 4.6), (0.3, 0.7, 0.32), rot=(-40, 0, -35)),     # forearms
        A.ell((-0.85, -0.45, z0 + 4.6), (0.3, 0.7, 0.32), rot=(-40, 0, 35)),
        A.ell((0, 0.4, z0 + 5.7), (0.55, 0.4, 0.5)),            # hair bun
    ], 2600, resolution=0.07, material="Marble")
    # Robe folds: vertical grooves.
    for v in body.data.vertices:
        if v.co.z < z0 + 3.6:
            a = math.atan2(v.co.y, v.co.x)
            k = 1 + 0.05 * math.sin(a * 11) * min(1.0, (z0 + 3.6 - v.co.z) / 1.5)
            v.co.x *= k
            v.co.y *= k
    wings = []
    for side in (-1, 1):
        # Folded wings: a shoulder arch rising above the head, primaries sweeping down to the hem.
        for f in range(7):
            k = f / 6
            top = z0 + 8.4 - k * 1.2
            pts = [(side * 0.45, 0.7, z0 + 5.0), (side * (1.25 + 0.15 * k), 1.0 + 0.1 * k, top - 0.6), (side * (1.45 + 0.1 * k), 1.2 + 0.12 * k, top),
                   (side * (1.65 - 0.05 * k), 1.35 + 0.15 * k, top - 2.6 - k * 0.6), (side * (1.3 - 0.1 * k), 1.45 + 0.1 * k, z0 + 1.2 + k * 0.6)]
            wings.append(shapes.tube(f"Feather{side}{f}", pts, lambda t, kk=k: (0.38 - 0.12 * kk) * math.sin(math.pi * min(1.0, 0.08 + t)) + 0.03, 7,
                                     "Marble", flatten=0.25, resample=3))
    figure = core.join([body] + wings, "Figure")
    core.tag(figure, "Marble")
    core.uv_box(figure, 2.0)
    core.smooth(figure, 60)
    paint.paint([figure], lambda c, n, o: paint.mix(MARBLE, P.LICHEN, 0.35 * max(0.0, n.z - 0.5) + 0.2 * max(0.0, -c.z + z0 + 1)),
                ao=0.7, ao_distance=1.2, ground=0.0, edge=0.25, crease=0.6, mottle=0.08, mottle_scale=0.5)
    return {"Kind": "landmark", "LodDistance": 220}


def bell_tower():
    """Buttressed bell tower: 10 x 10 base, 7 x 7 shaft to 23, open belfry with arches and a lit bell, steep
    stepped spire with an iron cross (~45 high)."""
    stone = []
    stone.append(shapes.box("Base", (10, 10, 2), (0, 0, 1), bevel=0.12, segments=1, material="Slate"))
    stone += _courses("Shaft", 7, 7, 2, 23, course=1.5, seed=4)
    for sx in (-1, 1):
        for sy in (-1, 1):
            stone.append(shapes.box(f"ButtA{sx}{sy}", (2.0, 2.0, 10), (sx * 3.6, sy * 3.6, 5), bevel=0.1, segments=1, material="Slate"))
            stone.append(shapes.box(f"ButtB{sx}{sy}", (1.4, 1.4, 6), (sx * 3.6, sy * 3.6, 13), bevel=0.08, segments=1, material="Slate"))
            cap = shapes.lathe(f"ButtCap{sx}{sy}", [(0.0, 16.0), (1.0, 16.0), (0.0, 17.6)], 4, "Slate")
            core.transform(cap, (sx * 3.6, sy * 3.6, 0), (0, 0, 45))
            stone.append(cap)
    stone.append(shapes.box("Floor", (8, 8, 0.6), (0, 0, 23.7), bevel=0.06, segments=1, material="Slate"))
    for sx in (-1, 1):
        for sy in (-1, 1):
            stone.append(shapes.box(f"Pier{sx}{sy}", (1.5, 1.5, 7), (sx * 3.2, sy * 3.2, 27.5), bevel=0.06, segments=1, material="Slate"))
    for k, (dx, dy, rot) in enumerate(((0, -3.2, 0), (0, 3.2, 0), (-3.2, 0, 90), (3.2, 0, 90))):
        arc = _arch(f"Arch{k}", 5.0, 29.4, 1.6, 1.2, 0.32)
        core.transform(arc, rot=(0, 0, rot))
        core.transform(arc, (dx, dy, 0))
        stone.append(arc)
    stone.append(shapes.box("Cornice", (8.6, 8.6, 0.8), (0, 0, 31.4), bevel=0.08, segments=1, material="Slate"))
    spire = shapes.lathe("Spire", [(0.0, 31.8), (4.4, 31.8), (4.0, 32.6), (3.2, 33.4), (2.6, 36.0), (1.9, 36.6), (1.5, 39.5), (0.9, 40.0),
                                   (0.6, 42.4), (0.0, 43.4)], 4, "Slate")
    core.transform(spire, rot=(0, 0, 45))
    stone.append(spire)
    for b in stone:
        _chip(b, 0.03, 0.5, 1)
    tower = core.join(stone, "Stone")
    core.tag(tower, "Slate")
    _finish_stone([tower], 7, angle=35, studs=3.0)
    cross = core.join([shapes.box("CrossV", (0.25, 0.25, 2.6), (0, 0, 44.6), material="Metal"),
                       shapes.box("CrossH", (1.3, 0.25, 0.25), (0, 0, 45.1), material="Metal")], "Iron")
    core.tag(cross, "Metal")
    paint.paint([cross], lambda c, n, o: P.IRON, ao=0.2, ground=None, edge=0.5)
    bell = shapes.lathe("Bell", [(1.25, 25.0), (1.32, 25.1), (1.2, 25.3), (0.95, 26.0), (0.9, 27.0), (0.7, 27.6), (0.0, 27.8)], 18, "Metal",
                        cap_bottom=False)
    yoke = shapes.box("Yoke", (6.0, 0.4, 0.4), (0, 0, 28.0), material="Wood")
    belly = core.join([bell, yoke], "Bell")
    core.tag(belly, "Metal", part="Bell")
    core.uv_box(belly, 1.5)
    paint.paint([belly], lambda c, n, o: paint.mix(paint.hex3("9a6a32"), paint.hex3("4f8a78"), 0.3 if n.z < 0 else 0.1), ao=0.4, ground=None,
                edge=0.4)
    glow = shapes.sphere("BellGlow", 0.6, (0, 0, 25.6), (1, 1, 0.6), 10, 6, "Neon", part="Bell", lod=False)
    paint.solid([glow], P.FLAME)
    return {"Kind": "landmark", "LodDistance": 260}


def mausoleum():
    """A small classical tomb at scale 1: stepped base 12 x 10, body 10 x 8 x 9, two columns, pediment roof,
    iron door with a knocker and a carved frieze (server scales it 0.7-1.3)."""
    stone = [shapes.box("Base", (12, 10, 1.0), (0, 0, 0.5), bevel=0.08, segments=1, material="Slate"),
             shapes.box("Step", (6, 1.6, 0.5), (0, -5.4, 0.25), bevel=0.05, segments=1, material="Slate")]
    stone += _courses("Body", 10, 8, 1.0, 9.6, course=1.08, seed=6, material="Marble")
    stone.append(shapes.box("Entablature", (11.2, 9.2, 1.0), (0, 0, 10.1), bevel=0.08, segments=1, material="Marble"))
    for sx in (-1, 1):
        col = shapes.lathe(f"Col{sx}", [(0.62, 1.0), (0.62, 1.3), (0.48, 1.45), (0.44, 9.0), (0.6, 9.2), (0.62, 9.6)], 12, "Marble")
        for v in col.data.vertices:  # fluting
            a = math.atan2(v.co.y, v.co.x)
            if 1.5 < v.co.z < 9.0:
                k = 1 - 0.06 * max(0.0, math.cos(a * 12))
                v.co.x *= k
                v.co.y *= k
        core.transform(col, (sx * 3.6, -4.65, 0))
        stone.append(col)
    roof = shapes.box("Pediment", (11.6, 9.6, 2.6), (0, 0, 11.9), material="Slate")
    core.subdivide(roof, 2, simple=True)
    for v in roof.data.vertices:  # gable: ridge along Y
        if v.co.z > 11.0:
            v.co.z = 10.6 + 2.8 * (1 - abs(v.co.x) / 5.8)
    tymp = shapes.box("Tympanum", (8.5, 0.3, 1.6), (0, -4.7, 11.3), material="Marble")
    for v in tymp.data.vertices:
        if v.co.z > 11.3:
            v.co.z = 10.5 + 2.1 * (1 - abs(v.co.x) / 4.25)
    stone.append(tymp)
    stone.append(roof)
    for b in stone:
        _chip(b, 0.03, 0.4, 2)
    body = core.join(stone, "Stone")
    core.tag(body, "Marble")
    _finish_stone([body], 8, angle=35, studs=3.0)
    door = shapes.box("Door", (3.0, 0.3, 5.0), (0, -4.08, 3.5), bevel=0.06, segments=2, material="Metal")
    knock = shapes.tube("Knocker", [(0.25 * math.cos(a), -4.3, 4.4 + 0.25 * math.sin(a)) for a in [k / 12 * math.tau for k in range(13)]], 0.05, 5,
                        "Metal", cap_start=False, cap_end=False)
    studs = [shapes.sphere(f"Stud{i}", 0.07, (-1.2 + (i % 5) * 0.6, -4.24, 1.4 + (i // 5) * 1.0), (1, 1, 1), 6, 4, "Metal") for i in range(20)]
    iron = core.join([door, knock] + studs, "Iron")
    core.tag(iron, "Metal")
    core.uv_box(iron, 1.0)
    paint.paint([iron], lambda c, n, o: paint.mix(P.IRON, paint.hex3("3a4a40"), 0.3), ao=0.3, ground=0.0, edge=0.5)
    return {"Kind": "landmark", "LodDistance": 200}


def hearse():
    """A Victorian funeral carriage (6 x 12 footprint): lacquered body with glass panels, gilt trim, curved roof
    with urn finials, spoked wheels (one off and lying beside it)."""
    parts = []
    body = shapes.box("Body", (4.6, 9.2, 3.4), (0, 0, 2.9), bevel=0.18, segments=3, material="Wood")
    roof = shapes.box("Roof", (5.2, 10.0, 0.5), (0, 0, 4.9), bevel=0.15, segments=2, material="Wood")
    for v in roof.data.vertices:
        v.co.z += 0.35 * (1 - (v.co.x / 2.6) ** 2)
    under = shapes.box("Under", (3.4, 8.0, 0.6), (0, 0, 1.0), bevel=0.08, material="Wood")
    seat = shapes.box("Seat", (3.6, 1.6, 1.2), (0, -5.4, 3.2), bevel=0.12, material="Wood")
    lacquer = core.join([body, roof, under, seat], "Lacquer")
    core.tag(lacquer, "Wood")
    glass = []
    for side in (-1, 1):
        for i in range(3):
            glass.append(shapes.box(f"Pane{side}{i}", (0.06, 2.2, 1.9), (side * 2.32, -2.6 + i * 2.6, 3.2), material="Glass"))
    panes = core.join(glass, "Glass")
    core.tag(panes, "SmoothPlastic", alpha=0.3, lod=False)
    trim = []
    for side in (-1, 1):
        trim.append(shapes.box(f"Rail{side}", (0.12, 9.4, 0.14), (side * 2.36, 0, 4.25), material="Metal"))
        trim.append(shapes.box(f"Sill{side}", (0.12, 9.4, 0.14), (side * 2.36, 0, 2.1), material="Metal"))
        for i in range(4):
            trim.append(shapes.box(f"Post{side}{i}", (0.12, 0.14, 2.2), (side * 2.36, -3.9 + i * 2.6, 3.2), material="Metal"))
    for sx in (-1, 1):
        for sy in (-1, 1):
            urn = shapes.lathe(f"Urn{sx}{sy}", [(0.0, 5.2), (0.12, 5.2), (0.25, 5.4), (0.15, 5.7), (0.22, 5.85), (0.0, 6.2)], 10, "Metal")
            core.transform(urn, (sx * 2.2, sy * 4.6, 0))
            trim.append(urn)
    gilt = core.join(trim, "Gilt")
    core.tag(gilt, "Metal", lod=False)
    wheels = []
    for k, (x, y, z, rot) in enumerate(((-2.7, -3.4, 1.25, (0, 90, 0)), (2.7, -3.4, 1.25, (0, 90, 0)), (-2.7, 3.6, 1.25, (0, 90, 0)),
                                        (3.9, 5.6, 0.18, (0, 0, 0)))):
        rim = shapes.tube(f"Rim{k}", [(1.2 * math.cos(a), 1.2 * math.sin(a), 0) for a in [i / 24 * math.tau for i in range(25)]], 0.1, 6, "Wood",
                          cap_start=False, cap_end=False)
        spokes = [shapes.tube(f"Sp{k}{i}", [(0, 0, 0), (1.15 * math.cos(i / 10 * math.tau), 1.15 * math.sin(i / 10 * math.tau), 0)], 0.045, 4, "Wood")
                  for i in range(10)]
        hub = shapes.cylinder(f"Hub{k}", 0.22, 0.4, (0, 0, 0), segments=10, material="Metal")
        w = core.join([rim, hub] + spokes, f"Wheel{k}")
        w.rotation_euler = tuple(math.radians(a) for a in rot)
        w.location = (x, y, z)
        core.apply_transform(w)
        wheels.append(w)
    wood = core.join(wheels, "Wheels")
    core.tag(wood, "Wood")
    for o in (lacquer, gilt, wood):
        core.uv_box(o, 2.0)
        core.smooth(o, 40)
    paint.paint([lacquer, wood], lambda c, n, o: LACQUER if o.name == "Lacquer" else paint.hex3("2a1f1a"), ao=0.5, ao_distance=1.0, ground=0.0,
                edge=0.3, mottle=0.08)
    paint.paint([gilt], lambda c, n, o: GOLD, ao=0.2, ground=None, edge=0.4)
    paint.solid([panes], paint.hex3("1c2430"))
    return {"Kind": "landmark", "LodDistance": 160}


def well():
    """Old stone well (radius 3) with timber posts, a shingled roof, crank, rope and bucket."""
    rng = random.Random(3)
    stones = []
    for ring in range(4):
        n = 14
        for i in range(n):
            a = (i + 0.5 * (ring % 2)) / n * math.tau
            r = 2.65
            b = shapes.box(f"S{ring}_{i}", (1.25, 0.8, 0.62), (0, 0, 0), bevel=0.1, segments=1, material="Slate")
            b.rotation_euler = (0, 0, a + math.pi / 2)
            b.location = (math.cos(a) * r, math.sin(a) * r, 0.33 + ring * 0.65)
            core.apply_transform(b)
            stones.append(b)
    lip = shapes.lathe("Lip", [(2.2, 2.75), (3.15, 2.75), (3.2, 2.95), (2.15, 2.95)], 24, "Slate", cap_bottom=False, cap_top=False)
    water = shapes.cylinder("Water", 2.3, 0.1, (0, 0, 1.2), segments=20, material="SmoothPlastic")
    stone = core.join(stones + [lip], "Stone")
    core.tag(stone, "Slate")
    _finish_stone([stone], 4, angle=35)
    core.tag(water, "SmoothPlastic", lod=False)
    paint.solid([water], paint.hex3("0c1218"))
    wood = []
    for sx in (-1, 1):
        wood.append(shapes.box(f"Post{sx}", (0.5, 0.5, 6.2), (sx * 2.9, 0, 3.1), bevel=0.05, material="Wood"))
    roof = shapes.box("Roof", (7.2, 4.4, 0.25), (0, 0, 6.6), bevel=0.04, material="Wood")
    for v in roof.data.vertices:
        v.co.z += 1.2 * (1 - abs(v.co.y) / 2.2)
    wood.append(roof)
    wood.append(shapes.cylinder("Axle", 0.18, 5.4, (0, 0, 5.0), (0, 90, 0), segments=8, material="Wood"))
    wood.append(shapes.tube("Crank", [(2.9, 0, 5.0), (3.3, 0, 5.0), (3.3, 0.4, 4.6), (3.6, 0.4, 4.6)], 0.06, 5, "Metal"))
    rope = shapes.tube("Rope", [(0, 0, 4.85), (0, 0, 2.6)], 0.05, 5, "Fabric")
    bucket = shapes.lathe("Bucket", [(0.0, 1.9), (0.35, 1.9), (0.42, 2.5), (0.38, 2.55)], 10, "Wood", cap_top=False)
    timber = core.join(wood + [rope, bucket], "Timber")
    core.tag(timber, "Wood")
    core.uv_box(timber, 2.0)
    paint.paint([timber], lambda c, n, o: paint.mix(P.WOOD, P.WOOD_GREY, 0.4), ao=0.5, ground=0.0, edge=0.3, mottle=0.1)
    _ = rng
    return {"Kind": "landmark", "LodDistance": 160}


ASSETS = {"landmark_angel": weeping_angel, "landmark_belltower": bell_tower, "landmark_mausoleum": mausoleum, "landmark_hearse": hearse,
          "landmark_well": well}


# --------------------------------------------------------------------------------------------------------
# Woodland, Spider Woodland and Settlement set pieces; crypt walls, gate and coffins.
def hollow_oak():
    """A huge gnarled oak (8 wide, ~30 tall) with a hollow opening on its front (-Y), heavy roots and limbs."""
    rng = random.Random(31)
    prof = [(5.6, 0.0), (4.6, 0.6), (4.0, 1.6)] + [(3.9 - 0.025 * (z - 2.4), z) for z in [2.4 + 0.7 * i for i in range(10)]] + \
        [(3.6, 10.0), (3.3, 14.0), (2.9, 18.0), (2.7, 21.0)]
    trunk = shapes.lathe("Trunk", prof, 36, "Wood", cap_bottom=False, cap_top=True, wobble=0.12, seed=4)
    for v in trunk.data.vertices:
        a = math.atan2(v.co.y, v.co.x)
        rr = 1 + 0.08 * math.sin(a * 7 + v.co.z * 0.35) + 0.05 * math.sin(a * 13)
        front = max(0.0, -math.sin(a))
        if 0.6 < v.co.z < 7.5 and front > 0.75:  # the hollow: a tall dark recess
            depth = (front - 0.75) / 0.25 * min(1.0, (v.co.z - 0.6) / 1.2, (7.5 - v.co.z) / 1.5)
            rr *= 1 - 0.45 * depth
        v.co.x *= rr
        v.co.y *= rr
        v.co.x += 0.6 * math.sin(v.co.z * 0.18)
    parts = [trunk] + roots(rng, 4.2, 7, 6.0)
    for k in range(5):
        a = k / 5 * math.tau + rng.uniform(-0.3, 0.3)
        d = Vector((math.cos(a), math.sin(a) * 0.8 + 0.25, 0.5)).normalized()
        gnarled(rng, parts, Vector((0, 0, 17 + rng.uniform(0, 4))), d, rng.uniform(9, 13), 1.2, 0, 2, spread=0.9, droop=0.3, n_branches=2,
                name=f"Limb{k}")
    wood = _finish_wood(parts, "warm", 31)
    me = wood.data
    col = me.color_attributes["Col"]
    for li, loop in enumerate(me.loops):  # darken the recess walls
        p = me.vertices[loop.vertex_index].co
        if p.y < -1.9 and 0.8 < p.z < 7.3 and abs(p.x) < 2.2:
            c = col.data[li].color_srgb
            col.data[li].color_srgb = (c[0] * 0.35, c[1] * 0.3, c[2] * 0.3, 1)
    # The hollow's dark interior: an inset shell that shows only where the recess cuts in.
    hollow = shapes.sphere("Hollow", 1.0, (0.35, -2.55, 4.0), (1.35, 0.55, 3.0), 16, 10, "Wood")
    core.tag(hollow, "Wood", lod=False)
    paint.solid([hollow], (0.035, 0.025, 0.02))
    return {"Kind": "landmark", "LodDistance": 240}


def den():
    """A rocky den mound 10 wide, 8 deep and 5 high with a dark burrow mouth on its front, framed by boulders and bones."""
    import bmesh
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=4, radius=1.0)
    mound = core.obj_from_bmesh("Mound", bm, "Slate")
    for v in mound.data.vertices:
        p = v.co.copy()
        d = 1 + 0.14 * noise.noise(p * 2.0) + 0.05 * noise.noise(p * 5)
        v.co = Vector((p.x * 5.0 * d, p.y * 4.0 * d, max(-0.15, p.z * 5.0 * d)))
        if p.y < -0.45 and abs(p.x) < 0.38 and p.z < 0.62:  # the burrow mouth
            v.co.y *= 0.55 + 0.45 * (abs(p.x) / 0.38) ** 2
    core.smooth(mound, 45)
    core.uv_box(mound, 3.0)
    boulders = []
    for k, (x, y, z, s) in enumerate(((-2.4, -3.1, 0.2, 1.2), (2.5, -3.0, 0.2, 1.3), (0.2, -2.7, 3.0, 1.1), (-4.0, -1.6, 0.0, 0.9),
                                      (4.1, -1.2, 0.0, 0.8))):
        bm = bmesh.new()
        bmesh.ops.create_icosphere(bm, subdivisions=2, radius=1.0)
        b = core.obj_from_bmesh(f"Rock{k}", bm, "Slate")
        for v in b.data.vertices:
            v.co *= 1 + 0.2 * noise.noise(v.co * 1.5 + Vector((k, 0, 0)))
        core.transform(b, (x, y, z), scale=(s, s * 0.8, s * 0.85))
        boulders.append(b)
    stone = core.join([mound] + boulders, "Stone")
    core.tag(stone, "Slate")

    def col(c, n, o):
        if c.y < -1.6 and abs(c.x) < 1.7 and c.z < 2.9 and n.y > -0.5 and n.z < 0.6:
            return (0.025, 0.02, 0.022)
        base = paint.mix(P.STONE_DARK, paint.hex3("4a3d33"), 0.5 + 0.5 * noise.noise(c * 0.5))
        return paint.mix(base, P.MOSS, max(0.0, n.z - 0.4) * 1.1)

    paint.paint([stone], col, ao=0.6, ao_distance=1.5, ground=0.0, edge=0.3, crease=0.5, mottle=0.12, mottle_scale=0.8)
    bones = [shapes.tube(f"Bone{k}", [(x - 0.35, -4.3 - k * 0.2, 0.1), (x + 0.35, -4.5 - k * 0.2, 0.14)], 0.07, 5, "SmoothPlastic")
             for k, x in enumerate((-1.4, 1.1, 2.2))]
    skull = shapes.sphere("Skull", 0.24, (-0.5, -4.6, 0.2), (1, 1.2, 0.9), 10, 6, "SmoothPlastic")
    bone = core.join(bones + [skull], "Bones")
    core.tag(bone, "SmoothPlastic", lod=False, detail=True)
    paint.paint([bone], lambda c, n, o: P.BONE, ao=0.3, ground=0.0, edge=0.3)
    return {"Kind": "landmark", "LodDistance": 140}


def brood_tree():
    """The spider brood tree: a pale dead giant (7 wide, ~32 tall) with long silk-wrapped limbs."""
    rng = random.Random(41)
    trunk = shapes.lathe("Trunk", [(4.6, 0.0), (3.6, 0.8), (3.2, 2.0), (3.0, 8.0), (2.6, 16.0), (2.1, 24.0), (1.4, 30.0), (0.6, 33.0)], 22, "Wood",
                         cap_bottom=False, wobble=0.15, seed=9)
    for v in trunk.data.vertices:
        a = math.atan2(v.co.y, v.co.x)
        k = 1 + 0.1 * math.sin(a * 6 + v.co.z * 0.5)
        v.co.x = v.co.x * k + 0.8 * math.sin(v.co.z * 0.15)
        v.co.y *= k
    parts = [trunk] + roots(rng, 3.4, 6, 5.0)
    for k in range(4):  # server limbs: yaw 45 + 90k degrees, drooping 30 degrees from 24 high (Blender dir = (sin a, -cos a))
        a = math.radians(45 + 90 * k)
        d = Vector((math.sin(a), -math.cos(a), -0.45)).normalized()
        gnarled(rng, parts, Vector((0, 0, 24)), d, 17, 1.0, 0, 2, spread=0.5, droop=0.2, n_branches=2, name=f"Limb{k}")
    wood = _finish_wood(parts, "grey", 41)
    me = wood.data
    col = me.color_attributes["Col"]
    for li, loop in enumerate(me.loops):  # silk-whitened bark
        p = me.vertices[loop.vertex_index].co
        k = 0.5 + 0.5 * noise.noise(p * 0.6)
        c = col.data[li].color_srgb
        m = paint.mix((c[0], c[1], c[2]), paint.hex3("cfcac0"), 0.25 + 0.35 * k)
        col.data[li].color_srgb = (m[0], m[1], m[2], 1)
    hollow = shapes.sphere("Hollow", 1.0, (0, -2.75, 6.0), (1.5, 0.5, 1.6), 14, 8, "Wood")
    core.tag(hollow, "Wood", lod=False)
    paint.solid([hollow], (0.03, 0.022, 0.02))
    return {"Kind": "landmark", "LodDistance": 240}


def stump_broken():
    """A broken stump 4 wide and 6 tall with a splintered top (cocoon cluster base)."""
    rng = random.Random(51)
    st = shapes.lathe("Stump", [(2.6, 0.0), (2.1, 0.5), (1.9, 1.5), (1.85, 4.8), (1.6, 5.6), (0.0, 5.2)], 18, "Wood", cap_bottom=False,
                      wobble=0.1, seed=3)
    for v in st.data.vertices:
        if v.co.z > 4.5 and math.hypot(v.co.x, v.co.y) > 0.6:
            a = math.atan2(v.co.y, v.co.x)
            v.co.z += 1.3 * max(0.0, math.sin(a * 4 + 1)) + 0.3 * rng.random()
    flare = shapes.lathe("Flare", [(3.0, 0.0), (2.3, 0.45), (2.0, 1.1)], 18, "Wood", cap_bottom=False, cap_top=False, wobble=0.15, seed=5)
    _finish_wood([st, flare] + roots(rng, 1.5, 4, 3.6), "warm", 51)
    return {"Kind": "landmark", "LodDistance": 160}


def chapel_steeple():
    """Brick steeple 5 x 5 x 22 with a belfry opening and a broken, leaning spire stump."""
    stone = _courses("Tower", 5, 5, 0, 17.0, course=0.85, bevel=0.05, seed=12, material="Brick")
    for k, (dx, dy, rot) in enumerate(((0, -2.5, 0), (0, 2.5, 0))):
        arc = _arch(f"Belfry{k}", 2.4, 18.6, 1.0, 0.8, 0.25, material="Brick")
        core.transform(arc, (dx, dy, 0), (0, 0, rot))
        stone.append(arc)
    for sx in (-1, 1):
        for sy in (-1, 1):
            stone.append(shapes.box(f"Pier{sx}{sy}", (1.2, 1.2, 3.4), (sx * 1.9, sy * 1.9, 18.7), bevel=0.04, segments=1, material="Brick"))
    stone.append(shapes.box("Cornice", (5.6, 5.6, 0.5), (0, 0, 20.6), bevel=0.05, segments=1, material="Brick"))
    spire = shapes.lathe("Spire", [(3.9, 20.85), (3.2, 21.3), (1.9, 23.8), (0.9, 25.6), (0.6, 26.1), (0.0, 25.7)], 4, "RoofShingles",
                         cap_bottom=True, cap_top=True)
    for v in spire.data.vertices:  # snapped tip, sagging to one side
        if v.co.z > 23.0:
            v.co.x += (v.co.z - 23.0) * 0.35
            v.co.z -= 0.25 * max(0.0, v.co.y)
    core.transform(spire, rot=(0, 0, 45))
    finial = shapes.tube("Finial", [(0.9, 0, 25.7), (1.25, 0.2, 26.6), (2.4, 0.4, 26.9)], 0.07, 4, "Metal")
    tower = core.join(stone, "Brick")
    core.tag(tower, "Brick")
    core.uv_box(tower, 3.0)
    core.smooth(tower, 35)
    paint.paint([tower], lambda c, n, o: paint.mix(paint.hex3("7a4a3a"), paint.hex3("4f3027"), 0.4 + 0.4 * noise.noise(c * 0.8)), ao=0.6,
                ao_distance=1.2, ground=0.0, edge=0.25, crease=0.5, mottle=0.1)
    spire = core.join([spire, finial], "Spire")
    core.tag(spire, "Slate")
    core.uv_box(spire, 2.0)
    paint.paint([spire], lambda c, n, o: paint.mix(P.ROOF_DARK, P.ROOF, 0.3 + 0.3 * noise.noise(c * 1.3)), ao=0.4, ground=None, edge=0.3,
                mottle=0.12)
    return {"Kind": "landmark", "LodDistance": 220}


def barn_wall():
    """A weathered plank wall 8 long and 12 high (stretched to each barn wall), with missing boards."""
    rng = random.Random(61)
    planks = []
    x = -4.0
    while x < 4.0:
        w = rng.uniform(0.55, 0.75)
        h = 12 - (rng.uniform(0, 5) if rng.random() < 0.25 else rng.uniform(0, 0.6))
        if rng.random() > 0.08:
            planks.append(shapes.box(f"P{len(planks)}", (min(w, 4.0 - x) - 0.04, 0.22, h), (x + w / 2, rng.uniform(-0.04, 0.04), h / 2), bevel=0.03,
                                     segments=1, material="WoodPlanks"))
        x += w
    for z in (2.0, 6.5, 10.5):
        planks.append(shapes.box(f"Beam{z}", (8.0, 0.35, 0.45), (0, 0.28, z), bevel=0.04, material="WoodPlanks"))
    wall = core.join(planks, "Wood")
    core.tag(wall, "WoodPlanks")
    core.uv_box(wall, 3.0)
    core.smooth(wall, 35)
    paint.paint([wall], lambda c, n, o: paint.mix(paint.hex3("6a5544"), P.WOOD_GREY, 0.35 + 0.35 * noise.noise(c * 1.5)), ao=0.5, ground=0.0,
                edge=0.25, crease=0.4, mottle=0.12)
    return {"Kind": "prop", "LodDistance": 160, "Length": 8.0}


def barn_roof():
    """A collapsed shingle roof slab 11 x 18 with broken rafters showing."""
    rng = random.Random(62)
    slab = shapes.box("Slab", (11.0, 18.0, 0.6), (0, 0, 0), material="RoofShingles")
    core.subdivide(slab, 3, simple=True)
    for v in slab.data.vertices:
        v.co.z += 0.5 * math.sin(v.co.y * 0.35) + 0.25 * noise.noise(v.co * 0.4)
        if v.co.y > 6.5 and v.co.x > 1.0:  # a torn corner
            v.co.z -= 1.2 * (v.co.y - 6.5) / 2.5
    rafters = [shapes.box(f"R{k}", (0.4, 0.5, 2.4), (rng.uniform(-4, 4), 8.6 + rng.uniform(0, 0.6), 0.6), (rng.uniform(-30, 30), 20, 0), material="Wood")
               for k in range(4)]
    roof = core.join([slab] + rafters, "Roof")
    core.tag(roof, "Slate")
    core.uv_box(roof, 3.0)
    core.smooth(roof, 35)
    paint.paint([roof], lambda c, n, o: paint.mix(P.ROOF, P.ROOF_DARK, 0.5 + 0.3 * noise.noise(c * 0.6)), ao=0.4, ground=None, edge=0.3,
                mottle=0.1)
    return {"Kind": "prop", "LodDistance": 160}


def hay_bale():
    """A bound hay bale 4 x 3 x 3: tufted straw block tied with two cords."""
    bale = shapes.box("Bale", (4.0, 3.0, 3.0), (0, 0, 1.5), bevel=0.4, segments=3, material="Fabric")
    core.subdivide(bale, 1, simple=True)
    for v in bale.data.vertices:  # loose straw tufts and a sagging top
        v.co += v.normal * 0.07 * noise.noise(v.co * 4.0)
        v.co.z -= 0.12 * max(0.0, v.co.z - 2.6) * (1 - abs(v.co.x) / 2.2)
    cords = []
    for x in (-1.0, 1.0):
        pts = [(x, 1.8 * math.cos(a), 1.5 + 1.8 * math.sin(a)) for a in [i / 32 * math.tau for i in range(33)]]
        pts = [(px, max(-1.63, min(1.63, py)), max(-0.02, min(3.12, pz))) for px, py, pz in pts]
        cords.append(shapes.tube(f"Cord{x}", pts, 0.07, 4, "Fabric", cap_start=False, cap_end=False))
    rng = random.Random(81)
    for k in range(14):  # stray straws
        p = Vector((rng.uniform(-1.9, 1.9), rng.uniform(-1.4, 1.4), 3.0))
        d = Vector((rng.uniform(-1, 1), rng.uniform(-1, 1), rng.uniform(0.1, 0.5))).normalized() * rng.uniform(0.5, 0.9)
        cords.append(shapes.tube(f"Straw{k}", [p, p + d], 0.025, 3, "Fabric"))
    cord = core.join(cords, "Cord")
    core.tag(cord, "Fabric", lod=False, detail=True)
    paint.paint([cord], lambda c, n, o: paint.hex3("4a3b2c") if c.z < 2.9 or abs(c.x - 1.0) < 0.1 or abs(c.x + 1.0) < 0.1 else
                paint.hex3("a38f5c"), ao=0.0, ground=None, edge=0.0)
    core.tag(bale, "Fabric")
    core.uv_box(bale, 1.5)
    core.smooth(bale, 50)
    paint.paint([bale], lambda c, n, o: paint.mix(paint.hex3("9a8656"), paint.hex3("6f6040"), 0.35 + 0.45 * noise.noise(c * 2.5)), ao=0.5,
                ground=0.0, edge=0.15, crease=0.3, mottle=0.18, mottle_scale=0.25)
    return {"Kind": "prop", "LodDistance": 120}


def beam_fallen():
    """A charred fallen roof beam 1 x 1 x 12 with a splintered end."""
    beam = shapes.box("Beam", (1.0, 12.0, 1.0), (0, 0, 0.5), bevel=0.08, material="Wood")
    core.subdivide(beam, 2, simple=True)
    for v in beam.data.vertices:
        if v.co.y > 5.4:
            v.co.y += 0.6 * noise.noise(v.co * 3)
    core.displace_noise(beam, 0.04, 0.3, 2)
    core.uv_box(beam, 2.0)
    core.smooth(beam, 35)
    paint.paint([beam], lambda c, n, o: paint.mix(paint.hex3("2a201b"), paint.hex3("4a3a30"), 0.5 + 0.5 * noise.noise(c)), ao=0.3, ground=0.0, edge=0.3)
    return {"Kind": "prop", "LodDistance": 120}


def crypt_wall():
    """Gothic crypt wall 8 long, 12 high, 2 thick: stone courses, a buttress and spiked iron cresting."""
    stone = []
    rng = random.Random(71)
    z = 0.0
    k = 0
    while z < 11.0:
        h = min(rng.uniform(0.95, 1.25), 11.0 - z)
        x = -4.0
        first = rng.uniform(0.6, 1.6) if k % 2 else rng.uniform(1.4, 2.2)
        while x < 3.95:
            w = min(first if x == -4.0 else rng.uniform(1.5, 2.4), 4.0 - x)
            stone.append(shapes.box(f"C{k}_{len(stone)}", (w - 0.07, 2.0 + rng.uniform(-0.06, 0.06), h - 0.07),
                                    (x + w / 2, rng.uniform(-0.03, 0.03), z + h / 2), bevel=0.07, segments=1, material="Slate"))
            x += w
        z += h
        k += 1
    stone.append(shapes.box("Core", (7.9, 1.8, 10.9), (0, 0, 5.5), material="Slate"))
    stone.append(shapes.box("Coping", (8.0, 2.5, 0.6), (0, 0, 11.3), bevel=0.08, segments=1, material="Slate"))
    stone.append(shapes.box("Buttress", (1.4, 1.2, 8.0), (-3.3, -1.5, 4.0), bevel=0.06, segments=1, material="Slate"))
    cap = shapes.box("ButtCap", (1.4, 1.2, 1.2), (-3.3, -1.5, 8.4), material="Slate")
    for v in cap.data.vertices:
        if v.co.z > 8.4 and v.co.y < -1.5:
            v.co.z -= 1.0
    stone.append(cap)
    for b in stone:
        _chip(b, 0.03, 0.4, 3)
    wall = core.join(stone, "Stone")
    core.tag(wall, "Slate")
    _finish_stone([wall], 9, angle=35, studs=3.0)
    iron = [shapes.box("Rail", (8.0, 0.12, 0.12), (0, 0, 12.0), material="Metal")]
    for i in range(10):
        x = -3.6 + i * 0.8
        iron.append(shapes.cylinder(f"Spike{i}", 0.04, 0.9, (x, 0, 12.0), segments=4, material="Metal"))
        iron.append(shapes.lathe(f"Tip{i}", [(0.0, 12.4), (0.09, 12.5), (0.0, 12.8)], 4, "Metal"))
        core.transform(iron[-1], (x, 0, 0))
    rail = core.join(iron, "Iron")
    core.tag(rail, "Metal", lod=False, detail=True)
    paint.paint([rail], lambda c, n, o: P.IRON, ao=0.2, ground=None, edge=0.5)
    return {"Kind": "prop", "LodDistance": 160, "Length": 8.0}


def crypt_gate_leaf():
    """One wrought-iron crypt gate leaf, 4 wide and 10 high, hinged at x = 0 (the server places two, mirrored, and
    the client swings them open for players who unlocked the crypt)."""
    iron = []
    x0 = 2.0
    iron.append(shapes.box("FrameB", (3.9, 0.18, 0.18), (x0, 0, 0.3), material="Metal"))
    iron.append(shapes.box("FrameT", (3.9, 0.18, 0.18), (x0, 0, 8.6), material="Metal"))
    iron.append(shapes.box("Hinge", (0.24, 0.24, 9.4), (0.1, 0, 4.7), material="Metal"))
    iron.append(shapes.box("Stile", (0.2, 0.2, 9.0), (3.9, 0, 4.5), material="Metal"))
    for i in range(7):
        x = 0.35 + i * 0.55
        top = 8.6 + 1.0 * math.sin((x / 4.0) * math.pi * 0.5 + 0.2)
        iron.append(shapes.cylinder(f"Bar{i}", 0.05, top, (x, 0, top / 2), segments=5, material="Metal"))
        iron.append(shapes.lathe(f"Spear{i}", [(0.0, top), (0.11, top + 0.15), (0.03, top + 0.5), (0.0, top + 0.55)], 4, "Metal"))
        core.transform(iron[-1], (x, 0, 0))
    for j in range(2):
        cz = 3.0 + j * 3.0
        ring = [(x0 + 0.7 * math.cos(a), 0, cz + 0.7 * math.sin(a)) for a in [m / 16 * math.tau for m in range(17)]]
        iron.append(shapes.tube(f"Ring{j}", ring, 0.05, 4, "Metal", cap_start=False, cap_end=False))
    scroll = [(0.4 + 3.2 * t, 0, 7.6 + 0.5 * math.sin(t * math.tau)) for t in [i / 16 for i in range(17)]]
    iron.append(shapes.tube("Scroll", scroll, 0.045, 4, "Metal", cap_start=False, cap_end=False))
    lock = shapes.box("Lock", (0.45, 0.32, 0.65), (3.75, -0.2, 4.6), bevel=0.05, material="Metal")
    chain = shapes.tube("Chain", [(3.2, -0.25, 4.95), (3.75, -0.38, 4.35), (4.15, -0.25, 4.95)], 0.06, 5, "Metal", resample=3)
    gate = core.join(iron + [lock, chain], "Iron")
    core.tag(gate, "Metal")
    core.uv_box(gate, 2.0)
    core.smooth(gate, 35)
    paint.paint([gate], lambda c, n, o: paint.mix(P.IRON, paint.hex3("3d4a42"), 0.25 + 0.2 * noise.noise(c * 2)), ao=0.3, ground=None, edge=0.5,
                mottle=0.1)
    return {"Kind": "prop", "LodDistance": 140, "Length": 4.0}


def standing_stone():
    """A weathered standing stone 3 wide, 1.6 deep and 11 high (scaled in height per stone) with a carved spiral."""
    stone = shapes.box("Slab", (3.0, 1.6, 11.0), (0, 0, 5.5), bevel=0.3, segments=2, material="Slate")
    core.subdivide(stone, 2, simple=True)
    for v in stone.data.vertices:
        t = v.co.z / 11.0
        taper = 1 - 0.18 * t
        v.co.x *= taper
        v.co.y *= 1 - 0.1 * t
        if v.co.z > 10.0:
            v.co.z -= 0.8 * max(0.0, v.co.x / 1.5)  # a slanted, broken top
        v.co += v.normal * 0.12 * noise.noise(v.co * 0.7)
    _chip(stone, 0.06, 0.5, 5)
    spiral = [(0.55 * t * math.cos(t * 9), -0.86, 6.5 + 0.55 * t * math.sin(t * 9)) for t in [i / 40 for i in range(41)]]
    carve = shapes.tube("Spiral", spiral, 0.06, 4, "Slate")
    obj = core.join([stone, carve], "Stone")
    core.tag(obj, "Slate")
    _finish_stone([obj], 13, angle=40, studs=2.5)
    me = obj.data
    col = me.color_attributes["Col"]
    for li, loop in enumerate(me.loops):  # lichen low down, a faint glow in the carving
        p = me.vertices[loop.vertex_index].co
        c = col.data[li].color_srgb
        if p.y < -0.8 and math.hypot(p.x, p.z - 6.5) < 0.62:
            m = paint.hex3("6f7fa8")
        else:
            m = paint.mix((c[0], c[1], c[2]), P.MOSS, max(0.0, 0.5 - p.z / 6) * (0.6 + 0.4 * noise.noise(p * 2)))
        col.data[li].color_srgb = (m[0], m[1], m[2], 1)
    return {"Kind": "prop", "LodDistance": 160, "Height": 11.0}


def stone_altar():
    """A low sacrificial altar slab 5 x 3 x 1.6 on two blocks, with old wax and a stain."""
    top = shapes.box("Top", (5.0, 3.0, 0.6), (0, 0, 1.3), bevel=0.1, segments=1, material="Slate")
    core.subdivide(top, 1, simple=True)
    _chip(top, 0.05, 0.4, 7)
    legs = [shapes.box(f"Leg{x}", (1.2, 2.4, 1.0), (x, 0, 0.5), bevel=0.08, segments=1, material="Slate") for x in (-1.6, 1.6)]
    obj = core.join([top] + legs, "Stone")
    core.tag(obj, "Slate")
    _finish_stone([obj], 17, angle=40)
    me = obj.data
    col = me.color_attributes["Col"]
    for li, loop in enumerate(me.loops):
        p = me.vertices[loop.vertex_index].co
        if p.z > 1.55 and math.hypot(p.x - 0.6, p.y + 0.2) < 0.9 + 0.2 * noise.noise(p * 3):
            c = col.data[li].color_srgb
            m = paint.mix((c[0], c[1], c[2]), paint.hex3("4a1c1c"), 0.6)
            col.data[li].color_srgb = (m[0], m[1], m[2], 1)
    wax = [shapes.lathe(f"Wax{k}", [(0.0, 1.6), (0.16, 1.6), (0.13, 1.6 + h), (0.0, 1.6 + h)], 8, "SmoothPlastic")
           for k, h in enumerate((0.35, 0.22, 0.5))]
    for k, w in enumerate(wax):
        core.transform(w, ((-1.8, -1.5, -1.9)[k], (0.9, 0.7, -0.9)[k], 0))
    candles = core.join(wax, "Wax")
    core.tag(candles, "SmoothPlastic", lod=False, detail=True)
    paint.paint([candles], lambda c, n, o: paint.hex3("d9cfb4"), ao=0.2, ground=None, edge=0.1)
    return {"Kind": "prop", "LodDistance": 120}


def coffin():
    """A wooden coffin 3 x 7 x 1.4 (hexagonal) with its lid slid aside."""
    hexa = [(0.0, -3.5), (1.25, -2.4), (1.5, 1.2), (0.0, 3.5)]
    def outline(sc):
        pts = [(1.0 * sc, -3.4), (1.5 * sc, -1.8), (1.2 * sc, 3.4), (-1.2 * sc, 3.4), (-1.5 * sc, -1.8), (-1.0 * sc, -3.4)]
        return pts
    import bmesh
    def prism(name, sc, z0, z1, mat):
        bm = bmesh.new()
        bot = [bm.verts.new((x, y, z0)) for x, y in outline(sc)]
        top = [bm.verts.new((x, y, z1)) for x, y in outline(sc)]
        bm.faces.new(list(reversed(bot)))
        bm.faces.new(top)
        for i in range(len(bot)):
            j = (i + 1) % len(bot)
            bm.faces.new((bot[i], bot[j], top[j], top[i]))
        o = core.obj_from_bmesh(name, bm, mat)
        core.bevel(o, 0.06, 2, 30)
        return o
    box = prism("Box", 1.0, 0.0, 1.1, "Wood")
    inner = prism("Inner", 0.85, 0.25, 1.15, "Wood")
    for p in inner.data.polygons:
        p.flip()
    lid = prism("Lid", 1.03, 1.1, 1.3, "Wood")
    core.transform(lid, (0.9, 0.6, 0.05), (0, 4, 14))
    obj = core.join([box, inner, lid], "Wood")
    core.tag(obj, "Wood")
    core.uv_box(obj, 2.0)
    core.smooth(obj, 30)
    paint.paint([obj], lambda c, n, o: paint.mix(P.WOOD_DARK, P.WOOD, 0.4 + 0.3 * noise.noise(c * 1.2)), ao=0.6, ao_distance=1.0, ground=0.0,
                edge=0.25, crease=0.5, mottle=0.1)
    _ = hexa
    return {"Kind": "prop", "LodDistance": 120}


ASSETS.update({"landmark_hollowoak": hollow_oak, "landmark_den": den, "landmark_broodtree": brood_tree, "stump_broken": stump_broken,
               "chapel_steeple": chapel_steeple, "barn_wall": barn_wall, "barn_roof": barn_roof, "hay_bale": hay_bale, "beam_fallen": beam_fallen,
               "crypt_wall": crypt_wall, "crypt_gate_leaf": crypt_gate_leaf, "coffin": coffin, "standing_stone": standing_stone,
               "stone_altar": stone_altar})


def sign_hanging():
    """A crooked wooden signpost 5.4 high: post, bracket arm and a 3.6 x 1.6 board hung on two chains (the server
    letters an invisible board part at (-2.1, 3.4, 0) in Roblox space, i.e. Blender (2.1, 0, 3.4))."""
    wood = [shapes.box("Post", (0.36, 0.36, 5.4), (0, 0, 2.7), (0, 2, 0), bevel=0.05, material="Wood"),
            shapes.box("Arm", (4.2, 0.26, 0.3), (1.95, 0, 5.0), bevel=0.04, material="Wood"),
            shapes.box("Brace", (0.2, 0.2, 1.6), (0.5, 0, 4.4), (0, 45, 0), bevel=0.03, material="Wood")]
    cap = shapes.lathe("Cap", [(0.0, 5.4), (0.3, 5.4), (0.0, 5.75)], 4, "Wood")
    core.transform(cap, rot=(0, 0, 45))
    board = shapes.box("Board", (3.6, 0.16, 1.6), (2.1, 0, 3.4), (0, -3, 0), bevel=0.05, segments=1, material="WoodPlanks")
    core.subdivide(board, 2, simple=True)
    for v in board.data.vertices:  # warped planks, chipped corner
        v.co.y += 0.03 * math.sin(v.co.x * 3)
        if v.co.x > 3.6 and v.co.z < 2.8:
            v.co.z += 0.25
    obj = core.join(wood + [cap, board], "Wood")
    core.tag(obj, "Wood")
    core.uv_box(obj, 2.0)
    core.smooth(obj, 35)
    paint.paint([obj], lambda c, n, o: paint.mix(paint.hex3("4a3628"), P.WOOD_GREY, 0.3 + 0.3 * noise.noise(c * 2)), ao=0.4, ground=0.0, edge=0.3,
                crease=0.4, mottle=0.12)
    links = [shapes.tube(f"Chain{x}", [(x, 0, 4.85), (x, 0, 4.2)], 0.04, 4, "Metal") for x in (0.6, 3.6)]
    iron = core.join(links, "Iron")
    core.tag(iron, "Metal", lod=False, detail=True)
    paint.paint([iron], lambda c, n, o: P.IRON, ao=0.1, ground=None, edge=0.4)
    return {"Kind": "prop", "LodDistance": 100}


ASSETS["sign_hanging"] = sign_hanging
