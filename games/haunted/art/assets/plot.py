"""Player plot and ghost-train art (TASK-0046): the ghost cart, track ties, trestles and route markers, the Scare Arch
and Fog Tunnel pieces, the station, plot walls and sign, the containment pen, exhibit plinths and trophies.

Server footprints (TrainService, PlotBuilder) stay as colliders or invisible parts; every asset's origin is the base
centre on the ground unless its docstring says otherwise. Blender -Y = the anchor's LookVector.
References: MIN-057-059 (vehicle finish: body, wheels, lamps, consistent detail), MIN-069 (masonry, iron, finials);
BAD-013/014 (flat cart platform with posts) are not repeated.
"""

import math
import random

from mathutils import noise

from hcart import anatomy as A
from hcart import core, paint, shapes
from hcart import palette as P

from assets.graveyard import _chip

GLOW = paint.hex3("aa6eff")
LACQUER = paint.hex3("2b1d36")
BRASS = P.BRASS
CRIMSON = paint.hex3("6e1f2c")
TIMBER = paint.hex3("4e3a2c")
RED_EYE = paint.hex3("ff4a36")


def _join_paint(groups, colors, ao_distance=1.2, detail=()):
    """groups: {part name: (material, [objs])}; paints all parts together so AO is shared."""
    objs = []
    for name, (mat, pieces) in groups.items():
        pieces = [p for p in pieces if p is not None]
        if not pieces:
            continue
        o = core.join(pieces, name)
        core.tag(o, mat, lod=mat != "Neon", detail=name in detail)
        core.uv_box(o, 2.0)
        core.smooth(o, 35)
        objs.append(o)
    lit = [o for o in objs if o["rbx_material"] == "Neon"]
    for o in lit:
        paint.solid([o], colors[o["rbx_part"]])
    shaded = [o for o in objs if o not in lit]

    def col(c, n, o):
        v = colors[o["rbx_part"]]
        return v(c, n) if callable(v) else v

    paint.paint(shaded, col, ao=0.5, ao_distance=ao_distance, ground=0.0, edge=0.25, crease=0.45, mottle=0.08, mottle_scale=0.8)
    return objs


def _wood(c, n):
    return paint.mix(TIMBER, P.WOOD_GREY, 0.3 + 0.3 * noise.noise(c * 1.6))


