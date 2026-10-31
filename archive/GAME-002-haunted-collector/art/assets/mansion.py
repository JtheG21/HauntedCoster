"""Player plot houses (TASK-0046): the Shabby Shack, the Restored Manor and the Grand Mansion.

Each tier is one asset in plot-local space around the house point (plot-local (0, 0, 30)): Blender x = -local X,
Blender y = local Z - 30, so the front (-Y) faces the hub. The footprints are PlotDecor.Houses (the server keeps
those boxes as colliders). Part names are the mansion-theme slots (TASK-0050): Walls, Trim, Roof, Stone, Brick,
Glass, Lamp, Wood, Iron.

References: MIN-069 (architecture kit: stepped bases, trims, gables, finials), MIN-054-056 (haunted houses);
BAD-017 (the rejected box shack) is not repeated: every tier has construction detail on every side.
"""

import math
import random

from mathutils import Vector, noise

from hcart import core, paint, shapes
from hcart import palette as P

SIDING = paint.hex3("554a66")
SIDING_SHACK = paint.hex3("5d4c3e")
TRIM = paint.hex3("a796b4")
TRIM_SHACK = paint.hex3("6e5d4c")
ROOF = paint.hex3("3a3148")
BRICK = paint.hex3("7a4034")
STONE = paint.hex3("6c6874")
DOOR = paint.hex3("40202c")
GLASS_LIT = P.GLASS
GLASS_DARK = paint.hex3("141622")
LAMP = paint.hex3("b878ff")
DECK = paint.hex3("5a4535")

MATERIALS = {"Walls": "WoodPlanks", "Trim": "Wood", "Roof": "RoofShingles", "Stone": "Slate", "Brick": "Brick", "Glass": "Neon",
             "Lamp": "Neon", "Wood": "Wood", "Iron": "Metal", "Tin": "CorrodedMetal"}


class Kit:
    """Collects pieces per theme slot, then joins, UV-maps and paints them together (shared AO)."""

    def __init__(self, seed: int):
        self.rng = random.Random(seed)
        self.parts: dict[str, list] = {k: [] for k in MATERIALS}
        self.glass_dark: list[tuple[Vector, float]] = []  # (centre, radius) of unlit panes
        self.n = 0

    def add(self, role: str, obj):
        self.n += 1
        obj.name = f"{role}{self.n}"
        self.parts[role].append(obj)
        return obj

    def box(self, role, size, loc, rot=(0, 0, 0), bevel=0.04, segments=1):
        return self.add(role, shapes.box("b", size, loc, rot, bevel=bevel, segments=segments, material=MATERIALS[role]))

    def finish(self, colors: dict, ao_distance: float = 2.5, detail: tuple = ()):
        objs = []
        for role, pieces in self.parts.items():
            if not pieces:
                continue
            o = core.join(pieces, role)
            core.tag(o, MATERIALS[role], lod=role not in ("Glass", "Lamp"), detail=role in detail)
            core.uv_box(o, 4.0 if role in ("Walls", "Roof") else 2.0)
            core.smooth(o, 30)
            objs.append(o)
        lit = [o for o in objs if o["rbx_part"] in ("Glass", "Lamp")]
        shaded = [o for o in objs if o not in lit]
        dark = self.glass_dark

        def col(c, n, o):
            role = o["rbx_part"]
            base = colors.get(role, (0.5, 0.5, 0.5))
            if callable(base):
                return base(c, n)
            return base

        paint.paint(shaded, col, ao=0.55, ao_distance=ao_distance, ground=0.0, edge=0.22, crease=0.45, mottle=0.08, mottle_scale=1.2)
        for o in lit:
            me = o.data
            attr = me.color_attributes.new("Col", "BYTE_COLOR", "CORNER")
            base = LAMP if o["rbx_part"] == "Lamp" else GLASS_LIT
            for poly in me.polygons:
                fc = o.matrix_world @ poly.center
                is_dark = any((fc - cc).length < r for cc, r in dark)
                rgb = GLASS_DARK if is_dark else base
                k = 1.0 if is_dark else 0.85 + 0.15 * noise.noise(fc * 0.7)
                for li in poly.loop_indices:
                    attr.data[li].color_srgb = (rgb[0] * k, rgb[1] * k, rgb[2] * k, 1.0)
        return objs


def _place(objs, loc, rot_z):
    for o in objs:
        core.transform(o, rot=(0, 0, rot_z))
        core.transform(o, loc)


