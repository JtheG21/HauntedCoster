"""Lantern Wisp (TASK-0043 revision 1, 2026-10-14): the approved lantern-perch design.

Target: 02 Research/assets/wisp-pilot/wisp-approved-concept.png (RSH-20261014-Wisp-Approved-Modeling-Handoff).
A grimy burlap-sack doll sewn from mismatched panels. Its broad lumpy head sweeps back into a curled lobe of darker
sacking (part of the head, sewn on, not hair); its wide grin is a seam laced shut with thick twine, and its sunken
eyes are laced shut the same way. Varied hand stitching (cross, whip, ladder, running, twine) with knots, loose
ends and frayed fibres holds the panels together. It crouches on a riveted iron tray, both hands gripping a
diagonal spiked pole, the toes of both feet curled over the tray's front lip; a weathered Gothic lantern with cyan
panes hangs from the tray on a short chain, turned corner-on like the concept.

References: MODEL-MIN-042 (articulated limbs, finish held on the rear view), MODEL-MIN-022 (organic limb volume,
painted shading), MODEL-MIN-011/012 (focal face). Rejected: MODEL-BAD-015/016 (plain box lantern, glow hiding the
form) and the earlier cute teardrop Wisp.

Construction (rigid articulated assembly, no skinning): the body (one metaball sculpt for torso and limbs, swept
fingers and toes for exact contact) is one rigid mesh with the pole and tray, so the grips cannot drift while it
moves. Separate logical parts animate in client/Art/Creatures: Head + Face (neck pivot) and Lamp + LampGlow
(pendulum from the tray ring). Perch is the pole and tray. Seams are sunk into the cloth (pucker, hem ridge and
pinch folds) before the stitches are laid on the displaced surface.
Everything is designed in the coordinates below, then lifted by LIFT so the lantern clears the ground at hover 4.
"""

import math
import random

import bmesh
import bpy
from mathutils import Matrix, Vector, noise
from mathutils.kdtree import KDTree

from hcart import anatomy as A
from hcart import core, paint, shapes

H = paint.hex3
# Palette read from the concept: cold grey-green sacking, slate panels, blue-black crevices.
SKIN_HI = H("e6f8f3")
SKIN = H("bcdcd4")
SKIN_MID = H("86a7a0")
SKIN_BONE = H("a4a896")  # a dirtier, yellower sack panel
PATCH = H("5f706b")
PATCH_DK = H("33403f")
CREVICE = H("141a1b")
SHADOW = H("2e3d3e")
STAIN = H("6d675a")
DARK = H("141617")  # the dark sack panel over the back of the head and its curl
DARK_HI = H("2f3a3b")
DARK_TEAL = H("15292a")
TWINE = H("d3cbb2")
TWINE_DK = H("7d7259")
EYE = H("b3c4bd")
EYE_DK = H("6f817c")
LIP = H("0e0f11")
THREADS = {"black": H("1c1a19"), "brown": H("3b2a1e"), "rust": H("5e3321"), "bone": H("a89e82"), "twine": TWINE}
IRON = H("1d1d1f")
IRON_MID = H("323031")
BRONZE = H("4f3d2e")
COPPER = H("9a6a45")
RUST = H("6b3e22")
VERDIGRIS = H("4a6f66")
PANE_CORE = H("9adad6")
PANE_MID = H("4f9fa2")
PANE_EDGE = H("1d4a4f")

# Metaball sizes are half-extents in studs: a Blender element's surface sits at ~0.574 x its radius/size
# (threshold 0.6, stiffness 2; capsule size_x is the half segment length; measured 2026-10-14).
MB = 1 / 0.574
LIFT = 1.1
ASSET_SCALE = 0.85  # whole perch scaled uniformly about the Root after the lift (6.1 studs tall, lantern 0.85 off the ground)
HEAD_SCALE = 1.05  # head sculpted at design size, then scaled about the chin socket to the concept proportion
HEAD_TURN = (10.0, -8.0, 12.0)  # pitch forward, cock, turn to its left (degrees): the approved pose

# Pole: a line through both grips. G2 = lower (left) hand; D = direction per stud of drop.
G2 = Vector((-0.42, -0.72, -0.35))
D = Vector((0.95, 0.2, -1.0))
POLE_R = 0.1
TOP_Z, BOT_Z = 1.85, -4.1


def pole_at(z: float) -> Vector:
    return G2 + D * (G2.z - z)


G1 = pole_at(0.85)  # upper (right) hand
TRAY_Z = -2.110  # tray floor top
LIP_TOP = -2.020
LIP_Y = 0.15  # lip outer face |y|
RING_Z = -2.205
HC = Vector((0.0, -0.22, 1.58))  # head centre
NECK = Vector((0, -0.14, 1.04))
CHIN = HC + Vector((0, 0.12, -0.42))  # the head scales about this point, so it stays seated on the neck
LAMP_PIVOT = Vector((0, 0, RING_Z))


def E(co, size, rot=(0, 0, 0), negative=False, stiffness=2.0):
    return A.ell(tuple(co), tuple(v * MB for v in size), rot=rot, negative=negative, stiffness=stiffness)


def B(co, r, negative=False, stiffness=2.0):
    return A.ball(tuple(co), r * MB, stiffness=stiffness, negative=negative)


def CAP(a, b, r, stiffness=2.0):
    a, b = Vector(a), Vector(b)
    d = b - a
    e = Vector((1, 0, 0)).rotation_difference(d.normalized()).to_euler()
    return {"type": "CAPSULE", "co": tuple((a + b) / 2), "size": (d.length / 2, 1, 1), "rot": tuple(math.degrees(x) for x in e),
            "radius": r * MB, "stiffness": stiffness}


def limb_caps(pts, radii, sub=3):
    """Tapered limb as overlapping capsules (metaballs blend the steps into a smooth taper)."""
    out = []
    for i in range(len(pts) - 1):
        a, b = Vector(pts[i]), Vector(pts[i + 1])
        for k in range(sub):
            t0, t1 = k / sub, (k + 1) / sub
            r = radii[i] + (radii[i + 1] - radii[i]) * (t0 + t1) / 2
            out.append(CAP(a.lerp(b, t0), a.lerp(b, t1), r))
    return out


# --- geometry helpers --------------------------------------------------------------------------------------------
def basis(u: Vector) -> tuple[Vector, Vector]:
    u = u.normalized()
    a = Vector((0, 0, 1)) if abs(u.z) < 0.9 else Vector((1, 0, 0))
    n = u.cross(a).normalized()
    return n, u.cross(n).normalized()


def ellipsoid(name, centre, radii, axes=None, seg=12, rings=8, material="Fabric", **props):
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=seg, v_segments=rings, radius=1.0)
    m = axes or Matrix.Identity(3)
    c = Vector(centre)
    for v in bm.verts:
        v.co = c + m @ Vector((v.co.x * radii[0], v.co.y * radii[1], v.co.z * radii[2]))
    obj = core.obj_from_bmesh(name, bm, material, **props)
    core.smooth(obj, 180)
    return obj


def bumps(t: float, k: int, amp: float) -> float:
    """Knuckle swellings along a finger/toe: k bumps over t in [0, 1]."""
    return amp * max(0.0, math.sin(t * math.pi * k)) ** 4


def rope(name, pts, radius, segs=7, per=3, ply=0.24, material="Fabric", end=0.6):
    """Two-ply twisted cord: a swept tube whose radius has two lobes winding along it; ends taper into the cloth."""
    P = [Vector(p) for p in pts]
    if len(P) > 2:
        P = shapes.catmull(P, per)
    else:
        P = [P[0].lerp(P[1], i / 4) for i in range(5)]
    frames = core.frame_along(P)
    lens = [0.0]
    for i in range(1, len(P)):
        lens.append(lens[-1] + (P[i] - P[i - 1]).length)
    total = max(lens[-1], 1e-6)
    bm = bmesh.new()
    rings = []
    for i, (p, m) in enumerate(zip(P, frames)):
        t = lens[i] / total
        taper = 1 - (1 - end) * max(0.0, abs(2 * t - 1) - 0.65) / 0.35
        ring = []
        for k in range(segs):
            a = math.tau * k / segs
            r = radius * taper * (1 + ply * math.cos(2 * (a - lens[i] / (radius * 1.7))))
            ring.append(bm.verts.new(p + m @ Vector((math.cos(a) * r, math.sin(a) * r, 0))))
        rings.append(ring)
    for i in range(len(rings) - 1):
        a, b = rings[i], rings[i + 1]
        for k in range(segs):
            bm.faces.new((a[k], a[(k + 1) % segs], b[(k + 1) % segs], b[k]))
    for ring, p in ((rings[0], P[0]), (rings[-1], P[-1])):
        c = bm.verts.new(p)
        for k in range(segs):
            bm.faces.new((ring[k], ring[(k + 1) % segs], c))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    obj = core.obj_from_bmesh(name, bm, material)
    core.smooth(obj, 180)
    return obj