# ------------------------------------------------------------------------------------------------- train
def ghost_cart():
    """The ghost-train cart, 4 wide and 6 long: a lacquered coffin-gondola with brass trim, crimson tufted seats for two,
    a curled prow with a bone skull figurehead and a hanging ghost-lamp, and four spoked iron wheels. Origin = bottom of
    the server's Base part (base centre - 0.5); front (-Y) = travel direction."""
    body = shapes.box("Hull", (3.8, 5.6, 1.9), (0, 0.15, 1.25), bevel=0.35, segments=3, material="Wood")
    core.subdivide(body, 1, simple=True)
    for v in body.data.vertices:  # coffin taper: narrower at the back, flared shoulders, a rising prow
        t = (v.co.y + 2.65) / 5.6  # 0 front .. 1 back
        k = 1.0 - 0.12 * max(0.0, t - 0.5) * 2 - 0.1 * max(0.0, 0.25 - t) * 4
        v.co.x *= k
        if v.co.z > 1.6:
            v.co.z += 0.35 * max(0.0, 0.3 - t) / 0.3
    well = shapes.box("Well", (3.0, 4.6, 1.2), (0, 0.35, 1.85), bevel=0.15, segments=2, material="Wood")
    for p in well.data.polygons:
        p.flip()
    prow = shapes.tube("Prow", [(0, -2.6, 1.6), (0, -3.1, 2.3), (0, -3.25, 3.0), (0, -2.95, 3.35), (0, -2.75, 3.1)],
                       lambda t: 0.42 * (1 - t) + 0.12, 8, "Wood", resample=3)
    lacquer = [body, well, prow]
    trim = [shapes.box("Rub", (3.95, 5.7, 0.14), (0, 0.15, 2.1), bevel=0.05, material="Metal"),
            shapes.box("Skirt", (3.9, 5.5, 0.14), (0, 0.15, 0.55), bevel=0.05, material="Metal")]
    for sx in (-1, 1):
        for y in (-1.6, 0.0, 1.6):  # brass coffin handles and corner studs
            trim.append(shapes.tube(f"Handle{sx}{y}", [(sx * 1.93, y - 0.45, 1.35), (sx * 2.1, y - 0.3, 1.2), (sx * 2.1, y + 0.3, 1.2),
                                                        (sx * 1.93, y + 0.45, 1.35)], 0.06, 5, "Metal"))
        trim.append(shapes.tube(f"Curl{sx}", [(sx * 1.5, 2.6, 2.1), (sx * 1.6, 3.0, 2.6), (sx * 1.3, 3.15, 3.0), (sx * 1.15, 2.9, 2.85)],
                                0.08, 5, "Metal", resample=3))
    # lamp hook from the prow tip
    trim.append(shapes.tube("Hook", [(0, -2.8, 3.3), (0, -3.4, 3.55), (0, -3.55, 3.3)], 0.05, 5, "Metal", resample=3))
    cushions = []
    for y in (-1.2, 1.6):  # seat cushions at the server seats (surface ~ z 2.0) with buttoned backs
        cushions.append(shapes.box(f"Seat{y}", (2.8, 1.6, 0.45), (0, y + 0.1, 1.85), bevel=0.18, segments=3, material="Fabric"))
        back = shapes.box(f"Back{y}", (2.8, 0.4, 1.3), (0, y + 0.95, 2.55), (-12, 0, 0), bevel=0.18, segments=3, material="Fabric")
        cushions.append(back)
    skull = A.organic("SkullHead", [A.ell((0, -3.15, 1.95), (0.55, 0.5, 0.55)), A.ell((0, -3.4, 1.6), (0.32, 0.25, 0.22)),
                                    A.ell((0.2, -3.62, 2.0), (0.14, 0.1, 0.14), negative=True, stiffness=1.3),
                                    A.ell((-0.2, -3.62, 2.0), (0.14, 0.1, 0.14), negative=True, stiffness=1.3)], 300, resolution=0.04,
                      material="SmoothPlastic")
    eyes = [shapes.sphere(f"Eye{sx}", 0.09, (sx * 0.2, -3.58, 2.0), (1, 1, 1), 8, 5, "Neon") for sx in (-1, 1)]
    lamp_cage = shapes.lathe("LampCage", [(0.0, 2.65), (0.28, 2.75), (0.3, 3.15), (0.12, 3.3), (0.0, 3.35)], 6, "Metal")
    core.transform(lamp_cage, (0, -3.55, 0))
    trim.append(lamp_cage)
    lamp = shapes.lathe("LampGlass", [(0.0, 2.75), (0.22, 2.8), (0.22, 3.1), (0.0, 3.15)], 8, "Neon")
    core.transform(lamp, (0, -3.55, 0))
    wheels = []
    for sx in (-1.1, 1.1):
        for y in (-1.9, 1.9):
            rim = shapes.lathe(f"Rim{sx}{y}", [(0.45, -0.07), (0.55, -0.07), (0.55, 0.07), (0.45, 0.07)], 14, "Metal", cap_bottom=False,
                               cap_top=False)
            hub = shapes.cylinder(f"Hub{sx}{y}", 0.14, 0.22, (0, 0, 0), segments=8, material="Metal")
            spokes = [shapes.box(f"Sp{k}", (0.07, 0.9, 0.05), (0, 0, 0), (0, 0, k * 45), material="Metal") for k in range(4)]
            w = core.join([rim, hub] + spokes, f"W{sx}{y}")
            core.transform(w, rot=(0, 90, 0))
            core.transform(w, (sx * 1.45 / 1.1, y, 0.6))
            wheels.append(w)
    _join_paint({"Body": ("Wood", lacquer), "Trim": ("Metal", trim), "Seats": ("Fabric", cushions), "Skull": ("SmoothPlastic", [skull]),
                 "Wheels": ("Metal", wheels), "Lamp": ("Neon", [lamp]), "Eyes": ("Neon", eyes)},
                {"Body": lambda c, n: paint.mix(LACQUER, paint.hex3("432c52"), 0.3 + 0.3 * max(0.0, n.z)),
                 "Trim": lambda c, n: paint.mix(BRASS, P.BRONZE, 0.4 + 0.3 * noise.noise(c * 2)), "Seats": CRIMSON, "Skull": P.BONE,
                 "Wheels": P.IRON, "Lamp": GLOW, "Eyes": GLOW}, ao_distance=0.8, detail=("Eyes",))
    return {"Kind": "vehicle", "LodDistance": 120}


def track_tie():
    """One sleeper under the rails: a weathered tie 3.4 x 0.7 with iron chairs and spike heads at the rails (x = +-1.1).
    Origin = rail centreline (the tie top sits 0.12 below the rails' centre)."""
    rng = random.Random(7)
    tie = shapes.box("Tie", (3.4, 0.7, 0.26), (0, 0, -0.27), (0, 0, rng.uniform(-2, 2)), bevel=0.04, segments=1, material="Wood")
    iron = []
    for sx in (-1.1, 1.1):
        iron.append(shapes.box(f"Chair{sx}", (0.55, 0.5, 0.1), (sx, 0, -0.1), material="Metal"))
        for dy in (-0.16, 0.16):
            iron.append(shapes.box(f"Spike{sx}{dy}", (0.1, 0.1, 0.08), (sx + (0.22 if dy > 0 else -0.22), dy, -0.02), material="Metal"))
    _join_paint({"Wood": ("Wood", [tie]), "Iron": ("Metal", iron)}, {"Wood": _wood, "Iron": P.IRON}, ao_distance=0.4)
    return {"Kind": "prop", "LodDistance": 60, "Cull": 160}


