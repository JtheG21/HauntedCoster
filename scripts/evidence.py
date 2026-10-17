#!/usr/bin/env python3
"""Evidence tooling for visual and motion references (ffmpeg only; no Pillow, numpy or drawtext needed).

  evidence.py frames  <video|REF-ID> [--start S] [--end S] [--fps 4] [--out DIR]
  evidence.py strip   <frames-dir> [--cols 4] [--rows 3] [--width 480] [--out DIR]
  evidence.py beats   <video|REF-ID> [--threshold 0.3]
  evidence.py sheet   <left.png> <right.png> [--height 540] [--out FILE]
  evidence.py stats   <image|video> [<image|video> ...] [--at SECONDS]
  evidence.py series  <video|REF-ID> [--fps 30] [--start S] [--end S] [--csv FILE]   per-frame luminance/saturation, mono runs, flash risk
  evidence.py audio   <video|REF-ID> [--window 0.1]   loudness envelope, silence and onset times
  evidence.py matrix  <img> [<img> ...] [--widths 90,180,340] [--out DIR]   same inputs at real display widths on dark and light
  evidence.py silhouette <img|video> [...] [--at S] [--mode luma|alpha] [--threshold 128] [--out FILE]   black/white shape sheet
  (series also takes --max-transitions N: exit 1 if the worst second has more, so a task can gate on it)

`<video|REF-ID>` is a file path or a REF note id; an id resolves to the first archived .mp4 the note embeds.
Outputs go to a fresh temp directory (printed), never into the vault. Frames are named f_0001.jpg ...
and `index.txt` maps each to its source timestamp, because ffmpeg here has no drawtext to burn labels in.
These are aids for jg's judgement, not pass/fail tests: promotional grading, crops and sparse sampling
change the numbers (see each REF note's evidence limits).
Exit codes: 0 ok, 1 ffmpeg failed or nothing found, 2 usage error.
"""

from __future__ import annotations

import argparse
import array
import math
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


def rel_luminance(r: int, g: int, b: int) -> float:
    lin = [((c / 255) ** 2.2) for c in (r, g, b)]
    return 0.2126 * lin[0] + 0.7152 * lin[1] + 0.0722 * lin[2]


def saturation(r: int, g: int, b: int) -> float:
    mx, mn = max(r, g, b), min(r, g, b)
    return 0.0 if mx == 0 else (mx - mn) / mx


