"""Hub walk estimates: informational; calibration failed twice (TASK-0130); Studio fresh-Play is the gate.

The slow route estimate (test_routes) runs only when HUB_WALK=1, through scripts/walk-check.sh; the default check.sh
unittest discovery skips it and keeps only the quick unit tests of the tolerance, clearance and edge rules.

A3 tolerance: abs(grid-Studio) <= max(0.10*Studio, 10 studs), per route.
TASK-0127/art-competitive.txt:70 records unchanged west geometry giving Practice
184.5 then 173.7 studs (10.8 studs) and Skill 175.9 then 158.6 in fresh Play.
TASK-0129/art-training.txt:28 also records east-route variation; :42 changes the
target height, so its pre/post-merge difference is NOT evidence of repeatability.
The allowance is user-approved A3, not a claim that this model reproduces physics.

Calibration runs against exact historical map commits; it never compares an old
length against today's geometry. TASK-0129's latest CSV is still pinned to
7f71497, so the ff44060 calibration uses its six post-merge pad lengths only.
There are no Studio centre-to-pad lengths in these records.

Run historical comparison: python3 tests/test_hub_walk.py --calibrate
"""
import argparse
import csv
import io
import math
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import time
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'scripts'))
from hub_nav import Heightfield, Part, WALK_SPEED, load_parts

# A4: set from the recorded second calibration, never infer success from W3 alone.
WALK_LENGTH_IS_GATE = False
EVIDENCE_REVISION = '725d2a4'
IDENTITY = ((1, 0, 0), (0, 1, 0), (0, 0, 1))


def within_tolerance(computed, measured):
    return math.isfinite(computed) and abs(computed-measured) <= max(.10*measured, 10.0)


def route_issues(route, length):
    if not math.isfinite(length):
        return 'unreachable'
    if '->Pad_' in route and not 8 <= length/WALK_SPEED <= 12:
        return 'outside 8-12 seconds'
    return ''


def historical_text(revision, path):
    return subprocess.check_output(['git', '-C', str(ROOT), 'show', f'{revision}:{path}'], text=True)


def calibrate():
    """Read-only historical comparisons. The task note stores results and map SHAs."""
    all_pass = True
    batches = [
        ('TASK-0127 rev1', '1181b5e', dict(Daily=189.9, VS=178.3, Blitz=173.6,
                                       Group=182.5, Practice=173.7, Skill=158.6)),
        ('TASK-0129 post-merge', 'ff44060', dict(Blitz=169.6, Daily=185.9, Group=174.3,
                                             Practice=173.9, Skill=154.7, VS=178.5)),
    ]
    for label, revision, pads in batches:
        benchmarks = {'spawn->Pad_'+name: length for name, length in pads.items()}
        if label == 'TASK-0127 rev1':
            text = historical_text(EVIDENCE_REVISION, 'docs/workflow/evidence/TASK-0127/glyph-reachability.csv')
            rows = csv.DictReader(io.StringIO('\n'.join(l for l in text.splitlines() if not l.startswith('#'))))
            benchmarks.update(('spawn->'+r['name'], float(r['route_length_studs'])) for r in rows)
        with tempfile.TemporaryDirectory(prefix='TASK-0130-calibration-') as tmp:
            path = Path(tmp) / 'Hub.rbxmx'
            path.write_text(historical_text(revision, 'games/mathshow/map/Hub.rbxmx'))
            started = time.perf_counter()
            nav = Heightfield(load_parts(path))
            print(f'\n{label}: map={revision}; evidence={EVIDENCE_REVISION}', flush=True)
            print('| Route | Studio studs | Grid studs | Delta studs | Delta % | Result |', flush=True)
            print('|---|---:|---:|---:|---:|---|', flush=True)
            spawn_part = next(p for p in nav.parts if p.cls == 'SpawnLocation')
            origin = (spawn_part.centre[0], spawn_part.centre[1]+3, spawn_part.centre[2])
            parts = {p.name: p for p in nav.parts}
            for route, measured in benchmarks.items():
                part = parts[route.split('->')[1]]
                target = part.centre
                if 'ModePad' in part.tags:
                    target = (target[0], target[1]+3, target[2])
                length, cells = nav.route(origin, target)
                passed = within_tolerance(length, measured)
                all_pass &= passed
                print(f'| {route} | {measured:.1f} | {length:.2f} | {length-measured:+.2f} | '
                      f'{100*(length/measured-1):+.2f}% | {"PASS" if passed else "FAIL"} |', flush=True)
            print(f'Runtime: {time.perf_counter()-started:.3f}s', flush=True)
    print(f'CALIBRATION {"PASS" if all_pass else "FAIL"}', flush=True)
    return all_pass


