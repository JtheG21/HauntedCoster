"""Trees, rocks and logs (TASK-0044).

References: MODEL-MIN-010 (expressive tree: face integrated into bark, tapered roots), MIN-054-056 (taper,
branching hierarchy, root spread), MIN-066/067 (stylized nature pack: twisted limbs, stumps, logs, rocks).
Rejected: MODEL-BAD-001-005 (cylinder trunks, abrupt joins, rectangular pasted faces).

Haunted trees keep TASK-0041's face layout (server/World/HauntedTree.luau SPECS): eyes sit on the trunk surface at
radius r, so the trunk is shaped to exactly r across the face band, with sockets, brow, cheeks, nose and mouth
cavity carved into the bark. The animated lids and jaw are separate small meshes (tree_lid, tree_jaw).
Blender front is -Y = the face direction.
"""

import math
import random

from mathutils import Vector, noise

from hcart import core, paint, shapes
from hcart import palette as P

BARK = paint.hex3("4f3e33")
BARK_LIGHT = paint.hex3("7a6352")
BARK_GREY = paint.hex3("5d5a52")
SOCKET = paint.hex3("120d0b")
PINE = paint.hex3("2f4a3c")
PINE_TIP = paint.hex3("4c6b55")


def _bark_color(c, n, o):
    base = BARK if o.get("tone", "warm") == "warm" else BARK_GREY
    k = noise.noise(Vector((c.x * 0.6, c.y * 0.6, c.z * 2.2))) * 0.5 + 0.5
    col = paint.mix(base, BARK_LIGHT, 0.25 * k)
    if n.z > 0.6 and c.z < 2.0:
        col = paint.mix(col, P.MOSS, 0.45 * min(1.0, (n.z - 0.6) * 3))
    if c.z < 0.5:
        col = paint.mix(col, P.MOSS_DARK, 0.35 * (1 - max(0.0, c.z) / 0.5))
    return col


def gnarled(rng, parts, start, direction, length, r0, level, levels, spread=1.0, droop=0.25, n_branches=3, name="Wood"):
    """One tapered, wandering limb that recursively forks (appends tubes to `parts`)."""

    def limb(start, direction, length, r0, level, idx):
        pts = [start]
        d = direction.normalized()
        p = start.copy()
        steps = 5
        for i in range(steps):
            t = (i + 1) / steps
            jitter = Vector((rng.uniform(-1, 1), rng.uniform(-1, 1), rng.uniform(-0.4, 0.6))) * 0.25
            d = (d + jitter + Vector((0, 0, -droop * t * (level / max(1, levels))))).normalized()
            p = p + d * (length / steps)
            pts.append(p.copy())
        r1 = r0 * 0.12 + 0.02
        parts.append(shapes.tube(f"{name}{level}_{idx}_{len(parts)}", pts, lambda t: r0 + (r1 - r0) * t ** 0.8, 7 if level < 2 else 5,
                                 "Wood", cap_start=False, resample=2))
        if level < levels:
            kids = 2 if level > 0 else n_branches
            for k in range(kids):
                t = rng.uniform(0.45, 0.85)
                i = min(int(t * steps), steps - 1)
                base = pts[i].lerp(pts[i + 1], t * steps - i)
                ang = rng.uniform(0, math.tau)
                side = Vector((math.cos(ang), math.sin(ang), 0))
                nd = (d * 0.5 + side * spread + Vector((0, 0, rng.uniform(0.15, 0.7)))).normalized()
                limb(base, nd, length * rng.uniform(0.45, 0.65), (r0 + (r1 - r0) * t) * 0.62, level + 1, k)

    limb(start, direction, length, r0, level, 0)


