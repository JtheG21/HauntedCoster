"""Lantern Wisp, hybrid build (TASK-0043 revision 1, 2026-10-15).

The body and head come from a Meshy 6 Lite image-to-3D generation of the approved concept (free plan, CC BY 4.0:
the game must credit Meshy). Its pose and proportions match the concept's front view better than the procedural
sculpt in assets/wisp.py, which stays registered as creature_wisp_procedural. Everything Meshy did poorly is
replaced with the procedural parts: the tray, chain, lantern and a thicker pole; the grin (smoothed, carved open
and laced with twine loops) and the eyes (smoothed, then set as eyeballs in sockets, laced shut). Paint is the
procedural cloth, grime and metal paint.

The eye and grin positions are found by casting rays through the concept's own pixels from the matched front
camera (the view Meshy was generated from), so the face lands where the concept draws it.

Source mesh: ~/Roblox-Work/haunted/art/meshy/wisp_meshy_v1.glb (not in the repo; override with WISP_MESHY).
"""

import math
import os
import random
from pathlib import Path

import bmesh
import bpy
from mathutils import Matrix, Vector, noise
from mathutils.bvhtree import BVHTree

from assets import wisp as W
from hcart import anatomy as A
from hcart.sourced import bounds as _bounds, seg_dist as _seg_dist  # noqa: F401
from hcart import core, paint, shapes

MESHY = Path(os.environ.get("WISP_MESHY", "~/Roblox-Work/haunted/art/meshy/wisp_meshy_v1.glb")).expanduser()
H = paint.hex3

# Measured on the Meshy mesh (its own units, front facing -Y, 2026-10-15).
S = 4.0  # Meshy units -> design units
TRAY_C = Vector((-0.28, 0.10, -0.225))  # top centre of Meshy's tray, where the toes grip
POLE_TIPS = (Vector((-0.497, -0.052, 0.464)), Vector((0.544, -0.302, -0.652)))
MESHY_LANTERN_H = 0.53  # apex to point
NECK_Z = 0.55
NECK_M = Vector((-0.05, -0.02, 0.55))

# The concept's front view (02 Research/assets/wisp-pilot/wisp-approved-concept.png, crop 0,0,860,1287), in pixels.
REF = (860, 1287)
# Meshy put its own eye lumps and tooth row where its head needs them; ours go exactly there (front ortho, x/z).
EYES_M = [((0.11, 0.817), 0.046), ((0.229, 0.752), 0.038)]
GRIN_M = [(-0.135, 0.8), (-0.08, 0.745), (-0.02, 0.703), (0.05, 0.676), (0.12, 0.665), (0.185, 0.678), (0.235, 0.712)]  # a rounder smile than Meshy's
GRIN_OLD = [(-0.105, 0.84), (-0.047, 0.77), (0.023, 0.712), (0.093, 0.677), (0.163, 0.677), (0.21, 0.70)]  # Meshy's tooth row
VIEW = {"yaw": -8.0, "el": 16.0, "lens": 50.0, "fill": 0.94}  # the compare.py front view

POLE_R = 0.17
HEAD_YAW = -22.0


def to_design(p: Vector) -> Vector:
    return (p - TRAY_C) * S + Vector((0, 0, W.TRAY_Z))


def _concept_rays(objs):
    """Camera rays through concept pixels, framed exactly as compare.py frames the whole Meshy mesh."""
    lo, hi = _bounds(objs)
    centre = (lo + hi) / 2
    tanh = 24.0 / (2 * VIEW["lens"])  # vertical sensor fit, 24 mm sensor
    dist = ((hi.z - lo.z) / VIEW["fill"]) / (2 * tanh) * 1.05
    a, el = math.radians(VIEW["yaw"] - 90), math.radians(VIEW["el"])
    cam = centre + Vector((math.cos(a) * math.cos(el), math.sin(a) * math.cos(el), math.sin(el))) * dist
    q = (centre - cam).to_track_quat("-Z", "Y")
    aspect = REF[0] / REF[1]

    def ray(px, py):
        d = q @ Vector(((px / REF[0] - 0.5) * 2 * tanh * aspect, (0.5 - py / REF[1]) * 2 * tanh, -1.0))
        return cam, d.normalized()

    px_size = lambda depth: 2 * depth * tanh / REF[1]  # noqa: E731  world units per concept pixel at a depth
    return ray, px_size


