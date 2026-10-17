"""Tests for scripts/evidence.py (needs ffmpeg). Run: python3 -m unittest discover -s tests"""

import contextlib
import io
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "scripts"))
import evidence  # noqa: E402


@unittest.skipUnless(shutil.which("ffmpeg") and shutil.which("ffprobe"), "needs ffmpeg")
class EvidenceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.TemporaryDirectory()
        cls.dir = Path(cls.tmp.name)
        cls.video = cls.dir / "clip.mp4"
        # 4 s: 2 s of a colour pattern, then a hard cut to a different pattern
        subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-f", "lavfi", "-i", "color=c=red:s=160x120:d=2:r=10",
                        "-f", "lavfi", "-i", "color=c=blue:s=160x120:d=2:r=10", "-filter_complex", "[0][1]concat=n=2:v=1:a=0",
                        str(cls.video)], check=True)

    @classmethod
    def tearDownClass(cls):
        cls.tmp.cleanup()

    def setUp(self):
        self.root = Path(tempfile.mkdtemp(prefix="vault-"))
        self.out = Path(tempfile.mkdtemp(prefix="out-"))
        self.addCleanup(shutil.rmtree, self.root, True)
        self.addCleanup(shutil.rmtree, self.out, True)

    def run_cmd(self, *argv):
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf), contextlib.redirect_stderr(buf):
            code = evidence.main(["--root", str(self.root), *argv])
        return code, buf.getvalue()

    def test_frames_index_and_strip(self):
        code, out = self.run_cmd("frames", str(self.video), "--fps", "2", "--out", str(self.out / "f"))
        self.assertEqual(code, 0, out)
        frames = sorted((self.out / "f").glob("f_*.jpg"))
        self.assertEqual(len(frames), 8)
        self.assertIn("f_0003.jpg\t00:01.00", (self.out / "f" / "index.txt").read_text())
        code, out = self.run_cmd("strip", str(self.out / "f"), "--cols", "4", "--rows", "2", "--width", "80",
                                 "--out", str(self.out / "s"))
        self.assertEqual(code, 0, out)
        self.assertTrue((self.out / "s" / "strip_01.jpg").exists())
        self.assertIn("r2c4=00:03.50", out)

    def test_strip_pads_a_partial_last_sheet(self):
        self.run_cmd("frames", str(self.video), "--fps", "2", "--out", str(self.out / "f"))
        code, out = self.run_cmd("strip", str(self.out / "f"), "--cols", "3", "--rows", "2", "--width", "80",
                                 "--out", str(self.out / "s"))
        self.assertEqual(code, 0, out)
        self.assertTrue((self.out / "s" / "strip_02.jpg").exists())

    def test_beats_finds_the_cut(self):
        code, out = self.run_cmd("beats", str(self.video))
        self.assertEqual(code, 0)
        self.assertIn("00:02.00", out)

    def test_stats_and_sheet(self):
        self.run_cmd("frames", str(self.video), "--fps", "1", "--out", str(self.out / "f"))
        red, blue = self.out / "f" / "f_0001.jpg", self.out / "f" / "f_0004.jpg"
        code, out = self.run_cmd("stats", str(red), str(blue))
        self.assertEqual(code, 0, out)
        self.assertRegex(out, r"warm_pct=100")
        self.assertRegex(out, r"cool_pct=100")
        self.assertIn("not a pass/fail", out)
        code, out = self.run_cmd("sheet", str(red), str(blue), "--out", str(self.out / "pair.png"))
        self.assertEqual(code, 0, out)
        self.assertTrue((self.out / "pair.png").exists())

    def test_ref_id_resolves_to_archived_video(self):
        note = self.root / "10 References/04 Vfx/REF-VFX-009-T.md"
        note.parent.mkdir(parents=True)
        note.write_text("---\nid: REF-VFX-009\n---\n![[clip.mp4]]\n")
        media = self.root / "10 References/04 Vfx/Media/clip.mp4"
        media.parent.mkdir()
        shutil.copy(self.video, media)
        self.assertEqual(evidence.resolve_video(self.root, "REF-VFX-009"), media.resolve())
        with self.assertRaises(evidence.EvidenceError):
            evidence.resolve_video(self.root, "REF-VFX-010")

    def test_refuses_to_write_inside_the_vault(self):
        code, out = self.run_cmd("frames", str(self.video), "--out", str(self.root / "frames"))
        self.assertEqual(code, 1)
        self.assertIn("inside the vault", out)

    def test_bad_inputs(self):
        self.assertEqual(self.run_cmd("stats", "/no/such.png")[0], 1)
        self.assertEqual(self.run_cmd("strip", str(self.out))[0], 1)


if __name__ == "__main__":
    unittest.main()