class HubWalkTest(unittest.TestCase):
    @unittest.skipUnless(os.environ.get('HUB_WALK') == '1', 'opt-in: scripts/walk-check.sh (informational)')
    def test_routes(self):
        started = time.perf_counter()
        try:
            nav = Heightfield(load_parts())
            count = 0
            for route, (length, cells) in nav.routes():
                count += 1
                issue = route_issues(route, length)
                if WALK_LENGTH_IS_GATE:
                    with self.subTest(route=route):
                        self.assertFalse(issue, f'{route}: {issue}; length={length:.2f}; cells={cells}')
                else:
                    print(f'INFORMATIONAL {route}: length={length:.2f} studs; '
                          f'time={length/WALK_SPEED:.3f}s; {issue or "within limits"}', flush=True)
            if WALK_LENGTH_IS_GATE:
                self.assertEqual(count, 46, 'Expected 12 pad routes and 34 glyph routes')
        except Exception as exc:
            if WALK_LENGTH_IS_GATE:
                raise
            print(f'INFORMATIONAL hub navigation unavailable: {type(exc).__name__}: {exc}', flush=True)
        finally:
            print(f'Hub walk test runtime: {time.perf_counter()-started:.3f}s; '
                  f'{"GATE" if WALK_LENGTH_IS_GATE else "INFORMATIONAL"}', flush=True)

    def test_calibration_tolerance(self):
        self.assertTrue(within_tolerance(59, 50))
        self.assertFalse(within_tolerance(61, 50))
        self.assertTrue(within_tolerance(220, 200))
        self.assertFalse(within_tolerance(221, 200))
        self.assertFalse(within_tolerance(math.inf, 200))

    def test_clearance_around_rotated_obstacle(self):
        floor = Part('floor', 'Part', (0, -.5, 0), IDENTITY, (20, 1, 20), 1, True, ())
        c = math.sqrt(.5)
        yaw = ((c, 0, c), (0, 1, 0), (-c, 0, c))
        obstacle = Part('obstacle', 'Part', (0, 5, 0), yaw, (2, 10, 2), 1, True, ())
        nav = Heightfield([floor, obstacle])
        # Outside the rotated part's footprint, but within radius two of it.
        self.assertIsNone(obstacle.interval(2, 0))
        self.assertNotIn(0, nav.floors[(2, 0)])
        self.assertIn(0, nav.floors[(4, 0)])

    def test_jump_cost_and_directed_edges(self):
        self.assertTrue(Heightfield.allowed((0, 0, 0), (1, 0, 7.2)))
        self.assertFalse(Heightfield.allowed((0, 0, 0), (1, 0, 7.3)))
        self.assertTrue(Heightfield.allowed((0, 0, 100), (1, 0, 0)))
        self.assertEqual(Heightfield.edge_cost((0, 0, 0), (1, 1, 7)), math.sqrt(2))
        self.assertAlmostEqual(Heightfield.edge_cost((0, 0, 0), (1, 0, .5)), math.sqrt(1.25))


if __name__ == '__main__':
    if '--calibrate' in sys.argv:
        parser = argparse.ArgumentParser()
        parser.add_argument('--calibrate', action='store_true')
        parser.parse_args()
        sys.exit(0 if calibrate() else 1)
    unittest.main()
