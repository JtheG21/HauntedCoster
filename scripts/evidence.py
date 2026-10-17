#!/usr/bin/env python3
"""Evidence tooling for visual and motion references (ffmpeg only; no Pillow, numpy or drawtext needed).

  evidence.py frames  <video|REF-ID> [--start S] [--end S] [--fps 4] [--out DIR]
  evidence.py strip   <frames-dir> [--cols 4] [--rows 3] [--width 480] [--out DIR]
  evidence.py beats   <video|REF-ID> [--threshold 0.3]
  evidence.py sheet   <left.png> <right.png> [--height 540] [--out FILE]
  evidence.py stats   <image|video> [<image|video> ...] [--at SECONDS]

`<video|REF-ID>` is a file path or a REF note id; an id resolves to the first archived .mp4 the note embeds.
Outputs go to a fresh temp directory (printed), never into the vault. Frames are named f_0001.jpg ...
and `index.txt` maps each to its source timestamp, because ffmpeg here has no drawtext to burn labels in.
These are aids for jg's judgement, not pass/fail tests: promotional grading, crops and sparse sampling
change the numbers (see each REF note's evidence limits).
Exit codes: 0 ok, 1 ffmpeg failed or nothing found, 2 usage error.
"""

from __future__ import annotations

import argparse
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(Path(__file__).resolve().parent))
import refs  # noqa: E402


class EvidenceError(Exception):
    pass


def ffmpeg(*args: str) -> subprocess.CompletedProcess:
    if not shutil.which("ffmpeg"):
        raise EvidenceError("ffmpeg not found (brew install ffmpeg)")
    r = subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error" if "showinfo" not in " ".join(args) else "info",
                        "-y", *args], capture_output=True, text=True)
    return r


def resolve_video(root: Path, arg: str) -> Path:
    p = Path(arg)
    if p.exists():
        return p.resolve()
    if re.match(r"^REF-[A-Z]+-\d{3}$", arg):
        for note in refs.ref_notes(root):
            if refs.ref_id(note) == arg:
                for name in re.findall(r"!\[\[([^\]]+\.mp4)\]\]", note.read_text(encoding="utf-8")):
                    for hit in (root / refs.REF_DIR).rglob(name):
                        return hit.resolve()
                raise EvidenceError(f"{arg} embeds no archived .mp4 that exists on disk")
        raise EvidenceError(f"{arg} is not a REF note in {root}")
    raise EvidenceError(f"no such file or REF id: {arg}")


def out_dir(root: Path, requested: str | None, prefix: str) -> Path:
    d = Path(requested) if requested else Path(tempfile.mkdtemp(prefix=f"{prefix}-"))
    d = d.resolve()
    try:
        d.relative_to(root.resolve())
        raise EvidenceError(f"refusing to write evidence output inside the vault: {d}")
    except ValueError:
        pass
    d.mkdir(parents=True, exist_ok=True)
    return d


def fmt_t(seconds: float) -> str:
    m, s = divmod(seconds, 60)
    return f"{int(m):02d}:{s:05.2f}"


def cmd_frames(root: Path, src: str, start: float, end: float | None, fps: float, out: str | None) -> int:
    video = resolve_video(root, src)
    d = out_dir(root, out, "frames")
    args = ["-ss", str(start)]
    if end is not None:
        args += ["-to", str(end)]
    r = ffmpeg(*args, "-i", str(video), "-vf", f"fps={fps}", "-q:v", "3", str(d / "f_%04d.jpg"))
    files = sorted(d.glob("f_*.jpg"))
    if r.returncode != 0 or not files:
        raise EvidenceError(f"ffmpeg extracted no frames: {r.stderr.strip()[:300]}")
    lines = [f"{f.name}\t{fmt_t(start + i / fps)}" for i, f in enumerate(files)]
    (d / "index.txt").write_text("\n".join(lines) + "\n")
    print(f"{len(files)} frames from {video.name} -> {d}\nindex: {d / 'index.txt'}")
    return 0


