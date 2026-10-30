"""HCM1 encoder round trip (art/hcart/codec.py). The Luau decoder has the twin spec
tests/MeshCodec.spec.luau, which embeds FIXTURE below."""

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from hcart import codec  # noqa: E402

FIXTURE = (
    "SENNMQQAAAACAAAAAQAAAAAAAAAAAADAvwAAAEAAAEBAAADAPwAAAAD/////AAD//////////wAA//8AAICA////gID//wAAAP8AAAD/"
    "ChQeAAAAAIABAAAAAQACwP+AAAAAAQACAAAAAgADAA=="
)
QUAD = dict(
    positions=[(0, 0, 0), (2, 0, 0), (2, 3, 0), (0, 3, -1.5)],
    normals=[(0, 0, 1), (0, 0, -1), (1, 0, 0), (0, 1, 0)],
    colors=[(255, 0, 0), (0, 255, 0), (0, 0, 255), (10, 20, 30)],
    faces=[(0, 1, 2), (0, 2, 3)],
    uvs=[(0, 0), (1.5, 0), (1, 2), (-0.25, 0.5)],
)


class CodecTest(unittest.TestCase):
    def test_fixture_matches_the_luau_spec(self):
        self.assertEqual(codec.to_text(codec.encode(**QUAD)), FIXTURE)

    def test_round_trip(self):
        d = codec.decode(codec.from_text(FIXTURE))
        self.assertEqual(d["faces"], [(0, 1, 2), (0, 2, 3)])
        for got, want in zip(d["positions"], QUAD["positions"]):
            for g, w in zip(got, want):
                self.assertAlmostEqual(g, w, places=3)
        for got, want in zip(d["normals"], QUAD["normals"]):
            for g, w in zip(got, want):
                self.assertAlmostEqual(g, w, delta=0.02)
        self.assertEqual(d["colors"], QUAD["colors"])
        self.assertEqual(d["uvs"], [(0, 0), (1.5, 0), (1, 2), (-0.25, 0.5)])

    def test_limits(self):
        with self.assertRaises(ValueError):
            codec.encode([], [], [], [])
        with self.assertRaises(ValueError):
            codec.encode(QUAD["positions"], QUAD["normals"], QUAD["colors"], [(0, 1, 9)])


if __name__ == "__main__":
    unittest.main()
