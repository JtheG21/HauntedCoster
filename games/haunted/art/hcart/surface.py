"""Reusable surface painting for Haunted Collector art: noise, cloth (sacking) and weathered metal.

Painters are fn(p, n, obj, cavity, openness) -> sRGB, applied by vertex_paint() as face-corner colours that the
production bake turns into texture maps. p is the world position, n the face normal, cavity > 0 on convex edges
and < 0 in creases, openness 1 in the open and 0 in occluded corners (ambient occlusion).

Moved out of assets/wisp.py (2026-10-16, chore/creature-pipeline) so every creature and prop can share them; the
math is unchanged, so earlier assets build identically.
"""

from __future__ import annotations

import math

from mathutils import Vector, noise
from mathutils.kdtree import KDTree

from hcart import paint

H = paint.hex3

# The sacking palette the Wisp was tuned with. Pass another dict with the same keys for a different cloth.
SACKING = {
    "stain": H("6d675a"),
    "dark_teal": H("15292a"),
    "fleck": H("33403f"),
    "shadow": H("2e3d3e"),
    "crevice": H("141a1b"),
    "seam": H("0d1112"),
}

# Weathered iron and copper (the Wisp lantern).
WEATHER = {
    "iron": H("23272a"),
    "iron_dk": H("111416"),
    "rust": H("6e3318"),
    "rust_hi": H("9a5228"),
    "rust_run": H("4a2614"),
    "verdigris": H("4a6f66"),
    "verdigris_hi": H("3f7a70"),
    "copper": H("9a6a45"),
    "copper_hi": H("c58a5a"),
}


def fbm(p, scale, octaves=3, off=0.0):
    acc, amp, tot = 0.0, 1.0, 0.0
    for i in range(octaves):
        acc += noise.noise(p / (scale * 0.5 ** i) + Vector((off + i * 7.1, off * 0.7 + i * 3.3, off * 1.3 + i * 5.9))) * amp
        tot += amp
        amp *= 0.5
    return acc / tot


def ridged(p, scale, off=0.0):
    """Crumpled-cloth creases: sharp valleys along the zero set of noise."""
    return 1.0 - abs(noise.noise(p / scale + Vector((off, off * 0.3, off * 0.7)))) * 2.0


class SeamIndex:
    """Nearest-seam lookup (distance and arc position) over sampled seam polylines."""

    def __init__(self, surfs, extra=()):
        pts, arcs = [], []
        for surf in surfs:
            acc = 0.0
            for i, (p, _) in enumerate(surf):
                if i:
                    acc += (p - surf[i - 1][0]).length
                pts.append(p.copy())
                arcs.append(acc)
        for p in extra:
            pts.append(Vector(p))
            arcs.append(0.0)
        self.arcs = arcs
        self.kd = KDTree(max(1, len(pts)))
        for i, p in enumerate(pts):
            self.kd.insert(p, i)
        self.kd.balance()
        self.empty = not pts

    def find(self, p):
        if self.empty:
            return 9.0, 0.0
        _, i, d = self.kd.find(p)
        return d, self.arcs[i]


def vertex_paint(objs, fn, ao_samples=16, ao_distance=0.6):
    """Face-corner colours from fn(p, n, obj, cavity, openness) (sRGB 0..1), with shared ambient occlusion."""
    occ = paint.occlusion(objs, ao_samples, ao_distance, None)
    for o in objs:
        me = o.data
        if "Col" in me.color_attributes:
            me.color_attributes.remove(me.color_attributes["Col"])
        attr = me.color_attributes.new("Col", "BYTE_COLOR", "CORNER")
        cav = paint.cavity(o)
        mw = o.matrix_world
        nm = mw.to_3x3().inverted().transposed()
        openness = occ[o.name]
        cache = {}
        for poly in me.polygons:
            fnrm = (nm @ poly.normal).normalized()
            for li in poly.loop_indices:
                vi = me.loops[li].vertex_index
                c = cache.get(vi)
                if c is None:
                    p = mw @ me.vertices[vi].co
                    c = fn(p, fnrm, o, cav[vi], openness[vi])
                    cache[vi] = c
                attr.data[li].color_srgb = (max(0, min(1, c[0])), max(0, min(1, c[1])), max(0, min(1, c[2])), 1.0)


