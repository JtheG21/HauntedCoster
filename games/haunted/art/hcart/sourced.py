"""Building game art from a generated or third-party base mesh (Meshy, a scan, a bought model).

The workflow the Lantern Wisp proved (TASK-0043 rev 1): keep the source geometry, split it into the parts the game
animates and paints, paint from the mesh's own relief, split the head for the neck turn, then scale to game size.
Each step is a function here; an asset module strings them together (see art/templates/sourced_creature.py and
05 Engineering/Blender Pipeline.md, "Sourced models").

Coordinates: measure points in the source mesh's own units first (front facing -Y), then move everything into
design units with one Matrix; helpers that take positions take world positions.
"""

from __future__ import annotations

import os
from pathlib import Path

import bmesh
import bpy
from mathutils import Vector
from mathutils.bvhtree import BVHTree
from mathutils.kdtree import KDTree

from hcart import core


def source_path(default: str, env: str) -> Path:
    """Source meshes stay out of the repo (licence and size): ~/Roblox-Work/haunted/art/<source>/..., overridable."""
    return Path(os.environ.get(env, default)).expanduser()


def load_glb(path: Path, name: str = "Source", weld: float | None = 1e-5) -> bpy.types.Object:
    """Imports a glTF, joins its meshes into one object with transforms applied and materials cleared.
    weld merges vertices closer than that distance: many exporters store every face with its own vertices, which
    would make separate_loose shatter the mesh into single faces. None skips it (the Wisp's welded Meshy file)."""
    if not path.exists():
        raise SystemExit(f"source mesh missing: {path} (not in the repo; see the asset module's docstring)")
    bpy.ops.import_scene.gltf(filepath=str(path))
    src = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    mesh = core.join(src, name)
    core.apply_transform(mesh)
    mesh.data.materials.clear()
    if weld:
        core.merge_close(mesh, weld)
    return mesh


def separate_loose(obj: bpy.types.Object) -> list[bpy.types.Object]:
    """Splits an object into its loose pieces; returns every mesh in the scene, largest (most vertices) first."""
    core.activate(obj)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.mesh.separate(type="LOOSE")
    bpy.ops.object.mode_set(mode="OBJECT")
    return sorted([o for o in bpy.context.scene.objects if o.type == "MESH"], key=lambda o: -len(o.data.vertices))


def split_faces(obj, keep_face, name, material):
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


def fit_axis(obj, a: Vector, b: Vector, radius: float):
    """Refits a rod's axis (a pole, staff, chain) to the vertices within radius of the rough line a-b.
    Returns (centre, unit axis) and a distance function to that axis."""
    import numpy as np
    vs = [obj.matrix_world @ v.co for v in obj.data.vertices]
    ax0 = (b - a).normalized()
    near = [p for p in vs if (p - (a + ax0 * (p - a).dot(ax0))).length < radius]
    pc = sum(near, Vector()) / len(near)
    ax = Vector(np.linalg.svd(np.array([tuple(p - pc) for p in near]), full_matrices=False)[2][0])
    return pc, ax


def axis_distance(pc: Vector, ax: Vector):
    return lambda p: (p - (pc + ax * (p - pc).dot(ax))).length


def bvh(obj) -> BVHTree:
    return BVHTree.FromObject(obj, bpy.context.evaluated_depsgraph_get())


def hits_from_front(tree: BVHTree, xz, depth: float = -2.0):
    """Surface points straight behind (x, z) positions read off a front view: casts along +Y from y=depth.
    Misses are dropped. Use it to place eyes, mouths and markers measured on the concept or a front render."""
    out = []
    for x, z in xz:
        loc, _, _, _ = tree.ray_cast(Vector((x, depth, z)), Vector((0, 1, 0)))
        if loc is not None:
            out.append(loc)
    return out


class Relief:
    """Per-vertex relief: how far each vertex stands out of (+) or sinks into (-) a smoothed copy of the surface,
    with the slow curvature-driven part removed so only local bumps and dips remain. Generated meshes carry their
    stitches, seams and loops as relief, which this reads more reliably than curvature.
    Relief(obj, scale)(p) is the value at the nearest vertex divided by scale (1.0 = a full stitch)."""

    def __init__(self, obj, scale: float, iters: int = 30):
        self.kd, self.rel = relief_map(obj, iters)
        self.scale = scale

    def __call__(self, p) -> float:
        return self.rel[self.kd.find(p)[1]] / self.scale


def relief_map(obj, iters=30):
    """(KDTree over world vertex positions, per-vertex relief array). See Relief."""
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
    base = rel.copy()
    for _ in range(iters):
        acc = np.zeros(n)
        np.add.at(acc, ev[:, 0], base[ev[:, 1]])
        np.add.at(acc, ev[:, 1], base[ev[:, 0]])
        base = 0.5 * base + 0.5 * acc / np.maximum(deg, 1)
    rel = rel - base
    mw = obj.matrix_world
    kd = KDTree(n)
    for i in range(n):
        kd.insert(mw @ Vector(co[i]), i)
    kd.balance()
    return kd, rel


