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
from hcart import core, paint, shapes

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


def lamp_details(lamp):
    """The concept's lamp detail on Meshy's lantern (Meshy units): rivets along the bands and corner posts,
    copper-bound triangular plates on the roof, and an even glowing pane surface just behind the bars."""
    import numpy as np
    from mathutils.bvhtree import BVHTree

    tree = BVHTree.FromObject(lamp, bpy.context.evaluated_depsgraph_get())
    vs = np.array([tuple(lamp.matrix_world @ v.co) for v in lamp.data.vertices])
    c, s_ = math.cos(LAMP_ANGLE), math.sin(LAMP_ANGLE)
    dx, dy = vs[:, 0] - LAMP_C[0], vs[:, 1] - LAMP_C[1]
    rr = np.maximum(np.abs(c * dx - s_ * dy), np.abs(s_ * dx + c * dy))

    def rmax(z, band=0.012, pct=97, face=None):
        m = np.abs(vs[:, 2] - z) < band
        if face is not None:  # only vertices on that face's side (where its axis gives the square distance)
            nrm, _ = frame(face)
            d = (vs[:, 0] - LAMP_C[0]) * nrm.x + (vs[:, 1] - LAMP_C[1]) * nrm.y
            m &= d > rr * 0.97
        return float(np.percentile(rr[m], pct)) if m.sum() > 20 else 0.16

    def frame(k):
        """Outward normal and along-face tangent of face k, in world (Meshy) axes."""
        a = LAMP_ANGLE + math.pi / 2 * k
        # face normals of the turned square: local +x rotated back by the lantern angle
        nrm = Vector((math.cos(-a), math.sin(-a), 0))
        tan = Vector((-nrm.y, nrm.x, 0))
        return nrm, tan

    centre = Vector((LAMP_C[0], LAMP_C[1], 0))

    def on_surface(k, u, z):
        """Point on face k at along-face offset u and height z, found by casting in from outside."""
        nrm, tan = frame(k)
        start = centre + nrm * 0.5 + tan * u + Vector((0, 0, z))
        loc, n, _, _ = tree.ray_cast(start, -nrm, 1.0)
        return (loc, n) if loc is not None else (None, None)

    rivets, rims, glass = [], [], []
    for k in range(4):
        for z in (-0.605, -0.865):  # top and bottom bands
            w = rmax(z) * 0.82
            for i in range(6):
                u = -w + 2 * w * i / 5
                loc, n = on_surface(k, u, z)
                if loc is not None:
                    rivets.append(W.ellipsoid("Rivet", loc + n * 0.001, (0.0045, 0.0045, 0.0045), seg=8, rings=5,
                                              material="Metal"))
        for i in range(5):  # down the corner post
            z = -0.64 - 0.2 * i / 4
            nrm, tan = frame(k)
            r = rmax(z)
            p = centre + (nrm + tan) * r * 0.985 + Vector((0, 0, z))
            loc, n, _, _ = tree.ray_cast(p + (nrm + tan).normalized() * 0.2, -(nrm + tan).normalized(), 0.5)
            if loc is not None:
                rivets.append(W.ellipsoid("Rivet", loc + n * 0.001, (0.004, 0.004, 0.004), seg=8, rings=5, material="Metal"))
        # A row of rivets down the roof edge, from the eave corner up to the peak.
        hip = (nrm + tan).normalized()
        for i in range(6):
            r = 0.215 - 0.15 * i / 5
            q = centre + hip * r * math.sqrt(2) * 0.97 + Vector((0, 0, -0.3))
            loc, n, _, _ = tree.ray_cast(q, Vector((0, 0, -1)), 0.5)
            if loc is not None:
                rivets.append(W.ellipsoid("Rivet", loc + n * 0.001, (0.0042, 0.0042, 0.0042), seg=8, rings=5, material="Metal"))
        # Copper-bound triangle on the roof face: cast down onto the roof.
        nrm, tan = frame(k)
        tri = [(-0.13, 0.205), (0.13, 0.205), (0.0, 0.07), (-0.13, 0.205)]
        pts = []
        for (u0, r0), (u1, r1) in zip(tri, tri[1:]):
            for t in [j / 8 for j in range(8)]:
                u, r = u0 + (u1 - u0) * t, r0 + (r1 - r0) * t
                q = centre + nrm * r + tan * u + Vector((0, 0, -0.3))
                loc, n, _, _ = tree.ray_cast(q, Vector((0, 0, -1)), 0.5)
                if loc is not None:
                    pts.append(loc + n * 0.004)
        if len(pts) > 6:
            pts.append(pts[0])
            rim = shapes.tube(f"RoofPlateRim{k}", pts, 0.0055, 5, "Metal", resample=0, flatten=0.6)
            core.smooth(rim, 50)
            rims.append(rim)
        # Even glowing glass behind the bars, following the lantern's pinched profile.
        zs = [-0.855 + 0.23 * j / 14 for j in range(15)]
        bm = bmesh.new()
        grid = []
        for z in zs:
            r = 0.5 * (rmax(z, pct=30, face=k) + rmax(z, pct=85, face=k))  # in front of Meshy's recessed panes, behind its bars
            row = []
            for i in range(9):
                u = (-0.92 + 1.84 * i / 8) * r
                row.append(bm.verts.new(centre + nrm * r + tan * u + Vector((0, 0, z))))
            grid.append(row)
        for a, b in zip(grid, grid[1:]):
            for i in range(8):
                bm.faces.new((a[i], a[i + 1], b[i + 1], b[i]))
        glass.append(core.obj_from_bmesh(f"Glass{k}", bm, "Neon"))
    return rivets, rims, glass