def track_trestle():
    """A timber trestle 4 high under the track (stretched in height to the rail height): two splayed legs, a cap beam,
    an X brace and stone footings. Origin on the ground; the cap's top is at 4."""
    wood = [shapes.box("Cap", (3.4, 0.5, 0.4), (0, 0, 3.8), bevel=0.04, material="Wood")]
    for sx in (-1, 1):
        wood.append(shapes.box(f"Leg{sx}", (0.36, 0.36, 4.1), (sx * 1.25, 0, 1.9), (0, -sx * 7, 0), bevel=0.04, material="Wood"))
    for a in (1, -1):
        wood.append(shapes.box(f"Brace{a}", (0.16, 0.2, 3.6), (0, 0.12, 1.9), (0, a * 34, 0), bevel=0.02, material="Wood"))
    stones = [shapes.box(f"Foot{sx}", (0.8, 0.8, 0.35), (sx * 1.5, 0, 0.12), bevel=0.08, material="Slate") for sx in (-1, 1)]
    bolts = [shapes.cylinder(f"Bolt{sx}", 0.06, 0.5, (sx * 1.25, 0, 3.75), (90, 0, 0), segments=6, material="Metal") for sx in (-1, 1)]
    _join_paint({"Wood": ("Wood", wood), "Stone": ("Slate", stones), "Iron": ("Metal", bolts)},
                {"Wood": _wood, "Stone": P.STONE_DARK, "Iron": P.IRON}, ao_distance=0.8)
    return {"Kind": "prop", "LodDistance": 80, "Cull": 200, "Height": 4.0}


def track_marker():
    """A route marker: a short iron post 3 high with a caged ghost-flame (marks the editor's control points)."""
    iron = [shapes.lathe("Post", [(0.22, 0.0), (0.22, 0.15), (0.1, 0.25), (0.08, 2.3), (0.14, 2.35)], 6, "Metal")]
    iron.append(shapes.lathe("Cage", [(0.0, 2.35), (0.24, 2.45), (0.26, 2.85), (0.3, 2.9), (0.0, 3.1)], 6, "Metal"))
    flame = shapes.lathe("Flame", [(0.0, 2.45), (0.15, 2.55), (0.12, 2.75), (0.0, 2.88)], 8, "Neon")
    _join_paint({"Iron": ("Metal", iron), "Flame": ("Neon", [flame])}, {"Iron": P.IRON, "Flame": GLOW}, ao_distance=0.4, detail=("Flame",))
    return {"Kind": "prop", "LodDistance": 60, "Cull": 220}