# ------------------------------------------------------------------------------------------- building blocks
def walls(k: Kit, cx, cy, w, d, h, role="Walls", plinth=0.9, corner=0.5, bands=(), lean=0.0):
    """A wall volume with a stone plinth, corner boards and trim bands (bands: heights)."""
    body = k.box(role, (w, d, h - plinth + 0.05), (cx, cy, plinth + (h - plinth) / 2), bevel=0.05)
    if lean:
        for v in body.data.vertices:
            v.co.x += lean * (v.co.z / h)
    k.box("Stone", (w + 0.5, d + 0.5, plinth), (cx, cy, plinth / 2), bevel=0.08)
    k.box("Stone", (w + 0.7, d + 0.7, 0.18), (cx, cy, plinth + 0.02), bevel=0.04)
    for sx in (-1, 1):
        for sy in (-1, 1):
            k.box("Trim", (corner, corner, h - plinth), (cx + sx * (w / 2 - corner / 2 + 0.08), cy + sy * (d / 2 - corner / 2 + 0.08),
                                                         plinth + (h - plinth) / 2), bevel=0.04)
    for z in bands:
        k.box("Trim", (w + 0.36, d + 0.36, 0.42), (cx, cy, z), bevel=0.06)
    return body


def gable_roof(k: Kit, cx, cy, w, d, wall_h, pitch, overhang=1.0, thick=0.5, sag=0.0, cresting=False, gable_role="Walls"):
    """A gable roof (ridge along X) with bargeboards, ridge cap and filled gable ends; returns the ridge height."""
    p = math.radians(pitch)
    half = d / 2 + overhang
    rise = (d / 2) * math.tan(p)
    ridge = wall_h + rise
    slope = half / math.cos(p)
    for s in (-1, 1):
        slab = k.add("Roof", shapes.box("Slab", (w + 2 * overhang, slope, thick), (0, 0, 0), bevel=0.05, segments=1, material="RoofShingles"))
        if sag:
            core.subdivide(slab, 2, simple=True)
            for v in slab.data.vertices:
                v.co.z -= sag * (1 - (2 * v.co.x / (w + 2 * overhang)) ** 2) * (0.6 + 0.4 * (v.co.y / slope + 0.5))
        slab.rotation_euler = (-s * p, 0, 0)
        slab.location = (cx, cy + s * half / 2, ridge - half * math.tan(p) / 2 + thick / 2 * math.cos(p))
        core.apply_transform(slab)
        for ex in (-1, 1):  # bargeboards under the rake
            bb = k.add("Trim", shapes.box("Barge", (0.22, slope + 0.1, 0.7), (0, 0, 0), bevel=0.03, material="Wood"))
            bb.rotation_euler = (-s * p, 0, 0)
            bb.location = (cx + ex * (w / 2 + overhang - 0.12), cy + s * half / 2, ridge - half * math.tan(p) / 2 - 0.1)
            core.apply_transform(bb)
        fascia = k.box("Trim", (w + 2 * overhang, 0.2, 0.55), (cx, cy + s * (half - 0.05), ridge - half * math.tan(p) - 0.15))
        _ = fascia
    k.box("Trim", (w + 2 * overhang + 0.2, 0.6, 0.45), (cx, cy, ridge + thick * 0.8))
    import bmesh
    for ex in (-1, 1):  # the gable triangles
        bm = bmesh.new()
        x = cx + ex * (w / 2 - 0.25)
        pts = [(cy - d / 2, wall_h - 0.05), (cy + d / 2, wall_h - 0.05), (cy, ridge - 0.2)]
        a = [bm.verts.new((x - 0.25, y, z)) for y, z in pts]
        b = [bm.verts.new((x + 0.25, y, z)) for y, z in pts]
        bm.faces.new(a)
        bm.faces.new(list(reversed(b)))
        for i in range(3):
            j = (i + 1) % 3
            bm.faces.new((a[i], b[i], b[j], a[j]))
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        k.add(gable_role, core.obj_from_bmesh("Gable", bm, MATERIALS[gable_role]))
    if cresting:
        n = int(w / 1.2)
        for i in range(n + 1):
            x = cx - w / 2 + i * w / n
            k.add("Iron", shapes.lathe("Crest", [(0.0, ridge + 0.5), (0.07, ridge + 0.5), (0.05, ridge + 1.0), (0.14, ridge + 1.1), (0.0, ridge + 1.5)],
                                       4, "Metal"))
            core.transform(k.parts["Iron"][-1], (x, cy, 0))
        k.box("Iron", (w, 0.1, 0.1), (cx, cy, ridge + 0.75), bevel=0.0)
    return ridge