def split_head(body, is_candidate, is_band, name: str = "Head"):
    """Splits a painted head off the body for the neck animation, keeping vertex colours.

    is_candidate(face centre) marks faces that may belong to the head (above the neck cut, plus chin and neck).
    Only candidates connected to the highest candidate face are taken, so a raised arm or shoulder that crosses
    the cut height stays with the body. is_band(face centre) marks a thin band of neck faces below the cut that is
    copied into the head too, so the overlap hides the seam while the head turns."""
    core.activate(body)
    bpy.ops.object.mode_set(mode="EDIT")
    bm = bmesh.from_edit_mesh(body.data)
    bm.faces.ensure_lookup_table()
    cand = {f.index for f in bm.faces if is_candidate(f.calc_center_median())}
    if not cand:
        bpy.ops.object.mode_set(mode="OBJECT")
        lo, hi = bounds([body])
        raise ValueError(f"split_head: no face passes is_candidate (body z {lo.z:.3f}..{hi.z:.3f}); check the neck height and units")
    seed = max(cand, key=lambda k: bm.faces[k].calc_center_median().z)
    island, todo = {seed}, [seed]
    while todo:
        f = bm.faces[todo.pop()]
        for e in f.edges:
            for g in e.link_faces:
                if g.index in cand and g.index not in island:
                    island.add(g.index)
                    todo.append(g.index)
    bpy.ops.object.mode_set(mode="OBJECT")

    def select(fn=None, ids=None):
        core.activate(body)
        bpy.ops.object.mode_set(mode="EDIT")
        bm = bmesh.from_edit_mesh(body.data)
        for f in bm.faces:
            f.select = (f.index in ids) if ids is not None else fn(f.calc_center_median())
        bmesh.update_edit_mesh(body.data)

    before = set(bpy.data.objects)
    select(fn=is_band)
    bpy.ops.mesh.duplicate()
    bpy.ops.mesh.separate(type="SELECTED")
    bpy.ops.object.mode_set(mode="OBJECT")
    band = next(iter(set(bpy.data.objects) - before), None)
    before = set(bpy.data.objects)
    select(ids=island)
    bpy.ops.mesh.separate(type="SELECTED")
    bpy.ops.object.mode_set(mode="OBJECT")
    head = next(iter(set(bpy.data.objects) - before))
    if band:
        head = core.join([head, band], name)
    head.name = name
    return head


def bounds(objs):
    pts = [o.matrix_world @ Vector(c) for o in objs for c in o.bound_box]
    lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    return lo, hi


def seg_dist(p, pts):
    """Distance from p to a polyline."""
    best = 9.0
    for a, b in zip(pts, pts[1:]):
        ab = b - a
        t = max(0.0, min(1.0, (p - a).dot(ab) / max(1e-9, ab.dot(ab))))
        best = min(best, (p - (a + ab * t)).length)
    return best


def game_parts():
    return [o for o in bpy.context.scene.objects if o.type == "MESH" and "rbx_material" in o.keys()]


def fit_to_height(height: float, lowest: float, hover_root: float = 4.0):
    """Scales the tagged parts uniformly to `height` studs tall and lifts them so the lowest point sits `lowest`
    studs above the ground, for a model rooted `hover_root` studs up (the creature Root hovers at 4).
    Pivots move with the geometry. Returns the scale factor."""
    parts = game_parts()
    lo, hi = bounds(parts)
    k = height / (hi.z - lo.z)
    dz = (lowest - hover_root) / k - lo.z
    for o in parts:
        o.location.z += dz
        core.apply_transform(o)
        o.scale = (k, k, k)
        core.apply_transform(o)
        if "rbx_pivot" in o.keys():
            pv = list(o["rbx_pivot"])
            o["rbx_pivot"] = (pv[0] * k, pv[1] * k, (pv[2] + dz) * k)
    return k


def keep_near(centre_parts, outer_part, inner: float = 0.5, fall: float = 2.0, reach: float = 0.6):
    """Decimation weight (for BAKE "keep"): 1 within `inner` of the centre of the named parts (e.g. the eyes),
    fading to 0 by fall; distances are relative to reach x the outer part's width (e.g. the head). Use it so the
    face keeps its triangles when the mesh is cut to budget."""
    cache = {}

    def keep(p):
        if not cache:
            outer = bpy.data.objects[outer_part]
            olo, ohi = bounds([outer])
            objs = [bpy.data.objects[n] for n in centre_parts if n in bpy.data.objects] or [outer]
            c = bounds(objs)
            cache["c"] = (c[0] + c[1]) / 2
            cache["r"] = reach * (ohi.x - olo.x)
        d = (p - cache["c"]).length / cache["r"]
        return 1.0 if d < inner else max(0.0, 1.0 - (d - inner) * fall)

    return keep


def tri_report(parts=None) -> dict:
    return {o.name: core.tri_count(o) for o in (parts or game_parts())}