def _smooth_region(obj, weight_fn, iters=30):
    """Laplacian smoothing weighted per vertex (0..1): irons Meshy's lumpy eyes and teeth flat."""
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bm.verts.ensure_lookup_table()
    w = [weight_fn(v.co) for v in bm.verts]
    idx = [i for i, x in enumerate(w) if x > 0]
    for _ in range(iters):
        new = {}
        for i in idx:
            v = bm.verts[i]
            nb = [e.other_vert(v).co for e in v.link_edges]
            if nb:
                avg = sum(nb, Vector()) / len(nb)
                new[i] = v.co.lerp(avg, 0.6 * w[i])
        for i, co in new.items():
            bm.verts[i].co = co
    bm.to_mesh(obj.data)
    bm.free()
    obj.data.update()


def _split_head(obj):
    """Moves the head (above the neck, but not the raised right arm) into its own object."""
    bm = bmesh.new()
    bm.from_mesh(obj.data)

    def is_head(co):
        return co.z > NECK_Z and (co.x > -0.15 or co.z > 0.68)

    head_faces = [f for f in bm.faces if all(is_head(v.co) for v in f.verts)]
    hb = bmesh.new()
    vmap = {}
    for f in head_faces:
        vs = []
        for v in f.verts:
            if v not in vmap:
                vmap[v] = hb.verts.new(v.co)
            vs.append(vmap[v])
        hb.faces.new(vs)
    bmesh.ops.delete(bm, geom=head_faces, context="FACES_ONLY")
    loose = [v for v in bm.verts if not v.link_faces]
    bmesh.ops.delete(bm, geom=loose, context="VERTS")
    bm.to_mesh(obj.data)
    bm.free()
    obj.data.update()
    return core.obj_from_bmesh("Head", hb, "Fabric")


def _neck_collar(body):
    """A stitched cloth collar over the open edge left where the head was cut away (the concept's neck seam)."""
    bm = bmesh.new()
    bm.from_mesh(body.data)
    edges = [e for e in bm.edges if e.is_boundary and min(v.co.z for v in e.verts) > NECK_Z - 0.08]
    pts = [(e.verts[0].co + e.verts[1].co) / 2 for e in edges]
    bm.free()
    if len(pts) < 8:
        return None
    c = sum(pts, Vector()) / len(pts)
    ref = Vector((1, 0, 0))
    up = Vector((0, 0, 1))
    pts.sort(key=lambda p: math.atan2((p - c).cross(ref).dot(up), (p - c).dot(ref)))
    ring = W.resample(pts[::3] + [pts[0]], 0.006)
    col = shapes.tube("Collar", ring, 0.02, 8, "Fabric", resample=0, cap_start=False, cap_end=False)
    core.smooth(col, 180)
    col["ring"] = [tuple(q) for q in ring]
    return col


def build_pole(top: Vector, bot: Vector):
    """The concept's thick spiked pole, laid over Meshy's thin one along the same axis."""
    ax = (top - bot).normalized()
    top, bot = top + ax * 0.12, bot - ax * 0.12
    L = (top - bot).length
    r = POLE_R
    prof = [(rr * 1.4, z * 1.25) for rr, z in [(0.0, 0.0), (0.025, 0.04), (0.088, 0.24), (0.06, 0.265), (0.06, 0.29), (0.118, 0.305),
                                               (0.124, 0.345), (0.118, 0.37), (0.07, 0.385), (0.07, 0.43), (0.1, 0.445), (0.1, 0.485),
                                               (0.072, 0.5)]] + [(r, 0.66)]
    mid = [(r, 0.7 + (L - 1.4) * k / 6) for k in range(1, 6)]
    full = prof + mid + [(rr, L - z) for rr, z in reversed(prof)]
    obj = shapes.lathe("Pole", full, 12, "Metal", cap_bottom=False, cap_top=False, wobble=0.012, seed=3)
    core.smooth(obj, 50)
    obj.matrix_world = Matrix.Translation(bot) @ ax.to_track_quat("Z", "Y").to_matrix().to_4x4()
    core.apply_transform(obj)
    return obj


