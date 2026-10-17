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

    def test_series_finds_mono_runs_and_flash_risk(self):
        video = self.dir / "strobe.mp4"
        # red 1 s, then 1 s alternating white/black every frame (a strobe), then red
        subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-f", "lavfi", "-i", "color=c=red:s=64x64:d=1:r=10",
                        "-f", "lavfi", "-i", "nullsrc=s=64x64:d=1:r=10,format=gray,geq=lum='if(lt(mod(N,2),1),255,0)',format=rgb24",
                        "-f", "lavfi", "-i", "color=c=red:s=64x64:d=1:r=10",
                        "-filter_complex", "[0][1][2]concat=n=3:v=1:a=0", str(video)], check=True)
        code, out = self.run_cmd("series", str(video), "--fps", "10")
        self.assertEqual(code, 0, out)
        self.assertIn("near-grayscale runs", out)
        self.assertIn("00:01.00", out)
        n = int(out.split("worst 1 s window starts")[1].split("with")[1].split()[0])
        self.assertGreaterEqual(n, 6)
        self.assertIn("not a conformance", out)

    def test_series_helpers(self):
        rows = [{"t": i / 10, "rel_lum": v, "sat": s, "luma": 0} for i, (v, s) in enumerate(
            [(0.2, 0.9), (0.9, 0.0), (0.9, 0.0), (0.2, 0.9)])]
        self.assertEqual(evidence.mono_runs(rows), [(0.1, 2)])
        self.assertEqual(evidence.luminance_transitions(rows), [0.1, 0.3])
        self.assertEqual(evidence.worst_window([0.1, 0.3, 2.0]), (2, 0.1))

    def test_audio_envelope(self):
        clip = self.dir / "tone.mp4"
        subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-f", "lavfi", "-i", "color=c=gray:s=64x64:d=2:r=10",
                        "-f", "lavfi", "-i", "aevalsrc='if(gt(t,1),0.5*sin(2*PI*440*t),0)':d=2:s=8000",
                        "-shortest", "-c:a", "aac", str(clip)], check=True)
        code, out = self.run_cmd("audio", str(clip))
        self.assertEqual(code, 0, out)
        self.assertIn("windows below -50 dBFS: 00:00.00", out)
        self.assertRegex(out, r"onsets .*: 00:0[01]\.[0-9]+|onsets .*: 00:01")
        no_audio = self.dir / "mute.mp4"
        subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", str(self.video), "-an", str(no_audio)], check=True)
        self.assertEqual(self.run_cmd("audio", str(no_audio))[0], 1)

    def make_png(self, name, color, size="120x60", alpha_box=False):
        path = self.dir / name
        vf = "format=rgba" if not alpha_box else "format=rgba,geq=r='r(X,Y)':g='g(X,Y)':b='b(X,Y)':a='if(between(X,30,90)*between(Y,15,45),255,0)'"
        subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-f", "lavfi", "-i", f"color=c={color}:s={size}:d=1",
                        "-vf", vf, "-frames:v", "1", str(path)], check=True)
        return path

    def test_matrix_builds_dark_and_light_sheets(self):
        a, b = self.make_png("a.png", "red"), self.make_png("b.png", "blue", "100x100")
        code, out = self.run_cmd("matrix", str(a), str(b), "--widths", "40,80", "--out", str(self.out / "m"))
        self.assertEqual(code, 0, out)
        self.assertIn("columns left to right: a.png, b.png", out)
        for name in ("matrix_dark.png", "matrix_light.png"):
            self.assertTrue((self.out / "m" / name).exists())
        self.assertEqual(list((self.out / "m").glob("cell_*")), [])  # temporary cells are removed
        self.assertEqual(self.run_cmd("matrix", "/no/such.png")[0], 1)

    def test_silhouette_luma_and_alpha_modes(self):
        bright = self.make_png("bright.png", "white")
        dark = self.make_png("dark.png", "black")
        code, out = self.run_cmd("silhouette", str(bright), str(dark), "--height", "60", "--out", str(self.out / "s.png"))
        self.assertEqual(code, 0, out)
        self.assertTrue((self.out / "s.png").exists())
        boxed = self.make_png("boxed.png", "black", alpha_box=True)
        code, out = self.run_cmd("silhouette", str(boxed), "--mode", "alpha", "--height", "60", "--out", str(self.out / "alpha.png"))
        self.assertEqual(code, 0, out)
        px = evidence.pixels(self.out / "alpha.png", None)
        white = sum(1 for p in px if p[0] > 200)
        self.assertGreater(white, 200)
        self.assertLess(white, len(px) - 200)  # a white shape on black, not all white or all black
        code, out = self.run_cmd("silhouette", str(self.video), "--at", "0.5", "--height", "40", "--out", str(self.out / "v.png"))
        self.assertEqual(code, 0, out)
        self.assertEqual(self.run_cmd("silhouette", str(self.out / "gone.png"))[0], 1)
        inside = self.root / "inside.png"
        self.assertEqual(self.run_cmd("silhouette", str(bright), "--out", str(inside))[0], 1)

    def test_series_gate_passes_calm_and_fails_strobe(self):
        calm = self.run_cmd("series", str(self.video), "--fps", "10", "--max-transitions", "6")
        self.assertEqual(calm[0], 0, calm[1])
        self.assertIn("PASS", calm[1])
        strobe = self.dir / "strobe2.mp4"
        subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-f", "lavfi", "-i",
                        "nullsrc=s=64x64:d=2:r=10,format=gray,geq=lum='if(lt(mod(N,2),1),255,0)',format=rgb24", str(strobe)], check=True)
        code, out = self.run_cmd("series", str(strobe), "--fps", "10", "--max-transitions", "6")
        self.assertEqual(code, 1, out)
        self.assertIn("FAIL", out)

    def test_bad_inputs(self):
        self.assertEqual(self.run_cmd("stats", "/no/such.png")[0], 1)
        self.assertEqual(self.run_cmd("strip", str(self.out))[0], 1)


if __name__ == "__main__":
    unittest.main()