def cmd_strip(root: Path, frames_dir: str, cols: int, rows: int, width: int, out: str | None) -> int:
    src = Path(frames_dir).resolve()
    files = sorted(src.glob("f_*.jpg"))
    if not files:
        raise EvidenceError(f"no f_*.jpg frames in {src} (run `frames` first)")
    d = out_dir(root, out, "strip")
    per = cols * rows
    index = {}
    idx = src / "index.txt"
    if idx.exists():
        index = dict(ln.split("\t") for ln in idx.read_text().splitlines() if "\t" in ln)
    sheets = 0
    for n in range(0, len(files), per):
        chunk = files[n:n + per]
        sheets += 1
        listing = d / f"list_{sheets:02d}.txt"
        # pad the last sheet by repeating its final frame so tile fills the grid
        padded = chunk + [chunk[-1]] * (per - len(chunk))
        listing.write_text("".join(f"file '{f}'\nduration 1\n" for f in padded) + f"file '{padded[-1]}'\n")
        r = ffmpeg("-f", "concat", "-safe", "0", "-i", str(listing), "-vf", f"scale={width}:-2,tile={cols}x{rows}",
                   "-frames:v", "1", "-q:v", "3", str(d / f"strip_{sheets:02d}.jpg"))
        if r.returncode != 0:
            raise EvidenceError(f"ffmpeg tile failed: {r.stderr.strip()[:300]}")
        listing.unlink()
        cells = [f"r{i // cols + 1}c{i % cols + 1}={index.get(f.name, f.name)}" for i, f in enumerate(chunk)]
        print(f"strip_{sheets:02d}.jpg (left to right, top to bottom): " + " ".join(cells))
    print(f"{sheets} sheet(s) -> {d}")
    return 0


def cmd_beats(root: Path, src: str, threshold: float) -> int:
    video = resolve_video(root, src)
    r = ffmpeg("-i", str(video), "-vf", f"select='gt(scene,{threshold})',showinfo", "-f", "null", "-")
    times = [float(t) for t in re.findall(r"pts_time:([0-9.]+)", r.stderr)]
    dur = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", str(video)],
                         capture_output=True, text=True).stdout.strip()
    print(f"{video.name}: duration {dur or '?'} s, scene-change threshold {threshold}")
    print("candidate beats (change points, not verified events): " + (", ".join(fmt_t(t) for t in times) or "none"))
    return 0


def cmd_sheet(root: Path, left: str, right: str, height: int, out: str | None) -> int:
    for f in (left, right):
        if not Path(f).exists():
            raise EvidenceError(f"no such image: {f}")
    dest = Path(out) if out else out_dir(root, None, "sheet") / "sheet.png"
    dest = dest.resolve()
    try:
        dest.relative_to(root.resolve())
        raise EvidenceError(f"refusing to write evidence output inside the vault: {dest}")
    except ValueError:
        pass
    dest.parent.mkdir(parents=True, exist_ok=True)
    r = ffmpeg("-i", left, "-i", right, "-filter_complex",
               f"[0:v]scale=-2:{height}[a];[1:v]scale=-2:{height}[b];[a][b]hstack", "-frames:v", "1", str(dest))
    if r.returncode != 0:
        raise EvidenceError(f"ffmpeg hstack failed: {r.stderr.strip()[:300]}")
    print(f"left={Path(left).name} | right={Path(right).name} -> {dest}")
    return 0


def pixels(path: Path, at: float | None) -> list[tuple[int, int, int]]:
    args = (["-ss", str(at)] if at is not None else []) + ["-i", str(path), "-frames:v", "1", "-vf", "scale=64:64",
                                                          "-f", "rawvideo", "-pix_fmt", "rgb24", "-"]
    if not shutil.which("ffmpeg"):
        raise EvidenceError("ffmpeg not found")
    r = subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", *args], capture_output=True)
    if r.returncode != 0 or len(r.stdout) < 64 * 64 * 3:
        raise EvidenceError(f"could not read pixels from {path}: {r.stderr.decode()[:200]}")
    d = r.stdout
    return [(d[i], d[i + 1], d[i + 2]) for i in range(0, 64 * 64 * 3, 3)]