def eye_parts(hits, rng):
    """Eyeballs set deep in sockets on the smoothed head, each laced shut across a slit, with a dark rim."""
    eyes, rims, slits, ropes = [], [], [], []
    for p, nrm, r in hits:
        fwd = nrm.normalized()
        c = p - fwd * r * 0.62
        eyes.append(W.ellipsoid(f"Eye{len(eyes)}", c, (r, r, r * 0.95), seg=20, rings=14, material="SmoothPlastic"))
        right = Vector((0, 0, 1)).cross(fwd).normalized()
        up = fwd.cross(right).normalized()
        pts = [c + fwd * r * 0.3 + (right * math.cos(t) + up * math.sin(t)) * r * 0.99 for t in [i / 24 * math.tau for i in range(25)]]
        rim = shapes.tube(f"Rim{len(rims)}", pts, lambda t, r=r: r * (0.1 + 0.12 * max(0.0, math.sin(math.tau * t))), 8, "Fabric",
                          resample=0, cap_start=False, cap_end=False, flatten=0.75)  # puffy lid, heavier along the top
        core.smooth(rim, 180)
        rims.append(rim)
        arc = []
        for i in range(15):
            ang = math.radians(-58 + 116 * i / 14)
            d_ = fwd * math.cos(ang) + right * math.sin(ang) + up * 0.08
            arc.append(c + d_.normalized() * (r + 0.002))
        sl = shapes.tube(f"Slit{len(slits)}", arc, lambda t, r=r: r * (0.04 + 0.11 * math.sin(math.pi * min(1, max(0, t))) ** 0.7), 6,
                         "SmoothPlastic", resample=0, flatten=0.5)
        core.smooth(sl, 180)
        slits.append(sl)
        for j in range(5):
            ang = math.radians(-40 + 80 * j / 4 + (rng.random() - 0.5) * 6)
            bd = (fwd * math.cos(ang) + right * math.sin(ang)).normalized()
            pts = [c + (bd + up * (0.32 * e + 0.08)).normalized() * (r + (0.08 * r if e == 0 else -0.01 * r)) for e in (-1, 0, 1)]
            ropes.append(W.rope(f"EyeTwine{len(eyes)}_{j}", pts, r * 0.055, segs=5, per=2))
    return eyes, rims, slits, ropes