def window(k: Kit, x, y, z, rot=0.0, w=2.4, h=3.0, lit=True, shutters=True, head="flat", boarded=False):
    """A framed sash window on a wall whose outward normal is -Y rotated by `rot` degrees about Z."""
    made = []

    def add(role, size, loc, r=(0, 0, 0), bevel=0.0):
        o = shapes.box("w", size, loc, r, bevel=bevel, segments=1, material=MATERIALS[role])
        made.append((role, o))

    add("Trim", (w + 0.5, 0.18, 0.26), (0, -0.12, h / 2 + 0.05))
    add("Trim", (w + 0.5, 0.18, 0.26), (0, -0.12, -h / 2 - 0.05))
    add("Trim", (0.26, 0.18, h + 0.3), (-w / 2 - 0.1, -0.12, 0))
    add("Trim", (0.26, 0.18, h + 0.3), (w / 2 + 0.1, -0.12, 0))
    add("Trim", (w + 0.8, 0.45, 0.16), (0, -0.25, -h / 2 - 0.2), bevel=0.04)  # sill
    if head == "pediment":
        add("Trim", (w + 0.9, 0.35, 0.22), (0, -0.2, h / 2 + 0.3))
        add("Trim", (w * 0.62, 0.3, 0.2), (0, -0.2, h / 2 + 0.55), bevel=0.05)
    elif head == "arch":
        add("Trim", (w + 0.6, 0.3, 0.5), (0, -0.18, h / 2 + 0.38), bevel=0.15)
    add("Glass", (w, 0.1, h), (0, 0.02, 0), bevel=0.0)
    add("Trim", (0.12, 0.14, h), (0, -0.06, 0), bevel=0.0)
    add("Trim", (w, 0.14, 0.12), (0, -0.06, 0.1), bevel=0.0)
    if shutters:
        for s in (-1, 1):
            add("Wood", (w * 0.48, 0.12, h + 0.1), (s * (w * 0.74 + 0.25), -0.12, 0), (0, 0, s * 6))
            for j in range(2):  # rails
                add("Wood", (w * 0.42, 0.06, 0.1), (s * (w * 0.74 + 0.25), -0.2, -h / 4 + j * h / 2), bevel=0.0)
    if boarded:
        for r in (32, -28):
            add("Wood", (w + 0.6, 0.12, 0.38), (0, -0.32, 0), (0, r, 0))
    for role, o in made:
        core.transform(o, rot=(0, 0, rot))
        core.transform(o, (x, y, z))
        k.add(role, o)
    if not lit or boarded:
        k.glass_dark.append((Vector((x, y, z)), max(w, h) * 0.7))


def door(k: Kit, x, y, w, h, rot=0.0, transom=True, z0=0.0):
    made = []

    def add(role, size, loc, r=(0, 0, 0), bevel=0.0):
        made.append((role, shapes.box("d", size, loc, r, bevel=bevel, segments=1, material=MATERIALS[role])))

    add("Wood", (w, 0.25, h), (0, 0.05, h / 2))
    for px in (-w / 4, w / 4):  # raised panels
        add("Wood", (w * 0.36, 0.08, h * 0.32), (px, -0.1, h * 0.72))
        add("Wood", (w * 0.36, 0.08, h * 0.4), (px, -0.1, h * 0.28))
    add("Trim", (w + 0.9, 0.3, 0.4), (0, -0.1, h + (1.0 if transom else 0.2)))
    add("Trim", (0.34, 0.3, h + (1.0 if transom else 0.2)), (-w / 2 - 0.2, -0.1, (h + (1.0 if transom else 0.2)) / 2))
    add("Trim", (0.34, 0.3, h + (1.0 if transom else 0.2)), (w / 2 + 0.2, -0.1, (h + (1.0 if transom else 0.2)) / 2))
    if transom:
        add("Glass", (w, 0.1, 0.7), (0, 0.0, h + 0.45), bevel=0.0)
    add("Iron", (0.2, 0.15, 0.2), (w * 0.32, -0.14, h * 0.5))
    for role, o in made:
        core.transform(o, rot=(0, 0, rot))
        core.transform(o, (x, y, z0))
        k.add(role, o)


def chimney(k: Kit, x, y, z0, h, tilt=0.0):
    pieces = [shapes.box("Stack", (2.0, 2.0, h), (0, 0, h / 2), bevel=0.04, segments=1, material="Brick"),
              shapes.box("Corbel", (2.5, 2.5, 0.45), (0, 0, h - 0.6), bevel=0.05, segments=1, material="Brick"),
              shapes.box("Cap", (2.3, 2.3, 0.3), (0, 0, h - 0.1), bevel=0.04, segments=1, material="Brick")]
    for px in (-0.45, 0.45):
        pieces.append(shapes.cylinder("Pot", 0.28, 0.8, (px, 0, h + 0.35), segments=8, material="Brick"))
    for o in pieces:
        core.transform(o, rot=(0, tilt, 0))
        core.transform(o, (x, y, z0))
        k.add("Brick", o)