def branch_tree(rng, height, trunk_r, levels=3, lean=0.15, spread=1.0, droop=0.25, n_branches=4, name="Wood"):
    """Recursive tapered limbs; returns a list of tube objects (joined later)."""
    parts = []

    def limb(start, direction, length, r0, level, idx):
        pts = [start]
        d = direction.normalized()
        p = start.copy()
        steps = 5
        for i in range(steps):
            t = (i + 1) / steps
            jitter = Vector((rng.uniform(-1, 1), rng.uniform(-1, 1), rng.uniform(-0.4, 0.6))) * 0.25
            d = (d + jitter + Vector((0, 0, -droop * t * (level / levels)))).normalized()
            p = p + d * (length / steps)
            pts.append(p.copy())
        r1 = r0 * 0.12 + 0.02
        parts.append(shapes.tube(f"{name}{level}_{idx}_{len(parts)}", pts, lambda t: r0 + (r1 - r0) * t ** 0.8, 7 if level < 2 else 5,
                                 "Wood", cap_start=False, resample=2))
        if level < levels:
            kids = 2 if level > 0 else n_branches
            for k in range(kids):
                t = rng.uniform(0.45, 0.85) if level > 0 else rng.uniform(0.4, 0.92)
                i = min(int(t * steps), steps - 1)
                base = pts[i].lerp(pts[i + 1], t * steps - i)
                ang = rng.uniform(0, math.tau)
                side = Vector((math.cos(ang), math.sin(ang), 0))
                nd = (d * 0.5 + side * spread + Vector((0, 0, rng.uniform(0.15, 0.7)))).normalized()
                limb(base, nd, length * rng.uniform(0.45, 0.65), (r0 + (r1 - r0) * t) * 0.62, level + 1, k)

    trunk_dir = Vector((rng.uniform(-lean, lean), rng.uniform(-lean, lean), 1))
    limb(Vector((0, 0, 0)), trunk_dir, height, trunk_r, 0, 0)
    return parts


def roots(rng, r_base, count, reach, name="Root"):
    parts = []
    for k in range(count):
        a = k / count * math.tau + rng.uniform(-0.3, 0.3)
        d = Vector((math.cos(a), math.sin(a), 0))
        length = reach * rng.uniform(0.8, 1.2)
        side = Vector((-d.y, d.x, 0)) * rng.uniform(-0.25, 0.25)
        pts = [d * r_base * 0.45 + Vector((0, 0, 1.25)), d * (r_base * 0.85) + Vector((0, 0, 0.85)),
               d * (r_base + length * 0.3) + side * 0.5 + Vector((0, 0, 0.42)), d * (r_base + length * 0.65) + side + Vector((0, 0, 0.14)),
               d * (r_base + length) + side * 1.2 + Vector((0, 0, -0.12))]
        parts.append(shapes.tube(f"{name}{k}", pts, lambda t: r_base * 0.5 * (1 - t) ** 1.3 + 0.05, 8, "Wood", resample=3,
                                 cap_start=False))
    return parts


def _finish_wood(objs, tone="warm", seed=1, ground=0.0, angle=70):
    wood = core.join(objs, "Wood")
    wood["tone"] = tone
    core.add_modifier(wood, "WELD", merge_threshold=0.002)
    core.apply_modifiers(wood)
    core.displace_noise(wood, 0.05, 0.35, seed)
    core.uv_box(wood, 3.0)
    core.smooth(wood, angle)
    paint.paint([wood], _bark_color, ao=0.6, ao_distance=1.6, ground=ground, edge=0.15, crease=0.4, mottle=0.1, mottle_scale=0.6,
                seed=seed)
    return wood


def dead_tree(seed):
    def make():
        rng = random.Random(seed)
        parts = branch_tree(rng, 9.5, 0.72, levels=3, lean=0.18, spread=1.1, droop=0.2, n_branches=4)
        flare = shapes.lathe("Flare", [(0.95, 0.0), (0.75, 0.35), (0.6, 0.9), (0.52, 1.8)], 10, "Wood", cap_bottom=False, wobble=0.12,
                             seed=seed)
        parts += [flare] + roots(rng, 0.7, 5, 1.8)
        _finish_wood(parts, "grey" if seed % 2 else "warm", seed)
        return {"Kind": "tree", "LodDistance": 90, "Height": 13}
    return make