def scare_arch():
    """The Scare Arch track piece: twisted timber posts 3.4 either side of the rails, a crossbeam hung with tattered
    cloth and bats, and a horned skull with red eyes at 10.4 (the server keeps its red light). Origin on the ground
    at the rail centre; the server origin is the rail height (1.4) above it."""
    rng = random.Random(23)
    wood = []
    for sx in (-1, 1):
        post = shapes.tube(f"Post{sx}", [(sx * 3.4, 0, 0), (sx * 3.45, 0.05, 4.0), (sx * 3.35, -0.05, 8.0), (sx * 3.4, 0, 10.6)],
                           lambda t: 0.5 - 0.15 * t, 8, "Wood", resample=3)
        for v in post.data.vertices:
            a = v.co.z * 0.9
            v.co.x += 0.06 * math.sin(a * 3)
            v.co.y += 0.06 * math.cos(a * 3)
        wood.append(post)
        wood.append(shapes.box(f"Knee{sx}", (1.6, 0.3, 0.3), (sx * 2.7, 0, 9.4), (0, sx * 40, 0), bevel=0.04, material="Wood"))
    beam = shapes.box("Beam", (8.6, 0.6, 0.8), (0, 0, 10.4), bevel=0.08, segments=1, material="Wood")
    core.subdivide(beam, 2, simple=True)
    for v in beam.data.vertices:
        v.co.z += 0.25 * math.sin(v.co.x * 0.4 + 0.5)
    wood.append(beam)
    cloth = []
    for k in range(7):  # tattered banners hanging from the beam
        x = -3.6 + k * 1.2 + rng.uniform(-0.2, 0.2)
        length = rng.uniform(1.6, 3.4)
        strip = shapes.box(f"Rag{k}", (rng.uniform(0.5, 0.9), 0.04, length), (x, 0.15, 10.1 - length / 2), bevel=0.0, segments=1, material="Fabric")
        core.subdivide(strip, 2, simple=True)
        for v in strip.data.vertices:
            d = 10.1 - v.co.z
            v.co.y += 0.12 * math.sin(d * 2 + k) * d / length
            if v.co.z < 10.1 - length + 0.25:
                v.co.z += rng.uniform(0, 0.35)
        cloth.append(strip)
    bone = [A.organic("Skull", [A.ell((0, -0.1, 11.3), (0.9, 0.8, 0.85)), A.ell((0, -0.45, 10.75), (0.55, 0.45, 0.35)),
                                A.ell((0.32, -0.75, 11.35), (0.22, 0.15, 0.22), negative=True, stiffness=1.3),
                                A.ell((-0.32, -0.75, 11.35), (0.22, 0.15, 0.22), negative=True, stiffness=1.3)], 500, resolution=0.05,
                      material="SmoothPlastic")]
    for sx in (-1, 1):
        bone.append(shapes.tube(f"Horn{sx}", [(sx * 0.6, 0, 11.9), (sx * 1.2, 0.1, 12.6), (sx * 1.4, 0.2, 13.4), (sx * 1.1, 0.3, 13.9)],
                                lambda t: 0.22 * (1 - t) + 0.03, 6, "SmoothPlastic", resample=3))
    eyes = [shapes.sphere(f"Eye{sx}", 0.16, (sx * 0.32, -0.7, 11.35), (1, 1, 1), 8, 5, "Neon") for sx in (-1, 1)]
    bats = []
    for k, (x, z) in enumerate(((-2.4, 9.2), (2.0, 8.8), (-0.9, 8.4))):
        wing = shapes.box(f"Bat{k}", (1.3, 0.05, 0.4), (x, -0.3, z), (0, 0, 0), bevel=0.0, segments=1, material="SmoothPlastic")
        core.subdivide(wing, 2, simple=True)
        for v in wing.data.vertices:
            v.co.z += 0.25 * abs(v.co.x - x) - 0.15 * math.cos((v.co.x - x) * 9)
        bats.append(wing)
        bats.append(shapes.sphere(f"BatBody{k}", 0.16, (x, -0.3, z + 0.05), (1, 1, 1.4), 8, 5, "SmoothPlastic"))
    _join_paint({"Wood": ("Wood", wood), "Cloth": ("Fabric", cloth), "Bone": ("SmoothPlastic", bone), "Bats": ("SmoothPlastic", bats),
                 "Eyes": ("Neon", eyes)},
                {"Wood": lambda c, n: paint.mix(paint.hex3("2e2420"), paint.hex3("4a3a30"), 0.4 + 0.4 * noise.noise(c)),
                 "Cloth": lambda c, n: paint.mix(paint.hex3("5a2430"), paint.hex3("2c1c26"), 0.5 + 0.5 * noise.noise(c * 2)), "Bone": P.BONE,
                 "Bats": paint.hex3("1a1420"), "Eyes": RED_EYE}, ao_distance=1.5, detail=("Bats",))
    return {"Kind": "prop", "LodDistance": 140}


