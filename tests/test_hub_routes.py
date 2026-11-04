"""Hub route reachability (TASK-0136): every plaza-to-pad corridor must be walkable without jumping. Exact, no sampling.

Corridors are polylines exported by scripts/build_hub.py to games/mathshow/map/Hub.routes.json. Each polyline segment owns a
rectangle CORRIDOR_WIDTH (12) wide centred on it; every interior joint adds a disc of radius CORRIDOR_WIDTH / 2 on the joint, so the
outer side of a bend is covered too (the rectangles of the two segments overlap on the inner side).

Floor: the route's own walkable parts. A walkable facet is the upward face of a collidable part with a slope under 45 degrees that
the segment's centreline crosses. F(s), the floor height at distance s along the centreline, is the highest of those facets (exact
breakpoints, including where two facets cross). A gap in F, or an upward step in F of more than STEP_UP between consecutive floor
facets, fails.

Obstacle: any CanCollide part with an upward face that, over its overlap with the corridor, rises more than STEP_UP above the floor
height F at the same distance s along the route. Tops are planes (or flat discs, for vertical cylinders), the overlap is a convex
polygon, and top - F is linear on each piece between F's breakpoints, so the worst point is a vertex: the convex clip below is exact,
not a lane or step sample. Parts hanging overhead are not exempted: anything solid whose top is more than STEP_UP over the floor and
touches the corridor is reported.

Pure stdlib; reuses only the part loader of scripts/hub_nav.py. Set HUB_UNDER_TEST=<file.rbxmx> to run the guard on another map.
"""
import json
import math
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'scripts'))
from hub_nav import Part, load_parts  # noqa: E402

HUB = Path(os.environ.get('HUB_UNDER_TEST') or ROOT / 'games/mathshow/map/Hub.rbxmx')
ROUTES = ROOT / 'games/mathshow/map/Hub.routes.json'
CORRIDOR_WIDTH = 12.0
STEP_UP = 1.0
WALKABLE_NORMAL_Y = 0.7  # cos 45 degrees: a facet steeper than this is a wall, not floor
EPS = 1e-6
PADS = {'Daily', 'VS', 'Blitz', 'Group', 'Practice', 'Skill'}


# ---- facets: the upward-facing surfaces of a part ----------------------------------------------------------------------------

class Facet:
    """Convex polygon in world x, z with plane height h = h0 + gx * (x - x0) + gz * (z - z0); or a flat disc."""

    def __init__(self, part, poly=None, disc=None, plane=None):
        self.part, self.poly, self.disc, self.plane = part, poly, disc, plane

    def height(self, x, z):
        h0, gx, gz, x0, z0 = self.plane
        return h0 + gx * (x - x0) + gz * (z - z0)


def facets(part):
    c, r, size = part.centre, part.rotation, part.size
    if part.shape == 2:  # cylinder: axis is local X
        if abs(abs(r[1][0]) - 1.0) > 1e-6 or abs(size[1] - size[2]) > 1e-6:
            raise ValueError(f'Unsupported collidable cylinder (tilted or elliptic): {part.name}')
        return [Facet(part, disc=(c[0], c[2], size[1] / 2), plane=(c[1] + size[0] / 2, 0.0, 0.0, c[0], c[2]))]
    if part.shape != 1:
        raise ValueError(f'Unsupported collidable shape {part.shape}: {part.name}')
    half = [s / 2 for s in size]
    out = []
    for axis in range(3):
        for sign in (1, -1):
            if sign * r[1][axis] <= 1e-9:
                continue
            others = [i for i in range(3) if i != axis]
            quad = []
            for u, v in ((1, 1), (1, -1), (-1, -1), (-1, 1)):
                local = [0.0, 0.0, 0.0]
                local[axis] = sign * half[axis]
                local[others[0]], local[others[1]] = u * half[others[0]], v * half[others[1]]
                quad.append(tuple(c[j] + sum(r[j][i] * local[i] for i in range(3)) for j in range(3)))
            p0, p1, p2 = quad[0], quad[1], quad[2]
            ax, az, ay = p1[0] - p0[0], p1[2] - p0[2], p1[1] - p0[1]
            bx, bz, by = p2[0] - p0[0], p2[2] - p0[2], p2[1] - p0[1]
            det = ax * bz - az * bx
            if abs(det) < 1e-12:
                continue  # a vertical face
            gx = (ay * bz - az * by) / det
            gz = (ax * by - ay * bx) / det
            out.append(Facet(part, poly=hull([(q[0], q[2]) for q in quad]), plane=(p0[1], gx, gz, p0[0], p0[2])))
    return out