def pine(seed):
    def make():
        rng = random.Random(seed)
        trunk = shapes.tube("Trunk", [(0, 0, -0.2), (0.1, 0, 6), (0.05, 0.08, 17.5)], lambda t: 0.75 * (1 - t) + 0.08, 9, "Wood",
                            resample=2, cap_start=False)
        parts = [trunk] + roots(rng, 0.8, 4, 1.4)
        wood = _finish_wood(parts, "warm", seed)
        tiers = []
        h0 = 4.5
        for i in range(6):
            t = i / 5
            r = 4.2 * (1 - t * 0.78)
            z = h0 + i * 2.25
            ring = []
            segs = 14
            prof = [(0.25, z + 2.9), (r * 0.45, z + 1.9), (r, z + 0.2), (r * 0.82, z - 0.15)]
            tier = shapes.lathe(f"Tier{i}", prof, segs, "SmoothPlastic", cap_top=True, cap_bottom=True)
            # Spiky drooping hem: alternate rim vertices pulled down and out.
            for v in tier.data.vertices:
                a = math.atan2(v.co.y, v.co.x)
                rr = math.hypot(v.co.x, v.co.y)
                if rr > r * 0.7:
                    spike = max(0.0, math.cos(a * segs / 2 + i))
                    v.co.z -= 0.55 * spike + 0.1 * rng.random()
                    v.co.x *= 1 + 0.12 * spike
                    v.co.y *= 1 + 0.12 * spike
            tier.rotation_euler = (math.radians(rng.uniform(-4, 4)), math.radians(rng.uniform(-4, 4)), rng.uniform(0, math.tau))
            core.apply_transform(tier)
            tiers.append(tier)
        needles = core.join(tiers, "Needles")
        core.tag(needles, "SmoothPlastic", part="Needles")
        core.smooth(needles, 25)
        paint.paint([needles], lambda c, n, o: paint.mix(PINE, PINE_TIP, max(0.0, min(1.0, n.z * 0.8 + 0.2))), ao=0.7, ao_distance=2.0,
                    ground=0.0, edge=0.25, crease=0.4, mottle=0.12, mottle_scale=0.8, seed=seed)
        paint.paint([wood], _bark_color, ao=0.7, ao_distance=1.5, ground=0.0, edge=0.1, mottle=0.08)
        return {"Kind": "tree", "LodDistance": 100, "Height": 18}
    return make


# --------------------------------------------------------------------------------------------------------
# Haunted trees (TASK-0041 layout). Values mirror server/World/HauntedTree.luau SPECS.
SPECS = {
    "pillar": dict(r=1.6, h=8.0, eyeY=4.4, eyeSep=0.62, eyeR=0.3, mouthY=3.15, mouthW=1.2, faceted=False, lean=0, brow=0, teeth=False),
    "broad": dict(r=2.1, h=7.0, eyeY=4.2, eyeSep=0.82, eyeR=0.34, mouthY=2.85, mouthW=1.8, faceted=False, lean=0, brow=8, teeth=True),
    "angular": dict(r=1.25, h=9.0, eyeY=4.8, eyeSep=0.5, eyeR=0.26, mouthY=3.75, mouthW=0.85, faceted=True, lean=6, brow=16, teeth=False),
}


def _falloff(d, radius):
    if d >= radius:
        return 0.0
    x = 1 - (d / radius) ** 2
    return x * x