def fog_tunnel():
    """The Fog Tunnel track piece: 7 wide, 7 high and 10 long, five timber ribs with iron straps, tattered canvas
    stretched between them (gaps let the fog spill out). Origin on the ground at the rail centre."""
    rng = random.Random(31)
    wood, iron, canvas = [], [], []
    for k in range(5):
        y = -5 + k * 2.5
        xs = [3.4 * math.cos(m / 16 * math.pi) for m in range(17)]
        pts = [(x, y, 6.8 * math.sin(math.acos(max(-1.0, min(1.0, x / 3.4)))) ** 0.6) for x in xs]
        wood.append(shapes.tube(f"Rib{k}", pts, 0.28, 6, "Wood", cap_start=True, cap_end=True))
        iron.append(shapes.tube(f"Strap{k}", [(p[0] * 1.02, p[1], p[2] * 1.02 + 0.05) for p in pts], 0.05, 4, "Metal"))
    for side in range(9):
        a0 = side / 9 * math.pi
        a1 = (side + 1) / 9 * math.pi
        for k in range(4):
            if rng.random() < 0.22:
                continue  # torn gaps
            y0, y1 = -5 + k * 2.5, -5 + (k + 1) * 2.5
            import bmesh
            bm = bmesh.new()

            def pt(a, y):
                x = 3.4 * math.cos(a)
                z = 6.8 * math.sin(math.acos(max(-1.0, min(1.0, x / 3.4)))) ** 0.6
                return (x * 1.01, y, z + 0.05)
            vs = [bm.verts.new(pt(a0, y0)), bm.verts.new(pt(a1, y0)), bm.verts.new(pt(a1, y1)), bm.verts.new(pt(a0, y1))]
            bm.faces.new(vs)
            bmesh.ops.subdivide_edges(bm, edges=bm.edges[:], cuts=2, use_grid_fill=True)
            o = core.obj_from_bmesh(f"Can{side}{k}", bm, "Fabric")
            for v in o.data.vertices:
                v.co.z -= 0.25 * math.sin((v.co.y - y0) / 2.5 * math.pi)  # sag between ribs
                if rng.random() < 0.08:
                    v.co.z -= rng.uniform(0.2, 0.5)
            canvas.append(o)
    for sx in (-1, 1):  # sill beams on the ground
        wood.append(shapes.box(f"Sill{sx}", (0.5, 10.4, 0.4), (sx * 3.4, 0, 0.2), bevel=0.05, material="Wood"))
    _join_paint({"Wood": ("Wood", wood), "Iron": ("Metal", iron), "Canvas": ("Fabric", canvas)},
                {"Wood": _wood, "Iron": P.IRON, "Canvas": lambda c, n: paint.mix(paint.hex3("6b6458"), paint.hex3("3e3a36"),
                                                                                    0.4 + 0.5 * noise.noise(c * 0.8))}, ao_distance=2.0)
    for o in [x for x in bpy_objects() if x.get("rbx_part") == "Canvas"]:
        for p in o.data.polygons:
            p.use_smooth = True
    return {"Kind": "prop", "LodDistance": 140}


def bpy_objects():
    import bpy
    return list(bpy.context.scene.objects)


def train_station():
    """The ghost-train station on the server's 7 x 7 platform (top at 1): plank deck with trim and a stone step, four
    iron posts with scroll brackets, a two-slope shingled canopy (top ~9.6) with a scalloped fascia, a name board at
    the front (-Y) and two hanging lanterns at +-2.6 (glass at 7.4; the server keeps their lights)."""
    wood, iron, roof, stone, glass = [], [], [], [], []
    deck = shapes.box("Deck", (7.0, 7.0, 0.7), (0, 0, 0.65), bevel=0.06, material="WoodPlanks")
    wood.append(deck)
    for i in range(8):  # plank seams as slightly raised boards
        wood.append(shapes.box(f"Plank{i}", (7.0, 0.82, 0.08), (0, -3.07 + i * 0.877, 1.02), bevel=0.02, material="WoodPlanks"))
    for sx in (-1, 1):
        wood.append(shapes.box(f"Edge{sx}", (0.3, 7.2, 0.35), (sx * 3.5, 0, 0.9), bevel=0.04, material="Wood"))
    stone.append(shapes.box("Base", (7.4, 7.4, 0.35), (0, 0, 0.17), bevel=0.06, material="Slate"))
    stone.append(shapes.box("Step", (3.0, 1.0, 0.5), (0, -4.0, 0.25), bevel=0.06, material="Slate"))
    for sx in (-1, 1):
        for sy in (-1, 1):
            iron.append(shapes.lathe(f"Post{sx}{sy}", [(0.28, 1.0), (0.28, 1.25), (0.16, 1.4), (0.14, 8.2), (0.24, 8.35), (0.24, 8.6)], 8, "Metal"))
            core.transform(iron[-1], (sx * 3.3, sy * 3.3, 0))
            iron.append(shapes.tube(f"Scroll{sx}{sy}", [(sx * 3.3, sy * 3.3, 7.2), (sx * 3.3, sy * 2.6, 7.9), (sx * 3.3, sy * 2.0, 8.4),
                                                         (sx * 3.3, sy * 2.2, 8.0)], 0.05, 4, "Metal", resample=3))
    for s2 in (-1, 1):
        slab = shapes.box(f"Roof{s2}", (8.6, 4.7, 0.3), (0, 0, 0), bevel=0.04, segments=1, material="RoofShingles")
        slab.rotation_euler = (math.radians(-s2 * 18), 0, 0)
        slab.location = (0, s2 * 2.05, 9.0)
        core.apply_transform(slab)
        roof.append(slab)
        for i in range(12):  # scalloped fascia
            x = -4.1 + i * 0.745
            sc = shapes.cylinder(f"Sc{s2}{i}", 0.36, 0.08, (x, s2 * 4.3, 8.15), (90, 0, 0), segments=8, material="Wood")
            wood.append(sc)
        wood.append(shapes.box(f"Fascia{s2}", (8.6, 0.12, 0.45), (0, s2 * 4.3, 8.45), bevel=0.02, material="Wood"))
    roof.append(shapes.box("Ridge", (8.8, 0.45, 0.35), (0, 0, 9.75), bevel=0.05, material="RoofShingles"))
    iron.append(shapes.box("BoardBar", (6.4, 0.1, 0.1), (0, -3.5, 8.95), material="Metal"))
    wood.append(shapes.box("Board", (6.0, 0.25, 1.2), (0, -3.5, 8.1), bevel=0.06, segments=1, material="Wood"))
    for sx in (-1, 1):  # board chains and lanterns on hooks
        iron.append(shapes.tube(f"BChain{sx}", [(sx * 2.6, -3.5, 8.95), (sx * 2.6, -3.5, 8.7)], 0.04, 4, "Metal"))
        iron.append(shapes.tube(f"Hook{sx}", [(sx * 2.6, 0, 8.9), (sx * 2.6, 0, 8.2)], 0.04, 4, "Metal"))
        iron.append(shapes.lathe(f"Lant{sx}", [(0.0, 6.7), (0.34, 6.85), (0.36, 7.85), (0.42, 7.95), (0.0, 8.25)], 6, "Metal"))
        core.transform(iron[-1], (sx * 2.6, 0, 0))
        glass.append(shapes.lathe(f"Glass{sx}", [(0.0, 6.85), (0.3, 6.95), (0.3, 7.8), (0.0, 7.85)], 6, "Neon"))
        core.transform(glass[-1], (sx * 2.6, 0, 0))
    _join_paint({"Wood": ("WoodPlanks", wood), "Iron": ("Metal", iron), "Roof": ("RoofShingles", roof), "Stone": ("Slate", stone),
                 "Glass": ("Neon", glass)},
                {"Wood": _wood, "Iron": P.IRON, "Roof": lambda c, n: paint.mix(P.ROOF, P.ROOF_DARK, 0.4 + 0.3 * noise.noise(c * 0.8)),
                 "Stone": P.STONE_DARK, "Glass": P.GLASS}, ao_distance=1.5)
    return {"Kind": "prop", "LodDistance": 160}