def hull(points):
    pts = sorted(set((round(x, 9), round(z, 9)) for x, z in points))

    def cross(o, a, b):
        return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])

    lower, upper = [], []
    for p in pts:
        while len(lower) >= 2 and cross(lower[-2], lower[-1], p) <= 0:
            lower.pop()
        lower.append(p)
    for p in reversed(pts):
        while len(upper) >= 2 and cross(upper[-2], upper[-1], p) <= 0:
            upper.pop()
        upper.append(p)
    return lower[:-1] + upper[:-1]


# ---- exact convex clipping ---------------------------------------------------------------------------------------------------

def clip_half(poly, ax, ay, bound):
    """Keep the part of a convex polygon where ax * x + ay * y <= bound (Sutherland-Hodgman, one half-plane)."""
    out = []
    for i, p in enumerate(poly):
        q = poly[(i + 1) % len(poly)]
        dp, dq = ax * p[0] + ay * p[1] - bound, ax * q[0] + ay * q[1] - bound
        if dp <= EPS:
            out.append(p)
        if (dp < -EPS and dq > EPS) or (dp > EPS and dq < -EPS):
            k = dp / (dp - dq)
            out.append((p[0] + k * (q[0] - p[0]), p[1] + k * (q[1] - p[1])))
    return out


def clip_box(poly, s0, s1, t0, t1):
    for ax, ay, bound in ((1, 0, s1), (-1, 0, -s0), (0, 1, t1), (0, -1, -t0)):
        poly = clip_half(poly, ax, ay, bound)
        if len(poly) < 3:
            return []
    return poly


def clip_line(poly, p0, p1):
    """Interval [k0, k1] of the segment p0 + k (p1 - p0), k in 0..1, inside a convex counter-clockwise polygon; None when outside."""
    k0, k1 = 0.0, 1.0
    dx, dz = p1[0] - p0[0], p1[1] - p0[1]
    for i, a in enumerate(poly):
        b = poly[(i + 1) % len(poly)]
        nx, nz = b[1] - a[1], -(b[0] - a[0])  # outward normal
        num = nx * (a[0] - p0[0]) + nz * (a[1] - p0[1])
        den = nx * dx + nz * dz
        if abs(den) < 1e-12:
            if num < -EPS:
                return None
        elif den > 0:
            k1 = min(k1, num / den)
        else:
            k0 = max(k0, num / den)
        if k0 > k1 + 1e-12:
            return None
    return k0, k1


def circle_extent(cx, cz, r, p0, p1):
    """Chord of the segment p0 -> p1 (k in 0..1) inside a disc, or None."""
    dx, dz = p1[0] - p0[0], p1[1] - p0[1]
    fx, fz = p0[0] - cx, p0[1] - cz
    a, b, c = dx * dx + dz * dz, 2 * (fx * dx + fz * dz), fx * fx + fz * fz - r * r
    disc = b * b - 4 * a * c
    if disc < 0:
        return None
    root = math.sqrt(disc)
    k0, k1 = max(0.0, (-b - root) / (2 * a)), min(1.0, (-b + root) / (2 * a))
    return (k0, k1) if k0 <= k1 else None


def inside(poly, pt):
    for i, a in enumerate(poly):
        b = poly[(i + 1) % len(poly)]
        if (b[0] - a[0]) * (pt[1] - a[1]) - (b[1] - a[1]) * (pt[0] - a[0]) < -EPS:
            return False
    return True