def haunted_trunk(kind, faced):
    def make():
        S = SPECS[kind]
        rng = random.Random({"pillar": 3, "broad": 5, "angular": 7}[kind] + (0 if faced else 11))
        r, h = S["r"], S["h"]
        lowY, highY = S["mouthY"] - 0.9, S["eyeY"] + 1.1
        # Dense rings across the face band, sparse elsewhere.
        zs = [0.0, 0.35, 0.8, 1.4]
        z = 1.4
        while z < lowY:
            z = min(lowY, z + 0.45)
            zs.append(z)
        while z < highY:
            z += 0.14
            zs.append(z)
        top = h
        while z < top:
            z = min(top, z + 0.5)
            zs.append(z)
        prof = []
        for z in zs:
            flare = 1 + 0.55 * math.exp(-z / 0.9)
            narrow = 1 - 0.4 * max(0.0, (z - highY) / max(0.1, top - highY)) ** 1.2
            prof.append((r * flare * narrow, z))
        prof.append((prof[-1][0] * 0.55, top - 0.25))
        prof.append((0.0, top - 0.9))  # a hollow, broken-off top
        segs = 20 if S["faceted"] else 44
        trunk = shapes.lathe("Trunk", prof, segs, "Wood", cap_bottom=False, cap_top=False)
        lean = math.radians(S["lean"])
        bend_from = highY + 0.6
        for v in trunk.data.vertices:
            if v.co.z > top - 1.0 and math.hypot(v.co.x, v.co.y) > 0.3:
                a = math.atan2(v.co.y, v.co.x)
                v.co.z += max(0.0, math.sin(a * 5 + 1.3)) * 1.1 + max(0.0, math.sin(a * 3 - 0.4)) * 0.6
            if v.co.z > bend_from:
                v.co.x += math.sin(lean) * (v.co.z - bend_from) * 0.9 + 0.12 * math.sin((v.co.z - bend_from) * 0.9)
        eye_l = Vector((-S["eyeSep"], -r, S["eyeY"]))
        eye_r = Vector((S["eyeSep"], -r, S["eyeY"]))
        mouth = Vector((0, -r, S["mouthY"] - 0.08))
        eR = S["eyeR"]
        tilt = math.radians(S["brow"])
        for v in trunk.data.vertices:
            p = v.co
            a = math.atan2(p.y, p.x)
            rr = math.hypot(p.x, p.y)
            front = max(0.0, -math.sin(a))  # 1 at -Y
            # Bark grooves everywhere except a smooth face band.
            face_w = front ** 2 * (1.0 if lowY - 0.4 < p.z < highY + 0.4 else 0.0) if faced else 0.0
            groove = 0.07 * math.sin(a * 9 + noise.noise(Vector((p.x, p.y, p.z * 0.4))) * 2.5) * (1 - face_w)
            rr *= 1 + groove
            if faced and lowY - 0.6 < p.z < highY + 0.6 and front > 0.2:
                band = min(1.0, (p.z - (lowY - 0.6)) / 0.6, ((highY + 0.6) - p.z) / 0.6)
                rr = rr + (r - rr) * band * min(1.0, front * 1.4)
            v.co.x = math.cos(a) * rr
            v.co.y = math.sin(a) * rr
        if faced:
            for v in trunk.data.vertices:
                p = v.co
                if p.y > -0.3:
                    continue
                inward = Vector((p.x, p.y, 0)).normalized()
                off = 0.0
                for e, side in ((eye_l, -1), (eye_r, 1)):
                    d = math.hypot(p.x - e.x, p.z - e.z)
                    off -= 0.42 * eR / 0.3 * _falloff(d, eR * 1.55)          # socket
                    off += 0.06 * _falloff(abs(d - eR * 1.5), 0.12)           # socket rim
                    by = e.z + eR + 0.28 + side * (p.x - e.x) * math.tan(tilt) * -1
                    off += 0.3 * _falloff(math.hypot((p.x - e.x * 0.8) * 0.75, p.z - by), eR * 1.9)  # brow
                    off += 0.12 * _falloff(math.hypot(p.x - e.x * 1.15, p.z - (e.z - eR * 2.1)), eR * 1.8)  # cheek
                nose_y = (S["eyeY"] + S["mouthY"]) / 2 + 0.1
                off += 0.16 * _falloff(math.hypot(p.x * 2.2, p.z - nose_y), 0.55)
                mx, mz = (p.x - mouth.x) / (S["mouthW"] * 0.5), (p.z - mouth.z) / 0.34
                md = math.hypot(mx, mz)
                off -= 0.32 * _falloff(md, 1.0)
                off += 0.05 * _falloff(abs(md - 1.05), 0.2)
                v.co += -inward * off
        parts = [trunk]
        crown_z = h * 0.62
        n_limbs = {"pillar": 3, "broad": 3, "angular": 5}[kind]
        for k in range(n_limbs):
            a = rng.uniform(0.2, math.pi - 0.2) + (0 if k % 2 else math.pi)  # sides and back, never across the face
            zz = crown_z + rng.uniform(-0.6, 1.8)
            d = Vector((math.cos(a), math.sin(a) * 0.6 + 0.35, 0)).normalized()
            L = {"pillar": 2.4, "broad": 4.2, "angular": 3.6}[kind] * rng.uniform(0.8, 1.2)
            rise = {"pillar": 0.6, "broad": 1.2, "angular": 2.2}[kind]
            zz = min(zz, h - 1.2)
            pts = [Vector((0, 0, zz)) + d * r * 0.5, Vector((0, 0, zz)) + d * (r + L * 0.4) + Vector((0, 0, rise * 0.4)),
                   Vector((0, 0, zz)) + d * (r + L) + Vector((rng.uniform(-0.4, 0.4), 0, rise))]
            lr = {"pillar": 0.42, "broad": 0.6, "angular": 0.26}[kind]
            gnarled(rng, parts, pts[0], (pts[1] - pts[0]), L, lr, 0, 2 if kind != "pillar" else 1, spread=0.8, droop=0.15,
                    n_branches=2, name=f"Limb{k}_")
        parts += roots(rng, r * 1.2, 6 if kind == "broad" else 5, r * 1.3)
        wood = _finish_wood(parts, "grey" if kind == "pillar" else "warm", seed=rng.randint(0, 99), angle=28 if S["faceted"] else 70)
        if faced:
            # Darken the carved sockets and mouth so they read as hollows in any light.
            me = wood.data
            col = me.color_attributes["Col"]
            mw = wood.matrix_world
            for li, loop in enumerate(me.loops):
                p = mw @ me.vertices[loop.vertex_index].co
                if p.y > -r * 0.4:
                    continue
                dark = 0.0
                for e in (eye_l, eye_r):
                    dark = max(dark, _falloff(math.hypot(p.x - e.x, p.z - e.z), eR * 1.35))
                mx, mz = (p.x - mouth.x) / (S["mouthW"] * 0.48), (p.z - mouth.z) / 0.3
                dark = max(dark, _falloff(math.hypot(mx, mz), 1.0))
                if dark > 0:
                    c = col.data[li].color_srgb
                    m = paint.mix((c[0], c[1], c[2]), SOCKET, min(1.0, dark * 1.6))
                    col.data[li].color_srgb = (m[0], m[1], m[2], 1)
            if S["teeth"]:
                teeth = []
                for i in range(5):
                    x = (i - 2) * S["mouthW"] * 0.18
                    base = Vector((x, -r + 0.16, S["mouthY"] + 0.12))
                    teeth.append(shapes.tube(f"Tooth{i}", [base, base + Vector((0, -0.04, -0.2 - 0.06 * (i % 2)))], lambda t: 0.08 * (1 - t) + 0.01,
                                             5, "Wood", cap_start=True))
                tj = core.join(teeth, "Teeth")
                core.tag(tj, "Wood", part="Wood", lod=False, detail=True)
                paint.paint([tj], lambda c, n, o: paint.hex3("8a7a5c"), ao=0.3, ground=None, edge=0.3)
        return {"Kind": "tree", "LodDistance": 80, "Archetype": kind, "Faced": faced, "Radius": r}
    return make