# --- paint (shared palette with assets/wisp.py) ----------------------------------------------------------------------
def metal_col(p, n, o, cv, op):
    name = o.name
    m = 0.5 + 0.5 * W.fbm(p, 0.2, 3, 7.0)
    edge = max(0.0, cv - 0.6) * 2.5 + (0.5 if noise.noise(p / 0.05) > 0.4 else 0.0)
    if name == "Pole":
        base = paint.mix(H("3f3e3b"), H("7d7a72"), m)
        base = paint.mix(base, H("b3a796"), min(0.5, edge))
    elif name.startswith("RoofPlateRim"):
        base = paint.mix(W.COPPER, H("5b3a24"), 0.3 + 0.5 * m)
    elif name.startswith(("Roof", "Ridge")):
        base = paint.mix(H("2e2e30"), H("4f4f53"), m)
        base = paint.mix(base, W.COPPER, min(0.6, edge))
    elif name == "Rivets" or name.endswith("Band"):
        base = paint.mix(W.COPPER, H("4a3020"), 0.35 + 0.45 * m)
    elif name.startswith("Bar"):
        base = paint.mix(W.IRON, W.IRON_MID, m * 0.6)
    else:
        base = paint.mix(W.IRON, W.IRON_MID, m)
        base = paint.mix(base, W.BRONZE, 0.7 + 0.3 * max(0.0, W.fbm(p, 0.12, 2, 9.0)))  # weathered bronze-iron
        base = paint.mix(base, W.COPPER, 0.18)
        worn = noise.noise(p / 0.04 + Vector((3.3, 0, 0)))
        if worn > 0.2:
            base = paint.mix(base, W.COPPER, min(0.65, (worn - 0.2) * 2.2))
    if W.fbm(p, 0.05, 2, 11.0) > 0.3:
        base = paint.mix(base, W.RUST, 0.45)
    streak = noise.noise(Vector((p.x * 38, p.y * 38, p.z * 3.0)))
    if streak > 0.45 and abs(n.z) < 0.6:
        base = paint.mix(base, H("3a2418"), min(0.35, (streak - 0.45) * 2.0))
    if op < 0.6:
        base = paint.mix(base, W.VERDIGRIS, (0.6 - op) * 0.6)
    base = paint.mix(base, H("0b0a09"), (1 - op) * 0.45)
    if noise.noise(p / 0.012) > 0.5:
        base = paint.mul(base, 0.7)
    return base


def pane_col(p, n, o, cv, op):
    q = p - W.LAMP_PIVOT
    zc = W.Z_TOP - W.LS * (W.Z_TOP - (W.Z_BT + W.Z_BB) / 2)
    hz = 1 - min(1.0, abs(p.z - zc) / (W.LS * (W.Z_BT - W.Z_BB) / 2))
    lat = max(abs(q.x), abs(q.y))
    across = min(abs(q.x), abs(q.y)) / max(1e-3, lat)
    t = max(0.0, min(1.0, 0.2 + 0.8 * hz ** 0.7 * (1 - across ** 1.5)))
    t *= 0.85 + 0.25 * noise.noise(Vector((p.x * 9, p.y * 9, p.z * 2)))
    c = paint.mix(W.PANE_EDGE, W.PANE_MID, min(1.0, t * 1.6))
    return paint.mix(c, W.PANE_CORE, max(0.0, t - 0.55) * 2.2)


def twine_col(p, n, o, cv, op):
    c = paint.mix(W.TWINE, W.TWINE_DK, max(0.0, W.fbm(p, 0.04, 2, 13.0)) * 0.7)
    c = paint.mix(c, H("2a241b"), min(0.75, max(0.0, -cv) * 1.3 + (1 - op) * 0.8))
    if cv > 0.15:
        c = paint.mix(c, H("efe8d4"), 0.3)
    return paint.mul(c, 0.94 + 0.1 * noise.noise(p / 0.006))


def eye_col(p, n, o, cv, op):
    if o.name == "FaceSeam":
        return W.LIP
    c = paint.mix(W.EYE, W.EYE_DK, max(0.0, W.fbm(p, 0.05, 2, 12.0)) * 0.6)
    c = paint.mix(c, W.SHADOW, min(1.0, (1 - op) * 1.3))
    return paint.mix(c, W.CREVICE, max(0.0, 0.62 - op) * 1.6)