def porch(k: Kit, cx, cy, w, d, deck, height, columns, balcony=False, rail_gap=3.6):
    """A deck with steps, turned columns, a rail and a shallow roof (front edge at cy - d/2)."""
    k.box("Wood", (w, d, deck), (cx, cy, deck / 2), bevel=0.05)
    for i, (sd, sh) in enumerate(((1.0, deck * 0.66), (0.9, deck * 0.33))):
        k.box("Wood", (rail_gap + 0.6, sd, sh), (cx, cy - d / 2 - sd / 2 - i * 0.9, sh / 2), bevel=0.04)
    front = cy - d / 2 + 0.45
    xs = [cx - w / 2 + 0.45 + i * (w - 0.9) / (columns - 1) for i in range(columns)]
    for x in xs:
        col = shapes.lathe("Column", [(0.42, 0.0), (0.42, 0.35), (0.3, 0.5), (0.24, 0.9), (0.26, height * 0.5), (0.22, height - 0.6),
                                      (0.32, height - 0.4), (0.42, height - 0.2), (0.42, height)], 10, "Wood")
        core.transform(col, (x, front, deck))
        k.add("Trim", col)
    k.box("Trim", (w + 0.4, 0.5, 0.6), (cx, front, deck + height + 0.1))
    roof = k.box("Roof", (w + 1.2, d + 0.9, 0.45), (cx, cy - 0.2, deck + height + 0.62), rot=(-4, 0, 0))
    _ = roof
    for x0, x1 in ((cx - w / 2 + 0.45, cx - rail_gap / 2), (cx + rail_gap / 2, cx + w / 2 - 0.45)):
        if x1 - x0 < 0.6:
            continue
        k.box("Trim", (x1 - x0, 0.22, 0.18), (0.5 * (x0 + x1), front, deck + 2.6))
        k.box("Trim", (x1 - x0, 0.22, 0.14), (0.5 * (x0 + x1), front, deck + 0.4))
        n = max(2, int((x1 - x0) / 0.5))
        for i in range(1, n):
            x = x0 + i * (x1 - x0) / n
            k.add("Trim", shapes.lathe("Bal", [(0.07, 0.0), (0.11, 0.5), (0.06, 1.1), (0.07, 2.2)], 4, "Wood"))
            core.transform(k.parts["Trim"][-1], (x, front, deck + 0.4))
    if balcony:
        top = deck + height + 0.9
        k.box("Iron", (w, 0.12, 0.12), (cx, front - 0.2, top + 1.8), bevel=0.0)
        k.box("Iron", (w, 0.1, 0.1), (cx, front - 0.2, top + 0.15), bevel=0.0)
        n = int(w / 0.45)
        for i in range(n + 1):
            x = cx - w / 2 + i * w / n
            k.add("Iron", shapes.cylinder("Rail", 0.04, 1.7, (x, front - 0.2, top + 0.95), segments=4, material="Metal"))
            if i % 4 == 2:
                k.add("Iron", shapes.lathe("Finial", [(0.0, top + 1.8), (0.09, top + 1.95), (0.0, top + 2.3)], 4, "Metal"))
                core.transform(k.parts["Iron"][-1], (x, front - 0.2, 0))


def lantern_bracket(k: Kit, x, y, z, rot=0.0):
    """A small iron wall lantern by a door."""
    made = [("Iron", shapes.box("Arm", (0.12, 0.7, 0.12), (0, -0.35, 0.3), material="Metal")),
            ("Iron", shapes.lathe("Cage", [(0.0, -0.55), (0.24, -0.4), (0.26, 0.3), (0.3, 0.38), (0.0, 0.62)], 6, "Metal")),
            ("Glass", shapes.lathe("Flame", [(0.0, -0.35), (0.18, -0.3), (0.18, 0.25), (0.0, 0.3)], 6, "Neon"))]
    for role, o in made:
        if o.name.startswith(("Cage", "Flame")):
            core.transform(o, (0, -0.75, 0))
        core.transform(o, rot=(0, 0, rot))
        core.transform(o, (x, y, z))
        k.add(role, o)


def siding_color(base, dark_k=0.72):
    def fn(c, n):
        # weathering: darker low down and under eaves, streaks
        k = 0.88 + 0.12 * noise.noise(Vector((c.x * 0.3, c.y * 0.3, c.z * 1.4)))
        low = min(1.0, max(0.0, (c.z - 0.9) / 3.0))
        return paint.mul(paint.mix(paint.mul(base, dark_k), base, 0.4 + 0.6 * low), k)
    return fn