def arch_strips(name, pairs, material="Fabric", **props):
    """Raised thread: each (a, b, normal, width, height) becomes an arched 3x3 strip (8 triangles), one mesh."""
    bm = bmesh.new()
    for a, b, nrm, width, height in pairs:
        a, b, nrm = Vector(a), Vector(b), Vector(nrm).normalized()
        t = b - a
        if t.length < 1e-5:
            continue
        side = nrm.cross(t.normalized()).normalized() * width
        mid = (a + b) / 2 + nrm * height * 0.7
        rows = []
        for p, lift in ((a, 0.0), (mid, 1.0), (b, 0.0)):
            rows.append([bm.verts.new(p - side), bm.verts.new(p + nrm * height * (0.45 + 0.55 * lift)), bm.verts.new(p + side)])
        for i in range(2):
            for j in range(2):
                bm.faces.new((rows[i][j], rows[i][j + 1], rows[i + 1][j + 1], rows[i + 1][j]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    obj = core.obj_from_bmesh(name, bm, material, **props)
    core.smooth(obj, 70)
    return obj


def resample(path, step):
    pts = [Vector(p) for p in path]
    out = [pts[0]]
    acc = 0.0
    for i in range(1, len(pts)):
        seg = pts[i] - pts[i - 1]
        L = seg.length
        while acc + L >= step:
            t = (step - acc) / L
            p = pts[i - 1] + seg * t
            out.append(p)
            seg = pts[i] - p
            pts[i - 1] = p
            L = seg.length
            acc = 0.0
        acc += L
    return out


def project_path(tree, path, centre_fn):
    out = []
    for p in path:
        p = Vector(p)
        h = A.project(tree, p, centre_fn(p) - p)
        if h:
            out.append((h[0], h[1]))
    return out


def reproject(tree, surf):
    """Re-lands a projected seam on a surface that has since been displaced."""
    out = []
    for p, n in surf:
        h = A.project(tree, p + n * 0.12, -n)
        out.append((h[0], h[1]) if h else (p, n))
    return out


def ring_path(centre, axis, radius, n=28, arc=(0.0, 360.0)):
    e1, e2 = basis(Vector(axis))
    c = Vector(centre)
    a0, a1 = math.radians(arc[0]), math.radians(arc[1])
    return [c + (e1 * math.cos(a0 + (a1 - a0) * i / n) + e2 * math.sin(a0 + (a1 - a0) * i / n)) * radius for i in range(n + 1)]


def plane_arc(centre, normal, radius, a0, a1, n=32, ref=Vector((0, 0, 1))):
    nn = Vector(normal).normalized()
    e1 = (ref - nn * ref.dot(nn)).normalized()
    e2 = nn.cross(e1)
    c = Vector(centre)
    return [c + (e1 * math.cos(math.radians(a0 + (a1 - a0) * i / n)) + e2 * math.sin(math.radians(a0 + (a1 - a0) * i / n))) * radius
            for i in range(n + 1)]


def displace(obj, fn):
    """Moves each vertex along its normal by fn(position)."""
    me = obj.data
    bm = bmesh.new()
    bm.from_mesh(me)
    bm.normal_update()
    for v in bm.verts:
        v.co += v.normal * fn(v.co)
    bm.to_mesh(me)
    bm.free()


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


def pucker(obj, seams: SeamIndex, depth=0.011, ridge=0.006, fold=0.0045):
    """Sewn cloth: the seam line sinks, a folded hem ridge runs beside it and pinch folds radiate from the stitches."""
    def fn(p):
        d, arc = seams.find(p)
        if d > 0.09:
            return 0.0
        off = -depth * max(0.0, 1 - d / 0.022) ** 2
        off += ridge * math.exp(-((d - 0.032) / 0.013) ** 2)
        if d > 0.012:
            off += fold * math.sin(arc / 0.052 * math.tau + 2.5 * noise.noise(p / 0.12)) * math.exp(-(d - 0.012) / 0.035)
        return off

    displace(obj, fn)


def custom_paint(objs, fn, ao_samples=16, ao_distance=0.6):
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


def burlap(p, n, cv, op, base, seams: SeamIndex | None, seed):
    """Coarse sacking: blotchy dye and stains, fibre speckle and a weave hint, cold shadows, dark sunk seams."""
    g = fbm(p, 0.22, 3, seed)
    c = paint.mul(base, 1.0 + 0.32 * g)  # blotchy dye within the panel
    c = paint.mix(c, paint.mul(base, 1.3), max(0.0, -g - 0.25) * 0.8)
    st = fbm(p, 0.14, 2, seed + 9.0)
    if st > 0.12:
        c = paint.mix(c, STAIN, min(0.6, (st - 0.12) * 1.8))
    tb = fbm(p, 0.18, 2, seed + 17.0)
    if tb > 0.08:
        c = paint.mix(c, DARK_TEAL, min(0.3, (tb - 0.08) * 1.0))  # teal-black blotches soaked into the sacking
    smudge = fbm(p, 0.07, 2, seed + 4.0)
    if smudge > 0.1:
        c = paint.mix(c, paint.mul(base, 0.5), min(0.6, (smudge - 0.1) * 1.8))  # grimy smudges
    if noise.noise(p / 0.05 + Vector((seed, 0, 5.0))) > 0.5:
        c = paint.mul(c, 0.9)  # coarse dark speckle
    fib = noise.noise(p / 0.011 + Vector((seed, 1.7, 0)))
    weave = math.sin((p.x + p.y * 0.6) * math.tau / 0.045) * math.sin((p.z - p.y * 0.4) * math.tau / 0.045)
    k = 1.0 + 0.035 * fib + 0.015 * weave
    if noise.noise(p / 0.04 + Vector((0, seed, 3.1))) > 0.62:
        c = paint.mix(c, PATCH_DK, 0.2)  # dark fibre flecks
    occl = 1 - op
    c = paint.mix(c, SHADOW, min(1.0, occl * 1.1))
    c = paint.mix(c, CREVICE, max(0.0, occl - 0.25) * 1.5)
    if cv < 0:
        c = paint.mix(c, CREVICE, min(0.75, -cv * 1.0))
    else:
        c = paint.mix(c, paint.mul(base, 1.35), min(0.35, cv * 0.5))
    if seams is not None:
        d, _ = seams.find(p)
        if d < 0.045:
            c = paint.mix(c, CREVICE, 0.55 * (1 - d / 0.045) ** 2)
        if d < 0.012:
            c = paint.mix(c, H("0d1112"), 0.75 * (1 - d / 0.012))  # the seam line itself
    return paint.mul(c, k)


# --- body ----------------------------------------------------------------------------------------------------------
SH_R, SH_L = Vector((-0.55, -0.06, 0.74)), Vector((0.55, -0.04, 0.71))
EL_R, EL_L = Vector((-1.3, -0.4, 0.92)), Vector((0.86, -0.3, 0.16))
HIP_R, HIP_L = Vector((-0.24, 0.2, -0.44)), Vector((0.24, 0.2, -0.44))
KN_R, KN_L = Vector((-0.78, -0.58, -0.72)), Vector((0.74, -0.6, -0.76))
AN_R, AN_L = Vector((-0.21, 0.07, -1.96)), Vector((0.2, 0.07, -1.96))


def build_body(wrist_r, wrist_l):
    """The stuffed sack: torso, arms and legs as one metaball sculpt, lumpy where the stuffing settles."""
    els = [
        E((0, 0.2, -0.32), (0.5, 0.42, 0.26)),                      # pelvis
        E((-0.2, 0.38, -0.4), (0.325, 0.3, 0.242)),                   # sagging seat
        E((0.2, 0.38, -0.4), (0.325, 0.3, 0.242)),
        E((0, -0.2, -0.06), (0.46, 0.48, 0.36)),                     # stuffed pot belly
        E((0, -0.12, 0.4), (0.41, 0.36, 0.33), rot=(30, 0, 0)),       # chest, pitched forward
        E((0, 0.14, 0.58), (0.4, 0.36, 0.3), rot=(38, 0, 0)),      # hunched back
        E((0, 0.06, 0.17), (0.36, 0.3, 0.2)),                      # waist
        E((0, -0.13, 0.28), (0.2, 0.06, 0.1), negative=True, stiffness=0.9),  # a slack fold under the chest
        CAP((0, -0.06, 0.62), (0, -0.16, 1.1), 0.1),                 # neck thrust forward
        B(SH_R, 0.16), B(SH_L, 0.16),
        B((-0.2, 0.27, 0.47), 0.07), B((0.2, 0.27, 0.47), 0.07),     # lumps of stuffing on the back
        B(HIP_R, 0.16), B(HIP_L, 0.16),
    ]
    els += limb_caps([SH_R, SH_R.lerp(EL_R, 0.5) + Vector((0, 0, 0.04)), EL_R], [0.112, 0.1, 0.088])
    els += limb_caps([EL_R, EL_R.lerp(wrist_r, 0.45), wrist_r], [0.088, 0.096, 0.07])
    els += limb_caps([SH_L, SH_L.lerp(EL_L, 0.5) + Vector((0.03, 0, 0)), EL_L], [0.112, 0.1, 0.088])
    els += limb_caps([EL_L, EL_L.lerp(wrist_l, 0.45), wrist_l], [0.088, 0.096, 0.07])
    els += [B(EL_R, 0.112), B(EL_L, 0.112), B(wrist_r, 0.075), B(wrist_l, 0.075)]
    for hip, kn, an, s in ((HIP_R, KN_R, AN_R, -1), (HIP_L, KN_L, AN_L, 1)):
        els += limb_caps([hip, hip.lerp(kn, 0.5) + Vector((0, 0, 0.03)), kn], [0.163, 0.144, 0.119])
        calf = kn.lerp(an, 0.3) + Vector((0, 0.05, 0))
        els += limb_caps([kn, calf, an], [0.106, 0.112, 0.0725])
        els += [B(kn, 0.122), B(kn + Vector((0, -0.05, 0.02)), 0.08), B(an, 0.065), B(an + Vector((s * 0.045, 0.0, -0.01)), 0.045)]
    body = A.organic("Torso", els, 30000, resolution=0.016, material="Fabric", smooth_iters=1)
    displace(body, lambda p: 0.012 * fbm(p, 0.2, 2, 1.0) + 0.005 * ridged(p, 0.1, 2.0) + 0.002 * fbm(p, 0.04, 2, 7.0))
    core.smooth(body, 180)
    return body


def grip_hand(name, g: Vector, wrist_from: Vector, seed=0):
    """Palm on the wrist side of the pole at grip point g; four knuckled fingers and a thumb wrap round the pole.
    Returns the parts and the wrist point the forearm should end at."""
    u = D.normalized()
    w = wrist_from - g
    n = (w - u * w.dot(u)).normalized()  # from the pole axis toward the palm
    b = n.cross(u)
    rng = random.Random(seed)
    parts = []
    palm_c = g + n * (POLE_R + 0.072)
    axes = Matrix((u, n, u.cross(n))).transposed()
    parts.append(ellipsoid(name + "Palm", palm_c, (0.19, 0.095, 0.145), axes, 12, 8))
    R = POLE_R + 0.043
    for k, a in enumerate((-0.118, -0.04, 0.038, 0.114)):
        rr = 0.045 if k in (1, 2) else 0.039
        sweep = 300 - (30 if k == 3 else 0) - (10 if k == 0 else 0)
        pts = []
        for i in range(9):
            th = math.radians(5 + sweep * i / 8)
            r_ = R + (0.032 if i == 1 else 0.006)
            pts.append(g + u * (a + 0.008 * (rng.random() - 0.5)) + (n * math.cos(th) + b * math.sin(th)) * r_)
        f = shapes.tube(name + f"F{k}", pts, lambda t, rr=rr: rr * (1.05 - 0.4 * t) + bumps(t, 3, 0.009), 7, "Fabric", resample=0)
        core.smooth(f, 180)
        parts.append(f)
    tpts = [g + n * (POLE_R + 0.05) - u * 0.1 + b * 0.03]
    for i in range(1, 6):
        th = math.radians(-25 - 42 * i)
        tpts.append(g - u * (0.12 + 0.012 * i) + (n * math.cos(th) + b * math.sin(th)) * (R + 0.004))
    th_ = shapes.tube(name + "Thumb", tpts, lambda t: 0.04 * (1.1 - 0.4 * t) + bumps(t, 2, 0.006), 7, "Fabric", resample=0)
    core.smooth(th_, 180)
    parts.append(th_)
    return parts, palm_c + n * 0.06


def feet(name, an, x, seed=0):
    rng = random.Random(seed)
    heel = Vector((x, 0.07, TRAY_Z + 0.042))
    ball = Vector((x, -0.07, TRAY_Z + 0.04))
    foot = A.limb(name + "Foot", [an, heel, heel.lerp(ball, 0.5), ball], [0.058, 0.054, 0.05, 0.046], 8, "Fabric", resample=2,
                  flatten=0.75)
    parts = [foot]
    for k, dx in enumerate((-0.078, -0.027, 0.024, 0.074)):
        splay = dx * 0.4
        xx = x + dx + splay * 0.3
        length = 1.0 if k in (1, 2) else 0.84
        r0 = 0.027 if k in (1, 2) else 0.024
        pts = [Vector((x + dx * 0.5, -0.05, TRAY_Z + 0.036)),
               Vector((xx, -0.115, LIP_TOP + 0.032)),
               Vector((xx + splay * 0.3, -LIP_Y - 0.024, LIP_TOP + 0.014)),
               Vector((xx + splay * 0.5, -LIP_Y - 0.032, LIP_TOP - 0.06 * length)),
               Vector((xx + splay * 0.6, -LIP_Y - 0.026, LIP_TOP - 0.11 * length)),
               Vector((xx + splay * 0.6, -LIP_Y - 0.004, LIP_TOP - 0.145 * length - 0.01 * rng.random()))]
        t_ = shapes.tube(name + f"Toe{k}", pts, lambda t, r0=r0: r0 * (1.08 - 0.55 * t) + bumps(t, 3, 0.005), 7, "Fabric", resample=2)
        core.smooth(t_, 180)
        parts.append(t_)
    return parts


# --- head ----------------------------------------------------------------------------------------------------------
# --- head ----------------------------------------------------------------------------------------------------------
EYES = ((0.0, 0.3, 0.24, 2.0), (0.42, 0.27, 0.22, 28.0))  # (x, z offset from HC, radius, cast yaw)
# The head's back sweeps up into a curled lobe of dark sacking (head-relative, before HEAD_SCALE).
LOBE = [(-0.3, 0.38, 0.32), (-0.64, 0.46, 0.48), (-0.96, 0.44, 0.64), (-1.2, 0.34, 0.84), (-1.28, 0.2, 1.06), (-1.2, 0.06, 1.22),
        (-1.03, -0.0, 1.27), (-0.9, 0.02, 1.2), (-0.85, 0.09, 1.1)]
LOBE_R = [0.57, 0.51, 0.44, 0.38, 0.31, 0.24, 0.17, 0.11, 0.06]
LOBE_EYE = Vector((-1.06, 0.22, 0.92))  # centre of the curl's spiral (head-relative)


def grin_z(s: float) -> float:
    return HC.z - 0.17 + 0.42 * s * s + 0.18 * s


def scalp_plane():
    return HC + Vector((0.0, -0.05, 0.36)), Vector((-0.22, 0.3, 0.93)).normalized()


def dark_side(p) -> float:
    """Signed distance into the dark sacking: the back of the head plus the top over its right side."""
    sc, sn = scalp_plane()
    back = (p - (HC + Vector((0.0, 0.2, 0.0)))).dot(Vector((0.0, 1.0, -0.1)).normalized())
    return max((p - sc).dot(sn), back)


def build_head():
    c = HC
    els = [
        E(c + Vector((0, 0.1, 0.12)), (0.63, 0.56, 0.55)),            # cranium, wider than tall
        E(c + Vector((0, -0.08, -0.06)), (0.69, 0.52, 0.48)),           # broad lower face carrying the grin
        E(c + Vector((0.02, -0.06, -0.4)), (0.6, 0.44, 0.32)),        # full round chin under the grin
        E(c + Vector((-0.5, -0.12, 0.02)), (0.28, 0.32, 0.3)),        # cheeks, uneven
        E(c + Vector((0.53, -0.1, -0.06)), (0.3, 0.34, 0.32)),
        E(c + Vector((-0.32, -0.3, 0.31)), (0.3, 0.26, 0.2)),         # heavy brows
        E(c + Vector((0.36, -0.26, 0.24)), (0.27, 0.25, 0.2)),
        E(c + Vector((-0.06, 0.32, 0.3)), (0.44, 0.42, 0.38)),         # skull swells back into the lobe
        E(c + Vector((-0.63, 0.02, 0.26)), (0.17, 0.22, 0.2)),        # temple lump
        E(c + Vector((0.12, 0.08, 0.46)), (0.42, 0.4, 0.22)),             # crown bump
        E(c + Vector((0.0, 0.14, -0.52)), (0.22, 0.22, 0.16)),          # chin socket over the neck
    ]
    els += [E(c + Vector((-0.1, 0.44, 0.3)), (0.56, 0.54, 0.54)),          # big hooded sack bulge at the back of the head
            E(c + Vector((-0.34, 0.4, 0.34)), (0.38, 0.34, 0.3)), CAP(c + Vector(LOBE[0]), c + Vector(LOBE[1]), 0.3)]  # rising into the lobe
    for x, dz, r, yaw in EYES:  # deep sockets
        a = math.radians(yaw)
        els.append(B(c + Vector((x, -0.48 + 0.12 * abs(math.sin(a)), dz)), r * 1.12, negative=True, stiffness=1.6))
    for i in range(15):  # the seam line the twine laces shut
        s = -0.92 + 1.84 * i / 14
        phi = math.radians(88 * s)
        rad = 0.86 - 0.12 * s * s
        els.append(E(Vector((math.sin(phi) * rad, c.y - math.cos(phi) * rad, grin_z(s))), (0.09, 0.09, 0.045 * (1 - 0.5 * s * s)),
                     rot=(0, 0, math.degrees(phi)), negative=True, stiffness=1.4))
    head = A.organic("Head", els, 45000, resolution=0.013, material="Fabric", smooth_iters=1)
    # The lobe: the back of the head sweeps up and rolls over into a spiral (swept so the curl stays crisp; it
    # starts inside the skull's bulge, so it grows out of the head rather than sitting on it).
    lobe = shapes.tube("Lobe", [c + Vector(p) for p in LOBE], LOBE_R, 14, "Fabric", resample=5, flatten=0.78, cap_start=False)
    head = core.join([head, lobe], "Head")
    displace(head, lambda p: 0.004 * fbm(p, 0.35, 2, 3.0) + 0.0035 * ridged(p, 0.11, 6.0) + 0.002 * fbm(p, 0.04, 2, 9.0))  # soft creases in the cloth
    core.smooth(head, 180)
    return head


def crumple_dark_panel(head):
    """The dark sacking is coarser and crumpled: ridged creases and lumps, fading in at its seam."""
    def fn(p):
        m = max(0.0, min(1.0, (dark_side(p) + 0.12) / 0.4))
        return m * (0.016 * ridged(p, 0.1, 5.0) + 0.009 * ridged(p, 0.045, 8.0) + 0.01 * fbm(p, 0.2, 2, 4.0))

    displace(head, fn)


def carve_mouth(head, grin, depth=0.11, half_gap=0.06):
    """Opens the grin: the lips part along the seam into a dark gap the twine bridges."""
    idx = SeamIndex([grin])

    def fn(p):
        d, _ = idx.find(p)
        if d > half_gap * 2.2:
            return 0.0
        if d < half_gap:
            return -depth * (1 - (d / half_gap) ** 2) ** 0.5
        return 0.006 * math.sin((d - half_gap) / (half_gap * 1.2) * math.pi)  # a slightly rolled lip

    displace(head, fn)


def cast_grin(tree):
    grin = []
    N = 44
    for i in range(N + 1):
        s = -1 + 2 * i / N
        phi = math.radians(92 * s)
        dirn = Vector((math.sin(phi), -math.cos(phi), 0))
        h = A.project(tree, Vector((0, HC.y, grin_z(s))) + dirn * 2.0, -dirn)
        if h:
            grin.append((h[0], h[1]))
    return grin


def head_seams(tree):
    """Seam paths on the head: (surf, closed, style key)."""
    sc, sn = scalp_plane()
    sc = sc + sn * 0.24  # the panel seam sits well back on the crown, clear of the eyes
    out = [(project_path(tree, resample(plane_arc(sc, sn, 1.3, 0, 360, 60), 0.02), lambda p: sc), True, "scalp")]
    lc = HC + Vector((-0.5, 0.0, 0.1))
    out.append((project_path(tree, resample(plane_arc(lc, Vector((1, 0.12, 0.1)), 1.0, -35, 70, 40, ref=Vector((0, -1, 0.4))), 0.02),
                             lambda p: lc), False, "temple"))
    rc = HC + Vector((0.42, 0.0, -0.05))
    out.append((project_path(tree, resample(plane_arc(rc, Vector((1, 0.35, 0.0)), 1.0, 95, 175, 30, ref=Vector((0, 0, 1))), 0.02),
                             lambda p: rc), False, "cheek"))
    fc = HC + Vector((0.05, 0.0, 0.05))
    out.append((project_path(tree, resample(plane_arc(fc, Vector((0.05, 0.42, -1.0)), 1.0, -60, 55, 40, ref=Vector((0, -1, 0))), 0.02),
                             lambda p: fc), False, "forehead"))
    nc = HC + Vector((-0.1, 0.3, 0.1))
    out.append((project_path(tree, resample(plane_arc(nc, Vector((1, 0.0, 0.0)), 1.2, -120, 5, 40, ref=Vector((0, 0, 1))), 0.02),
                             lambda p: nc), False, "nape"))
    jc = HC + Vector((0.0, 0.05, -0.3))
    out.append((project_path(tree, resample(plane_arc(jc, Vector((0, 0.35, 1)), 1.0, 205, 335, 40, ref=Vector((1, 0, 0))), 0.02),
                             lambda p: jc), False, "jaw"))
    # A seam along the lobe's outer curve, where two pieces of dark sacking were joined.
    eye = HC + LOBE_EYE
    axis = [HC + Vector(p) for p in LOBE[1:7]]
    path = [q + ((q - eye) - Vector((0, (q - eye).y, 0))).normalized() * 0.6 for q in axis]
    out.append((project_path(tree, resample(path, 0.02), lambda p: min(axis, key=lambda q: (q - p).length)), False, "lobe"))
    return [(s, closed, key) for s, closed, key in out if len(s) > 3]


def mouth_twine(tree, grin, rng):
    """The grin is laced across with thick twisted twine, each loop bridging the open gap from lip to lip. `grin` is
    the seam on the uncarved face (it gives each loop its frame); `tree` is the carved surface the ends sink into.
    Returns rope objects, the punch-hole points and the dark mouth interior."""
    ropes, holes = [], []
    M = 23
    for k in range(M):
        s = -0.84 + 1.72 * k / (M - 1) + (rng.random() - 0.5) * 0.02
        f = (s + 1) / 2 * (len(grin) - 1)
        i = min(len(grin) - 2, int(f))
        p = grin[i][0].lerp(grin[i + 1][0], f - i)
        nrm = grin[i][1].lerp(grin[i + 1][1], f - i).normalized()
        tang = (grin[i + 1][0] - grin[i][0]).normalized()
        up = tang.cross(nrm).normalized()
        if up.z < 0:
            up = -up
        L = (0.066 + 0.03 * (1 - abs(s))) * (0.9 + 0.2 * rng.random())
        tilt = 0.32 + (rng.random() - 0.5) * 0.08
        ends = []
        for sgn in (1, -1):
            q = p + up * (L + 0.03) * sgn + tang * tilt * L * sgn
            h = A.project(tree, q + nrm * 0.25, -nrm)
            ends.append(h[0] - h[1] * 0.008 if h else q)
        top, bot = ends
        if (top - bot).length > 2.6 * (L + 0.03):
            continue  # an end slipped round the cheek
        holes += [top, bot]
        mid = p + nrm * (0.034 + 0.01 * rng.random()) - tang * 0.022  # out over the gap
        pts = [top, top.lerp(mid, 0.55) + nrm * 0.014, mid, bot.lerp(mid, 0.55) + nrm * 0.014, bot]  # a C-shaped loop
        ropes.append(rope(f"Twine{k}", pts, 0.03 + 0.005 * rng.random(), segs=7, per=2))  # game-weight, not decimated
    slot = shapes.tube("GrinSlot", [p - n * 0.05 for p, n in grin], lambda t: 0.07 * math.sin(math.pi * min(1, max(0, t))) ** 0.5 + 0.008,
                       6, "SmoothPlastic", resample=0, flatten=0.55, cap_start=False, cap_end=False)  # the dark inside of the mouth
    core.smooth(slot, 180)
    return ropes, holes, slot


def eye_parts(tree, rng):
    """Sunken eyes, each laced shut across a dark slit with small twine stitches, under a heavy sewn lid."""
    eyes, lids, slits, ropes = [], [], [], []
    for x, dz, r, yaw in EYES:
        a = math.radians(yaw)
        dirn = Vector((math.sin(a), -math.cos(a), 0))
        h = A.project(tree, Vector((x, HC.y, HC.z + dz)) + dirn * 2.0, -dirn)
        if not h:
            h = A.project(tree, Vector((x, -2.0, HC.z + dz)), Vector((0, 1, 0)))
        p, nrm = h
        fwd = (nrm * 0.5 + dirn * 0.5).normalized()
        c = p - fwd * r * 0.22  # sitting deep in a round socket
        eyes.append(ellipsoid(f"Eye{len(eyes)}", c, (r, r, r * 0.95), seg=18, rings=12, material="SmoothPlastic"))
        right = Vector((0, 0, 1)).cross(fwd).normalized()
        up = fwd.cross(right).normalized()
        pts = []
        for i in range(25):
            ang = math.tau * i / 24
            pts.append(c + fwd * r * 0.32 + (right * math.cos(ang) + up * math.sin(ang)) * r * 0.99)
        rim = shapes.tube(f"Rim{len(lids)}", pts, lambda t: 0.02, 8, "Fabric", resample=0,
                          cap_start=False, cap_end=False, flatten=0.75)  # heavier along the top
        core.smooth(rim, 180)
        lids.append(rim)
        arc = []
        for i in range(15):
            ang = math.radians(-58 + 116 * i / 14)
            d_ = (fwd * math.cos(ang) + right * math.sin(ang)) + up * (0.1 + 0.08 * (i / 14 - 0.5) ** 2)
            arc.append(c + d_.normalized() * (r + 0.002))
        sl = shapes.tube(f"Slit{len(slits)}", arc, lambda t: 0.008 + 0.024 * math.sin(math.pi * min(1, max(0, t))) ** 0.7, 6,
                         "SmoothPlastic", resample=0, flatten=0.5)
        core.smooth(sl, 180)
        slits.append(sl)
        for j in range(6):
            ang = math.radians(-44 + 88 * j / 5 + (rng.random() - 0.5) * 6)
            bd = (fwd * math.cos(ang) + right * math.sin(ang)).normalized()
            tilt = (rng.random() - 0.5) * 0.12
            pts = []
            for e_ in (-1, 0, 1):
                d_ = (bd + up * (0.3 * e_ + 0.1) + right * tilt * e_).normalized()
                pts.append(c + d_ * (r + (0.016 if e_ == 0 else -0.002)))
            ropes.append(rope(f"EyeTwine{len(eyes)}_{j}", pts, 0.0095, segs=5, per=2))
    return eyes, lids, slits, ropes


# --- stitching -----------------------------------------------------------------------------------------------------
# Every seam gets its own hand: stitch kind, thread, size and spacing. (kind, thread, spacing, length, width/radius)
STYLES = {
    "shoulder": ("ladder", "brown", 0.045, 0.085, 0.02),
    "elbow": ("ladder", "black", 0.045, 0.08, 0.019),
    "wrist": ("whip", "brown", 0.04, 0.07, 0.018),
    "hip": ("ladder", "brown", 0.05, 0.09, 0.021),
    "knee": ("ladder", "black", 0.045, 0.085, 0.02),
    "ankle": ("whip", "black", 0.04, 0.07, 0.018),
    "neck": ("twine", "twine", 0.06, 0.09, 0.016),
    "chest": ("x", "black", 0.055, 0.095, 0.02),
    "belly": ("ladder", "brown", 0.05, 0.09, 0.02),
    "back": ("x", "brown", 0.055, 0.095, 0.02),
    "patch": ("x", "black", 0.05, 0.07, 0.016),
    "seat": ("ladder", "black", 0.05, 0.085, 0.02),
    "scalp": ("whip", "brown", 0.045, 0.06, 0.009),
    "temple": ("whip", "brown", 0.045, 0.08, 0.0142),
    "cheek": ("x", "black", 0.05, 0.065, 0.011),
    "forehead": ("x", "black", 0.055, 0.065, 0.01),
    "nape": ("ladder", "black", 0.06, 0.09, 0.013),
    "jaw": ("running", "black", 0.055, 0.04, 0.0128),
    "lobe": ("ladder", "black", 0.06, 0.08, 0.0149),
}


def lay_stitches(surf, key, closed, tree, rng, groups):
    """Adds one seam's stitches to `groups[thread] = {"pairs": [...], "objs": [...]}`; returns stitch-hole points."""
    kind, thread, spacing, length, w = STYLES[key]
    g = groups.setdefault(thread, {"pairs": [], "objs": []})
    holes = []
    total, nxt = 0.0, spacing * 0.5
    for i in range(1, len(surf)):
        p0, n0 = surf[i - 1]
        p1, n1 = surf[i]
        seg = (p1 - p0).length
        while total + seg >= nxt:
            t = (nxt - total) / max(seg, 1e-6)
            nxt += spacing * (0.85 + 0.3 * rng.random())
            if rng.random() < 0.05:
                continue  # a missed stitch
            p = p0.lerp(p1, t)
            n = n0.lerp(n1, t).normalized()
            tan = (p1 - p0).normalized()
            across = n.cross(tan).normalized()
            L = length * (0.85 + 0.3 * rng.random())
            jit = (rng.random() - 0.5) * 0.25
            if kind == "x":
                dirs = [(across + tan * (0.75 + jit)).normalized(), (across - tan * (0.75 - jit)).normalized()]
            elif kind == "whip":
                dirs = [(across + tan * (0.8 + jit)).normalized()]
            elif kind == "ladder":
                dirs = [(across + tan * jit).normalized()]
            elif kind == "running":
                dirs = [(tan + across * jit * 0.5).normalized()]
            else:
                dirs = [(across + tan * jit * 0.6).normalized()]
            for d in dirs:
                a, b = p - d * L * 0.5, p + d * L * 0.5
                ha = A.project(tree, a + n * 0.1, -n)
                hb = A.project(tree, b + n * 0.1, -n)
                a = ha[0] if ha else a
                b = hb[0] if hb else b
                if (a - b).length > L * 1.6:
                    continue  # an end slipped onto another surface
                holes += [a, b]
                if kind == "twine":
                    pts = [a - n * 0.004, a.lerp(b, 0.5) + n * (0.016 + 0.006 * rng.random()), b - n * 0.004]
                    g["objs"].append(rope(f"St_{key}_{len(g['objs'])}", pts, w, segs=6, per=3))
                else:  # twisted thread pulled through two holes, arching slightly over the seam
                    pts = [a - n * 0.004, a.lerp(b, 0.5) + n * (w * 0.9), b - n * 0.004]
                    g["objs"].append(rope(f"St_{key}_{len(g['objs'])}", pts, w * 0.62, segs=6, per=2, ply=0.3))
        total += seg
    if not closed and len(surf) > 2:
        for end, nb in ((surf[0], surf[1]), (surf[-1], surf[-2])):
            p, n = end
            g["objs"].append(ellipsoid(f"Knot_{key}_{len(g['objs'])}", p + n * 0.012, (0.018, 0.018, 0.016), seg=7, rings=5))
            if rng.random() < 0.75:  # a loose end hanging from the knot
                down = Vector((0, 0, -1))
                side = n.cross(down).normalized() * (0.02 if rng.random() < 0.5 else -0.02)
                pts = [p + n * 0.014, p + n * 0.03 + down * 0.025, p + n * 0.035 + down * 0.06 + side, p + n * 0.028 + down * 0.095 + side * 2]
                lo = shapes.tube(f"Loose_{key}_{len(g['objs'])}", pts, lambda t: w * 0.7 * (1 - 0.5 * t), 4, "Fabric", resample=2)
                g["objs"].append(lo)
    return holes


def frayed(surf, tree, count, rng):
    """Short burlap fibres sticking out beside a seam (frayed sack edge)."""
    out = []
    for _ in range(count):
        p, n = surf[rng.randrange(len(surf))]
        tan = Vector((rng.random() - 0.5, rng.random() - 0.5, rng.random() - 0.5))
        tan = (tan - n * tan.dot(n)).normalized()
        base = p + tan * (0.012 + 0.02 * rng.random())
        h = A.project(tree, base + n * 0.1, -n)
        if not h:
            continue
        b0 = h[0]
        tip = b0 + (n * 0.6 + tan).normalized() * (0.02 + 0.025 * rng.random())
        out.append(shapes.tube(f"Fibre{len(out)}", [b0 - n * 0.003, b0.lerp(tip, 0.5) + n * 0.004, tip], lambda t: 0.0035 * (1 - 0.6 * t), 3,
                               "Fabric", resample=0, cap_start=False))
    return out


def build_threads(name, groups, part, fibres=()):
    """Paints every thread group its colour and joins them into one detail part."""
    objs = []
    for thread, g in groups.items():
        col = THREADS[thread]
        members = list(g["objs"])
        if g["pairs"]:
            members.append(arch_strips(f"{name}_{thread}", g["pairs"]))
        if not members:
            continue

        def fn(p, n, o, cv, op, col=col):
            c = paint.mix(col, paint.mul(col, 1.45), min(0.5, max(0.0, cv) * 0.8))
            c = paint.mix(c, paint.mul(col, 0.45), min(0.6, max(0.0, -cv) * 0.9))
            c = paint.mul(c, 0.92 + 0.12 * noise.noise(p / 0.01))
            return paint.mul(c, 0.55 + 0.45 * op)

        custom_paint(members, fn, ao_samples=6, ao_distance=0.06)
        objs += members
    if fibres:
        custom_paint(list(fibres), lambda p, n, o, cv, op: paint.mix(SKIN_BONE, SKIN_HI, 0.3 + 0.4 * max(0, noise.noise(p / 0.01))),
                     ao_samples=2, ao_distance=0.01)
        objs += list(fibres)
    out = core.join(objs, name)
    core.tag(out, "Fabric", part=part, lod=False, detail=True)
    return out


def build_pole():
    top = pole_at(TOP_Z)
    bot = pole_at(BOT_Z)
    L = (top - bot).length
    r = POLE_R
    prof = [(rr * 1.55, z * 1.35) for rr, z in [(0.0, 0.0), (0.025, 0.04), (0.088, 0.24), (0.06, 0.265), (0.06, 0.29), (0.118, 0.305),
            (0.124, 0.345), (0.118, 0.37), (0.07, 0.385), (0.07, 0.43), (0.1, 0.445), (0.1, 0.485), (0.072, 0.5)]] + [(r, 0.53 * 1.35)]
    mid = [(r, 0.72 + (L - 1.44) * k / 6) for k in range(1, 6)]
    full = prof + mid + [(rr, L - z) for rr, z in reversed(prof)]
    obj = shapes.lathe("Pole", full, 12, "Metal", cap_bottom=False, cap_top=False, wobble=0.015, seed=3)
    core.smooth(obj, 50)
    q = (top - bot).normalized().to_track_quat("Z", "Y")
    obj.matrix_world = Matrix.Translation(bot) @ q.to_matrix().to_4x4()
    core.apply_transform(obj)
    return obj


def build_tray():
    parts = []
    hx = 0.43
    parts.append(shapes.box("TrayFloor", (2 * hx, 2 * LIP_Y, 0.035), (0, 0, TRAY_Z - 0.0175), bevel=0.006, segments=1))
    for sgn in (-1, 1):
        parts.append(shapes.box(f"TrayLip{sgn}", (2 * hx, 0.035, LIP_TOP - (TRAY_Z - 0.035)),
                                (0, sgn * (LIP_Y - 0.0175), (LIP_TOP + TRAY_Z - 0.035) / 2), bevel=0.006, segments=1))
        parts.append(shapes.box(f"TrayRim{sgn}", (2 * hx + 0.02, 0.05, 0.022), (0, sgn * (LIP_Y - 0.01), LIP_TOP + 0.004), bevel=0.005,
                                segments=1))
        # Upturned end flanges ending in a curled scroll, like a pagoda eave.
        parts.append(shapes.box(f"TrayEnd{sgn}", (0.035, 2 * LIP_Y + 0.06, 0.2), (sgn * (hx + 0.03), 0, TRAY_Z + 0.05),
                                rot=(0, sgn * 24, 0), bevel=0.006, segments=1))
        scroll = []
        for i in range(10):
            a = i / 9 * math.pi * 1.4
            scroll.append(Vector((sgn * (hx + 0.08 + 0.05 * (1 - math.cos(a)) * 0.9), 0, TRAY_Z + 0.14 + 0.05 * math.sin(a))))
        for yy in (-LIP_Y - 0.01, LIP_Y + 0.01):
            sc = shapes.tube(f"TrayScroll{sgn}{yy}", [p + Vector((0, yy, 0)) for p in scroll], lambda t: 0.022 * (1 - 0.5 * t), 5, "Metal",
                             resample=0)
            pass  # no scroll ends: the concept tray is a plain shallow dish
    parts.append(shapes.box("TrayKeel", (0.36, 0.12, 0.05), (0, 0, TRAY_Z - 0.055), bevel=0.008, segments=1))
    ring = shapes.tube("TrayRing", [(0.045 * math.cos(a), 0, RING_Z + 0.045 * math.sin(a)) for a in [k / 10 * math.tau for k in range(11)]],
                       0.015, 6, "Metal", cap_start=False, cap_end=False)
    parts.append(ring)
    for sgn in (-1, 1):
        for k, x in enumerate((-0.36, -0.2, 0.2, 0.36)):
            parts.append(shapes.sphere(f"Rivet{sgn}{k}", 0.016, (x, sgn * (LIP_Y + 0.002), (LIP_TOP + TRAY_Z) / 2 - 0.02), (1, 0.55, 1), 6, 4,
                                       "Metal"))
    tray = core.join(parts, "Tray")
    core.tag(tray, "Metal", part="Perch")
    core.smooth(tray, 35)
    return tray


# --- lantern -------------------------------------------------------------------------------------------------------
LS = 1.55  # lantern scale about its top ring
Z_TOP = -2.890
Z_APEX = -2.830
Z_EAVE = -3.380
Z_BT = -3.460
Z_BB = -4.340
Z_BASE = -4.420
Z_POINT = -4.580
EAVE_H = 0.44


def half_w(z: float) -> float:
    """Concave lantern body: wide under the eave, pinched at the waist, flaring at the foot."""
    t = (z - Z_BB) / (Z_BT - Z_BB)
    return 0.265 + 0.1 * (2 * t - 1) ** 2 + 0.02 * t


def square_ring(name, h, z0, z1, depth, material="Metal"):
    ri, ro = (h - depth) * math.sqrt(2), h * math.sqrt(2)
    o = shapes.lathe(name, [(ri, z0), (ro, z0), (ro, z1), (ri, z1), (ri, z0)], 4, material, cap_bottom=False, cap_top=False)
    core.transform(o, rot=(0, 0, 45))
    core.smooth(o, 30)
    return o


def build_lantern():
    iron, rivets = [], []
    roof = shapes.lathe("Roof", [(EAVE_H * math.sqrt(2), Z_EAVE), ((EAVE_H + 0.02) * math.sqrt(2), Z_EAVE + 0.03),
                                 (0.08 * math.sqrt(2), Z_APEX), (0.0, Z_APEX + 0.005)], 4, "Metal")
    core.transform(roof, rot=(0, 0, 45))
    core.smooth(roof, 30)
    iron.append(roof)
    for k in range(4):
        rot = Matrix.Rotation(math.radians(90 * k), 3, "Z")
        # Raised, copper-bound triangular plate lying on this roof face (built on the face plane itself).
        eave_mid = Vector((0, -(EAVE_H + 0.02), Z_EAVE + 0.03))  # on the roof face itself
        apex_mid = Vector((0, -0.08, Z_APEX))
        up_face = apex_mid - eave_mid
        nrm = rot @ Vector((0, -up_face.z, up_face.y)).normalized()  # perpendicular to the face, pointing out
        if nrm.z < 0:
            nrm = -nrm

        def on_face(f, sx):
            return rot @ (eave_mid + up_face * f + Vector((sx * (EAVE_H + 0.02) * (1 - f) * 0.86, 0, 0)))

        outer = [on_face(0.09, -1), on_face(0.09, 1), on_face(0.8, 0)]
        cen = (outer[0] + outer[1] + outer[2]) / 3
        inner = [q.lerp(cen, 0.13) for q in outer]
        bm = bmesh.new()  # copper-bound rim
        vs = [bm.verts.new(q + nrm * 0.045) for q in outer]
        vb = [bm.verts.new(q - nrm * 0.004) for q in outer]
        vi = [bm.verts.new(q + nrm * 0.045) for q in inner]
        vd = [bm.verts.new(q + nrm * 0.026) for q in inner]
        for i in range(3):
            j = (i + 1) % 3
            bm.faces.new((vb[i], vb[j], vs[j], vs[i]))
            bm.faces.new((vs[i], vs[j], vi[j], vi[i]))
            bm.faces.new((vi[i], vi[j], vd[j], vd[i]))
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        iron.append(core.obj_from_bmesh(f"RoofPlateRim{k}", bm, "Metal"))
        bm = bmesh.new()  # the dark iron panel set inside it
        bm.faces.new([bm.verts.new(q + nrm * 0.026) for q in inner])
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        iron.append(core.obj_from_bmesh(f"RoofPanel{k}", bm, "Metal"))
        for t_ in (0.15, 0.38, 0.62, 0.85):
            rivets.append((outer[0].lerp(outer[1], t_) + nrm * 0.047 + (cen - outer[0].lerp(outer[1], t_)).normalized() * 0.03, nrm))
        for t_ in (0.35, 0.7):
            rivets.append((outer[0].lerp(outer[2], t_) + nrm * 0.047 + (cen - outer[0].lerp(outer[2], t_)).normalized() * 0.03, nrm))
            rivets.append((outer[1].lerp(outer[2], t_) + nrm * 0.047 + (cen - outer[1].lerp(outer[2], t_)).normalized() * 0.03, nrm))
        # Ridge strap down each roof hip, and horns curling up and out from the eave corners.
        corner = rot @ Vector((EAVE_H, -EAVE_H, Z_EAVE + 0.02))
        apex = Vector((0, 0, Z_APEX))
        iron.append(shapes.tube(f"Ridge{k}", [corner.lerp(apex, t) + Vector((0, 0, 0.022)) for t in (0.0, 0.5, 0.92)], 0.026, 4, "Metal",
                                resample=0))
        cdir = rot @ Vector((1, -1, 0)).normalized()
        c0 = rot @ Vector((EAVE_H, -EAVE_H, Z_EAVE + 0.01))
        pts = [c0 - cdir * 0.08, c0 + cdir * 0.06, c0 + cdir * 0.15 + Vector((0, 0, 0.06)), c0 + cdir * 0.19 + Vector((0, 0, 0.18)),
               c0 + cdir * 0.17 + Vector((0, 0, 0.3)), c0 + cdir * 0.13 + Vector((0, 0, 0.36))]
        horn = shapes.tube(f"Horn{k}", [c0 + (q - c0) * 0.6 for q in pts], lambda t: 0.06 * (1 - t) ** 1.25 + 0.005, 6, "Metal", resample=2)
        core.smooth(horn, 60)
        iron.append(horn)
        zs = [Z_EAVE, Z_BT, Z_BT - 0.15, (Z_BT + Z_BB) / 2, Z_BB + 0.15, Z_BB, Z_BASE - 0.02]
        post_pts = [rot @ Vector((half_w(min(Z_BT, max(Z_BB, z))) + 0.008, -(half_w(min(Z_BT, max(Z_BB, z))) + 0.008), z)) for z in zs]
        post_pts += [rot @ Vector((0.41, -0.41, Z_BASE - 0.05)), rot @ Vector((0.44, -0.44, Z_BASE - 0.09))]
        post = shapes.tube(f"Post{k}", post_pts, lambda t: 0.066 * (1 - 0.8 * max(0, t - 0.72) / 0.28), 4, "Metal", resample=0)
        core.smooth(post, 45)
        iron.append(post)
        for f in (-0.5, 0.0, 0.5):
            bpts = []
            for i in range(7):
                z = Z_BT - 0.03 - (Z_BT - Z_BB - 0.06) * i / 6
                h = half_w(z)
                bpts.append(rot @ Vector((f * (h - 0.06), -(h + 0.008), z)))
            bar = shapes.tube(f"Bar{k}_{f}", bpts, 0.02, 5, "Metal", resample=0, flatten=0.6)
            core.smooth(bar, 60)
            iron.append(bar)
        # A flat iron frame round each pane (strips inside the posts, riveted), as on the concept.
        for sx in (-1, 1):
            spts = []
            for i in range(7):
                z = Z_BT - 0.03 - (Z_BT - Z_BB - 0.06) * i / 6
                h = half_w(z)
                spts.append(rot @ Vector((sx * (h - 0.045), -(h + 0.004), z)))
            strip = shapes.tube(f"Strip{k}_{sx}", spts, 0.032, 4, "Metal", resample=0, flatten=0.35)
            core.smooth(strip, 40)
            iron.append(strip)
            for i in (1, 3, 5):
                q = spts[i]
                rivets.append((q + rot @ Vector((0, -0.012, 0)), rot @ Vector((0, -1, 0))))
        for z, n, h in ((Z_EAVE - 0.045, 7, EAVE_H + 0.03), (Z_BT - 0.015, 6, half_w(Z_BT) + 0.045), (Z_BB + 0.015, 6, half_w(Z_BB) + 0.045)):
            for j in range(n):
                x = (j / (n - 1) * 2 - 1) * (h - 0.1)
                rivets.append((rot @ Vector((x, -(h + 0.002), z)), rot @ Vector((0, -1, 0))))
    iron.append(square_ring("EaveBand", EAVE_H + 0.03, Z_EAVE - 0.09, Z_EAVE, 0.07))
    iron.append(square_ring("TopBand", half_w(Z_BT) + 0.045, Z_BT - 0.06, Z_BT + 0.03, 0.08))
    iron.append(square_ring("FootBand", half_w(Z_BB) + 0.045, Z_BB - 0.03, Z_BB + 0.06, 0.08))
    base = shapes.lathe("Base", [(0.0, Z_POINT), (0.03 * math.sqrt(2), Z_POINT + 0.03), (0.08 * math.sqrt(2), Z_POINT + 0.07),
                                 (0.12 * math.sqrt(2), Z_POINT + 0.08), ((half_w(Z_BB) + 0.02) * math.sqrt(2), Z_BASE),
                                 ((half_w(Z_BB) + 0.02) * math.sqrt(2), Z_BB - 0.02)], 4, "Metal", cap_top=True)
    core.transform(base, rot=(0, 0, 45))
    core.smooth(base, 30)
    iron.append(base)
    fin = shapes.lathe("Finial", [(0.1, Z_APEX - 0.01), (0.075, Z_APEX + 0.03), (0.04, Z_APEX + 0.05), (0.055, Z_APEX + 0.08),
                                  (0.03, Z_APEX + 0.1), (0.0, Z_APEX + 0.105)], 8, "Metal")
    core.smooth(fin, 40)
    iron.append(fin)
    iron.append(shapes.tube("FinialRing", [(0, 0.04 * math.cos(a), Z_TOP - 0.045 + 0.045 * math.sin(a)) for a in [k / 10 * math.tau for k in range(11)]],
                            0.014, 5, "Metal", cap_start=False, cap_end=False))
    bm = bmesh.new()
    for p, nrm in rivets:
        n_ = Vector(nrm).normalized()
        e1, e2 = basis(n_)
        ring = [bm.verts.new(p + (e1 * math.cos(a) + e2 * math.sin(a)) * 0.024) for a in [k / 6 * math.tau for k in range(6)]]
        top = bm.verts.new(p + n_ * 0.018)
        for k in range(6):
            bm.faces.new((ring[k], ring[(k + 1) % 6], top))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    iron.append(core.obj_from_bmesh("Rivets", bm, "Metal"))
    # Glowing panes on all four sides, following the concave profile just inside the bars.
    bm = bmesh.new()
    for k in range(4):
        rot = Matrix.Rotation(math.radians(90 * k), 3, "Z")
        rows = []
        for i in range(9):
            z = Z_BT - 0.02 - (Z_BT - Z_BB - 0.04) * i / 8
            h = half_w(z)
            rows.append([bm.verts.new(rot @ Vector(((j / 8 * 2 - 1) * (h - 0.01), -(h - 0.014), z))) for j in range(9)])
        for i in range(8):
            for j in range(8):
                bm.faces.new((rows[i][j], rows[i][j + 1], rows[i + 1][j + 1], rows[i + 1][j]))
    for z in (Z_BT - 0.02, Z_BB + 0.02):
        h = half_w(z)
        bm.faces.new([bm.verts.new(Vector((sx * (h - 0.01), sy * (h - 0.01), z))) for sx, sy in ((-1, -1), (1, -1), (1, 1), (-1, 1))])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    panes = core.obj_from_bmesh("LampGlow", bm, "Neon")
    core.smooth(panes, 30)
    # Chain (not scaled with the lantern): alternating oval links from the tray ring down to the finial ring.
    links = []
    z0, z1 = RING_Z - 0.03, Z_TOP - 0.02
    nlinks = 3
    for i in range(nlinks):
        zc = z0 - (z0 - z1) * (i + 0.5) / nlinks
        lh = (z0 - z1) / nlinks * 0.62 + 0.025
        yaw = 0 if i % 2 else math.pi / 2
        pts = [Vector((0, 0, zc)) + Matrix.Rotation(yaw, 3, "Z") @ Vector((0.07 * math.cos(a), 0, lh * math.sin(a)))
               for a in [k / 12 * math.tau for k in range(13)]]
        links.append(shapes.tube(f"Link{i}", pts, 0.03, 6, "Metal", cap_start=False, cap_end=False))
    # Scale the lantern about its hanging ring and turn it corner-on, as in the concept.
    pivot = Vector((0, 0, Z_TOP))
    m = Matrix.Translation(pivot) @ Matrix.Rotation(math.radians(45), 4, "Z") @ Matrix.Scale(LS, 4) @ Matrix.Translation(-pivot)
    for o in iron + [panes]:
        o.matrix_world = m @ o.matrix_world
        core.apply_transform(o)
    core.tag(panes, "Neon", part="LampGlow", pivot=tuple(LAMP_PIVOT), lod=False)
    return iron + links, panes  # joined after painting, so each piece gets its own finish


# --- assembly ------------------------------------------------------------------------------------------------------
# --- assembly ------------------------------------------------------------------------------------------------------
def _seg_d(p, a, b):
    ab = b - a
    t = max(0.0, min(1.0, (p - a).dot(ab) / max(1e-9, ab.dot(ab))))
    return (p - (a + ab * t)).length


def lantern_wisp():
    rng = random.Random(14)
    handR, wristR = grip_hand("HandR", G1, EL_R, seed=1)
    handL, wristL = grip_hand("HandL", G2, EL_L, seed=2)
    torso = build_body(wristR, wristL)
    feet_parts = feet("FootR", AN_R, -0.2, 3) + feet("FootL", AN_L, 0.2, 4)
    body_parts = [torso] + handR + handL + feet_parts

    # Body seams: rings at every joint, then the patch seams of the sack.
    btree = A.surface_bvh(body_parts)
    rings = [("shoulder", SH_R, EL_R - SH_R, 0.1), ("shoulder", SH_L, EL_L - SH_L, 0.1),
             ("elbow", EL_R.lerp(wristR, 0.1), wristR - EL_R, 0.08), ("elbow", EL_L.lerp(wristL, 0.1), wristL - EL_L, 0.08),
             ("wrist", wristR.lerp(EL_R, 0.07), wristR - EL_R, 0.06), ("wrist", wristL.lerp(EL_L, 0.07), wristL - EL_L, 0.06),
             ("hip", HIP_R.lerp(KN_R, 0.2), KN_R - HIP_R, 0.12), ("hip", HIP_L.lerp(KN_L, 0.2), KN_L - HIP_L, 0.12),
             ("knee", KN_R.lerp(AN_R, 0.17), AN_R - KN_R, 0.09), ("knee", KN_L.lerp(AN_L, 0.17), AN_L - KN_L, 0.09),
             ("ankle", AN_R.lerp(KN_R, 0.13), KN_R - AN_R, 0.06), ("ankle", AN_L.lerp(KN_L, 0.13), KN_L - AN_L, 0.06)]
    bseams = []
    for key, c, ax, rad in rings:
        bseams.append((project_path(btree, resample(ring_path(c, ax, rad + 0.3, 48), 0.02), lambda p, c=c: c), True, key))
    neck_c = Vector((0, -0.08, 0.74))
    bseams.append((project_path(btree, resample(ring_path(neck_c, Vector((0, -0.3, 1)), 0.6, 48), 0.02), lambda p: neck_c), True, "neck"))
    chest = [(-0.36, -0.75, 0.6), (-0.22, -0.75, 0.44), (-0.06, -0.75, 0.27), (0.12, -0.75, 0.17), (0.3, -0.75, 0.2)]
    bseams.append((project_path(btree, resample(chest, 0.02), lambda p: Vector((p.x * 0.4, 0.05, p.z))), False, "chest"))
    belly_c = Vector((0, 0.0, -0.18))
    bseams.append((project_path(btree, resample(ring_path(belly_c, Vector((0, 0.2, 1)), 0.75, 40, (205, 335)), 0.02), lambda p: belly_c),
                   False, "belly"))
    back = [(0.1, 0.85, 0.7), (0.08, 0.85, 0.4), (0.11, 0.85, 0.15), (0.07, 0.85, -0.05)]
    bseams.append((project_path(btree, resample(back, 0.02), lambda p: Vector((p.x, 0.12, p.z))), False, "back"))
    seat_c = Vector((0, 0.2, -0.22))
    bseams.append((project_path(btree, resample(ring_path(seat_c, Vector((0, -0.4, 1)), 0.75, 40, (15, 165)), 0.02), lambda p: seat_c),
                   False, "seat"))
    # Patches sewn onto the limbs: an oval on the right upper arm, a strip down the left thigh, one on the left forearm.
    for key, a_, b_, side in (("patch", SH_R.lerp(EL_R, 0.25), SH_R.lerp(EL_R, 0.75), Vector((0, -1, 0.3))),
                              ("patch", HIP_L.lerp(KN_L, 0.2), HIP_L.lerp(KN_L, 0.85), Vector((0.3, -1, 0))),
                              ("patch", EL_L.lerp(wristL, 0.25), EL_L.lerp(wristL, 0.7), Vector((0.2, -1, 0.4)))):
        ax = (b_ - a_).normalized()
        nrm = (side - ax * side.dot(ax)).normalized()
        e2 = ax.cross(nrm).normalized()
        L2 = (b_ - a_).length / 2
        mid = (a_ + b_) / 2
        ring = [mid + ax * math.cos(t) * L2 * 0.9 + e2 * math.sin(t) * 0.09 + nrm * 0.5 for t in [k / 24 * math.tau for k in range(25)]]
        bseams.append((project_path(btree, resample(ring, 0.02), lambda p, mid=mid: mid + (p - mid - nrm * (p - mid).dot(nrm)) * 0.2),
                       True, key))
    bseams = [s for s in bseams if len(s[0]) > 3]
    pucker(torso, SeamIndex([s for s, _, _ in bseams]))
    btree = A.surface_bvh(body_parts)
    bseams = [(reproject(btree, s), closed, key) for s, closed, key in bseams]
    bgroups, bholes = {}, []
    for s, closed, key in bseams:
        bholes += lay_stitches(s, key, closed, btree, rng, bgroups)
    bfib = []
    for s, closed, key in bseams:
        if key in ("neck", "chest", "seat", "shoulder"):
            bfib += frayed(s, btree, 10, rng)
    bindex = SeamIndex([s for s, _, _ in bseams], extra=bholes)

    # Head: sculpt, sink the seams and the grin, crumple the dark panel, then lace and stitch on the final surface.
    head = build_head()
    htree = A.surface_bvh([head])
    grin0 = cast_grin(htree)
    grin = grin0
    hseams = head_seams(htree)
    pucker(head, SeamIndex([s for s, _, _ in hseams]), depth=0.012)
    carve_mouth(head, grin)
    crumple_dark_panel(head)
    htree = A.surface_bvh([head])
    grin = reproject(htree, grin)
    hseams = [(reproject(htree, s), closed, key) for s, closed, key in hseams]
    twine, mouth_holes, slot = mouth_twine(htree, grin0, rng)
    eyes, lids, slits, eye_twine = eye_parts(htree, rng)
    hgroups, hholes = {}, []
    for s, closed, key in hseams:
        hholes += lay_stitches(s, key, closed, htree, rng, hgroups)
    hfib = []
    for s, closed, key in hseams:
        if key in ("scalp", "lobe"):
            hfib += frayed(s, htree, 26, rng)
    hindex = SeamIndex([s for s, _, _ in hseams] + [grin], extra=hholes + mouth_holes)
    grin_index = SeamIndex([grin0])

    pole = build_pole()
    tray = build_tray()
    lamp_parts, panes = build_lantern()

    # Paint. Sack panels each have their own dye; seams and stitch holes are sunk and dark.
    limb_segs = [(SH_R, EL_R, PATCH_DK), (SH_L, EL_L, SKIN), (EL_R, wristR, SKIN), (EL_L, wristL, SKIN_MID),
                 (HIP_R, KN_R, SKIN), (HIP_L, KN_L, SKIN_MID), (KN_R, AN_R, SKIN), (KN_L, AN_L, SKIN)]

    def body_col(p, n, o, cv, op):
        name = o.name
        base = SKIN
        if name.startswith("Torso"):
            best, bd = None, 0.17
            for a, b, col in limb_segs:
                d = _seg_d(p, a, b)
                if d < bd:
                    best, bd = col, d
            if best is not None and (p - Vector((0, 0.05, 0.2))).length > 0.42:
                base = best
            elif p.y < -0.02 and p.z > 0.24 and p.z > 0.6 - 0.606 * (p.x + 0.36) - 0.18:
                base = PATCH_DK  # dark chest panel under the chin
            elif p.y > 0.15 and p.z < -0.2:
                base = PATCH_DK  # seat patch
            elif p.y > 0.12 and p.z > 0.42:
                base = PATCH_DK  # dark yoke across the shoulders
            elif p.z < 0.2 and p.y < 0.1:
                base = SKIN_BONE  # a dirtier belly panel
        elif "Hand" in name:
            base = SKIN_MID
        elif "Foot" in name:
            base = SKIN_MID
        c = burlap(p, n, cv, op, base, bindex, 1.0)
        dirt = max(0.0, min(1.0, (-0.35 - p.z) / 1.2)) * (0.75 + 0.25 * fbm(p, 0.1, 2, 31.0))
        c = paint.mix(c, paint.mix(STAIN, CREVICE, 0.45), dirt * 0.55)  # grime soaked up from below
        if "Toe" in name and p.z < LIP_TOP - 0.06:
            c = paint.mix(c, CREVICE, 0.3)  # grimy toe tips
        if ("Hand" in name and name[-2:] in ("F0", "F1", "F2", "F3")) and op < 0.7:
            c = paint.mix(c, CREVICE, 0.2)
        return c

    def head_col(p, n, o, cv, op):
        # The pale face shades gradually through grey-teal into the near-black back and lobe (no hard colour edge;
        # the seam and its stitches cross the gradient).
        if o.name.startswith("Rim"):
            return paint.mix(paint.mix(SHADOW, CREVICE, 0.55), PATCH_DK, 0.25 * max(0.0, fbm(p, 0.03, 2, 2.0)))
        base = SKIN
        if p.x < -0.5 + 0.12 * (p.y - HC.y):
            base = SKIN_MID
        elif p.z < HC.z - 0.3:
            base = SKIN_BONE
        pale = burlap(p, n, cv, op, base, hindex, 5.0)
        gd, _ = grin_index.find(p)
        if gd < 0.16:
            pale = paint.mix(pale, PATCH_DK, 0.45 * (1 - gd / 0.16) ** 1.5)  # grime worked into the lips
        d = dark_side(p) + 0.09 * fbm(p, 0.25, 2, 21.0)
        t = max(0.0, min(1.0, (d + 0.22) / 0.42))
        t = t * t * (3 - 2 * t)
        if t <= 0.0:
            return pale
        g = fbm(p, 0.12, 3, 3.0)
        dark = paint.mix(DARK, DARK_TEAL, 0.5 + 0.45 * g)
        dark = paint.mix(dark, DARK_HI, min(0.45, max(0.0, cv) * 0.5))
        dark = paint.mix(dark, H("0b0e0f"), min(0.85, max(0.0, -cv) * 1.1 + (1 - op) * 0.9))
        dark = paint.mul(dark, 1 + 0.12 * noise.noise(p / 0.011))
        sd, _ = hindex.find(p)
        if sd < 0.04:
            dark = paint.mix(dark, H("0b0e0f"), 0.6 * (1 - sd / 0.04))
        mid = paint.mix(PATCH_DK, SHADOW, 0.5)  # a cold grey-teal in the middle of the fade
        if t < 0.5:
            return paint.mix(pale, paint.mix(pale, mid, 0.6), t * 2)
        return paint.mix(paint.mix(pale, mid, 0.6), dark, (t - 0.5) * 2)

    def metal_col(p, n, o, cv, op):
        name = o.name
        m = 0.5 + 0.5 * fbm(p, 0.2, 3, 7.0)
        edge = max(0.0, cv - 0.6) * 2.5 + (0.5 if noise.noise(p / 0.05) > 0.4 else 0.0)  # sharp edges and worn spots
        if name == "Pole":
            base = paint.mix(H("3f3e3b"), H("7d7a72"), m)  # worn grey steel with bronze wear
            base = paint.mix(base, H("b3a796"), min(0.5, edge))
        elif name.startswith("RoofPlateRim"):
            base = paint.mix(COPPER, H("5b3a24"), 0.3 + 0.5 * m)  # copper-bound plate rims
        elif name.startswith(("Roof", "Ridge")):
            base = paint.mix(H("2e2e30"), H("4f4f53"), m)  # grey iron roof and inset panels
            base = paint.mix(base, COPPER, min(0.6, edge))
        elif name == "Rivets" or name.endswith("Band"):
            base = paint.mix(COPPER, H("4a3020"), 0.35 + 0.45 * m)  # copper banding and rivet heads
        elif name.startswith("Bar"):
            base = paint.mix(IRON, IRON_MID, m * 0.6)
        else:  # frame, horns, posts, chain, tray: dark iron, bronze where worn, copper only on worn spots
            base = paint.mix(IRON, IRON_MID, m)
            base = paint.mix(base, BRONZE, 0.25 * max(0.0, fbm(p, 0.12, 2, 9.0)))
            worn = noise.noise(p / 0.04 + Vector((3.3, 0, 0)))
            if worn > 0.35:
                base = paint.mix(base, COPPER, min(0.6, (worn - 0.35) * 2.5))
        if fbm(p, 0.05, 2, 11.0) > 0.42:
            base = paint.mix(base, RUST, 0.35)  # pitting and rust blooms
        streak = noise.noise(Vector((p.x * 38, p.y * 38, p.z * 3.0)))
        if streak > 0.45 and abs(n.z) < 0.6:
            base = paint.mix(base, H("3a2418"), min(0.35, (streak - 0.45) * 2.0))  # rust run down the sides
        if op < 0.6:
            base = paint.mix(base, VERDIGRIS, (0.6 - op) * 0.6)
        base = paint.mix(base, H("0b0a09"), (1 - op) * 0.7)
        if noise.noise(p / 0.012) > 0.5:
            base = paint.mul(base, 0.7)
        return base

    for o in body_parts + [head, pole, tray] + lamp_parts + lids:
        core.uv_box(o, 1.2)
    custom_paint(body_parts + [head, pole, tray] + lids, lambda p, n, o, cv, op: (
        metal_col(p, n, o, cv, op) if o.get("rbx_material") == "Metal" else
        head_col(p, n, o, cv, op) if o.name == "Head" or o.name.startswith("Rim") else body_col(p, n, o, cv, op)),
        ao_samples=20, ao_distance=0.45)
    custom_paint(lamp_parts, metal_col, ao_samples=16, ao_distance=0.35)
    lamp = core.join(lamp_parts, "LampIron")
    core.tag(lamp, "Metal", part="Lamp", pivot=tuple(LAMP_PIVOT))
    body_st = build_threads("BodyStitches", bgroups, "Body", bfib)
    head_st = build_threads("HeadStitches", hgroups, "Head", hfib)

    def twine_col(p, n, o, cv, op):
        c = paint.mix(TWINE, TWINE_DK, max(0.0, fbm(p, 0.04, 2, 13.0)) * 0.7)
        c = paint.mix(c, H("2a241b"), min(0.75, max(0.0, -cv) * 1.3 + (1 - op) * 0.8))
        if cv > 0.15:
            c = paint.mix(c, H("efe8d4"), 0.3)
        return paint.mul(c, 0.94 + 0.1 * noise.noise(p / 0.006))

    custom_paint(twine + eye_twine, twine_col, ao_samples=10, ao_distance=0.08)
    face_twine = core.join(twine + eye_twine, "FaceTwine")
    core.tag(face_twine, "Fabric", part="Twine", pivot=tuple(NECK))  # its own part so its LOD twin never hides the eyes
    eyes_o = core.join(eyes, "FaceEyes")
    dark = core.join([slot] + slits, "FaceSeam")

    def eye_col(p, n, o, cv, op):
        if o.name == "FaceSeam":
            return LIP
        c = paint.mix(EYE, EYE_DK, max(0.0, fbm(p, 0.05, 2, 12.0)) * 0.6)
        c = paint.mix(c, SHADOW, min(1.0, (1 - op) * 1.3))
        c = paint.mix(c, CREVICE, max(0.0, 0.62 - op) * 1.6)  # dark where the eye meets its socket
        return c

    custom_paint([eyes_o, dark], eye_col, ao_samples=14, ao_distance=0.2)
    face = core.join([eyes_o, dark], "Face")
    core.tag(face, "SmoothPlastic", part="Face", pivot=tuple(NECK), lod=False)

    body = core.join(body_parts, "Body")
    core.tag(body, "Fabric", part="Body")
    core.smooth(body, 180)
    head = core.join([head] + lids, "Head")
    core.tag(head, "Fabric", part="Head", pivot=tuple(NECK))
    perch = core.join([pole, tray], "Perch")
    core.tag(perch, "Metal", part="Perch")

    # The head was sculpted large for surface detail; scale it (and everything on it) about the chin socket.
    pitch, roll, yaw = (math.radians(v) for v in HEAD_TURN)
    turn = Matrix.Rotation(yaw, 4, "Z") @ Matrix.Rotation(roll, 4, "Y") @ Matrix.Rotation(pitch, 4, "X")
    hm = (Matrix.Translation(NECK) @ turn @ Matrix.Translation(-NECK) @ Matrix.Translation(CHIN) @ Matrix.Scale(HEAD_SCALE, 4)
          @ Matrix.Translation(-CHIN))
    for o in (head, head_st, face, face_twine):
        o.matrix_world = hm @ o.matrix_world
        core.apply_transform(o)

    def pane_col(p, n, o, cv, op):
        # Glowing frosted glass: bright core, deep teal at the frame, uneven streaks.
        q = p - LAMP_PIVOT
        zc = Z_TOP - LS * (Z_TOP - (Z_BT + Z_BB) / 2)
        hz = 1 - min(1.0, abs(p.z - zc) / (LS * (Z_BT - Z_BB) / 2))
        lat = max(abs(q.x), abs(q.y))
        across = min(abs(q.x), abs(q.y)) / max(1e-3, lat)
        t = max(0.0, min(1.0, 0.2 + 0.8 * hz ** 0.7 * (1 - across ** 1.5)))
        t *= 0.85 + 0.25 * noise.noise(Vector((p.x * 9, p.y * 9, p.z * 2)))
        c = paint.mix(PANE_EDGE, PANE_MID, min(1.0, t * 1.6))
        return paint.mix(c, PANE_CORE, max(0.0, t - 0.55) * 2.2)

    custom_paint([panes], pane_col, ao_samples=2, ao_distance=0.01)
    ember = A.embers("Ember", [body, head], 22, seed=7, length=0.32, width=0.03)
    if ember:
        paint.solid([ember], paint.hex3("ff7a2e"))
    _report_clearance(body, lamp, panes)
    _lift_all(LIFT)
    return {"Kind": "creature", "Species": "Wisp", "LodDistance": 60}


def _lift_all(dz):
    """Lifts the design so the lantern clears the ground at hover 4, then scales it uniformly about the Root."""
    k = ASSET_SCALE
    for o in bpy.context.scene.objects:
        if o.type == "MESH" and "rbx_material" in o.keys():
            o.location.z += dz
            core.apply_transform(o)
            o.scale = (k, k, k)
            core.apply_transform(o)
            if "rbx_pivot" in o.keys():
                pv = list(o["rbx_pivot"])
                o["rbx_pivot"] = (pv[0] * k, pv[1] * k, (pv[2] + dz) * k)


def _report_clearance(body, lamp, panes):
    """Prints the contact/clearance numbers the acceptance checklist asks for (Blender log), before the lift."""
    a, b = pole_at(TOP_Z), pole_at(BOT_Z)
    ax = (b - a).normalized()

    def axis_dist(p):
        t = max(0.0, min((b - a).length, (p - a).dot(ax)))
        return (p - (a + ax * t)).length

    mw = body.matrix_world
    vs = [mw @ v.co for v in body.data.vertices]
    free = [p for p in vs if (p - G1).length > 0.22 and (p - G2).length > 0.22]
    print("CLEARANCE body-to-pole (outside hands) min", round(min(axis_dist(p) for p in free) - POLE_R, 4))
    grip = [p for p in vs if (p - G1).length < 0.13 or (p - G2).length < 0.13]
    print("CLEARANCE hand surface to pole surface min", round(min(axis_dist(p) for p in grip) - POLE_R, 4))
    worst = 9.0
    pts = [lamp.matrix_world @ v.co for v in lamp.data.vertices if (lamp.matrix_world @ v.co).z < RING_Z - 0.2]
    pts += [panes.matrix_world @ v.co for v in panes.data.vertices]
    for ax_ in ("X", "Y"):
        for ang in (-0.35, -0.2, 0.0, 0.2, 0.35):
            R = Matrix.Rotation(ang, 3, ax_)
            for p in pts[::3]:
                q = LAMP_PIVOT + R @ (p - LAMP_PIVOT)
                worst = min(worst, axis_dist(q) - POLE_R)
    print("CLEARANCE lantern-to-pole under +-0.35 rad swing min", round(worst, 4))
    lo = min(p.z for p in pts)
    print("CLEARANCE lantern bottom above ground (hover 4, after lift and scale)", round((lo + LIFT) * ASSET_SCALE + 4.0, 3))


ASSETS = {"creature_wisp": lantern_wisp}

# Production bake (hcart/bake.py): game parts and the full-detail sources baked onto them.
BAKE = {"creature_wisp": {
    "Creature": {"size": 2048, "metal": 0.0, "parts": {
        "Body": {"src": ["Body", "BodyStitches"], "tris": 5000},
        "Head": {"src": ["Head", "HeadStitches"], "tris": 5000},
    }},
    "Face": {"size": 1024, "metal": 0.0, "parts": {
        "Face": {"src": ["Face"], "tris": 1600},
        "FaceTwine": {"src": ["FaceTwine"]},  # built at game weight; decimating thin loops breaks them
    }},
    "Metal": {"size": 1024, "metal": 0.75, "parts": {
        "Perch": {"src": ["Perch"]},
        "LampIron": {"src": ["LampIron"]},
    }},
}}