def separate_head(body, neck_z, x_arm, z_arm, band=0.12):
    """Splits the painted head off the body for the neck animation, keeping its vertex colours (Blender's own
    separate). A thin band of neck faces below the cut is copied into the head as well, so the overlap hides the
    seam while the head turns. The raised right arm stays with the body."""
    def meshy(c):  # back to Meshy units, where the head was measured
        return Vector(((c.x) / Hy.S + Hy.TRAY_C.x, c.y / Hy.S + Hy.TRAY_C.y, (c.z - W.TRAY_Z) / Hy.S + Hy.TRAY_C.z))

    def in_neck(m, r=0.055):
        return math.hypot(m.x - Hy.NECK_M.x, m.y - Hy.NECK_M.y) < r

    def is_cand(c):
        m = meshy(c)
        chin = m.y < Hy.NECK_M.y - 0.03 and abs(m.x - 0.05) < 0.26
        return m.z > Hy.NECK_M.z + 0.02 or (m.z > Hy.NECK_M.z - 0.02 and (in_neck(m) or chin))

    def head_island():
        """Candidate faces connected to the top of the head (the raised shoulder is its own island)."""
        core.activate(body)
        bpy.ops.object.mode_set(mode="EDIT")
        bm = bmesh.from_edit_mesh(body.data)
        bm.faces.ensure_lookup_table()
        cand = {f.index for f in bm.faces if is_cand(f.calc_center_median())}
        seed = max(cand, key=lambda k: bm.faces[k].calc_center_median().z)
        keep, todo = {seed}, [seed]
        while todo:
            f = bm.faces[todo.pop()]
            for e in f.edges:
                for g in e.link_faces:
                    if g.index in cand and g.index not in keep:
                        keep.add(g.index)
                        todo.append(g.index)
        bpy.ops.object.mode_set(mode="OBJECT")
        return keep

    island = head_island()

    def is_head(c):
        return False  # replaced by the island selection below

    def is_band(c):
        m = meshy(c)
        return Hy.NECK_M.z - band / Hy.S < m.z <= Hy.NECK_M.z and in_neck(m, 0.06)

    def select(fn, ids=None):
        core.activate(body)
        bpy.ops.object.mode_set(mode="EDIT")
        bm = bmesh.from_edit_mesh(body.data)
        for f in bm.faces:
            f.select = (f.index in ids) if ids is not None else fn(f.calc_center_median())
        bmesh.update_edit_mesh(body.data)

    before = set(bpy.data.objects)
    select(is_band)
    bpy.ops.mesh.duplicate()
    bpy.ops.mesh.separate(type="SELECTED")
    bpy.ops.object.mode_set(mode="OBJECT")
    band_obj = next(iter(set(bpy.data.objects) - before), None)
    before = set(bpy.data.objects)
    select(None, island)
    bpy.ops.mesh.separate(type="SELECTED")
    bpy.ops.object.mode_set(mode="OBJECT")
    head = next(iter(set(bpy.data.objects) - before))
    if band_obj:
        head = core.join([head, band_obj], "Head")
    head.name = "Head"
    return head


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

    # Puffy cloth lids round Meshy's eye lumps (a light touch: a ring on the surface, heavier along the top).
    lids = []
    for p_, r in eyes_m:
        loc, nrm, _, _ = tree.find_nearest(p_)
        fwd = nrm.normalized()
        right = Vector((0, 0, 1)).cross(fwd).normalized()
        up = fwd.cross(right).normalized()
        ring = []
        for i in range(33):
            t = math.tau * i / 32
            q = p_ + (right * math.cos(t) + up * math.sin(t)) * r * 1.02
            hit, hn, _, _ = tree.find_nearest(q)
            ring.append(hit + hn * r * 0.04)
        lid = shapes.tube(f"Lid{len(lids)}", ring, lambda t, r=r: r * (0.1 + 0.14 * max(0.0, math.sin(math.tau * t))), 8, "Fabric",
                          resample=0, cap_start=False, cap_end=False, flatten=0.7)
        core.smooth(lid, 180)
        lids.append(lid)

    pole = _split(creature, lambda c, n: pole_d(c) < POLE_FACE_R, "Pole", "Metal")
    eyes = _split(creature, lambda c, n: any((c - p).length < r * 0.95 for p, r in eyes_m), "Eyes", "SmoothPlastic")
    tray = _split(lamp, lambda c, n: c.z > TRAY_SPLIT_Z, "Tray", "Metal")

    def is_pane(c, n):
        if not (-0.86 < c.z < -0.62) or abs(n.z) > 0.7:
            return False
        r = _lamp_r(c)
        return 0.11 < r < 0.16  # recessed between the frame bars (bars and posts stand out to ~0.167)

    rivets, rims, glass = lamp_details(lamp)  # Meshy's own pane faces stay as dark metal behind the new glass
    if rivets:
        rivets = [core.join(rivets, "Rivets")]
    panes = core.join(glass, "LampGlow") if glass else None
    if panes:
        core.decimate_to(panes, 320)  # flat Neon glass: shape only, keeps the asset inside the 8.5k creature budget

    # Into design units, standing on the procedural tray height.
    m = Matrix.Translation(Vector((0, 0, W.TRAY_Z))) @ Matrix.Scale(Hy.S, 4) @ Matrix.Translation(-Hy.TRAY_C)
    parts = [o for o in (creature, lamp, pole, eyes, tray, panes) if o] + rivets + rims + lids
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
            c = paint.mix(c, paint.mix(base, W.SKIN_HI, 0.15), 0.4)  # the face is cleaner than the body: no brown stains
            d = (p - head_c).dot(up_back) + 0.1 * W.fbm(p, 0.25, 2, 21.0)
            t = max(0.0, min(1.0, (d + 0.25) / 0.35))
            t = t * t * (3 - 2 * t)
            dark = paint.mix(W.DARK, W.DARK_TEAL, 0.5 + 0.45 * W.fbm(p, 0.12, 3, 3.0))
            dark = paint.mix(dark, H("0b0e0f"), min(0.85, max(0.0, -cv) * 1.4 + (1 - op) * 0.9))
            c = paint.mix(c, dark, t)
            g = grin_dist(p)
            ends = min((p - grin_d[0]).length, (p - grin_d[-1]).length) if grin_d else 9.0
            if g < 0.22 and not (ends < 0.12 and g > 0.06):  # nothing past the corners of the mouth  # the grin: twine on the raised loops, black in the gaps between them
                rl = relief(p)
                k = 1.0 if g < 0.14 else max(0.0, (0.22 - g) / 0.08)
                if rl > 0.38:
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

    def lid_col(p, n, o, cv, op):
        c = W.burlap(p, n, cv, op, paint.mix(W.SKIN, W.SKIN_MID, 0.35), None, 7.0)
        return paint.mix(c, W.CREVICE, min(0.7, (1 - op) * 1.4))  # dark crease where the lid meets the eye

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
        if o.name == "Pole" or o.name.startswith(("Rivet", "RoofPlateRim")):
            return Hy.metal_col(p, n, o, cv, op)
        base = paint.mix(Hy.metal_col(p, n, o, cv, op), W.IRON, 0.35)  # darker iron than the procedural lamp
        if o.name == "Tray":
            return base
        # Weathering: blotchy dark iron, rust patches and runs, teal patina in the recesses, bright worn copper edges.
        blot = W.fbm(p, 0.35, 3, 51.0)
        base = paint.mix(base, H("23272a"), 0.45)  # blue-grey iron under the bronze
        base = paint.mix(base, H("111416"), max(0.0, min(0.8, (blot + 0.05) * 2.2)))
        rust = W.fbm(p, 0.13, 3, 57.0) + 0.3 * noise.noise(p / 0.025)
        if rust > 0.18:
            base = paint.mix(base, paint.mix(H("6e3318"), H("9a5228"), 0.5 + 0.5 * noise.noise(p / 0.015)), min(0.65, (rust - 0.18) * 2.6))
        run = noise.noise(Vector((p.x * 30, p.y * 30, p.z * 2.5)))
        if run > 0.35 and abs(n.z) < 0.5:
            base = paint.mix(base, H("4a2614"), min(0.5, (run - 0.35) * 2.0))
        if op < 0.75:
            base = paint.mix(base, paint.mix(W.VERDIGRIS, H("3f7a70"), 0.5), min(0.8, (0.8 - op) * 2.2))
        if cv > 0.35:
            base = paint.mix(base, paint.mix(W.COPPER, H("c58a5a"), 0.4), min(0.8, (cv - 0.35) * 2.5))
        if noise.noise(p / 0.004) > 0.4:
            base = paint.mul(base, 0.6)  # pitting
        return base

    for o in parts:
        core.uv_box(o, 1.2)
    W.custom_paint([creature] + lids, lambda p, n, o, cv, op: lid_col(p, n, o, cv, op) if o.name.startswith("Lid")
                   else cloth_col(p, n, o, cv, op), ao_samples=20, ao_distance=0.45)
    # (the lids join the head once it is split off, so they turn with it)
    if eyes:
        core.subdivide(eyes, 2)  # fine enough to carry the painted slit and its stitches
        W.custom_paint([eyes], eye_col, ao_samples=10, ao_distance=0.2)
    W.custom_paint([o for o in (lamp, pole, tray) if o] + rivets + rims, lamp_col, ao_samples=16, ao_distance=0.35)
    lamp = core.join([lamp] + rivets + rims, "LampIron")
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
    # The head: split off (after painting) so the client can turn it about the neck; eyes and lids ride with it.
    x_arm = (-0.15 - Hy.TRAY_C.x) * Hy.S
    z_arm = (0.68 - Hy.TRAY_C.z) * Hy.S + W.TRAY_Z
    head = separate_head(creature, neck.z, x_arm, z_arm)
    if lids:
        head = core.join([head] + lids, "Head")
    core.tag(creature, "Fabric", part="Body")
    core.tag(head, "Fabric", part="Head", pivot=tuple(neck))
    core.smooth(head, 180)
    if eyes:
        core.tag(eyes, "SmoothPlastic", part="Face", pivot=tuple(neck), lod=False)
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

_face = {}


def keep_face(p):
    """Decimation weight: 1 on the eyes and grin, fading out over the head, so the face keeps its triangles."""
    if not _face:
        head, eyes = bpy.data.objects["Head"], bpy.data.objects.get("Eyes")
        hlo, hhi = Hy._bounds([head])
        c = Hy._bounds([eyes]) if eyes else (hlo, hhi)
        _face["c"] = (c[0] + c[1]) / 2
        _face["r"] = 0.6 * (hhi.x - hlo.x)
    d = (p - _face["c"]).length / _face["r"]
    return 1.0 if d < 0.5 else max(0.0, 1.0 - (d - 0.5) * 2.0)


BAKE = {"creature_wisp": {
    "Creature": {"size": 1024, "metal": 0.0, "parts": {
        "Body": {"src": ["Body"], "tris": 2300},
        "Head": {"src": ["Head"], "tris": 3000, "keep": keep_face},
        "Eyes": {"src": ["Eyes"], "tris": 600},
    }},
    "Metal": {"size": 1024, "metal": 0.75, "parts": {
        "Perch": {"src": ["Perch"], "tris": 500},
        "LampIron": {"src": ["LampIron"], "tris": 1700},
    }},
}}
