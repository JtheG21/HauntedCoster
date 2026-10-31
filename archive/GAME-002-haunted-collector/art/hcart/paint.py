"""Vertex painting: base colours by region, ambient occlusion, cavity/edge wear, height gradients and noise.

The stylized look is painted into face-corner colours ("Col", sRGB bytes), which Roblox multiplies with the
MeshPart material texture. Paint after all geometry for an asset exists so occlusion sees every part.
"""

from __future__ import annotations

import math
import random
from typing import Callable, Sequence

import bpy
from mathutils import Color, Vector, noise
from mathutils.bvhtree import BVHTree

ColorFn = Callable[[Vector, Vector, bpy.types.Object], Sequence[float]]


def hex3(h: str) -> tuple[float, float, float]:
    h = h.lstrip("#")
    return (int(h[0:2], 16) / 255, int(h[2:4], 16) / 255, int(h[4:6], 16) / 255)


def mix(a, b, t: float):
    return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))


def mul(a, k):
    if isinstance(k, (int, float)):
        return tuple(v * k for v in a)
    return tuple(a[i] * k[i] for i in range(3))


def shift(c, hue: float = 0.0, sat: float = 1.0, val: float = 1.0):
    col = Color(c)
    h, s, v = col.hsv
    col.hsv = ((h + hue) % 1.0, max(0, min(1, s * sat)), max(0, min(1, v * val)))
    return (col.r, col.g, col.b)


def _bvh(objs: Sequence[bpy.types.Object], ground: float | None) -> BVHTree:
    verts, polys = [], []
    for o in objs:
        base = len(verts)
        mw = o.matrix_world
        verts.extend(mw @ v.co for v in o.data.vertices)
        polys.extend([base + i for i in p.vertices] for p in o.data.polygons)
    if ground is not None:
        base = len(verts)
        s = 400
        verts.extend([Vector((-s, -s, ground)), Vector((s, -s, ground)), Vector((s, s, ground)), Vector((-s, s, ground))])
        polys.append([base, base + 1, base + 2, base + 3])
    return BVHTree.FromPolygons(verts, polys)


def _hemisphere(n: int, seed: int) -> list[Vector]:
    rng = random.Random(seed)
    dirs = []
    for i in range(n):
        u, v = (i + rng.random()) / n, rng.random()
        r = math.sqrt(u)
        a = math.tau * v
        dirs.append(Vector((r * math.cos(a), r * math.sin(a), math.sqrt(max(0.0, 1 - u)))))
    return dirs


def occlusion(objs: Sequence[bpy.types.Object], samples: int = 24, distance: float = 2.0, ground: float | None = 0.0) -> dict:
    """Per-object list of per-vertex openness (1 = fully open, 0 = fully occluded)."""
    tree = _bvh(objs, ground)
    hemi = _hemisphere(samples, 7)
    out = {}
    for o in objs:
        mw = o.matrix_world
        nm = mw.to_3x3().inverted().transposed()
        vals = []
        for v in o.data.vertices:
            p = mw @ v.co
            n = (nm @ v.normal).normalized()
            t = n.orthogonal().normalized()
            b = n.cross(t)
            hit = 0.0
            origin = p + n * 0.02
            for d in hemi:
                w = t * d.x + b * d.y + n * d.z
                loc, _, _, dist = tree.ray_cast(origin, w, distance)
                if loc is not None:
                    hit += 1.0 - (dist / distance) * 0.5
            vals.append(1.0 - hit / samples)
        out[o.name] = vals
    return out


def cavity(obj: bpy.types.Object) -> list[float]:
    """Per-vertex convexity in [-1, 1]: positive = convex edge, negative = crease."""
    me = obj.data
    nbrs = [[] for _ in me.vertices]
    for e in me.edges:
        a, b = e.vertices
        nbrs[a].append(b)
        nbrs[b].append(a)
    out = []
    for v in me.vertices:
        if not nbrs[v.index]:
            out.append(0.0)
            continue
        acc = 0.0
        for j in nbrs[v.index]:
            d = me.vertices[j].co - v.co
            if d.length > 1e-6:
                acc += d.normalized().dot(v.normal)
        out.append(max(-1.0, min(1.0, -acc / len(nbrs[v.index]) * 3)))
    return out