# ------------------------------------------------------------------------------------------------- plot
def plot_wall():
    """A low fieldstone boundary wall 8 long, 1 thick and 1.7 high with a rounded coping (tiled along each plot side)."""
    rng = random.Random(41)
    stones = []
    for row in range(3):
        x = -4.0 + (0.4 if row % 2 else 0.0)
        while x < 4.0:
            w = min(rng.uniform(0.7, 1.3), 4.0 - x)
            if w > 0.25:
                s = shapes.box(f"S{row}{len(stones)}", (w - 0.06, 1.0, 0.42), (x + w / 2, rng.uniform(-0.03, 0.03), 0.22 + row * 0.44),
                               bevel=0.0, segments=1, material="Cobblestone")
                stones.append(s)
            x += w
    coping = shapes.box("Coping", (8.0, 1.15, 0.32), (0, 0, 1.52), bevel=0.12, segments=1, material="Slate")
    core_ = shapes.box("Core", (7.95, 0.8, 1.3), (0, 0, 0.65), material="Cobblestone")

    def col(c, n):
        base = paint.mix(paint.hex3("5c544c"), paint.hex3("736a60"), 0.5 + 0.5 * noise.noise(c * 1.7))
        return paint.mix(base, P.MOSS_DARK, max(0.0, n.z) * 0.5 * (0.5 + 0.5 * noise.noise(c * 0.6)) + max(0.0, 0.4 - c.z) * 0.6)

    _join_paint({"Stone": ("Cobblestone", stones + [core_]), "Coping": ("Slate", [coping])}, {"Stone": col, "Coping": stone_cap},
                ao_distance=0.6)
    return {"Kind": "prop", "LodDistance": 120, "Length": 8.0}


def stone_cap(c, n):
    return paint.mix(P.STONE_DARK, P.STONE, 0.4 + 0.4 * noise.noise(c * 1.2))