def poly_disc_extremes(poly, cx, cz, r):
    """Extreme points of (convex polygon intersect disc): vertices in the disc, edge-circle crossings, the centre if inside."""
    pts = [p for p in poly if math.hypot(p[0] - cx, p[1] - cz) <= r + EPS]
    for i, a in enumerate(poly):
        b = poly[(i + 1) % len(poly)]
        ext = circle_extent(cx, cz, r, a, b)
        if ext:
            pts += [(a[0] + k * (b[0] - a[0]), a[1] + k * (b[1] - a[1])) for k in set(ext)]
    if inside(poly, (cx, cz)):
        pts.append((cx, cz))
    return pts


# ---- one segment -------------------------------------------------------------------------------------------------------------

class Segment:
    def __init__(self, p0, p1):
        self.p0, self.p1 = p0, p1
        self.length = math.hypot(p1[0] - p0[0], p1[1] - p0[1])
        self.u = ((p1[0] - p0[0]) / self.length, (p1[1] - p0[1]) / self.length)
        self.n = (-self.u[1], self.u[0])

    def to_st(self, x, z):
        dx, dz = x - self.p0[0], z - self.p0[1]
        return dx * self.u[0] + dz * self.u[1], dx * self.n[0] + dz * self.n[1]

    def to_xz(self, s, t):
        return self.p0[0] + self.u[0] * s + self.n[0] * t, self.p0[1] + self.u[1] * s + self.n[1] * t


class Floor:
    """F(s): the highest walkable facet under the centreline, as linear pieces (s0, s1, h at s0, slope, part name)."""

    def __init__(self, seg, all_facets):
        cands = []
        for f in all_facets:
            if f.disc is None:
                if 1.0 / math.sqrt(1 + f.plane[1] ** 2 + f.plane[2] ** 2) < WALKABLE_NORMAL_Y:
                    continue
                ext = clip_line(f.poly, seg.p0, seg.p1)
            else:
                ext = circle_extent(*f.disc, seg.p0, seg.p1)
            if not ext or (ext[1] - ext[0]) * seg.length < 1e-6:
                continue
            s0, s1 = ext[0] * seg.length, ext[1] * seg.length
            h0 = f.height(*seg.to_xz(s0, 0))
            cands.append((s0, s1, h0, (f.height(*seg.to_xz(s1, 0)) - h0) / (s1 - s0), f.part.name))
        cuts = {0.0, seg.length}
        for c in cands:
            cuts.update((c[0], c[1]))
        for i, a in enumerate(cands):
            for b in cands[i + 1:]:
                if abs(a[3] - b[3]) > 1e-12:
                    s = (b[2] - b[3] * b[0] - a[2] + a[3] * a[0]) / (a[3] - b[3])
                    if max(a[0], b[0]) < s < min(a[1], b[1]):
                        cuts.add(s)
        cuts = sorted(c for c in cuts if 0 <= c <= seg.length)
        self.pieces, self.problems = [], []
        for lo, hi in zip(cuts, cuts[1:]):
            if hi - lo < 1e-7:
                continue
            mid = (lo + hi) / 2
            cover = [c for c in cands if c[0] - EPS <= mid <= c[1] + EPS]
            if not cover:
                self.problems.append(f'no walkable floor from s={lo:.2f} to s={hi:.2f}')
                continue
            best = max(cover, key=lambda c: c[2] + c[3] * (mid - c[0]))
            self.pieces.append((lo, hi, best[2] + best[3] * (lo - best[0]), best[3], best[4]))
        for a, b in zip(self.pieces, self.pieces[1:]):
            if abs(a[1] - b[0]) < 1e-6:
                step = b[2] - (a[2] + a[3] * (a[1] - a[0]))
                if step > STEP_UP + EPS:
                    self.problems.append(f'floor steps up {step:.2f} studs at s={a[1]:.2f} from {a[4]} to {b[4]}')

    def at(self, s, side=0):
        """F at s; side -1 / +1 takes the left / right limit at a breakpoint."""
        for lo, hi, h, slope, _ in self.pieces:
            if lo - EPS <= s <= hi + EPS and not (side < 0 and s <= lo + EPS) and not (side > 0 and s >= hi - EPS):
                return h + slope * (s - lo)
        return -math.inf


# ---- the guard ---------------------------------------------------------------------------------------------------------------

