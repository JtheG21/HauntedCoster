"""Scene, mesh and modifier helpers for the Haunted Collector art generators (Blender 5.1, headless).

Conventions (05 Engineering/Blender Pipeline.md): 1 Blender unit = 1 stud, Z up, the asset's front faces -Y,
origin at the base centre. Every exported mesh object carries custom properties read by hcart.export:
  rbx_material   Roblox material name (SmoothPlastic, Wood, Slate, Fabric, Metal, Neon, Glass, ...)
  rbx_alpha      transparency 0..1 (optional)
  rbx_part       logical part name for animation/variants (optional, defaults to the object name)
  rbx_pivot      (x, y, z) joint pivot in asset space for animated parts (optional)
  rbx_lod        False to skip the LOD1 copy (small parts)
"""

from __future__ import annotations

import math
import random

import bmesh
import bpy
from mathutils import Matrix, Vector


def reset_scene() -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    sc.unit_settings.system = "NONE"
    sc.unit_settings.system_rotation = "DEGREES"


def link(obj: bpy.types.Object) -> bpy.types.Object:
    bpy.context.scene.collection.objects.link(obj)
    return obj


def obj_from_bmesh(name: str, bm: bmesh.types.BMesh, material: str = "SmoothPlastic", **props) -> bpy.types.Object:
    me = bpy.data.meshes.new(name)
    bm.normal_update()
    bm.to_mesh(me)
    bm.free()
    obj = link(bpy.data.objects.new(name, me))
    tag(obj, material, **props)
    return obj


def tag(obj: bpy.types.Object, material: str, alpha: float = 0.0, part: str | None = None, pivot=None, lod: bool = True, color=None,
        detail: bool = False) -> bpy.types.Object:
    obj["rbx_material"] = material
    obj["rbx_detail"] = bool(detail)
    obj["rbx_alpha"] = float(alpha)
    obj["rbx_part"] = part or obj.name
    obj["rbx_lod"] = bool(lod)
    if pivot is not None:
        obj["rbx_pivot"] = tuple(float(v) for v in pivot)
    if color is not None:
        obj["base_color"] = tuple(float(v) for v in color)
    return obj


def activate(obj: bpy.types.Object) -> None:
    bpy.context.view_layer.update()
    for o in bpy.context.view_layer.objects:
        if o is not None:
            o.select_set(False)
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)


def add_modifier(obj, kind: str, **settings):
    m = obj.modifiers.new(kind.lower(), kind)
    for k, v in settings.items():
        setattr(m, k, v)
    return m


def apply_modifiers(obj: bpy.types.Object) -> bpy.types.Object:
    activate(obj)
    for m in list(obj.modifiers):
        bpy.ops.object.modifier_apply(modifier=m.name)
    return obj


def apply_transform(obj: bpy.types.Object) -> None:
    activate(obj)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)


def smooth(obj: bpy.types.Object, angle: float = 40.0) -> bpy.types.Object:
    me = obj.data
    me.shade_smooth()
    if angle < 180:
        me.set_sharp_from_angle(angle=math.radians(angle))
    return obj


def flat(obj: bpy.types.Object) -> bpy.types.Object:
    obj.data.shade_flat()
    return obj


def join(objs: list[bpy.types.Object], name: str | None = None) -> bpy.types.Object:
    objs = [o for o in objs if o is not None]
    target = objs[0]
    props = {k: target[k] for k in target.keys()}
    for o in objs:
        apply_modifiers(o)
    for o in bpy.context.view_layer.objects:
        if o is not None:
            o.select_set(False)
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = target
    if len(objs) > 1:
        bpy.ops.object.join()
    for k, v in props.items():
        target[k] = v
    if name:
        target.name = name
        target.data.name = name
        target["rbx_part"] = name
    return target


def tri_count(obj: bpy.types.Object) -> int:
    dg = bpy.context.evaluated_depsgraph_get()
    me = obj.evaluated_get(dg).to_mesh()
    n = sum(len(p.vertices) - 2 for p in me.polygons)
    obj.evaluated_get(dg).to_mesh_clear()
    return n


def decimate_to(obj: bpy.types.Object, max_tris: int, keep=None, keep_factor: float = 1.0) -> bpy.types.Object:
    """keep: optional fn(world position) -> 0..1; weighted vertices cost more to collapse, so detail stays there."""
    n = tri_count(obj)
    if n > max_tris:
        m = add_modifier(obj, "DECIMATE", ratio=max(0.02, max_tris / n), use_collapse_triangulate=True)
        if keep:
            vg = obj.vertex_groups.new(name="DecimateKeep")
            mw = obj.matrix_world
            for v in obj.data.vertices:
                vg.add([v.index], 0.8 * max(0.0, min(1.0, keep(mw @ v.co))), "REPLACE")  # 1.0 locks a vertex
            m.vertex_group = vg.name
            m.vertex_group_factor = keep_factor
            m.invert_vertex_group = True  # Blender decimates where the group is weighted; invert so weight = keep
        apply_modifiers(obj)
        if keep:
            obj.vertex_groups.remove(obj.vertex_groups["DecimateKeep"])
    return obj


