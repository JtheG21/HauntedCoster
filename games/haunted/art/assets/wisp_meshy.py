"""Lantern Wisp, Meshy-faithful build (TASK-0043 revision 1, 2026-10-15). This is creature_wisp.

jg's call (2026-10-15): the raw Meshy 6 Lite generation of the approved concept was the closest attempt, so its
geometry is kept as generated: same pose, head, face, tray, chain and lantern. No re-sculpting, turning or part
swaps (that was assets/wisp_hybrid.py, now creature_wisp_hybrid). This build only splits the mesh into the parts
the game animates and paints, and adds colour and texture: sacking cloth with grime, a dark crown, twine and
thread on Meshy's stitches, glossy eyes, a dark mouth gap, a steel pole, weathered bronze and copper on the lamp,
and glowing panes.

Meshy free plan, CC BY 4.0: the game must credit Meshy (SYS-Haunted-Art-Direction, "Third-party sources").
Source mesh: ~/Roblox-Work/haunted/art/meshy/wisp_meshy_v1.glb (not in the repo; override with WISP_MESHY).
"""

import math

import bmesh
import bpy
from mathutils import Matrix, Vector, noise

from assets import wisp as W
from assets import wisp_hybrid as Hy
from hcart import core, paint

H = paint.hex3

# Meshy units, front facing -Y (measured 2026-10-15).
TRAY_SPLIT_Z = -0.335  # Meshy's tray sits above this; chain and lantern below
CHAIN_TOP = Vector((-0.27, 0.03, -0.33))  # the lantern swings from here
LAMP_C = (-0.24, 0.018)  # lantern axis
LAMP_ANGLE = math.radians(46)  # its square body is turned corner-on
POLE_FACE_R = 0.036  # faces this close to the pole axis are the pole


def _split(obj, keep_face, name, material):
    """Moves the faces where keep_face(centre, normal) into a new object; returns it (or None)."""
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    faces = [f for f in bm.faces if keep_face(f.calc_center_median(), f.normal)]
    if not faces:
        bm.free()
        return None
    nb = bmesh.new()
    vmap = {}
    for f in faces:
        vs = []
        for v in f.verts:
            if v not in vmap:
                vmap[v] = nb.verts.new(v.co)
            vs.append(vmap[v])
        nb.faces.new(vs)
    bmesh.ops.delete(bm, geom=faces, context="FACES_ONLY")
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
    bm.to_mesh(obj.data)
    bm.free()
    obj.data.update()
    return core.obj_from_bmesh(name, nb, material)


def relief_map(obj, iters=30):
    """Per-vertex relief: how far each vertex stands out of (+) or sinks into (-) a smoothed copy of the surface.
    Meshy's stitches and tooth loops stand out; the gaps between them sink. More reliable than curvature here."""
    import numpy as np
    me = obj.data
    n = len(me.vertices)
    co = np.empty(n * 3)
    me.vertices.foreach_get("co", co)
    co = co.reshape(n, 3)
    ev = np.empty(len(me.edges) * 2, dtype=np.int64)
    me.edges.foreach_get("vertices", ev)
    ev = ev.reshape(-1, 2)
    deg = np.bincount(ev.ravel(), minlength=n).astype(float)
    sm = co.copy()
    for _ in range(iters):
        acc = np.zeros_like(sm)
        np.add.at(acc, ev[:, 0], sm[ev[:, 1]])
        np.add.at(acc, ev[:, 1], sm[ev[:, 0]])
        sm = 0.5 * sm + 0.5 * acc / np.maximum(deg, 1)[:, None]
    nrm = np.empty(n * 3)
    me.vertices.foreach_get("normal", nrm)
    nrm = nrm.reshape(n, 3)
    rel = ((co - sm) * nrm).sum(1)
    base = rel.copy()  # subtract the slow, curvature-driven part so only local bumps and dips remain
    for _ in range(iters):
        acc = np.zeros(n)
        np.add.at(acc, ev[:, 0], base[ev[:, 1]])
        np.add.at(acc, ev[:, 1], base[ev[:, 0]])
        base = 0.5 * base + 0.5 * acc / np.maximum(deg, 1)
    rel = rel - base
    mw = obj.matrix_world
    from mathutils.kdtree import KDTree
    kd = KDTree(n)
    for i in range(n):
        kd.insert(mw @ Vector(co[i]), i)
    kd.balance()
    return kd, rel