def check_route(route, parts):
    """Failure strings for one route; empty when the whole corridor is walkable without a jump."""
    points = [tuple(p) for p in route['points']]
    all_facets = [f for p in parts if p.collide for f in facets(p)]
    half = CORRIDOR_WIDTH / 2
    mode = route['mode']
    failures = []
    segs = [Segment(a, b) for a, b in zip(points, points[1:])]
    floors = [Floor(s, all_facets) for s in segs]
    for i, fl in enumerate(floors):
        failures += [f'{mode}: segment {i + 1}: {p}' for p in fl.problems]
    for i, (seg, fl) in enumerate(zip(segs, floors)):
        cuts = sorted({0.0, seg.length, *[p[0] for p in fl.pieces], *[p[1] for p in fl.pieces]})
        slabs = [(lo, hi) for lo, hi in zip(cuts, cuts[1:]) if hi - lo > 1e-7]
        for f in all_facets:
            worst = None
            for lo, hi in slabs:
                if f.disc is not None:
                    cx, cz, r = f.disc
                    cs, ct = seg.to_st(cx, cz)
                    tstar = min(max(ct, -half), half)  # the widest chord of the disc inside the strip lies at t nearest its centre
                    if abs(tstar - ct) > r:
                        continue
                    w = math.sqrt(max(r * r - (tstar - ct) ** 2, 0.0))
                    s_lo, s_hi = max(lo, cs - w), min(hi, cs + w)
                    if s_lo > s_hi + EPS:
                        continue
                    spots = [(s_lo, tstar), (s_hi, tstar)]
                else:
                    spots = clip_box([seg.to_st(*q) for q in f.poly], lo, hi, -half, half)
                for s, t in spots:
                    top = f.plane[0] if f.disc is not None else f.height(*seg.to_xz(s, t))
                    floor = fl.at(min(max(s, lo), hi), -1 if s >= hi - EPS else 1)
                    if floor == -math.inf:
                        continue  # a gap in the floor is already reported
                    rise = top - floor
                    if rise > STEP_UP + EPS and (worst is None or rise > worst[0]):
                        worst = (rise, s, t)
            if worst:
                x, z = seg.to_xz(worst[1], worst[2])
                failures.append(f'{mode}: segment {i + 1} s={worst[1]:.2f} t={worst[2]:+.2f} ({x:.1f}, {z:.1f}): {f.part.name} rises {worst[0]:.2f} studs above the floor')
    for i in range(1, len(points) - 1):  # joints: floor taken at the joint itself
        cx, cz = points[i]
        joint_floor = max(floors[i - 1].at(segs[i - 1].length, -1), floors[i].at(0.0, 1))
        if joint_floor == -math.inf:
            continue
        for f in all_facets:
            if f.disc is not None:
                if math.hypot(f.disc[0] - cx, f.disc[1] - cz) > f.disc[2] + half:
                    continue
                top = f.plane[0]
            else:
                cands = poly_disc_extremes(f.poly, cx, cz, half)
                gl = math.hypot(f.plane[1], f.plane[2])
                if gl > 1e-12:  # the highest point of the disc along the plane's gradient, if the polygon reaches it
                    peak = (cx + half * f.plane[1] / gl, cz + half * f.plane[2] / gl)
                    if inside(f.poly, peak):
                        cands.append(peak)
                if not cands:
                    continue
                top = max(f.height(*q) for q in cands)
            if top - joint_floor > STEP_UP + EPS:
                failures.append(f'{mode}: joint {i} at ({cx:.1f}, {cz:.1f}): {f.part.name} rises {top - joint_floor:.2f} studs above the floor')
    return failures


def check_routes(routes, parts):
    return [msg for r in routes for msg in check_route(r, parts)]


def make_block(name, centre, size, yaw=0.0):
    c, s = math.cos(yaw), math.sin(yaw)
    return Part(name, 'Part', centre, ((c, 0.0, s), (0.0, 1.0, 0.0), (-s, 0.0, c)), size, 1, True, ())


# ---- tests -------------------------------------------------------------------------------------------------------------------

def flat():
    return make_block('Floor', (5, -0.5, 0), (30, 1, 20))  # top at y = 0