def roof_color(c, n):
    k = 0.85 + 0.25 * noise.noise(c * 0.35)
    moss = max(0.0, noise.noise(c * 0.22 + Vector((3, 1, 0)))) * 0.5
    return paint.mix(paint.mul(ROOF, k), P.MOSS_DARK, moss * 0.6)


def stone_color(c, n):
    return paint.mix(paint.mix(STONE, P.STONE_DARK, 0.5 + 0.5 * noise.noise(c * 0.9)), P.MOSS_DARK, max(0.0, 0.5 - c.z) * 0.8)


# ------------------------------------------------------------------------------------------------ the tiers
def house_t0():
    """Shabby Shack (16 x 12 x 9 with a 6 x 10 lean-to): board-and-gap plank walls on a rubble footing, a sagging
    patched roof, a rusted tin lean-to, a crooked door, one lit and one boarded window, a stovepipe and a rain barrel."""
    k = Kit(100)
    rng = k.rng
    w, d, h = 16.0, 12.0, 8.4
    cx, cy = 0.0, 0.0
    k.box("Walls", (w - 0.6, d - 0.6, h - 0.4), (cx, cy, 0.6 + (h - 0.4) / 2 - 0.2), bevel=0.0)  # dark core behind the boards
    for side in range(4):  # vertical boards on each face, slightly irregular
        length = w if side % 2 == 0 else d
        nrm = [(0, -1), (1, 0), (0, 1), (-1, 0)][side]
        x = -length / 2
        while x < length / 2 - 0.1:
            bw = min(rng.uniform(0.62, 0.9), length / 2 - x)
            top = h - rng.uniform(0.0, 0.35) - (0.0 if side % 2 == 0 else 0.0)
            tilt = rng.uniform(-1.5, 1.5)
            o = shapes.box("Board", (bw - 0.05, 0.16, top - 0.45), (0, 0, 0.45 + (top - 0.45) / 2), (0, tilt, 0), bevel=0.0, segments=1,
                           material="WoodPlanks")
            core.transform(o, (x + bw / 2, -(d / 2 if side % 2 == 0 else w / 2) - 0.05 + rng.uniform(-0.03, 0.03), 0))
            core.transform(o, rot=(0, 0, [0, 90, 180, 270][side]))
            k.add("Walls", o)
            x += bw
        _ = nrm
    for sx in (-1, 1):  # corner posts and a sill beam
        for sy in (-1, 1):
            k.box("Trim", (0.55, 0.55, h + 0.2), (sx * (w / 2 + 0.05), sy * (d / 2 + 0.05), (h + 0.2) / 2), bevel=0.05)
    for z in (0.55, h - 0.1):
        k.box("Trim", (w + 0.4, d + 0.4, 0.35), (0, 0, z), bevel=0.04)
    for i in range(9):  # rubble footing
        for sy in (-1, 1):
            x = -w / 2 + 0.9 + i * (w - 1.8) / 8
            o = shapes.sphere("Rubble", 0.55, (x + rng.uniform(-0.3, 0.3), sy * (d / 2 + 0.15), 0.2), (1.2, 0.8, 0.55), 6, 4, "Slate")
            k.add("Stone", o)
    ridge = gable_roof(k, cx, cy, w, d, h, 24, overhang=0.9, thick=0.45, sag=0.55, gable_role="Walls")
    for px, py in ((3.5, -3.6), (-4.4, 3.0), (5.6, 2.2)):  # tin patches and loose planks on the roof
        z = h + (d / 2 - abs(py)) * math.tan(math.radians(24)) + 0.3
        k.box("Tin", (2.2, 1.8, 0.08), (px, py, z), rot=(-24 if py > 0 else 24, 0, rng.uniform(-10, 10)), bevel=0.0)
    k.box("Wood", (0.5, 4.2, 0.18), (-1.0, -3.3, h + 1.6), rot=(24, 0, 12))
    # Lean-to on the west (local -X = Blender +X): plank walls and a corrugated tin roof
    lx, ly, lw, ld, lh = 11.0, 1.0, 6.0, 10.0, 5.6
    for side, (sx, sy, sw, sd, ang) in enumerate(((lx + lw / 2, ly, ld, 0.16, 90), (lx, ly - ld / 2, lw, 0.16, 0), (lx, ly + ld / 2, lw, 0.16, 0))):
        n = int(sw / 0.75)
        for i in range(n):
            t = (i + 0.5) / n
            bh = lh - 0.5 - rng.uniform(0, 0.4) - (1.4 * t if side > 0 else 0.0)
            o = shapes.box("LB", (sw / n - 0.06, sd, bh), (-sw / 2 + t * sw, 0, bh / 2 + 0.2), (0, rng.uniform(-2, 2), 0), bevel=0.0, segments=1,
                           material="WoodPlanks")
            core.transform(o, rot=(0, 0, ang))
            core.transform(o, (sx, sy, 0))
            k.add("Walls", o)
    tin = shapes.box("TinRoof", (lw + 1.4, ld + 1.0, 0.12), (0, 0, 0), bevel=0.0, segments=1, material="CorrodedMetal")
    core.subdivide(tin, 3, simple=True)
    for v in tin.data.vertices:
        v.co.z += 0.12 * math.sin(v.co.y * 5.0) + 0.15 * noise.noise(v.co * 0.6)
    tin.rotation_euler = (0, math.radians(-14), 0)
    tin.location = (lx + 0.3, ly, lh - 0.4)
    core.apply_transform(tin)
    k.add("Tin", tin)
    # Front: crooked door on a crate step, one lit window, one boarded
    door(k, -0.4, -d / 2 - 0.25, 3.0, 6.0, rot=0.0, transom=False, z0=0.55)
    k.box("Wood", (0.25, 0.12, 6.4), (-0.4, -d / 2 - 0.5, 3.6), rot=(0, 38, 0))  # Z brace
    k.box("Wood", (4.0, 3.0, 0.6), (0, -7.5, 0.3), rot=(0, 0, 4), bevel=0.06)
    window(k, -4.0, -d / 2 - 0.15, 4.8, w=2.6, h=2.6, lit=True, shutters=False)
    window(k, 4.0, -d / 2 - 0.15, 4.8, w=2.6, h=2.6, lit=False, shutters=False, boarded=True)
    window(k, -w / 2 - 0.15, 1.5, 4.8, rot=-90, w=2.2, h=2.4, lit=True, shutters=False)
    lantern_bracket(k, 1.9, -d / 2 - 0.2, 6.3)
    # Stovepipe through the roof with a rain cap, guy wire
    pipe = shapes.tube("Pipe", [(-4.8, 2.5, ridge - 1.4), (-4.9, 2.5, ridge + 1.2), (-5.4, 2.6, ridge + 3.4)], 0.32, 10, "CorrodedMetal")
    k.add("Tin", pipe)
    k.add("Tin", shapes.lathe("RainCap", [(0.0, 0.0), (0.75, 0.0), (0.0, 0.55)], 10, "CorrodedMetal"))
    core.transform(k.parts["Tin"][-1], (-5.45, 2.6, ridge + 3.55))
    # Rain barrel and firewood by the lean-to
    barrel = shapes.lathe("Barrel", [(0.0, 0.0), (0.75, 0.0), (0.85, 0.7), (0.75, 1.5), (0.0, 1.45)], 12, "Wood")
    core.transform(barrel, (8.4, -4.6, 0))
    k.add("Wood", barrel)
    for z in (0.3, 1.2):
        k.add("Iron", shapes.lathe("Hoop", [(0.86, z - 0.06), (0.86, z + 0.06)], 12, "Metal", cap_bottom=False, cap_top=False))
        core.transform(k.parts["Iron"][-1], (8.4, -4.6, 0))
    for i in range(7):
        log = shapes.cylinder("Log", 0.22, 2.0, (0, 0, 0), (90, 0, 0), segments=7, material="Wood")
        core.transform(log, (13.2 - (i % 4) * 0.46 - (0.23 if i >= 4 else 0), -5.6, 0.22 + (0.4 if i >= 4 else 0)))
        k.add("Wood", log)
    k.finish({"Walls": siding_color(SIDING_SHACK, 0.6), "Trim": TRIM_SHACK, "Roof": roof_color, "Stone": stone_color, "Brick": BRICK,
              "Wood": paint.hex3("4c3a2c"), "Iron": P.IRON, "Tin": lambda c, n: paint.mix(paint.hex3("6a5a52"), paint.hex3("8a4a2a"),
                                                                                                0.5 + 0.5 * noise.noise(c * 0.8))},
             detail=("Iron",))
    return {"Kind": "house", "LodDistance": 260}