def paint(objs: Sequence[bpy.types.Object], color: ColorFn | None = None, ao: float = 0.55, ao_distance: float = 2.0,
          ao_samples: int = 24, ground: float | None = 0.0, edge: float = 0.18, crease: float = 0.25,
          gradient: tuple[float, float, float] | None = None, mottle: float = 0.06, mottle_scale: float = 1.5,
          seed: int = 0) -> None:
    """Writes the final "Col" attribute. `color(face_centre, face_normal, obj)` gives the base sRGB colour;
    without it the object's `base_color` property is used. `gradient` = (z_low, z_high, dark_factor_at_low)."""
    objs = [o for o in objs if o.type == "MESH"]
    occ = occlusion(objs, ao_samples, ao_distance, ground) if ao > 0 else {}
    off = Vector((seed * 3.7, seed * 1.9, seed * 5.3))
    for o in objs:
        me = o.data
        if "Col" in me.color_attributes:
            me.color_attributes.remove(me.color_attributes["Col"])
        attr = me.color_attributes.new("Col", "BYTE_COLOR", "CORNER")
        cav = cavity(o) if (edge or crease) else None
        mw = o.matrix_world
        nm = mw.to_3x3().inverted().transposed()
        base_prop = tuple(o["base_color"]) if "base_color" in o.keys() else (0.8, 0.8, 0.8)
        openness = occ.get(o.name)
        for poly in me.polygons:
            fc = mw @ poly.center
            fn = (nm @ poly.normal).normalized()
            base = tuple(color(fc, fn, o)) if color else base_prop
            for li in poly.loop_indices:
                vi = me.loops[li].vertex_index
                p = mw @ me.vertices[vi].co
                k = 1.0
                if openness is not None:
                    k *= 1.0 - ao * (1.0 - openness[vi])
                if gradient is not None:
                    z0, z1, dark = gradient
                    t = max(0.0, min(1.0, (p.z - z0) / max(1e-4, z1 - z0)))
                    k *= dark + (1 - dark) * t
                c = base
                if cav is not None:
                    cv = cav[vi]
                    if cv > 0:
                        c = mix(c, (1, 1, 1), edge * cv * 0.6)
                    else:
                        k *= 1.0 + crease * cv
                if mottle:
                    k *= 1.0 + mottle * noise.noise(p / mottle_scale + off)
                attr.data[li].color_srgb = (min(1, c[0] * k), min(1, c[1] * k), min(1, c[2] * k), 1.0)


def solid(objs: Sequence[bpy.types.Object], rgb: Sequence[float]) -> None:
    """Flat colour with no shading (emissive parts: eyes, flames, glass)."""
    for o in objs:
        me = o.data
        if "Col" in me.color_attributes:
            me.color_attributes.remove(me.color_attributes["Col"])
        attr = me.color_attributes.new("Col", "BYTE_COLOR", "CORNER")
        for d in attr.data:
            d.color_srgb = (rgb[0], rgb[1], rgb[2], 1.0)


def gradient_solid(obj: bpy.types.Object, low, high, z0: float, z1: float) -> None:
    me = obj.data
    if "Col" in me.color_attributes:
        me.color_attributes.remove(me.color_attributes["Col"])
    attr = me.color_attributes.new("Col", "BYTE_COLOR", "CORNER")
    mw = obj.matrix_world
    for li, loop in enumerate(me.loops):
        p = mw @ me.vertices[loop.vertex_index].co
        t = max(0.0, min(1.0, (p.z - z0) / max(1e-4, z1 - z0)))
        c = mix(low, high, t)
        attr.data[li].color_srgb = (c[0], c[1], c[2], 1.0)