def lantern_wisp_hybrid():
    rng = random.Random(15)
    bpy.ops.import_scene.gltf(filepath=str(MESHY))
    src = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    mesh = core.join(src, "Meshy")
    core.apply_transform(mesh)
    for m in list(mesh.data.materials):
        mesh.data.materials.clear()
        break
    core.activate(mesh)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.mesh.separate(type="LOOSE")
    bpy.ops.object.mode_set(mode="OBJECT")
    pieces = sorted([o for o in bpy.context.scene.objects if o.type == "MESH"], key=lambda o: -len(o.data.vertices))
    creature = pieces[0]
    for o in pieces[1:]:
        bpy.data.objects.remove(o)  # Meshy's tray, chain and lantern: replaced by the procedural ones
    creature.name = "Body"
    core.merge_close(creature, 1e-5)

    # Fit the pole's axis to its own vertices (the extreme vertices sit on knuckles and spikes).
    vs = [creature.matrix_world @ v.co for v in creature.data.vertices]
    a0, b0 = POLE_TIPS
    ax0 = (b0 - a0).normalized()
    near = [p for p in vs if (p - (a0 + ax0 * (p - a0).dot(ax0))).length < 0.035]
    c = sum(near, Vector()) / len(near)
    import numpy as np
    arr = np.array([tuple(p - c) for p in near])
    ax = Vector(np.linalg.svd(arr, full_matrices=False)[2][0])
    if ax.dot(ax0) < 0:
        ax = -ax
    ts = [(p - c).dot(ax) for p in near]
    pole_tips = (c + ax * min(ts), c + ax * max(ts))
    print("HYBRID pole fit", len(near), [tuple(round(x, 3) for x in t) for t in pole_tips])

    # Face positions.
    tree = BVHTree.FromObject(creature, bpy.context.evaluated_depsgraph_get())
    eye_hits = []
    for (x, z), r in EYES_M:
        loc, nrm, _, _ = tree.ray_cast(Vector((x, -2.0, z)), Vector((0, 1, 0)))
        eye_hits.append((loc, nrm, r))
    grin_m = []
    for x, z in GRIN_M:
        loc, nrm, _, _ = tree.ray_cast(Vector((x, -2.0, z)), Vector((0, 1, 0)))
        if loc is not None:
            grin_m.append(loc)
    grin_old = []
    for x, z in GRIN_OLD:
        loc, _, _, _ = tree.ray_cast(Vector((x, -2.0, z)), Vector((0, 1, 0)))
        if loc is not None:
            grin_old.append(loc)
    print("HYBRID eyes", [(tuple(round(c, 3) for c in h[0]), round(h[2], 3)) for h in eye_hits], "grin pts", len(grin_m))

    # Iron out Meshy's lumpy eyes and bump-teeth before the real ones go in.
    def face_w(co):
        w = 0.0
        for p, _, r in eye_hits:
            d = (co - p).length
            w = max(w, max(0.0, 1 - d / (r * 2.4)))
        d = min(_seg_dist(co, grin_m), _seg_dist(co, grin_old))
        w = max(w, max(0.0, 1 - d / 0.1))
        return min(1.0, w * 1.6)

    _smooth_region(creature, face_w, iters=80)
    _smooth_region(creature, lambda co: 0.4, iters=9)  # tidy Meshy's ragged seam frills
    _smooth_region(creature, lambda co: max(0.0, 1 - (co - NECK_M).length / 0.16), iters=30)  # the jumbled stitching round the neck

    head = _split_head(creature)
    collar = _neck_collar(creature)
    # Meshy turned the face too far to its left; the concept faces the viewer more.
    hcm = sum((Vector(c) for c in head.bound_box), Vector()) / 8
    squash = Matrix.Translation(hcm) @ Matrix.Diagonal((0.9, 0.88, 1.0, 1.0)) @ Matrix.Translation(-hcm)  # shorter at the back
    turn = Matrix.Translation(NECK_M) @ Matrix.Rotation(math.radians(HEAD_YAW), 4, "Z") @ Matrix.Translation(-NECK_M) @ squash
    head.matrix_world = turn @ head.matrix_world
    core.apply_transform(head)
    eye_hits = [(turn @ p, (turn.to_3x3() @ n).normalized(), r) for p, n, r in eye_hits]
    grin_m = [turn @ p for p in grin_m]
    m = Matrix.Translation(Vector((0, 0, W.TRAY_Z))) @ Matrix.Scale(S, 4) @ Matrix.Translation(-TRAY_C)
    for o in (creature, head) + ((collar,) if collar else ()):
        o.matrix_world = m @ o.matrix_world
        core.apply_transform(o)
    eye_hits = [(to_design(p), n, r * S) for p, n, r in eye_hits]
    neck = to_design(NECK_M)

    # The grin: cast onto the smoothed head, carved open, laced across with twine.
    htree = A.surface_bvh([head])
    grin_d = W.resample([to_design(p) for p in grin_m], 0.03)
    grin = []
    for q in grin_d:
        loc, nrm, _, _ = htree.find_nearest(q)
        if loc is not None:
            grin.append((loc, nrm))
    # Lumpy, crumpled sacking over the crown and back (the face stays smooth enough to read).
    hc0 = sum((Vector(c) for c in head.bound_box), Vector()) / 8
    ub = Vector((-0.15, 0.5, 0.85)).normalized()
    W.displace(head, lambda p: max(0.0, min(1.0, (p - hc0).dot(ub) / 0.6 + 0.4)) * (0.03 * W.fbm(p, 0.3, 2, 8.0) + 0.012 * W.ridged(p, 0.12, 5.0)))
    W.carve_mouth(head, grin, depth=0.11, half_gap=0.055)
    htree = A.surface_bvh([head])
    twine, mouth_holes, slot = W.mouth_twine(htree, grin, rng, thick=0.9, count=24)
    eyes, rims, slits, eye_twine = eye_parts(eye_hits, rng)
    # The neck seam is laced with the same heavy twine loops as the grin (the concept's collar).
    if collar:
        btree = A.surface_bvh([creature, head])
        ring = []
        for q in collar["ring"]:
            loc, nrm, _, _ = btree.find_nearest(m @ Vector(q))
            if loc is not None:
                ring.append((loc, nrm))
        ring = ring[:: max(1, len(ring) // 60)]
        neck_twine, _, neck_slot = W.mouth_twine(btree, ring, rng, thick=1.1, count=18)
        bpy.data.objects.remove(neck_slot)
        eye_twine += neck_twine

    # Perch: the concept's thick pole on Meshy's pole axis, the procedural tray, chain and lantern.
    pole = build_pole(to_design(pole_tips[0]), to_design(pole_tips[1]))
    tray = W.build_tray()
    W.LS = 1.35 * MESHY_LANTERN_H * S / (W.Z_APEX - W.Z_POINT)  # Meshy drew the lantern small; the concept's is ~1.4x the head
    for o in [o for o in bpy.context.scene.objects if o.name.startswith("TrayScroll")]:
        bpy.data.objects.remove(o)
    lamp_parts, panes = W.build_lantern()

    # Paint.
    hc = sum((Vector(c) for c in head.bound_box), Vector()) / 8
    hr = (Vector(head.bound_box[6]) - Vector(head.bound_box[0])).length / 2
    up_back = Vector((-0.15, 0.5, 0.85)).normalized()

    def cloth_col(p, n, o, cv, op):
        if o.name.startswith("Rim"):
            return paint.mix(paint.mix(W.SKIN_MID, W.PATCH, 0.4), W.SHADOW, 0.35 + 0.3 * max(0.0, W.fbm(p, 0.03, 2, 2.0)))  # puffy cloth lid
        patch = W.fbm(p, 0.55, 2, 41.0)
        base = paint.mix(W.SKIN, W.PATCH, max(0.0, min(1.0, (patch - 0.15) * 2.5)) * 0.55)  # sewn panels of different sacking
        base = paint.mix(base, W.SHADOW, 0.18 if o.name != "Head" else 0.06)
        pale = W.burlap(p, n, max(-1.0, min(1.0, cv * 4.5)), op, base, None, 5.0 if o.name == "Head" else 1.0)  # Meshy's seams read dark
        if o.name != "Head":
            dirt = max(0.0, min(1.0, (W.TRAY_Z + 0.9 - p.z) / 1.4)) * (0.75 + 0.25 * W.fbm(p, 0.1, 2, 31.0))
            return paint.mix(pale, paint.mix(W.STAIN, W.CREVICE, 0.45), dirt * 0.5)
        d = (p - hc).dot(up_back) / hr + 0.1 * W.fbm(p, 0.25, 2, 21.0)
        t = max(0.0, min(1.0, (d + 0.36) / 0.32))
        t = t * t * (3 - 2 * t)
        g = W.fbm(p, 0.12, 3, 3.0)
        dark = paint.mix(W.DARK, W.DARK_TEAL, 0.5 + 0.45 * g)
        dark = paint.mix(dark, H("0b0e0f"), min(0.85, max(0.0, -cv) * 1.1 + (1 - op) * 0.9))
        return paint.mix(pale, dark, t)

    if collar:
        creature = core.join([creature, collar], "Body")
    for o in [creature, head, pole, tray] + lamp_parts + rims:
        core.uv_box(o, 1.2)
    W.custom_paint([creature, head, pole, tray] + rims, lambda p, n, o, cv, op: (
        metal_col(p, n, o, cv, op) if o.get("rbx_material") == "Metal" else cloth_col(p, n, o, cv, op)), ao_samples=20, ao_distance=0.45)
    W.custom_paint(lamp_parts, metal_col, ao_samples=16, ao_distance=0.35)
    W.custom_paint([panes], pane_col, ao_samples=2, ao_distance=0.01)
    W.custom_paint(twine + eye_twine, twine_col, ao_samples=10, ao_distance=0.08)
    eyes_o = core.join(eyes, "FaceEyes")
    dark = core.join([slot] + slits, "FaceSeam")
    W.custom_paint([eyes_o, dark], eye_col, ao_samples=14, ao_distance=0.2)

    lamp = core.join(lamp_parts, "LampIron")
    core.tag(lamp, "Metal", part="Lamp", pivot=tuple(W.LAMP_PIVOT))
    face_twine = core.join(twine + eye_twine, "FaceTwine")
    core.tag(face_twine, "Fabric", part="Twine", pivot=tuple(neck))
    face = core.join([eyes_o, dark], "Face")
    core.tag(face, "SmoothPlastic", part="Face", pivot=tuple(neck), lod=False)
    core.tag(creature, "Fabric", part="Body")
    head = core.join([head] + rims, "Head")
    core.tag(head, "Fabric", part="Head", pivot=tuple(neck))
    perch = core.join([pole, tray], "Perch")
    core.tag(perch, "Metal", part="Perch")
    core.smooth(creature, 180)
    core.smooth(head, 180)

    # Lift and scale: 6.1 studs tall, lantern 0.85 studs off the ground at hover 4.
    objs = [o for o in bpy.context.scene.objects if o.type == "MESH" and "rbx_material" in o.keys()]
    lo, hi = _bounds(objs)
    W.ASSET_SCALE = 6.1 / (hi.z - lo.z)
    dz = (0.85 - 4.0) / W.ASSET_SCALE - lo.z
    W._lift_all(dz)
    print("HYBRID tris", {o.name: len(o.data.polygons) for o in objs}, "scale", round(W.ASSET_SCALE, 3))
    return {"Kind": "creature", "Species": "Wisp", "LodDistance": 60, "Credit": "Base model generated with Meshy (CC BY 4.0)"}


ASSETS = {"creature_wisp_hybrid": lantern_wisp_hybrid}

BAKE = {"creature_wisp_hybrid": {
    "Creature": {"size": 2048, "metal": 0.0, "parts": {
        "Body": {"src": ["Body"], "tris": 6000},
        "Head": {"src": ["Head"], "tris": 6000},
    }},
    "Face": {"size": 1024, "metal": 0.0, "parts": {
        "Face": {"src": ["Face"], "tris": 1600},
        "FaceTwine": {"src": ["FaceTwine"]},
    }},
    "Metal": {"size": 1024, "metal": 0.75, "parts": {
        "Perch": {"src": ["Perch"]},
        "LampIron": {"src": ["LampIron"]},
    }},
}}