def tree_lid():
    """Bark eyelid: a curved shell nominally 0.75 wide (eyeR 0.3); the server scales it to its Lid part."""
    lid = shapes.sphere("Lid", 0.375, (0, 0, 0), (1, 0.42, 0.82), 16, 10, "Wood")
    for v in lid.data.vertices:
        if v.co.y > 0.02:
            v.co.y = 0.02 + (v.co.y - 0.02) * 0.2
    core.smooth(lid, 60)
    core.uv_box(lid, 1.0)
    paint.paint([lid], lambda c, n, o: paint.mix(BARK, BARK_LIGHT, 0.35 if c.z > 0 else 0.0), ao=0.2, ground=None, edge=0.3, mottle=0.1,
                mottle_scale=0.15)
    return {"Kind": "part", "Nominal": 0.75}


def tree_jaw():
    """Lower jaw slab nominally 1.4 wide (mouthW 1.2); bark outside, dark gum on top."""
    jaw = shapes.box("Jaw", (1.4, 0.32, 0.46), (0, 0, 0), bevel=0.12, segments=3)
    for v in jaw.data.vertices:
        v.co.y += 0.12 * (v.co.x / 0.7) ** 2  # curve back to follow the trunk
        v.co.z -= 0.06 * (v.co.x / 0.7) ** 2
    core.displace_noise(jaw, 0.02, 0.2, 4)
    core.smooth(jaw, 50)
    core.uv_box(jaw, 1.0)
    paint.paint([jaw], lambda c, n, o: SOCKET if n.z > 0.6 and c.y > -0.15 else paint.mix(BARK, BARK_LIGHT, 0.2), ao=0.3, ground=None,
                edge=0.3, mottle=0.1, mottle_scale=0.15)
    return {"Kind": "part", "Nominal": 1.4}


