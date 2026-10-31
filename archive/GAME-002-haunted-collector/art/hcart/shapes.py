"""Shape generators: lathes, swept tubes, rounded boxes, metaball blobs and skinned limb graphs."""

from __future__ import annotations

import math
import random
from typing import Callable, Sequence

import bmesh
import bpy
from mathutils import Matrix, Vector

from . import core


def lathe(name: str, profile: Sequence[tuple[float, float]], segments: int = 16, material: str = "SmoothPlastic",
          cap_bottom: bool = True, cap_top: bool = True, wobble: float = 0.0, seed: int = 0, **props) -> bpy.types.Object:
    """Revolves (radius, z) points around Z. Profile goes bottom to top."""
    rng = random.Random(seed)
    bm = bmesh.new()
    rings = []
    phase = [rng.random() * math.tau for _ in range(3)]
    for r, z in profile:
        ring = []
        for s in range(segments):
            a = math.tau * s / segments
            rr = r * (1 + wobble * (math.sin(a * 2 + phase[0]) * 0.5 + math.sin(a * 3 + phase[1]) * 0.35 + math.sin(z * 1.7 + phase[2]) * 0.3)) if wobble else r
            ring.append(bm.verts.new((math.cos(a) * rr, math.sin(a) * rr, z)))
        rings.append(ring)
    for i in range(len(rings) - 1):
        a, b = rings[i], rings[i + 1]
        for s in range(segments):
            bm.faces.new((a[s], a[(s + 1) % segments], b[(s + 1) % segments], b[s]))
    if cap_bottom and profile[0][0] > 1e-4:
        bm.faces.new(list(reversed(rings[0])))
    if cap_top and profile[-1][0] > 1e-4:
        bm.faces.new(rings[-1])
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return core.obj_from_bmesh(name, bm, material, **props)


def tube(name: str, points: Sequence[Sequence[float]], radii: Sequence[float] | Callable[[float], float], segments: int = 8,
         material: str = "SmoothPlastic", cap_start: bool = True, cap_end: bool = True, flatten: float = 1.0,
         wobble: float = 0.0, seed: int = 0, resample: int = 0, **props) -> bpy.types.Object:
    """Sweeps a circle along a polyline. `radii` is per point or a function of t in [0, 1]. `resample` > 0
    re-samples the path with a Catmull-Rom spline for smooth bends."""
    pts = [Vector(p) for p in points]
    if resample and len(pts) > 2:
        pts = catmull(pts, resample)
    n = len(pts)
    lens = [0.0]
    for i in range(1, n):
        lens.append(lens[-1] + (pts[i] - pts[i - 1]).length)
    total = lens[-1] or 1.0
    if isinstance(radii, (int, float)):
        rs = [float(radii)] * n
    elif callable(radii):
        rs = [radii(l / total) for l in lens]
    elif len(radii) == n:
        rs = list(radii)
    else:
        rs = [interp_list(radii, l / total) for l in lens]
    rng = random.Random(seed)
    frames = core.frame_along(pts)
    bm = bmesh.new()
    rings = []
    for i, (p, m) in enumerate(zip(pts, frames)):
        ring = []
        for s in range(segments):
            a = math.tau * s / segments
            w = 1 + (wobble * (rng.random() - 0.5) if wobble else 0)
            local = Vector((math.cos(a) * rs[i] * w, math.sin(a) * rs[i] * flatten * w, 0))
            ring.append(bm.verts.new(p + m @ local))
        rings.append(ring)
    for i in range(n - 1):
        a, b = rings[i], rings[i + 1]
        for s in range(segments):
            bm.faces.new((a[s], a[(s + 1) % segments], b[(s + 1) % segments], b[s]))
    if cap_start and rs[0] > 1e-4:
        c = bm.verts.new(pts[0] - (pts[1] - pts[0]).normalized() * rs[0] * 0.35)
        for s in range(segments):
            bm.faces.new((rings[0][(s + 1) % segments], rings[0][s], c))
    if cap_end and rs[-1] > 1e-4:
        c = bm.verts.new(pts[-1] + (pts[-1] - pts[-2]).normalized() * rs[-1] * 0.35)
        for s in range(segments):
            bm.faces.new((rings[-1][s], rings[-1][(s + 1) % segments], c))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return core.obj_from_bmesh(name, bm, material, **props)


def interp_list(vals: Sequence[float], t: float) -> float:
    if len(vals) == 1:
        return vals[0]
    x = t * (len(vals) - 1)
    i = min(int(x), len(vals) - 2)
    return vals[i] + (vals[i + 1] - vals[i]) * (x - i)


def catmull(pts: list[Vector], per_seg: int) -> list[Vector]:
    out = []
    ext = [pts[0] * 2 - pts[1]] + pts + [pts[-1] * 2 - pts[-2]]
    for i in range(1, len(ext) - 2):
        p0, p1, p2, p3 = ext[i - 1], ext[i], ext[i + 1], ext[i + 2]
        for k in range(per_seg):
            t = k / per_seg
            t2, t3 = t * t, t * t * t
            out.append(0.5 * ((2 * p1) + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (-p0 + 3 * p1 - 3 * p2 + p3) * t3))
    out.append(pts[-1].copy())
    return out