STRAIGHT = {'mode': 'T', 'points': [[0.0, 0.0], [10.0, 0.0]]}
BEND = {'mode': 'T', 'points': [[0.0, 0.0], [10.0, 0.0], [10.0, 10.0]]}


def named(fails, name):
    return any(name in f for f in fails)


class GuardOnSyntheticWorlds(unittest.TestCase):
    """The guard itself, on tiny worlds with a known answer."""

    def test_clear_floor_passes(self):
        self.assertEqual(check_route(STRAIGHT, [flat()]), [])

    def test_thin_obstacle_between_the_old_sample_lanes_fails(self):  # the audit's false negative
        fails = check_route(STRAIGHT, [flat(), make_block('Pole', (5, 2, 1), (1, 4, 0.4))])
        self.assertTrue(named(fails, 'Pole'), fails)

    def test_obstacle_just_outside_the_corridor_passes(self):
        self.assertEqual(check_route(STRAIGHT, [flat(), make_block('Pole', (5, 2, 6.3), (1, 4, 0.4))]), [])

    def test_obstacle_reaching_the_corridor_edge_fails(self):
        fails = check_route(STRAIGHT, [flat(), make_block('Pole', (5, 2, 6.5), (1, 4, 1.4))])
        self.assertTrue(named(fails, 'Pole'), fails)

    def test_rotated_obstacle_corner_is_caught(self):  # a 45-degree square whose corner pokes 0.3 into the corridor
        corner = math.sqrt(2)
        fails = check_route(STRAIGHT, [flat(), make_block('Diamond', (5, 2, 6.0 + corner - 0.3), (2, 4, 2), yaw=math.pi / 4)])
        self.assertTrue(named(fails, 'Diamond'), fails)

    def test_rotated_obstacle_corner_just_outside_passes(self):
        corner = math.sqrt(2)
        self.assertEqual(check_route(STRAIGHT, [flat(), make_block('Diamond', (5, 2, 6.0 + corner + 0.05), (2, 4, 2), yaw=math.pi / 4)]), [])

    def test_a_rise_of_exactly_one_stud_passes_and_more_fails(self):
        self.assertEqual(check_route(STRAIGHT, [flat(), make_block('Kerb', (5, 0.5, 0), (4, 1.0, 2))]), [])
        fails = check_route(STRAIGHT, [flat(), make_block('Kerb', (5, 0.55, 0), (4, 1.1, 2))])
        self.assertTrue(named(fails, 'Kerb'), fails)

    def test_floor_step_between_consecutive_floor_parts_fails(self):
        low, high = make_block('Low', (0, -0.5, 0), (10, 1, 20)), make_block('High', (10, 0.1, 0), (10, 1, 20))
        self.assertEqual(check_route({'mode': 'T', 'points': [[-4.0, 0.0], [12.0, 0.0]]}, [low, high]), [])  # 0.6 step
        high = make_block('High', (10, 0.6, 0), (10, 1, 20))
        fails = check_route({'mode': 'T', 'points': [[-4.0, 0.0], [12.0, 0.0]]}, [low, high])  # 1.1 step
        self.assertTrue(named(fails, 'steps up'), fails)

    def test_gap_in_the_floor_fails(self):
        a, b = make_block('A', (0, -0.5, 0), (10, 1, 20)), make_block('B', (14, -0.5, 0), (10, 1, 20))
        fails = check_route({'mode': 'T', 'points': [[-4.0, 0.0], [16.0, 0.0]]}, [a, b])
        self.assertTrue(named(fails, 'no walkable floor'), fails)

    def test_a_ramp_is_floor_not_an_obstacle(self):  # 1-in-2 slope, 4 studs high, 20 wide, onto a landing
        phi = math.atan2(4, 8)
        rot = ((math.cos(phi), -math.sin(phi), 0.0), (math.sin(phi), math.cos(phi), 0.0), (0.0, 0.0, 1.0))
        ramp = Part('Ramp', 'Part', (4 + math.sin(phi) / 2, 2 - math.cos(phi) / 2, 0), rot, (math.hypot(8, 4), 1.0, 20), 1, True, ())
        top = make_block('Top', (13, 3.5, 0), (10, 1, 20))
        self.assertEqual(check_route({'mode': 'T', 'points': [[0.5, 0.0], [12.0, 0.0]]}, [make_block('Base', (0, -0.5, 0), (4, 1, 20)), ramp, top]), [])

    def test_vertical_cylinder_obstacle(self):
        rot = ((0.0, -1.0, 0.0), (1.0, 0.0, 0.0), (0.0, 0.0, 1.0))  # local X mapped to world Y
        near = Part('Post', 'Part', (5, 2, 5.5), rot, (4, 2.0, 2.0), 2, True, ())
        far = Part('Post', 'Part', (5, 2, 7.2), rot, (4, 2.0, 2.0), 2, True, ())
        self.assertTrue(named(check_route(STRAIGHT, [flat(), near]), 'Post'))
        self.assertEqual(check_route(STRAIGHT, [flat(), far]), [])

    def test_outer_corner_of_a_bend_is_covered_by_the_joint_disc(self):
        floor = make_block('Floor', (10, -0.5, 5), (40, 1, 40))
        self.assertEqual(check_route(BEND, [floor]), [])
        near = make_block('Post', (10 + 4.2, 2, -4.2), (0.5, 4, 0.5))  # outside both rectangles, nearest corner 5.59 from the joint
        far = make_block('Post', (10 + 4.6, 2, -4.6), (0.5, 4, 0.5))  # nearest corner 6.15 from the joint
        self.assertTrue(named(check_route(BEND, [floor, near]), 'Post'))
        self.assertEqual(check_route(BEND, [floor, far]), [])