def _manor_front_windows(k, cx, front, h, cols, rows_z, lit_pattern, head="pediment"):
    for r, z in enumerate(rows_z):
        for i, x in enumerate(cols):
            window(k, cx + x, front - 0.12, z, w=2.4, h=3.0, lit=lit_pattern(r, i), shutters=True, head=head if r == 0 else "arch")


def house_t1():
    """Restored Manor: a two-storey clapboard manor (26 x 14 x 13) with a steep gable, a one-storey west wing
    (10 x 12 x 10), a columned porch (12 x 6), shuttered sash windows, two chimneys and wall lanterns."""
    k = Kit(101)
    # Main block: Blender centre (0, 2)
    cx, cy, w, d, h = 0.0, 2.0, 26.0, 14.0, 13.0
    walls(k, cx, cy, w, d, h, bands=(h * 0.5, h - 0.2))
    gable_roof(k, cx, cy, w, d, h, 32, overhang=1.0)
    front = cy - d / 2
    _manor_front_windows(k, cx, front, h, (-9.0, -4.5, 4.5, 9.0), (h * 0.32, h * 0.7), lambda r, i: (r + i) % 3 != 1)
    window(k, cx, front - 0.12, h * 0.7, lit=True, shutters=False, head="arch")
    door(k, cx, front - 0.2, 4.0, 7.0, z0=0.85)
    lantern_bracket(k, cx - 3.4, front - 0.25, 6.4)
    lantern_bracket(k, cx + 3.4, front - 0.25, 6.4)
    for sx in (-1, 1):  # side windows
        for z in (h * 0.32, h * 0.7):
            window(k, cx + sx * (w / 2 + 0.12), cy + 1.5, z, rot=90 * sx, lit=z < 6, shutters=True)
    for x in (-6.0, 6.0):  # rear windows
        window(k, cx + x, cy + d / 2 + 0.12, h * 0.6, rot=180, lit=False, shutters=False)
    chimney(k, cx + (w / 2 - 3), cy + 2, h - 1, 9.5)  # Blender +X = local -X (west)
    chimney(k, cx - (w / 2 - 3), cy + 2, h - 1, 8.5)
    # West wing: Blender centre (18, 3)
    wx, wy, ww, wd, wh = 18.0, 3.0, 10.0, 12.0, 10.0
    walls(k, wx, wy, ww, wd, wh, bands=(wh - 0.2,))
    gable_roof(k, wx, wy, ww, wd, wh, 34, overhang=0.8)
    window(k, wx, wy - wd / 2 - 0.12, wh * 0.5, lit=True, shutters=True, head="pediment")
    window(k, wx + ww / 2 + 0.12, wy, wh * 0.5, rot=90, lit=False, shutters=True)
    # Porch: Blender centre (0, -8), 12 x 6, deck 0.8, columns 6 high
    porch(k, 0.0, -8.0, 12.0, 6.0, 0.8, 6.0, 4)
    k.finish({"Walls": siding_color(SIDING), "Trim": TRIM, "Roof": roof_color, "Stone": stone_color, "Brick": BRICK, "Wood": DOOR,
              "Iron": P.IRON}, detail=("Iron",))
    return {"Kind": "house", "LodDistance": 300}


