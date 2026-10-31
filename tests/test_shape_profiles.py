"""ShapeProfiles.luau must match the shard PNGs it's generated from."""

import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class ShapeProfiles(unittest.TestCase):
    def test_file_matches_the_pngs(self):
        r = subprocess.run([sys.executable, str(ROOT / "scripts" / "shape_profiles.py")], capture_output=True, text=True)
        self.assertEqual(r.returncode, 0, r.stderr)


if __name__ == "__main__":
    unittest.main()