class HubRoutes(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.data = json.loads(ROUTES.read_text())
        cls.parts = load_parts(HUB)

    def test_every_pad_has_a_route(self):
        tagged = {p.name for p in self.parts if 'ModePad' in p.tags}
        self.assertEqual(tagged, {'Pad_' + m for m in PADS})
        self.assertEqual({r['mode'] for r in self.data['routes']}, PADS)

    def test_route_ends_on_its_pad(self):
        for r in self.data['routes']:
            pad = next(p for p in self.parts if p.name == 'Pad_' + r['mode'])
            x, z = r['points'][-1]
            self.assertLessEqual(abs(x - pad.centre[0]), 0.5, r['mode'])
            self.assertLessEqual(abs(z - pad.centre[2]), 0.5, r['mode'])

    def test_declared_width_is_at_least_the_checked_width(self):
        for r in self.data['routes']:
            self.assertGreaterEqual(r['width'], CORRIDOR_WIDTH, r['mode'])
        self.assertGreaterEqual(self.data['min_width'], CORRIDOR_WIDTH)

    def test_every_corridor_is_clear(self):
        failures = check_routes(self.data['routes'], self.parts)
        self.assertEqual(failures, [], '\n' + '\n'.join(failures))

    def test_canary_pole_between_the_old_sample_lanes_is_caught(self):
        """A 0.5-stud-wide CanCollide pole 1 stud off the Daily centreline (the old lanes were 2 apart) must fail the guard by name."""
        daily = next(r for r in self.data['routes'] if r['mode'] == 'Daily')
        (x0, z0), (x1, z1) = daily['points'][0], daily['points'][-1]
        pole = make_block('CanaryPole', ((x0 + x1) / 2 + 1.0, 50.0, (z0 + z1) / 2), (0.5, 100.0, 0.5))  # Daily runs along z
        fails = check_route(daily, self.parts + [pole])
        self.assertTrue(named(fails, 'CanaryPole'), fails)

    def test_sidecar_matches_generator(self):
        with tempfile.TemporaryDirectory() as tmp:
            out = Path(tmp) / 'Hub.rbxmx'
            subprocess.run([sys.executable, str(ROOT / 'scripts/build_hub.py'), '--out', str(out)], check=True, capture_output=True)
            self.assertEqual((Path(tmp) / 'Hub.routes.json').read_text(), ROUTES.read_text(), 'run python3 scripts/build_hub.py')


if __name__ == '__main__':
    unittest.main()