def image_stats(px: list[tuple[int, int, int]]) -> dict:
    luma = sorted(int(0.299 * r + 0.587 * g + 0.114 * b) for r, g, b in px)
    n = len(px)
    bins: dict[tuple[int, int, int], int] = {}
    for r, g, b in px:
        k = (r >> 5, g >> 5, b >> 5)
        bins[k] = bins.get(k, 0) + 1
    top = sorted(bins.items(), key=lambda kv: -kv[1])[:6]
    return {
        "mean_luma": round(sum(luma) / n, 1),
        "p5_luma": luma[int(n * 0.05)],
        "p95_luma": luma[int(n * 0.95)],
        "clipped_highlights_pct": round(100 * sum(1 for v in luma if v >= 235) / n, 1),
        "crushed_shadows_pct": round(100 * sum(1 for v in luma if v <= 16) / n, 1),
        "warm_pct": round(100 * sum(1 for r, _, b in px if r > b + 20) / n, 1),
        "cool_pct": round(100 * sum(1 for r, _, b in px if b > r + 20) / n, 1),
        "palette": [f"#{(k[0] * 32 + 16):02x}{(k[1] * 32 + 16):02x}{(k[2] * 32 + 16):02x} {round(100 * c / n)}%" for k, c in top],
    }


def cmd_stats(root: Path, inputs: list[str], at: float | None) -> int:
    results = []
    for src in inputs:
        p = Path(src)
        if not p.exists():
            raise EvidenceError(f"no such file: {src}")
        results.append((p.name, image_stats(pixels(p, at))))
    for name, s in results:
        print(f"{name}: " + ", ".join(f"{k}={v}" for k, v in s.items() if k != "palette"))
        print("  palette: " + ", ".join(s["palette"]))
    if len(results) == 2:
        (_, a), (_, b) = results
        print("difference (second minus first; an aid for jg, not a pass/fail): "
              + ", ".join(f"{k}={round(b[k] - a[k], 1)}" for k in a if k != "palette"))
    return 0


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--root", type=Path, default=ROOT)
    sub = ap.add_subparsers(dest="cmd", required=True)
    f = sub.add_parser("frames")
    f.add_argument("src"); f.add_argument("--start", type=float, default=0.0); f.add_argument("--end", type=float)
    f.add_argument("--fps", type=float, default=4.0); f.add_argument("--out")
    s = sub.add_parser("strip")
    s.add_argument("frames_dir"); s.add_argument("--cols", type=int, default=4); s.add_argument("--rows", type=int, default=3)
    s.add_argument("--width", type=int, default=480); s.add_argument("--out")
    b = sub.add_parser("beats")
    b.add_argument("src"); b.add_argument("--threshold", type=float, default=0.3)
    sh = sub.add_parser("sheet")
    sh.add_argument("left"); sh.add_argument("right"); sh.add_argument("--height", type=int, default=540); sh.add_argument("--out")
    st = sub.add_parser("stats")
    st.add_argument("inputs", nargs="+"); st.add_argument("--at", type=float)
    a = ap.parse_args(argv)
    root = a.root.resolve()
    try:
        if a.cmd == "frames":
            return cmd_frames(root, a.src, a.start, a.end, a.fps, a.out)
        if a.cmd == "strip":
            return cmd_strip(root, a.frames_dir, a.cols, a.rows, a.width, a.out)
        if a.cmd == "beats":
            return cmd_beats(root, a.src, a.threshold)
        if a.cmd == "sheet":
            return cmd_sheet(root, a.left, a.right, a.height, a.out)
        return cmd_stats(root, a.inputs, a.at)
    except EvidenceError as e:
        print(f"evidence: {e}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