def house_t2():
    """Grand Mansion: a wide two-and-a-half-storey manor (32 x 16 x 15) with twin wings (10 x 12 x 12), a corner tower
    (7 x 7, 28 high: belvedere and spire with the purple lamp), a deep porch with a balcony, iron cresting, dormers."""
    k = Kit(102)
    cx, cy, w, d, h = 0.0, 2.0, 32.0, 16.0, 15.0
    walls(k, cx, cy, w, d, h, bands=(h * 0.46, h - 0.2))
    ridge = gable_roof(k, cx, cy, w, d, h, 38, overhang=1.0, cresting=True)
    front = cy - d / 2
    _manor_front_windows(k, cx, front, h, (-12.0, -6.0, 6.0, 12.0), (h * 0.3, h * 0.7), lambda r, i: (r * 2 + i) % 4 != 3)
    window(k, cx, front - 0.12, h * 0.7, lit=True, shutters=False, head="arch")
    door(k, cx, front - 0.2, 4.4, 7.4, z0=0.85)
    lantern_bracket(k, cx - 3.6, front - 0.25, 6.8)
    lantern_bracket(k, cx + 3.6, front - 0.25, 6.8)
    for dx in (-7.5, 7.5):  # dormers on the front slope
        base_z = h + 2.6
        dy = front + 2.3
        k.box("Walls", (3.2, 3.2, 3.0), (cx + dx, dy + 0.6, base_z + 0.8), bevel=0.04)
        k.add("Roof", shapes.lathe("DormerRoof", [(0.0, 0.0), (2.6, 0.0), (0.0, 1.9)], 4, "RoofShingles"))
        core.transform(k.parts["Roof"][-1], (cx + dx, dy + 0.6, base_z + 2.3), (0, 0, 45), (1.0, 1.0, 1.0))
        window(k, cx + dx, dy - 1.05, base_z + 0.9, w=1.8, h=2.0, lit=dx > 0, shutters=False)
    for sx in (-1, 1):
        for z in (h * 0.3, h * 0.7):
            window(k, cx + sx * (w / 2 + 0.12), cy + 2.5, z, rot=90 * sx, lit=z < 6, shutters=True)
    for x in (-9.0, 0.0, 9.0):
        window(k, cx + x, cy + d / 2 + 0.12, h * 0.6, rot=180, lit=x == 0.0, shutters=False)
    chimney(k, cx + (w / 2 - 3), cy + 3, h - 1, 11.0)
    chimney(k, cx - (w / 2 - 3), cy + 3, h - 1, 10.0)
    # Wings: Blender centres (21, 3) and (-21, 3)
    for wx in (21.0, -21.0):
        wy, ww, wd, wh = 3.0, 10.0, 12.0, 12.0
        walls(k, wx, wy, ww, wd, wh, bands=(wh * 0.5, wh - 0.2))
        gable_roof(k, wx, wy, ww, wd, wh, 36, overhang=0.8, cresting=True)
        for z in (wh * 0.32, wh * 0.72):
            window(k, wx, wy - wd / 2 - 0.12, z, lit=(z < 6) == (wx > 0), shutters=True, head="pediment")
        window(k, wx + math.copysign(ww / 2 + 0.12, wx), wy, wh * 0.5, rot=90 * math.copysign(1, wx), lit=False, shutters=True)
    # Tower: local (11, 0, 38) -> Blender (-11, 8); 7 x 7, walls to 22, belvedere to 25.5, spire to 36, lamp 37.5
    tx, ty, ts = -11.0, 8.0, 7.0
    walls(k, tx, ty, ts, ts, 22.0, bands=(11.0, 21.8))
    for z in (8.0, 15.0):
        window(k, tx, ty - ts / 2 - 0.12, z, w=2.0, h=2.8, lit=z > 10, shutters=False, head="arch")
    k.box("Trim", (ts + 1.2, ts + 1.2, 0.5), (tx, ty, 22.2))
    for sx in (-1, 1):
        for sy in (-1, 1):
            k.box("Trim", (0.7, 0.7, 3.4), (tx + sx * (ts / 2 - 0.1), ty + sy * (ts / 2 - 0.1), 24.1))
    for side in range(4):  # belvedere glazing between the posts
        ang = side * 90
        o = shapes.box("Belv", (ts - 1.0, 0.12, 2.8), (0, -(ts / 2 - 0.15), 24.0), bevel=0.0, material="Neon")
        core.transform(o, rot=(0, 0, ang))
        core.transform(o, (tx, ty, 0))
        k.add("Lamp", o)
        for j in (-1, 0, 1):
            m = shapes.box("Mullion", (0.14, 0.2, 2.8), (j * (ts - 1.0) / 3, -(ts / 2 - 0.05), 24.0), bevel=0.0, material="Wood")
            core.transform(m, rot=(0, 0, ang))
            core.transform(m, (tx, ty, 0))
            k.add("Trim", m)
    k.box("Trim", (ts + 1.4, ts + 1.4, 0.6), (tx, ty, 25.8))
    spire = shapes.lathe("Spire", [(0.0, 26.0), (5.6, 26.0), (5.2, 26.5), (3.6, 28.5), (2.2, 31.0), (1.1, 34.0), (0.55, 36.0), (0.0, 36.6)], 4,
                         "RoofShingles")
    core.transform(spire, (tx, ty, 0), (0, 0, 45))
    k.add("Roof", spire)
    k.add("Iron", shapes.cylinder("Mast", 0.08, 1.4, (tx, ty, 37.0), segments=6, material="Metal"))
    k.add("Lamp", shapes.lathe("TowerLamp", [(0.0, 36.8), (0.55, 37.0), (0.7, 37.6), (0.5, 38.2), (0.0, 38.4)], 8, "Neon"))
    core.transform(k.parts["Lamp"][-1], (tx, ty, 0))
    for side in range(4):  # widow's walk
        o = shapes.box("Walk", (ts + 1.2, 0.08, 0.08), (0, -(ts / 2 + 0.55), 23.4), bevel=0.0, material="Metal")
        core.transform(o, rot=(0, 0, side * 90))
        core.transform(o, (tx, ty, 0))
        k.add("Iron", o)
    # Porch with a balcony: Blender centre (0, -8.5), 16 x 5, columns 7 high
    porch(k, 0.0, -8.5, 16.0, 5.0, 0.8, 7.0, 6, balcony=True)
    k.finish({"Walls": siding_color(SIDING), "Trim": TRIM, "Roof": roof_color, "Stone": stone_color, "Brick": BRICK, "Wood": DOOR,
              "Iron": P.IRON}, detail=("Iron",))
    _ = ridge
    return {"Kind": "house", "LodDistance": 340}


ASSETS = {"house_t0": house_t0, "house_t1": house_t1, "house_t2": house_t2}