def merge_close(obj: bpy.types.Object, dist: float = 1e-4) -> None:
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=dist)
    bm.to_mesh(obj.data)
    bm.free()


def uv_box(obj: bpy.types.Object, studs_per_tile: float = 4.0, seed: int = 0) -> None:
    """Box-projected UVs in world units so Roblox material textures keep one density across assets."""
    me = obj.data
    if not me.uv_layers:
        me.uv_layers.new(name="UVMap")
    bm = bmesh.new()
    bm.from_mesh(me)
    uv = bm.loops.layers.uv.active
    rng = random.Random(seed)
    ox, oy = rng.random(), rng.random()
    mw = obj.matrix_world
    for f in bm.faces:
        n = f.normal
        ax = max(range(3), key=lambda i: abs(n[i]))
        for loop in f.loops:
            p = mw @ loop.vert.co
            if ax == 0:
                u, v = p.y, p.z
            elif ax == 1:
                u, v = p.x, p.z
            else:
                u, v = p.x, p.y
            loop[uv].uv = (u / studs_per_tile + ox, v / studs_per_tile + oy)
    bm.to_mesh(me)
    bm.free()


def displace_noise(obj: bpy.types.Object, strength: float, scale: float, seed: int = 0, axis_mask=(1, 1, 1)) -> None:
    """Moves vertices along their normals by 3D noise (organic irregularity)."""
    from mathutils import noise

    off = Vector((seed * 13.1, seed * 7.7, seed * 3.3))
    me = obj.data
    bm = bmesh.new()
    bm.from_mesh(me)
    bm.normal_update()
    for v in bm.verts:
        d = noise.noise(v.co / scale + off) * strength
        v.co += Vector((v.normal.x * axis_mask[0], v.normal.y * axis_mask[1], v.normal.z * axis_mask[2])) * d
    bm.to_mesh(me)
    bm.free()


def subdivide(obj: bpy.types.Object, levels: int = 1, simple: bool = False) -> None:
    add_modifier(obj, "SUBSURF", levels=levels, render_levels=levels, subdivision_type="SIMPLE" if simple else "CATMULL_CLARK")
    apply_modifiers(obj)


def bevel(obj: bpy.types.Object, width: float, segments: int = 2, angle: float = 40.0) -> None:
    add_modifier(obj, "BEVEL", width=width, segments=segments, limit_method="ANGLE", angle_limit=math.radians(angle))
    apply_modifiers(obj)


def transform(obj: bpy.types.Object, loc=(0, 0, 0), rot=(0, 0, 0), scale=(1, 1, 1)) -> bpy.types.Object:
    obj.location = loc
    obj.rotation_euler = tuple(math.radians(a) for a in rot)
    obj.scale = scale
    apply_transform(obj)
    return obj


def duplicate(obj: bpy.types.Object, name: str) -> bpy.types.Object:
    new = obj.copy()
    new.data = obj.data.copy()
    new.name = name
    link(new)
    return new


def mirror_x(obj: bpy.types.Object) -> bpy.types.Object:
    add_modifier(obj, "MIRROR", use_axis=(True, False, False), use_bisect_axis=(False, False, False), use_clip=False)
    apply_modifiers(obj)
    return obj


def frame_along(points: list[Vector]) -> list[Matrix]:
    """Parallel-transport frames along a polyline (no twisting), for tubes and sweeps."""
    frames = []
    t0 = (points[1] - points[0]).normalized()
    up = Vector((0, 0, 1)) if abs(t0.z) < 0.9 else Vector((1, 0, 0))
    n = t0.cross(up).normalized()
    for i, p in enumerate(points):
        if i == 0:
            t = t0
        elif i == len(points) - 1:
            t = (points[i] - points[i - 1]).normalized()
        else:
            t = (points[i + 1] - points[i - 1]).normalized()
        n = (n - t * n.dot(t)).normalized()
        b = t.cross(n).normalized()
        m = Matrix((n, b, t)).transposed()
        frames.append(m)
    return frames


def lerp(a, b, t):
    return a + (b - a) * t


def smoothstep(e0: float, e1: float, x: float) -> float:
    t = max(0.0, min(1.0, (x - e0) / (e1 - e0)))
    return t * t * (3 - 2 * t)