def burlap(p, n, cv, op, base, seams: SeamIndex | None, seed, pal=SACKING):
    """Coarse sacking: blotchy dye and stains, fibre speckle and a weave hint, cold shadows, dark sunk seams."""
    g = fbm(p, 0.22, 3, seed)
    c = paint.mul(base, 1.0 + 0.32 * g)  # blotchy dye within the panel
    c = paint.mix(c, paint.mul(base, 1.3), max(0.0, -g - 0.25) * 0.8)
    st = fbm(p, 0.14, 2, seed + 9.0)
    if st > 0.12:
        c = paint.mix(c, pal["stain"], min(0.6, (st - 0.12) * 1.8))
    tb = fbm(p, 0.18, 2, seed + 17.0)
    if tb > 0.08:
        c = paint.mix(c, pal["dark_teal"], min(0.3, (tb - 0.08) * 1.0))  # teal-black blotches soaked into the sacking
    smudge = fbm(p, 0.07, 2, seed + 4.0)
    if smudge > 0.1:
        c = paint.mix(c, paint.mul(base, 0.5), min(0.6, (smudge - 0.1) * 1.8))  # grimy smudges
    if noise.noise(p / 0.05 + Vector((seed, 0, 5.0))) > 0.5:
        c = paint.mul(c, 0.9)  # coarse dark speckle
    fib = noise.noise(p / 0.011 + Vector((seed, 1.7, 0)))
    weave = math.sin((p.x + p.y * 0.6) * math.tau / 0.045) * math.sin((p.z - p.y * 0.4) * math.tau / 0.045)
    k = 1.0 + 0.035 * fib + 0.015 * weave
    if noise.noise(p / 0.04 + Vector((0, seed, 3.1))) > 0.62:
        c = paint.mix(c, pal["fleck"], 0.2)  # dark fibre flecks
    occl = 1 - op
    c = paint.mix(c, pal["shadow"], min(1.0, occl * 1.1))
    c = paint.mix(c, pal["crevice"], max(0.0, occl - 0.25) * 1.5)
    if cv < 0:
        c = paint.mix(c, pal["crevice"], min(0.75, -cv * 1.0))
    else:
        c = paint.mix(c, paint.mul(base, 1.35), min(0.35, cv * 0.5))
    if seams is not None:
        d, _ = seams.find(p)
        if d < 0.045:
            c = paint.mix(c, pal["crevice"], 0.55 * (1 - d / 0.045) ** 2)
        if d < 0.012:
            c = paint.mix(c, pal["seam"], 0.75 * (1 - d / 0.012))  # the seam line itself
    return paint.mul(c, k)


def relief_stitches(c, rl, thread, crevice, ridge=0.35, sink=-0.4):
    """Thread colour on raised stitch ridges and a dark line in the sunk seam beside them, from a relief value
    (sourced.Relief: +1 = a full stitch above the surface)."""
    if rl > ridge:
        return paint.mix(c, thread, min(0.85, (rl - ridge) * 1.5))
    if rl < sink:
        return paint.mix(c, crevice, min(0.6, (-rl + sink)))
    return c


def weathered_iron(base, p, n, cv, op, pal=WEATHER):
    """Weathering over a metal colour: blotchy dark iron, rust patches and runs, teal patina in the recesses,
    bright worn copper on the edges and fine pitting."""
    blot = fbm(p, 0.35, 3, 51.0)
    base = paint.mix(base, pal["iron"], 0.45)  # blue-grey iron under the bronze
    base = paint.mix(base, pal["iron_dk"], max(0.0, min(0.8, (blot + 0.05) * 2.2)))
    rust = fbm(p, 0.13, 3, 57.0) + 0.3 * noise.noise(p / 0.025)
    if rust > 0.18:
        base = paint.mix(base, paint.mix(pal["rust"], pal["rust_hi"], 0.5 + 0.5 * noise.noise(p / 0.015)), min(0.65, (rust - 0.18) * 2.6))
    run = noise.noise(Vector((p.x * 30, p.y * 30, p.z * 2.5)))
    if run > 0.35 and abs(n.z) < 0.5:
        base = paint.mix(base, pal["rust_run"], min(0.5, (run - 0.35) * 2.0))
    if op < 0.75:
        base = paint.mix(base, paint.mix(pal["verdigris"], pal["verdigris_hi"], 0.5), min(0.8, (0.8 - op) * 2.2))
    if cv > 0.35:
        base = paint.mix(base, paint.mix(pal["copper"], pal["copper_hi"], 0.4), min(0.8, (cv - 0.35) * 2.5))
    if noise.noise(p / 0.004) > 0.4:
        base = paint.mul(base, 0.6)  # pitting
    return base
