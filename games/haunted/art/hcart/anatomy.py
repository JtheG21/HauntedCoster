"""Creature helpers: metaball ellipsoids, tapered limbs, surface-projected stitches, horns, teeth and eyes."""

from __future__ import annotations

import math
import random
from typing import Sequence

import bmesh
import bpy
from mathutils import Matrix, Vector
from mathutils.bvhtree import BVHTree

from . import core, shapes


def ell(co, size, rot=(0, 0, 0), radius=1.0, stiffness=2.0, negative=False) -> dict:
    return {"type": "ELLIPSOID", "co": co, "size": size, "rot": rot, "radius": radius, "stiffness": stiffness, "negative": negative}


def ball(co, radius, stiffness=2.0, negative=False) -> dict:
    return {"type": "BALL", "co": co, "radius": radius, "stiffness": stiffness, "negative": negative}


def cap(co, length, radius, rot=(0, 0, 0), stiffness=2.0) -> dict:
    return {"type": "CAPSULE", "co": co, "size": (length, 1, 1), "rot": rot, "radius": radius, "stiffness": stiffness}


def organic(name: str, elements: Sequence[dict], max_tris: int, resolution: float = 0.07, material: str = "Fabric",
            smooth_iters: int = 2, **props) -> bpy.types.Object:
    """Metaball union -> smoothed, decimated mesh (smooth form transitions without boxy joins)."""
    obj = shapes.blob(name, elements, resolution=resolution, material=material, **props)
    if smooth_iters:
        core.add_modifier(obj, "SMOOTH", factor=0.5, iterations=smooth_iters)
        core.apply_modifiers(obj)
    core.decimate_to(obj, max_tris)
    core.smooth(obj, 180)
    return obj


def limb(name: str, points, radii, segments: int = 8, material: str = "Fabric", resample: int = 3, flatten: float = 1.0,
         **props) -> bpy.types.Object:
    obj = shapes.tube(name, points, radii, segments, material, resample=resample, flatten=flatten, **props)
    core.smooth(obj, 180)
    return obj


def surface_bvh(objs: Sequence[bpy.types.Object]) -> BVHTree:
    verts, polys = [], []
    for o in objs:
        base = len(verts)
        verts.extend(o.matrix_world @ v.co for v in o.data.vertices)
        polys.extend([base + i for i in p.vertices] for p in o.data.polygons)
    return BVHTree.FromPolygons(verts, polys)


def project(tree: BVHTree, point: Vector, toward: Vector) -> tuple[Vector, Vector] | None:
    """Casts from `point` along `toward` (outside -> inside) and returns (surface point, normal)."""
    d = toward.normalized()
    loc, nrm, _, _ = tree.ray_cast(point, d, 20.0)
    if loc is None:
        return None
    return loc, nrm


def stitches(name: str, tree: BVHTree, path: Sequence[Sequence[float]], inward: Sequence[float] | None, count: int,
             length: float = 0.28, radius: float = 0.035, lift: float = 0.02, material: str = "Fabric", seed: int = 0,
             centre: Sequence[float] | None = None, **props) -> bpy.types.Object | None:
    """Short cross-stitches laid across a seam. `path` is a rough polyline outside the body; each sample is
    projected onto the surface along `inward` (or toward `centre`), and a stitch is laid across the seam."""
    pts = [Vector(p) for p in path]
    lens = [0.0]
    for i in range(1, len(pts)):
        lens.append(lens[-1] + (pts[i] - pts[i - 1]).length)
    total = lens[-1]
    rng = random.Random(seed)
    parts = []
    for k in range(count):
        s = (k + 0.5) / count * total
        i = max(1, next((j for j in range(1, len(lens)) if lens[j] >= s), len(lens) - 1))
        t = (s - lens[i - 1]) / max(1e-6, lens[i] - lens[i - 1])
        p = pts[i - 1].lerp(pts[i], t)
        tangent = (pts[i] - pts[i - 1]).normalized()
        d = Vector(inward) if inward is not None else (Vector(centre) - p)
        hit = project(tree, p, d)
        if not hit:
            continue
        loc, nrm = hit
        across = nrm.cross(tangent).normalized()
        jitter = (rng.random() - 0.5) * 0.25
        a = loc + nrm * lift - across * length * (0.5 + jitter * 0.3)
        b = loc + nrm * lift + across * length * (0.5 - jitter * 0.3)
        mid = (a + b) / 2 + nrm * radius * 1.2
        parts.append(shapes.tube(f"{name}_{k}", [a, mid, b], radius, 4, material, resample=0))
    if not parts:
        return None
    obj = core.join(parts, name)
    core.tag(obj, material, **props)
    return obj


def cone(name: str, base, tip, r0: float, segments: int = 6, material: str = "SmoothPlastic", curve=None, **props):
    base, tip = Vector(base), Vector(tip)
    pts = [base.lerp(tip, t) + (Vector(curve) * math.sin(t * math.pi * 0.5) if curve else Vector()) for t in (0, 0.35, 0.7, 1.0)]
    return shapes.tube(name, pts, lambda t: r0 * (1 - t) + 0.004, segments, material, cap_end=False, resample=2, **props)


def teeth_row(name: str, centre, width: float, count: int, length: float, down: bool = True, depth_curve: float = 0.15,
              r0: float = 0.05, forward: Vector | None = None, material: str = "SmoothPlastic", seed: int = 1, **props):
    rng = random.Random(seed)
    c = Vector(centre)
    parts = []
    for i in range(count):
        t = i / max(1, count - 1) * 2 - 1
        x = t * width / 2
        y = abs(t) ** 2 * depth_curve
        base = c + Vector((x, y, 0))
        l = length * (0.7 + 0.5 * rng.random()) * (1.25 if abs(t) > 0.6 else 1.0)
        tip = base + Vector((0, 0, -l if down else l))
        parts.append(cone(f"{name}{i}", base, tip, r0 * (1.2 if abs(t) > 0.6 else 1.0), 5, material))
    obj = core.join(parts, name)
    core.tag(obj, material, **props)
    return obj
