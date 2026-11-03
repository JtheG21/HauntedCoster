"""Hub walk gate; discovered automatically by scripts/check.sh.

Calibration is pending: do not treat this prototype as an approved replacement
for Studio pathfinding. Full failure messages retain route, length and cells.
"""
import math
from pathlib import Path
import sys
import time
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'scripts'))
from hub_nav import Heightfield, WALK_SPEED, load_parts


class HubWalkTest(unittest.TestCase):
    def test_routes(self):
        started = time.perf_counter()
        nav = Heightfield(load_parts())
        for route, (length, cells) in nav.routes():
            with self.subTest(route=route):
                detail = f'{route}: length={length:.2f} studs; time={length/WALK_SPEED:.3f}s; cells={cells}'
                self.assertTrue(math.isfinite(length), detail)
                if '->Pad_' in route:
                    self.assertGreaterEqual(length/WALK_SPEED, 8, detail)
                    self.assertLessEqual(length/WALK_SPEED, 12, detail)
        print(f'Hub walk test runtime: {time.perf_counter()-started:.3f}s')


if __name__ == '__main__':
    unittest.main()