def box(name: str, size: Sequence[float], loc=(0, 0, 0), rot=(0, 0, 0), bevel: float = 0.0, segments: int = 2,
        material: str = "SmoothPlastic", subdiv: int = 0, **props) -> bpy.types.Object:
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    for v in bm.verts:
        v.co = Vector((v.co.x * size[0], v.co.y * size[1], v.co.z * size[2]))
    obj = core.obj_from_bmesh(name, bm, material, **props)
    if bevel > 0:
        core.add_modifier(obj, "BEVEL", width=bevel, segments=segments, limit_method="NONE")
    if subdiv:
        core.add_modifier(obj, "SUBSURF", levels=subdiv, render_levels=subdiv)
    core.apply_modifiers(obj)
    core.transform(obj, loc, rot)
    return obj


def cylinder(name: str, radius: float, depth: float, loc=(0, 0, 0), rot=(0, 0, 0), segments: int = 12,
             bevel: float = 0.0, material: str = "SmoothPlastic", radius_top: float | None = None, **props) -> bpy.types.Object:
    rt = radius if radius_top is None else radius_top
    obj = lathe(name, [(radius, -depth / 2), (rt, depth / 2)], segments, material, **props)
    if bevel > 0:
        core.bevel(obj, bevel, 2, 30)
    core.transform(obj, loc, rot)
    return obj


def sphere(name: str, radius: float, loc=(0, 0, 0), scale=(1, 1, 1), segments: int = 16, rings: int = 10,
           material: str = "SmoothPlastic", **props) -> bpy.types.Object:
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=segments, v_segments=rings, radius=radius)
    obj = core.obj_from_bmesh(name, bm, material, **props)
    obj.location = loc
    obj.scale = scale
    core.apply_transform(obj)
    return obj


def blob(name: str, elements: Sequence[dict], resolution: float = 0.12, threshold: float = 0.6,
         material: str = "SmoothPlastic", **props) -> bpy.types.Object:
    """Smooth union of metaball elements -> mesh. Element dict: type (BALL/CAPSULE/ELLIPSOID/CUBE), co,
    radius, size (x, y, z) for capsule/ellipsoid/cube, rot (deg xyz), stiffness, negative."""
    mb = bpy.data.metaballs.new(name + "_mb")
    mb.resolution = resolution
    mb.render_resolution = resolution
    mb.threshold = threshold
    for e in elements:
        el = mb.elements.new(type=e.get("type", "BALL"))
        el.co = e["co"]
        el.radius = e.get("radius", 1.0)
        el.stiffness = e.get("stiffness", 2.0)
        el.use_negative = e.get("negative", False)
        if "size" in e:
            el.size_x, el.size_y, el.size_z = e["size"]
        if "rot" in e:
            q = Vector(tuple(math.radians(a) for a in e["rot"]))
            from mathutils import Euler

            el.rotation = Euler(q).to_quaternion()
    mobj = core.link(bpy.data.objects.new(name + "_mbo", mb))
    bpy.context.view_layer.update()
    dg = bpy.context.evaluated_depsgraph_get()
    me = bpy.data.meshes.new_from_object(mobj.evaluated_get(dg))
    obj = core.link(bpy.data.objects.new(name, me))
    bpy.data.objects.remove(mobj)
    bpy.data.metaballs.remove(mb)
    bpy.context.view_layer.update()
    core.merge_close(obj, 1e-4)
    core.tag(obj, material, **props)
    return obj


def skin_graph(name: str, verts: Sequence[Sequence[float]], edges: Sequence[tuple[int, int]], radii: Sequence[float],
               subdiv: int = 2, material: str = "SmoothPlastic", root: int = 0, **props) -> bpy.types.Object:
    """Skin modifier over a vertex/edge graph (limbs, branches, creature torsos), then Catmull-Clark."""
    me = bpy.data.meshes.new(name)
    me.from_pydata([tuple(v) for v in verts], [tuple(e) for e in edges], [])
    obj = core.link(bpy.data.objects.new(name, me))
    core.add_modifier(obj, "SKIN", use_smooth_shade=True, branch_smoothing=0.6)
    sv = me.skin_vertices[0].data
    for i, r in enumerate(radii):
        if isinstance(r, (tuple, list)):
            sv[i].radius = (r[0], r[1])
        else:
            sv[i].radius = (r, r)
        sv[i].use_root = i == root
    if subdiv:
        core.add_modifier(obj, "SUBSURF", levels=subdiv, render_levels=subdiv)
    core.apply_modifiers(obj)
    core.tag(obj, material, **props)
    return obj


def bend_z(obj: bpy.types.Object, fn: Callable[[float], tuple[float, float]]) -> None:
    """Offsets each vertex in X/Y by fn(z) (gentle leans and curves on lathed shapes)."""
    for v in obj.data.vertices:
        dx, dy = fn(v.co.z)
        v.co.x += dx
        v.co.y += dy


def scale_by(obj: bpy.types.Object, fn: Callable[[Vector], tuple[float, float, float]]) -> None:
    for v in obj.data.vertices:
        s = fn(v.co.copy())
        v.co.x *= s[0]
        v.co.y *= s[1]
        v.co.z *= s[2]


def deform(obj: bpy.types.Object, fn: Callable[[Vector], Vector]) -> None:
    for v in obj.data.vertices:
        v.co = fn(v.co.copy())