def plot_sign():
    """The plot's name sign: two timber posts 5.2 high and an arched board 7.4 x 2.4 (board centre at 2.8; the server
    letters an invisible board part there), a little iron lantern on top."""
    wood = []
    for sx in (-1, 1):
        wood.append(shapes.box(f"Post{sx}", (0.45, 0.45, 5.2), (sx * 3.6, 0, 2.6), (0, sx * 1.5, 0), bevel=0.05, material="Wood"))
        cap = shapes.lathe(f"Cap{sx}", [(0.0, 5.2), (0.36, 5.2), (0.0, 5.65)], 4, "Wood")
        core.transform(cap, (sx * 3.6, 0, 0), (0, 0, 45))
        wood.append(cap)
    board = shapes.box("Board", (7.2, 0.22, 2.4), (0, 0, 2.8), bevel=0.0, segments=1, material="WoodPlanks")
    core.subdivide(board, 2, simple=True)
    for v in board.data.vertices:  # arched top
        if v.co.z > 3.5:
            v.co.z += 0.5 * math.cos(v.co.x / 3.6 * math.pi / 2)
    wood.append(board)
    wood.append(shapes.box("Rail", (7.6, 0.3, 0.3), (0, 0, 1.45), bevel=0.04, material="Wood"))
    iron = [shapes.lathe("Lant", [(0.0, 4.25), (0.22, 4.35), (0.24, 4.85), (0.3, 4.95), (0.0, 5.2)], 6, "Metal"),
            shapes.box("Bracket", (0.1, 0.1, 0.5), (0, 0, 4.15), material="Metal")]
    core.transform(iron[0], (0, -0.05, 0.2))
    glass = [shapes.lathe("Glass", [(0.0, 4.4), (0.18, 4.45), (0.18, 4.85), (0.0, 4.9)], 6, "Neon")]
    core.transform(glass[0], (0, -0.05, 0.2))
    _join_paint({"Wood": ("WoodPlanks", wood), "Iron": ("Metal", iron), "Glass": ("Neon", glass)},
                {"Wood": lambda c, n: paint.mix(paint.hex3("4a3628"), P.WOOD_GREY, 0.3 + 0.3 * noise.noise(c * 2)), "Iron": P.IRON,
                 "Glass": P.GLASS}, ao_distance=0.8)
    return {"Kind": "prop", "LodDistance": 140}


def pen_cage():
    """The containment pen, 16 x 16: a slate floor with a carved, glowing rune circle, and wrought-iron fencing on three
    sides (open at +Y, the server's open front) with spear-topped bars and corner posts with finials."""
    stone = [shapes.box("Floor", (16.0, 16.0, 0.4), (0, 0, 0.2), bevel=0.12, segments=1, material="Slate")]
    rune = []
    for r, w in ((5.6, 0.18), (4.6, 0.12)):
        ring = [(r * math.cos(t), r * math.sin(t), 0.44) for t in [m / 48 * math.tau for m in range(49)]]
        rune.append(shapes.tube(f"Ring{r}", ring, w, 4, "Neon", cap_start=False, cap_end=False, flatten=0.3))
    for k in range(5):  # pentagram
        a0 = math.pi / 2 + k * 2 * math.tau / 5
        a1 = math.pi / 2 + (k + 1) * 2 * math.tau / 5
        rune.append(shapes.tube(f"Star{k}", [(4.6 * math.cos(a0), 4.6 * math.sin(a0), 0.44), (4.6 * math.cos(a1), 4.6 * math.sin(a1), 0.44)],
                                0.1, 4, "Neon", flatten=0.3))
    for k in range(10):  # glyphs between the rings
        a = k / 10 * math.tau
        rune.append(shapes.box(f"Glyph{k}", (0.5, 0.12, 0.05), (5.1 * math.cos(a), 5.1 * math.sin(a), 0.44), (0, 0, math.degrees(a) + 90),
                               material="Neon"))
    iron = []
    h = 4.2
    for side, (cx, cy, ang) in enumerate(((0, -7.8, 0), (7.8, 0, 90), (-7.8, 0, 90))):
        panel = [shapes.box("RailTop", (15.4, 0.12, 0.12), (0, 0, h - 0.4), material="Metal"),
                 shapes.box("RailBot", (15.4, 0.12, 0.12), (0, 0, 0.75), material="Metal")]
        for i in range(25):
            x = -7.2 + i * 0.6
            panel.append(shapes.cylinder(f"Bar{i}", 0.05, h - 0.4, (x, 0, 0.4 + (h - 0.4) / 2), segments=5, material="Metal"))
            if i % 2 == 0:
                tip = shapes.lathe(f"Tip{i}", [(0.0, h), (0.1, h + 0.12), (0.03, h + 0.4), (0.0, h + 0.45)], 4, "Metal")
                core.transform(tip, (x, 0, 0))
                panel.append(tip)
        for o in panel:
            core.transform(o, rot=(0, 0, ang))
            core.transform(o, (cx, cy, 0))
        iron += panel
    for sx in (-1, 1):
        for sy in (-1, 1):
            iron.append(shapes.box(f"Corner{sx}{sy}", (0.45, 0.45, h + 0.3), (sx * 7.8, sy * 7.8, (h + 0.3) / 2 + 0.3), bevel=0.04, material="Metal"))
            iron.append(shapes.lathe(f"Fin{sx}{sy}", [(0.0, h + 0.6), (0.3, h + 0.7), (0.1, h + 1.0), (0.2, h + 1.2), (0.0, h + 1.6)], 6, "Metal"))
            core.transform(iron[-1], (sx * 7.8, sy * 7.8, 0))
    _join_paint({"Stone": ("Slate", stone), "Iron": ("Metal", iron), "Rune": ("Neon", rune)},
                {"Stone": lambda c, n: paint.mix(paint.hex3("3c3346"), paint.hex3("2a2432"), 0.4 + 0.4 * noise.noise(c * 0.5)),
                 "Iron": P.IRON, "Rune": GLOW}, ao_distance=1.0, detail=())
    return {"Kind": "prop", "LodDistance": 140}


