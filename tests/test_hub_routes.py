"""Hub route reachability (TASK-0136): every plaza-to-pad corridor must be walkable without jumping.

The corridors are polylines exported by scripts/build_hub.py to games/mathshow/map/Hub.routes.json. For each one, seven lanes
across its width are walked in 0.5-stud steps over the collidable parts of Hub.rbxmx: the floor may rise at most STEP_UP (1.0
stud) per step, and no collidable part may stand in the body (floor + 1 .. floor + 5 studs) of a lane. Pure stdlib; it reuses
only the part loader and the ray/solid intersection of scripts/hub_nav.py, not its calibration or route search.
"""
import json
import math
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'scripts'))
from hub_nav import HEADROOM, load_parts  # noqa: E402

HUB = ROOT / 'games/mathshow/map/Hub.rbxmx'
ROUTES = ROOT / 'games/mathshow/map/Hub.routes.json'
STEP = 0.5
CELL = 16
EPS = 1e-6
PADS = {'Daily', 'VS', 'Blitz', 'Group', 'Practice', 'Skill'}


class Terrain:
    def __init__(self, parts):
        self.parts = [p for p in parts if p.collide]
        self.cells = {}
        for p in self.parts:
            rx = sum(abs(p.rotation[0][i] * p.size[i] / 2) for i in range(3))
            rz = sum(abs(p.rotation[2][i] * p.size[i] / 2) for i in range(3))
            for cx in range(math.floor((p.centre[0] - rx) / CELL), math.floor((p.centre[0] + rx) / CELL) + 1):
                for cz in range(math.floor((p.centre[2] - rz) / CELL), math.floor((p.centre[2] + rz) / CELL) + 1):
                    self.cells.setdefault((cx, cz), []).append(p)

    def column(self, x, z):
        """Merged vertical solids [(bottom, top, [part names])] at a world x, z, lowest first."""
        spans = []
        for p in self.cells.get((math.floor(x / CELL), math.floor(z / CELL)), ()):
            iv = p.interval(x, z)
            if iv is not None:
                spans.append((iv[0], iv[1], p.name))
        spans.sort()
        merged = []
        for lo, hi, name in spans:
            if merged and lo <= merged[-1][1] + EPS:
                merged[-1][1] = max(merged[-1][1], hi)
                merged[-1][2].append(name)
            else:
                merged.append([lo, hi, [name]])
        return merged


def lanes(points, width):
    """Yield (offset, [(x, z)]) for 7 lanes from -width/2 to width/2, each segment sampled every STEP."""
    half = width / 2
    for k in range(7):
        offset = -half + k * width / 6
        samples = []
        for (x0, z0), (x1, z1) in zip(points, points[1:]):
            length = math.hypot(x1 - x0, z1 - z0)
            dx, dz = (x1 - x0) / length, (z1 - z0) / length
            n = int(length / STEP)
            for i in range(n + 1):
                t = i * STEP
                samples.append((x0 + dx * t - dz * offset, z0 + dz * t + dx * offset))
        yield offset, samples


def first_blocker(terrain, samples, start_y):
    """Walk one lane; return None, or (sample index, x, z, rise needed, part names) at the first sample that cannot be walked."""
    h = start_y
    for i, (x, z) in enumerate(samples):
        col = terrain.column(x, z)
        reach = [s for s in col if s[1] <= h + 1.0 + EPS]  # solids whose top is within step-up of the current floor
        if not reach:
            above = [s for s in col if s[1] > h]
            if not above:
                return i, x, z, math.inf, ['(no floor)']
            low = min(above, key=lambda s: s[1])
            return i, x, z, low[1] - h, low[2][:4]
        floor = max(reach, key=lambda s: s[1])[1]
        for lo, hi, names in col:
            if hi > floor + 1.0 + EPS and lo < floor + HEADROOM - EPS:
                return i, x, z, hi - floor, names[:4]
        h = floor
    return None


class HubRoutes(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.data = json.loads(ROUTES.read_text())
        cls.parts = load_parts(HUB)
        cls.terrain = Terrain(cls.parts)

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

    def test_corridors_are_wide_enough(self):
        for r in self.data['routes']:
            self.assertGreaterEqual(r['width'], 12.0, r['mode'])
        self.assertGreaterEqual(self.data['min_width'], 12.0)

    def test_no_rise_above_one_stud(self):
        failures = []
        for r in self.data['routes']:
            for offset, samples in lanes(r['points'], r['width']):
                bad = first_blocker(self.terrain, samples, 0.5)
                if bad:
                    i, x, z, rise, names = bad
                    failures.append(f"{r['mode']:<9} lane {offset:+.0f} sample {i} at ({x:.1f}, {z:.1f}): needs a {rise:.1f}-stud rise: {', '.join(names)}")
        self.assertEqual(failures, [], '\n' + '\n'.join(failures))

    def test_sidecar_matches_generator(self):
        with tempfile.TemporaryDirectory() as tmp:
            out = Path(tmp) / 'Hub.rbxmx'
            subprocess.run([sys.executable, str(ROOT / 'scripts/build_hub.py'), '--out', str(out)], check=True, capture_output=True)
            self.assertEqual((Path(tmp) / 'Hub.routes.json').read_text(), ROUTES.read_text(), 'run python3 scripts/build_hub.py')


if __name__ == '__main__':
    unittest.main()