def _lamp_r(p):
    """Square (L-inf) distance from the lantern axis in the lantern's own turned frame."""
    dx, dy = p.x - LAMP_C[0], p.y - LAMP_C[1]
    c, s = math.cos(LAMP_ANGLE), math.sin(LAMP_ANGLE)
    return max(abs(c * dx - s * dy), abs(s * dx + c * dy))


def lantern_wisp_meshy():
    bpy.ops.import_scene.gltf(filepath=str(Hy.MESHY))
    src = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    mesh = core.join(src, "Meshy")
    core.apply_transform(mesh)
    mesh.data.materials.clear()
    core.activate(mesh)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.mesh.separate(type="LOOSE")
    bpy.ops.object.mode_set(mode="OBJECT")
    creature, lamp = sorted([o for o in bpy.context.scene.objects if o.type == "MESH"], key=lambda o: -len(o.data.vertices))[:2]
    creature.name, lamp.name = "Body", "LampIron"

    # Pole axis, fitted to the pole's own vertices.
    import numpy as np
    vs = [creature.matrix_world @ v.co for v in creature.data.vertices]
    a0, b0 = Hy.POLE_TIPS
    ax0 = (b0 - a0).normalized()
    near = [p for p in vs if (p - (a0 + ax0 * (p - a0).dot(ax0))).length < 0.035]
    pc = sum(near, Vector()) / len(near)
    ax = Vector(np.linalg.svd(np.array([tuple(p - pc) for p in near]), full_matrices=False)[2][0])

    def pole_d(p):
        return (p - (pc + ax * (p - pc).dot(ax))).length

    eyes_m = []
    tree = __import__("mathutils").bvhtree.BVHTree.FromObject(creature, bpy.context.evaluated_depsgraph_get())
    for (x, z), r in Hy.EYES_M:
        loc, _, _, _ = tree.ray_cast(Vector((x, -2.0, z)), Vector((0, 1, 0)))
        eyes_m.append((loc, r))
    grin_m = []
    for x, z in Hy.GRIN_OLD:
        loc, _, _, _ = tree.ray_cast(Vector((x, -2.0, z)), Vector((0, 1, 0)))
        if loc is not None:
            grin_m.append(loc)

    pole = _split(creature, lambda c, n: pole_d(c) < POLE_FACE_R, "Pole", "Metal")
    eyes = _split(creature, lambda c, n: any((c - p).length < r * 0.95 for p, r in eyes_m), "Eyes", "SmoothPlastic")
    tray = _split(lamp, lambda c, n: c.z > TRAY_SPLIT_Z, "Tray", "Metal")

    def is_pane(c, n):
        if not (-0.86 < c.z < -0.62) or abs(n.z) > 0.7:
            return False
        r = _lamp_r(c)
        return 0.11 < r < 0.16  # recessed between the frame bars (bars and posts stand out to ~0.167)

    panes = _split(lamp, is_pane, "LampGlow", "Neon")

    # Into design units, standing on the procedural tray height.
    m = Matrix.Translation(Vector((0, 0, W.TRAY_Z))) @ Matrix.Scale(Hy.S, 4) @ Matrix.Translation(-Hy.TRAY_C)
    parts = [o for o in (creature, lamp, pole, eyes, tray, panes) if o]
    for o in parts:
        o.matrix_world = m @ o.matrix_world
        core.apply_transform(o)
    eyes_d = [(m @ p, r * Hy.S) for p, r in eyes_m]
    grin_d = [m @ p for p in grin_m]
    chain_top = m @ CHAIN_TOP
    neck = m @ Hy.NECK_M

    lo, hi = Hy._bounds([creature])
    head_c = Vector(((lo.x + hi.x) / 2, (lo.y + hi.y) / 2, (m @ Hy.NECK_M).z + 0.85))
    up_back = Vector((-0.15, 0.5, 0.85)).normalized()

    pcd, axd = m @ pc, (m.to_3x3() @ ax).normalized()

    def pole_dd(p):
        return (p - (pcd + axd * (p - pcd).dot(axd))).length

    def grin_dist(p):
        return Hy._seg_dist(p, grin_d)

    rel_kd, rel = relief_map(creature)
    rel_scale = 0.012  # relief that counts as a full stitch or loop (design units)

    def relief(p):
        return rel[rel_kd.find(p)[1]] / rel_scale

    def cloth_col(p, n, o, cv, op):
        patch = W.fbm(p, 0.55, 2, 41.0)
        base = paint.mix(W.SKIN, W.PATCH, max(0.0, min(1.0, (patch - 0.15) * 2.5)) * 0.55)
        base = paint.mix(base, W.SHADOW, 0.14)
        c = W.burlap(p, n, max(-1.0, min(1.0, cv * 4.0)), op, base, None, 3.0)
        head = p.z > neck.z - 0.05
        if head:  # the dark sacking over the crown, back and curl
            d = (p - head_c).dot(up_back) + 0.1 * W.fbm(p, 0.25, 2, 21.0)
            t = max(0.0, min(1.0, (d + 0.25) / 0.35))
            t = t * t * (3 - 2 * t)
            dark = paint.mix(W.DARK, W.DARK_TEAL, 0.5 + 0.45 * W.fbm(p, 0.12, 3, 3.0))
            dark = paint.mix(dark, H("0b0e0f"), min(0.85, max(0.0, -cv) * 1.4 + (1 - op) * 0.9))
            c = paint.mix(c, dark, t)
            g = grin_dist(p)
            if g < 0.22:  # the grin: twine on the raised loops, black in the gaps between them
                rl = relief(p)
                k = 1.0 if g < 0.14 else max(0.0, (0.22 - g) / 0.08)
                if rl > 0.28:
                    tw = paint.mix(W.TWINE, W.TWINE_DK, max(0.0, W.fbm(p, 0.04, 2, 13.0)) * 0.6)
                    tw = paint.mix(tw, H("2a241b"), min(0.6, (1 - op) * 0.9))
                    c = paint.mix(c, tw, min(1.0, rl * 2.5) * k)
                else:
                    c = paint.mix(c, W.LIP, max(0.0, min(1.0, 0.2 - rl * 1.5)) * k)
            for ep, r in eyes_d:  # dark socket crease round each eye
                e = (p - ep).length
                if r * 0.9 < e < r * 1.35:
                    c = paint.mix(c, W.CREVICE, 0.55 * (1 - abs(e - r * 1.1) / (r * 0.25)))
        elif pole_dd(p) > 0.2:  # (not the hands round the pole: their knuckles are not stitches)
            rl = relief(p)
            if rl > 0.35:  # Meshy's stitch ridges, as dark thread
                c = paint.mix(c, paint.mix(W.THREADS["brown"], W.THREADS["black"], 0.35), min(0.85, (rl - 0.35) * 1.5))
            elif rl < -0.4:  # the sunk seam beside them
                c = paint.mix(c, W.CREVICE, min(0.6, (-rl - 0.4)))
        dirt = max(0.0, min(1.0, (W.TRAY_Z + 0.9 - p.z) / 1.4)) * (0.75 + 0.25 * W.fbm(p, 0.1, 2, 31.0))
        return paint.mix(c, paint.mix(W.STAIN, W.CREVICE, 0.45), dirt * 0.45)

    def eye_col(p, n, o, cv, op):
        c = paint.mix(W.EYE, H("c9d6d1"), 0.4 + 0.3 * max(0.0, W.fbm(p, 0.05, 2, 12.0)))
        ep, r = min(eyes_d, key=lambda e: (p - e[0]).length)
        q = p - ep
        up = Vector((0, 0, 1))
        side = up.cross(n).normalized() if n.length > 0 else Vector((1, 0, 0))
        v = q.dot(up) / r
        u = q.dot(side) / r
        if abs(u) < 0.62:  # the laced slit across the middle, with its bone stitches
            if abs(v + 0.02) < 0.06:
                c = paint.mix(c, W.LIP, 0.9)
            elif abs(v) < 0.24 and (abs(u * 9.0) % 1.0) < 0.32:
                c = paint.mix(c, H("e9e6da"), 0.85)
        return paint.mix(c, W.SHADOW, min(1.0, (1 - op) * 1.3))

    def lamp_col(p, n, o, cv, op):
        if o.name == "Pole":
            return Hy.metal_col(p, n, o, cv, op)
        base = paint.mix(Hy.metal_col(p, n, o, cv, op), W.IRON, 0.35)  # darker iron than the procedural lamp
        if cv > 0.45:  # worn copper on the raised edges, rivets and frame lips
            base = paint.mix(base, W.COPPER, min(0.7, (cv - 0.25) * 2.0))
        return base

    for o in parts:
        core.uv_box(o, 1.2)
    W.custom_paint([creature], cloth_col, ao_samples=20, ao_distance=0.45)
    if eyes:
        core.subdivide(eyes, 2)  # fine enough to carry the painted slit and its stitches
        W.custom_paint([eyes], eye_col, ao_samples=10, ao_distance=0.2)
    W.custom_paint([o for o in (lamp, pole, tray) if o], lamp_col, ao_samples=16, ao_distance=0.35)
    if panes:
        pz = [(o_.matrix_world @ v.co).z for o_ in (panes,) for v in o_.data.vertices]
        z0, z1 = min(pz), max(pz)

        def pane_col(p, n, o, cv, op):
            hz = 1 - abs((p.z - z0) / max(1e-3, z1 - z0) * 2 - 1)  # brightest at mid-height
            t = max(0.0, min(1.0, 0.25 + 0.85 * hz ** 0.6)) * (0.85 + 0.25 * noise.noise(Vector((p.x * 9, p.y * 9, p.z * 2))))
            c = paint.mix(W.PANE_EDGE, W.PANE_MID, min(1.0, t * 1.6))
            return paint.mix(c, W.PANE_CORE, max(0.0, t - 0.5) * 2.0)

        W.custom_paint([panes], pane_col, ao_samples=2, ao_distance=0.01)

    if eyes:
        core.smooth(eyes, 180)
    core.tag(creature, "Fabric", part="Body")
    if eyes:
        core.tag(eyes, "SmoothPlastic", part="Eyes", lod=False)  # rides with the body (the head is not split)
    core.tag(lamp, "Metal", part="Lamp", pivot=tuple(chain_top))
    if panes:
        core.tag(panes, "Neon", part="LampGlow", pivot=tuple(chain_top), lod=False)
    perch = core.join([o for o in (pole, tray) if o], "Perch")
    core.tag(perch, "Metal", part="Perch")
    for o in (creature, lamp, perch):
        core.smooth(o, 180)

    objs = [o for o in bpy.context.scene.objects if o.type == "MESH" and "rbx_material" in o.keys()]
    lo, hi = Hy._bounds(objs)
    W.ASSET_SCALE = 6.1 / (hi.z - lo.z)
    W._lift_all((0.85 - 4.0) / W.ASSET_SCALE - lo.z)
    print("MESHY parts", {o.name: len(o.data.polygons) for o in objs}, "panes", bool(panes), "eyes", bool(eyes))
    return {"Kind": "creature", "Species": "Wisp", "LodDistance": 60, "Credit": "Base model generated with Meshy (CC BY 4.0)"}


ASSETS = {"creature_wisp": lantern_wisp_meshy}

BAKE = {"creature_wisp": {
    "Creature": {"size": 2048, "metal": 0.0, "parts": {
        "Body": {"src": ["Body"], "tris": 9000},
        "Eyes": {"src": ["Eyes"], "tris": 600},
    }},
    "Metal": {"size": 2048, "metal": 0.75, "parts": {
        "Perch": {"src": ["Perch"], "tris": 1500},
        "LampIron": {"src": ["LampIron"], "tris": 4000},
    }},
}}