def boulder(seed):
    def make():
        import bmesh
        rng = random.Random(seed)
        bm = bmesh.new()
        bmesh.ops.create_icosphere(bm, subdivisions=4, radius=1.0)
        rock = core.obj_from_bmesh("Rock", bm, "Slate")
        sx, sy, sz = rng.uniform(1.1, 1.4), rng.uniform(0.85, 1.1), rng.uniform(0.55, 0.75)
        for v in rock.data.vertices:
            p = v.co
            d = 1 + 0.22 * noise.noise(p * 1.3 + Vector((seed, 0, 0))) + 0.08 * noise.noise(p * 4 + Vector((0, seed, 0)))
            v.co = Vector((p.x * sx * d, p.y * sy * d, p.z * sz * d))
            if v.co.z < -0.15:
                v.co.z = -0.15 + (v.co.z + 0.15) * 0.2
        for v in rock.data.vertices:
            v.co.z += 0.18
        core.transform(rock, scale=(2.2, 2.2, 2.2))
        core.smooth(rock, 38)
        core.uv_box(rock, 4.0, seed)

        def col(c, n, o):
            base = paint.mix(P.STONE, P.STONE_DARK, 0.4 + 0.3 * noise.noise(c * 0.8))
            if n.z > 0.5:
                base = paint.mix(base, P.MOSS, min(1.0, (n.z - 0.5) * 2.2))
            return base

        paint.paint([rock], col, ao=0.55, ao_distance=2.0, ground=0.0, edge=0.35, crease=0.4, mottle=0.1, mottle_scale=0.7, seed=seed)
        return {"Kind": "rock", "LodDistance": 90}
    return make


def fallen_log():
    rng = random.Random(9)
    pts = [(0, -6.2, 1.0), (0.2, -2.0, 1.05), (-0.1, 2.0, 0.98), (0.1, 6.0, 0.95)]
    log = shapes.tube("Log", pts, lambda t: 1.0 - 0.12 * t, 22, "Wood", resample=2, cap_start=False, cap_end=False)
    for v in log.data.vertices:
        a = math.atan2(v.co.z - 1.0, v.co.x)
        v.co.x *= 1 + 0.06 * math.sin(a * 9)
    ends = []
    for y, r in ((-6.2, 1.0), (6.0, 0.88)):
        ring = shapes.lathe("End", [(r * 0.98, -0.12), (r * 0.6, -0.02), (r * 0.15, -0.25), (0.0, -0.3)], 22, "Wood", cap_bottom=False)
        ring.rotation_euler = (math.radians(90 if y < 0 else -90), 0, 0)
        ring.location = (0, y, 1.0)
        core.apply_transform(ring)
        ends.append(ring)
    stubs = [shapes.tube(f"Stub{k}", [(0, y, 1.6), (s * 0.5, y + 0.3, 2.3)], lambda t: 0.25 * (1 - 0.7 * t), 6, "Wood", cap_start=False)
             for k, (y, s) in enumerate(((-2.5, 1), (2.8, -1)))]
    wood = _finish_wood([log] + ends + stubs, "warm", 9)
    me = wood.data
    col = me.color_attributes["Col"]
    for li, loop in enumerate(me.loops):
        p = me.vertices[loop.vertex_index].co
        if abs(p.y) > 5.6 and math.hypot(p.x, p.z - 1.0) < 0.7:
            col.data[li].color_srgb = (SOCKET[0], SOCKET[1], SOCKET[2], 1)
    return {"Kind": "prop", "LodDistance": 80, "Length": 12.2}


ASSETS = {
    "tree_dead_a": dead_tree(1), "tree_dead_b": dead_tree(2), "tree_dead_c": dead_tree(4),
    "tree_pine_a": pine(1), "tree_pine_b": pine(2),
    "tree_haunted_pillar": haunted_trunk("pillar", True), "tree_haunted_broad": haunted_trunk("broad", True),
    "tree_haunted_angular": haunted_trunk("angular", True),
    "tree_old_pillar": haunted_trunk("pillar", False), "tree_old_broad": haunted_trunk("broad", False),
    "tree_old_angular": haunted_trunk("angular", False),
    "tree_lid": tree_lid, "tree_jaw": tree_jaw,
    "rock_a": boulder(1), "rock_b": boulder(2), "rock_c": boulder(3),
    "log_fallen": fallen_log,
}