def exhibit_plinth():
    """An exhibit pedestal: a stepped dark-marble plinth (4 x 4, top at 1) on a 5.6 base, with four brass stanchions
    and sagging velvet ropes round three sides (open at the front, -Y)."""
    stone = [shapes.box("Base", (5.6, 5.6, 0.4), (0, 0, 0.2), bevel=0.08, segments=1, material="Marble"),
             shapes.box("Ped", (4.0, 4.0, 0.6), (0, 0, 0.7), bevel=0.08, segments=1, material="Marble"),
             shapes.box("Top", (4.3, 4.3, 0.18), (0, 0, 0.94), bevel=0.06, segments=1, material="Marble")]
    brass, rope = [], []
    posts = [(-2.6, -2.6), (2.6, -2.6), (2.6, 2.6), (-2.6, 2.6)]
    for x, y in posts:
        brass.append(shapes.lathe(f"Stan{x}{y}", [(0.0, 0.4), (0.3, 0.4), (0.3, 0.5), (0.07, 0.6), (0.06, 2.0), (0.14, 2.1), (0.0, 2.3)], 8, "Metal"))
        core.transform(brass[-1], (x, y, 0))
    for (x0, y0), (x1, y1) in zip(posts[1:], posts[2:] + posts[:1]):  # three sides, skipping the front pair
        pts = [(x0 + (x1 - x0) * t, y0 + (y1 - y0) * t, 1.95 - 0.45 * math.sin(t * math.pi)) for t in [k / 8 for k in range(9)]]
        rope.append(shapes.tube(f"Rope{x0}{y0}", pts, 0.07, 5, "Fabric"))
    _join_paint({"Stone": ("Marble", stone), "Brass": ("Metal", brass), "Rope": ("Fabric", rope)},
                {"Stone": lambda c, n: paint.mix(paint.hex3("3a3542"), paint.hex3("57506a"), 0.4 + 0.4 * noise.noise(c * 1.4)), "Brass": BRASS,
                 "Rope": CRIMSON}, ao_distance=0.8)
    return {"Kind": "prop", "LodDistance": 100}


def trophy():
    """A trophy: a dark plinth 2 x 1.5 x 2 and a two-handled urn cup (part Cup, tinted per trophy) with a ghost finial,
    up to 3.8."""
    plinth = shapes.box("Plinth", (2.0, 2.0, 1.5), (0, 0, 0.75), bevel=0.1, segments=1, material="Marble")
    cup = [shapes.lathe("Urn", [(0.0, 1.5), (0.55, 1.5), (0.6, 1.62), (0.2, 1.75), (0.18, 2.0), (0.45, 2.15), (0.7, 2.6), (0.72, 3.05),
                                (0.6, 3.15), (0.0, 3.15)], 16, "Foil")]
    for sx in (-1, 1):
        cup.append(shapes.tube(f"H{sx}", [(sx * 0.6, 0, 2.95), (sx * 1.05, 0, 2.9), (sx * 1.0, 0, 2.4), (sx * 0.62, 0, 2.3)], 0.06, 6, "Foil",
                               resample=3))
    cup.append(shapes.lathe("Lid", [(0.0, 3.15), (0.62, 3.15), (0.4, 3.3), (0.12, 3.4), (0.0, 3.4)], 16, "Foil"))
    ghost = A.organic("Ghost", [A.ell((0, 0, 3.6), (0.18, 0.16, 0.2)), A.ell((0, 0, 3.45), (0.2, 0.17, 0.12))], 200, resolution=0.025,
                      material="SmoothPlastic")
    _join_paint({"Plinth": ("Marble", [plinth]), "Cup": ("Foil", cup), "Ghost": ("SmoothPlastic", [ghost])},
                {"Plinth": paint.hex3("2c2732"), "Cup": paint.hex3("e0c070"), "Ghost": P.GHOST}, ao_distance=0.6)
    return {"Kind": "prop", "LodDistance": 80}


ASSETS = {"ghost_cart": ghost_cart, "track_tie": track_tie, "track_trestle": track_trestle, "track_marker": track_marker,
          "scare_arch": scare_arch, "fog_tunnel": fog_tunnel, "train_station": train_station, "plot_wall": plot_wall, "plot_sign": plot_sign,
          "pen_cage": pen_cage, "exhibit_plinth": exhibit_plinth, "trophy": trophy}