def frame_series(video: Path, fps: float, start: float, end: float | None) -> list[dict]:
    args = ["ffmpeg", "-hide_banner", "-loglevel", "error", "-ss", str(start)]
    if end is not None:
        args += ["-to", str(end)]
    args += ["-i", str(video), "-vf", f"fps={fps},scale=32:32", "-f", "rawvideo", "-pix_fmt", "rgb24", "-"]
    r = subprocess.run(args, capture_output=True)
    size = 32 * 32 * 3
    if r.returncode != 0 or len(r.stdout) < size:
        raise EvidenceError(f"could not read frames: {r.stderr.decode()[:200]}")
    rows = []
    for i in range(len(r.stdout) // size):
        d = r.stdout[i * size:(i + 1) * size]
        px = [(d[j], d[j + 1], d[j + 2]) for j in range(0, size, 3)]
        n = len(px)
        rows.append({"t": start + i / fps,
                     "rel_lum": sum(rel_luminance(*p) for p in px) / n,
                     "sat": sum(saturation(*p) for p in px) / n,
                     "luma": sum(0.299 * p[0] + 0.587 * p[1] + 0.114 * p[2] for p in px) / n})
    return rows


def mono_runs(rows: list[dict], sat_max: float = 0.06) -> list[tuple[float, int]]:
    """Runs of near-grayscale frames: (start time, length in frames)."""
    runs, cur = [], None
    for i, r in enumerate(rows):
        if r["sat"] <= sat_max:
            cur = cur or [r["t"], 0]
            cur[1] += 1
        elif cur:
            runs.append((cur[0], cur[1]))
            cur = None
    if cur:
        runs.append((cur[0], cur[1]))
    return runs


def luminance_transitions(rows: list[dict], delta: float = 0.10, dark_max: float = 0.80) -> list[float]:
    """Times where whole-frame relative luminance changes by >= delta between frames (darker side < dark_max)."""
    out = []
    for a, b in zip(rows, rows[1:]):
        if abs(b["rel_lum"] - a["rel_lum"]) >= delta and min(a["rel_lum"], b["rel_lum"]) < dark_max:
            out.append(b["t"])
    return out


def worst_window(times: list[float], width: float = 1.0) -> tuple[int, float]:
    best, at = 0, 0.0
    for t0 in times:
        n = sum(1 for t in times if t0 <= t < t0 + width)
        if n > best:
            best, at = n, t0
    return best, at


def cmd_series(root: Path, src: str, fps: float, start: float, end: float | None, csv: str | None,
               max_transitions: int | None = None) -> int:
    video = resolve_video(root, src)
    rows = frame_series(video, fps, start, end)
    if csv:
        dest = Path(csv).resolve()
        try:
            dest.relative_to(root.resolve())
            raise EvidenceError(f"refusing to write evidence output inside the vault: {dest}")
        except ValueError:
            pass
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_text("t,rel_lum,sat,luma\n" + "".join(
            f"{r['t']:.3f},{r['rel_lum']:.4f},{r['sat']:.4f},{r['luma']:.1f}\n" for r in rows))
    print(f"{video.name}: {len(rows)} frames at {fps} fps from {fmt_t(start)}")
    runs = mono_runs(rows)
    print("near-grayscale runs (start, frames, ms): " + (
        ", ".join(f"{fmt_t(s)} x{n} ({round(1000 * n / fps)} ms)" for s, n in runs) or "none"))
    trans = luminance_transitions(rows)
    n, at = worst_window(trans)
    print(f"luminance transitions >= 10% of full scale: {len(trans)} total; worst 1 s window starts {fmt_t(at)} with {n}")
    print("heuristic only: whole-frame mean at 32x32, not the area-based WCAG flash test and not a conformance "
          "result; more than 6 transitions in one second (about 3 flashes) means look at it with a proper tool.")
    if max_transitions is not None:
        ok = n <= max_transitions
        print(f"{'PASS' if ok else 'FAIL'}: worst second has {n} large luminance transitions (limit {max_transitions})")
        return 0 if ok else 1
    return 0


def cmd_audio(root: Path, src: str, window: float) -> int:
    video = resolve_video(root, src)
    r = subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-i", str(video), "-vn", "-ac", "1",
                        "-ar", "8000", "-f", "s16le", "-"], capture_output=True)
    if r.returncode != 0 or not r.stdout:
        raise EvidenceError(f"no readable audio track: {r.stderr.decode()[:200]}")
    samples = array.array("h")
    samples.frombytes(r.stdout[: len(r.stdout) // 2 * 2])
    step = int(8000 * window)
    db = []
    for i in range(0, len(samples) - step + 1, step):
        chunk = samples[i:i + step]
        rms = math.sqrt(sum(x * x for x in chunk) / len(chunk)) / 32768
        db.append(20 * math.log10(rms) if rms > 0 else -120.0)
    per_sec = int(round(1 / window))
    print(f"{video.name}: {len(db)} windows of {window}s; peak {max(db):.1f} dBFS (RMS per window), "
          f"median {sorted(db)[len(db) // 2]:.1f} dBFS")
    print("RMS dBFS per second (max of each second): " + ", ".join(
        f"{i // per_sec}s={max(db[i:i + per_sec]):.0f}" for i in range(0, len(db), per_sec)))
    quiet, cur = [], None
    for i, v in enumerate(db):
        if v < -50:
            cur = cur if cur is not None else i
        elif cur is not None:
            quiet.append((cur * window, i * window))
            cur = None
    if cur is not None:
        quiet.append((cur * window, len(db) * window))
    print("windows below -50 dBFS: " + (", ".join(f"{fmt_t(a)}-{fmt_t(b)}" for a, b in quiet) or "none"))
    onsets = [round(i * window, 2) for i in range(1, len(db)) if db[i] > -35 and db[i] - db[i - 1] >= 6]
    print("onsets (rise of 6 dB or more into a window above -35 dBFS): " + (", ".join(fmt_t(t) for t in onsets) or "none"))
    print("These describe level over time only; they do not say what the sound is or how good it is.")
    return 0


def media_size(path: Path) -> tuple[int, int]:
    r = subprocess.run(["ffprobe", "-v", "error", "-select_streams", "v:0", "-show_entries", "stream=width,height",
                        "-of", "csv=p=0", str(path)], capture_output=True, text=True)
    try:
        w, h = r.stdout.strip().split(",")[:2]
        return int(w), int(h)
    except ValueError:
        raise EvidenceError(f"cannot read size of {path}")


def cmd_matrix(root: Path, inputs: list[str], widths: list[int], out: str | None) -> int:
    paths = [Path(i) for i in inputs]
    for p in paths:
        if not p.exists():
            raise EvidenceError(f"no such image: {p}")
    d = out_dir(root, out, "matrix")
    aspect = max(media_size(p)[1] / media_size(p)[0] for p in paths)
    cell_w = max(widths) + 20
    for name, bg in (("dark", "0x1b1b24"), ("light", "0xd9d2c3")):
        rows = []
        for w in widths:
            h = max(40, int(round(w * aspect)) + 20)
            cells = []
            for i, p in enumerate(paths):
                cell = d / f"cell_{name}_{w}_{i}.png"
                fc = (f"color=c={bg}:s={cell_w}x{h}[bg];[0:v]scale={w}:-2:flags=lanczos[img];"
                      "[bg][img]overlay=(main_w-overlay_w)/2:(main_h-overlay_h)/2")
                r = ffmpeg("-i", str(p), "-filter_complex", fc, "-frames:v", "1", str(cell))
                if r.returncode != 0:
                    raise EvidenceError(f"ffmpeg cell failed for {p.name}: {r.stderr.strip()[:200]}")
                cells.append(cell)
            row = d / f"row_{name}_{w}.png"
            args = []
            for c in cells:
                args += ["-i", str(c)]
            r = ffmpeg(*args, "-filter_complex", f"hstack=inputs={len(cells)}" if len(cells) > 1 else "null",
                       "-frames:v", "1", str(row))
            if r.returncode != 0:
                raise EvidenceError(f"ffmpeg row failed: {r.stderr.strip()[:200]}")
            rows.append(row)
        args = []
        for r_ in rows:
            args += ["-i", str(r_)]
        r = ffmpeg(*args, "-filter_complex", f"vstack=inputs={len(rows)}" if len(rows) > 1 else "null",
                   "-frames:v", "1", str(d / f"matrix_{name}.png"))
        if r.returncode != 0:
            raise EvidenceError(f"ffmpeg stack failed: {r.stderr.strip()[:200]}")
        for tmp in list(d.glob(f"cell_{name}_*.png")) + list(d.glob(f"row_{name}_*.png")):
            tmp.unlink()
    print("columns left to right: " + ", ".join(p.name for p in paths))
    print(f"rows top to bottom: display widths {', '.join(str(w) for w in widths)} px")
    print(f"matrix_dark.png and matrix_light.png -> {d}")
    return 0


def cmd_silhouette(root: Path, inputs: list[str], at: float | None, mode: str, threshold: int,
                   height: int, out: str | None) -> int:
    for f in inputs:
        if not Path(f).exists():
            raise EvidenceError(f"no such file: {f}")
    dest = Path(out).resolve() if out else out_dir(root, None, "silhouette") / "silhouette.png"
    try:
        dest.relative_to(root.resolve())
        raise EvidenceError(f"refusing to write evidence output inside the vault: {dest}")
    except ValueError:
        pass
    dest.parent.mkdir(parents=True, exist_ok=True)
    tmp = Path(tempfile.mkdtemp(prefix="sil-"))
    pieces = []
    for i, f in enumerate(inputs):
        piece = tmp / f"s{i}.png"
        if mode == "alpha":
            vf = f"scale=-2:{height},format=rgba,alphaextract,format=gray,lutyuv=y='if(gt(val,{threshold}),255,0)'"
        else:
            vf = f"scale=-2:{height},format=gray,lutyuv=y='if(gt(val,{threshold}),255,0)'"
        args = (["-ss", str(at)] if at is not None else []) + ["-i", f, "-vf", vf, "-frames:v", "1", str(piece)]
        r = ffmpeg(*args)
        if r.returncode != 0 or not piece.exists():
            raise EvidenceError(f"silhouette failed for {f}: {r.stderr.strip()[:200]}")
        pieces.append(piece)
    args = []
    for pc in pieces:
        args += ["-i", str(pc)]
    r = ffmpeg(*args, "-filter_complex", f"hstack=inputs={len(pieces)}" if len(pieces) > 1 else "null",
               "-frames:v", "1", str(dest))
    shutil.rmtree(tmp, ignore_errors=True)
    if r.returncode != 0:
        raise EvidenceError(f"ffmpeg stack failed: {r.stderr.strip()[:200]}")
    print("left to right: " + ", ".join(Path(f).name for f in inputs) + f"; mode={mode}, threshold={threshold} -> {dest}")
    print("a shape aid for jg's judgement of readability, not a pass/fail")
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
    se = sub.add_parser("series")
    se.add_argument("src"); se.add_argument("--fps", type=float, default=30.0); se.add_argument("--start", type=float, default=0.0)
    se.add_argument("--end", type=float); se.add_argument("--csv"); se.add_argument("--max-transitions", type=int)
    au = sub.add_parser("audio")
    au.add_argument("src"); au.add_argument("--window", type=float, default=0.1)
    mx = sub.add_parser("matrix")
    mx.add_argument("inputs", nargs="+"); mx.add_argument("--widths", default="90,180,340"); mx.add_argument("--out")
    si = sub.add_parser("silhouette")
    si.add_argument("inputs", nargs="+"); si.add_argument("--at", type=float); si.add_argument("--mode", choices=["luma", "alpha"], default="luma")
    si.add_argument("--threshold", type=int, default=128); si.add_argument("--height", type=int, default=540); si.add_argument("--out")
    a = ap.parse_args(argv)
    root = a.root.resolve()
    try:
        if a.cmd == "matrix":
            return cmd_matrix(root, a.inputs, [int(w) for w in a.widths.split(",") if w.strip()], a.out)
        if a.cmd == "silhouette":
            return cmd_silhouette(root, a.inputs, a.at, a.mode, a.threshold, a.height, a.out)
        if a.cmd == "series":
            return cmd_series(root, a.src, a.fps, a.start, a.end, a.csv, a.max_transitions)
        if a.cmd == "audio":
            return cmd_audio(root, a.src, a.window)
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
