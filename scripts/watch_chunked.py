#!/usr/bin/env python3
"""Run the /watch skill's Gemini engine over a long video in short segments, with retries.

Why: whole-video Gemini requests for long videos return HTTP 503 ("high demand") far more often than
short clips do, even while short requests succeed (2026-10-14, 27-minute YouTube video). Splitting the
video into 2-5 minute segments and retrying each one gets every segment through.

    python3 scripts/watch_chunked.py <URL-or-path> [--question TEXT] [--segment 300]
        [--start 0:00] [--end 27:38] [--retries 4] [--sleep 20] [--model ID] [--out DIR]

Behavior:
- Always passes --engine gemini. There is NO silent fallback to the local engine: segments that still
  fail are listed in the report so you can decide (rerun later, or `watch.py --engine local`).
- A segment that exhausts its retries is split in half once and each half is retried.
- 503 and per-minute 429s are retried. A *daily* quota 429 stops the whole run (every further request
  would fail and count). Anything else Gemini rejects (400, 404, missing key) is not retried.
- The free tier has a small daily request limit per model (20/day for gemini-3.7-flash on 2026-10-14),
  and every retry is a request. Prefer fewer, longer segments (--segment 300) and --retries 3.
- Output goes to --out (default: a new temp dir), never into the vault. `report.md` there is the
  combined, timestamped answer. Paths are printed to stdout; the API key is never read or printed here.
- Gemini output is secondary evidence. Segments can contradict each other: read the report critically.

Exit codes: 0 all segments answered, 3 some segments failed, 1 nothing answered, 2 usage/setup error.
"""
from __future__ import annotations

import argparse
import glob
import json
import os
import re
import subprocess
import sys
import tempfile
import time
from pathlib import Path

DEFAULT_QUESTION = (
    "Summarize this segment with timestamps. List each concrete UI design rule the speaker states, and "
    "for each on-screen example say which game/screen it is, whether the speaker calls it good or bad, "
    "and why. Note fonts, palettes, icon use, layout and placement. Say when something is not visible."
)
ANSWER_HEADER = "## Answer (from Gemini)"
MIN_TAIL = 30  # a trailing segment shorter than this is merged into the previous one
MIN_SPLIT = 90  # failed segments shorter than this are not split further


def parse_ts(text: str) -> int:
    """'90', '1:30' or '1:02:03' -> seconds."""
    parts = [int(p) for p in text.strip().split(":")]
    if not 1 <= len(parts) <= 3 or any(p < 0 for p in parts):
        raise ValueError(f"bad timestamp: {text!r}")
    total = 0
    for p in parts:
        total = total * 60 + p
    return total


def fmt_ts(seconds: int) -> str:
    h, rem = divmod(int(seconds), 3600)
    m, s = divmod(rem, 60)
    return f"{h}:{m:02d}:{s:02d}" if h else f"{m}:{s:02d}"


def plan_segments(start: int, end: int, size: int) -> list[tuple[int, int]]:
    """Cut [start, end) into pieces of at most `size` seconds; fold a tiny tail into the last piece."""
    if end <= start:
        raise ValueError("end must be after start")
    if size <= 0:
        raise ValueError("segment size must be positive")
    segs: list[tuple[int, int]] = []
    cur = start
    while cur < end:
        nxt = min(cur + size, end)
        segs.append((cur, nxt))
        cur = nxt
    if len(segs) > 1 and segs[-1][1] - segs[-1][0] < MIN_TAIL:
        last = segs.pop()
        segs[-1] = (segs[-1][0], last[1])
    return segs


def classify(output: str) -> str:
    """'ok' | 'retry' | 'quota' (daily limit, stop) | 'fatal' for one watch.py run's output."""
    if ANSWER_HEADER in output:
        return "ok"
    if re.search(r"HTTP 429\b", output) and re.search(r"per day|PerDay|daily", output, re.I):
        return "quota"
    if re.search(r"HTTP (503|429)\b", output) or "Gemini service:" in output:
        return "retry"
    return "fatal"


def extract_answer(output: str) -> str:
    """The answer body from a watch.py report, without Gemini's provenance boilerplate."""
    if ANSWER_HEADER not in output:
        return ""
    body = output.split(ANSWER_HEADER, 1)[1]
    body = re.split(r"\n## ", body, maxsplit=1)[0]
    lines = [ln for ln in body.strip().splitlines()
             if not ln.startswith(("_These are Gemini's observations", "[watch]"))]
    return "\n".join(lines).strip()


def find_watch_script() -> Path | None:
    override = os.environ.get("WATCH_SCRIPT")
    if override:
        return Path(override)
    pattern = str(Path.home() / ".claude/plugins/cache/*/watch/*/skills/watch/scripts/watch.py")
    matches = sorted(glob.glob(pattern))
    return Path(matches[-1]) if matches else None


def probe_duration(source: str) -> int | None:
    """Duration in seconds via yt-dlp (URLs) or ffprobe (local files); None if neither can tell."""
    cmds = []
    if re.match(r"https?://", source):
        cmds.append(["yt-dlp", "--skip-download", "--no-warnings", "--print", "duration", source])
    else:
        cmds.append(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of",
                     "default=nw=1:nk=1", source])
    for cmd in cmds:
        try:
            out = subprocess.run(cmd, capture_output=True, text=True, timeout=120).stdout.strip()
            return int(float(out.splitlines()[-1]))
        except (OSError, ValueError, IndexError, subprocess.TimeoutExpired):
            continue
    return None


def run_watch(watch: Path, source: str, question: str, span: tuple[int, int], model: str | None) -> str:
    env = dict(os.environ)
    if model:
        env["WATCH_GEMINI_MODEL"] = model
    cmd = [sys.executable, str(watch), source, "--engine", "gemini", "--start", fmt_ts(span[0]),
           "--end", fmt_ts(span[1]), "--question", question]
    proc = subprocess.run(cmd, capture_output=True, text=True, env=env)
    return (proc.stdout or "") + (proc.stderr or "")


def answer_span(watch: Path, source: str, question: str, span: tuple[int, int], *, retries: int,
                pause: float, model: str | None, out: Path, depth: int = 0) -> list[dict]:
    """Return result dicts (one per final segment) for `span`, splitting once on exhausted retries."""
    label = f"{fmt_ts(span[0])}-{fmt_ts(span[1])}"
    last_kind, last_text = "fatal", ""
    for attempt in range(1, retries + 1):
        text = run_watch(watch, source, question, span, model)
        kind = classify(text)
        last_kind, last_text = kind, text
        print(f"[chunked] {label} attempt {attempt}/{retries}: {kind}", file=sys.stderr)
        if kind == "ok":
            raw = out / f"seg-{span[0]:05d}-{span[1]:05d}.md"
            raw.write_text(text, encoding="utf8")
            return [{"span": span, "ok": True, "answer": extract_answer(text), "attempts": attempt}]
        if kind in ("fatal", "quota"):
            break
        if attempt < retries:
            time.sleep(pause)
    if last_kind == "retry" and depth == 0 and span[1] - span[0] >= MIN_SPLIT * 2:
        mid = span[0] + (span[1] - span[0]) // 2
        print(f"[chunked] {label} still failing; splitting at {fmt_ts(mid)}", file=sys.stderr)
        results: list[dict] = []
        for half in ((span[0], mid), (mid, span[1])):
            results += answer_span(watch, source, question, half, retries=retries, pause=pause,
                                   model=model, out=out, depth=1)
        return results
    reason = next((ln.strip("- ").strip() for ln in last_text.splitlines()
                   if ln.strip().startswith("- Gemini")), last_kind)
    return [{"span": span, "ok": False, "reason": reason[:300], "attempts": attempt,
             "quota": last_kind == "quota"}]


def build_report(source: str, question: str, results: list[dict], model: str | None) -> str:
    done = [r for r in results if r["ok"]]
    failed = [r for r in results if not r["ok"]]
    lines = [
        "# watch_chunked report",
        "",
        f"- **Source:** {source}",
        f"- **Engine:** gemini{' (' + model + ')' if model else ''}, segmented",
        f"- **Segments:** {len(done)} answered, {len(failed)} failed",
        f"- **Question:** {question}",
        "",
        "> Gemini's reading of the video, segment by segment. Segments are independent and can contradict",
        "> each other. This is secondary evidence, not our own viewing of the frames.",
        "",
    ]
    for r in sorted(results, key=lambda r: r["span"]):
        lines.append(f"## {fmt_ts(r['span'][0])} - {fmt_ts(r['span'][1])}")
        lines.append("")
        lines.append(r["answer"] if r["ok"] else f"**FAILED after {r['attempts']} attempts:** {r['reason']}")
        lines.append("")
    if failed:
        spans = ", ".join(f"{fmt_ts(r['span'][0])}-{fmt_ts(r['span'][1])}" for r in failed)
        lines += ["## Failed segments", "", f"{spans}. Rerun later with `--start/--end`, or decide whether "
                  "to use `watch.py --engine local` for them. No fallback was attempted.", ""]
    return "\n".join(lines)


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("source", help="video URL or local path")
    ap.add_argument("--question", default=DEFAULT_QUESTION)
    ap.add_argument("--segment", type=int, default=300, help="segment length in seconds (default 300)")
    ap.add_argument("--start", default="0:00")
    ap.add_argument("--end", help="end time; default is the video's duration (probed with yt-dlp/ffprobe)")
    ap.add_argument("--retries", type=int, default=3, help="attempts per segment (default 3)")
    ap.add_argument("--sleep", type=float, default=20.0, help="seconds between retries (default 20)")
    ap.add_argument("--model", help="sets WATCH_GEMINI_MODEL for this run")
    ap.add_argument("--out", help="output directory (default: new temp dir)")
    ap.add_argument("--dry-run", action="store_true", help="print the segment plan and exit")
    args = ap.parse_args(argv)

    try:
        start = parse_ts(args.start)
        end = parse_ts(args.end) if args.end else probe_duration(args.source)
    except ValueError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2
    if end is None:
        print("error: could not determine the duration; pass --end", file=sys.stderr)
        return 2
    try:
        segs = plan_segments(start, end, args.segment)
    except ValueError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2
    if args.dry_run:
        print(json.dumps([[fmt_ts(a), fmt_ts(b)] for a, b in segs]))
        return 0

    watch = find_watch_script()
    if not watch or not watch.is_file():
        print("error: watch.py not found. Install the watch plugin or set WATCH_SCRIPT.", file=sys.stderr)
        return 2
    out = Path(args.out) if args.out else Path(tempfile.mkdtemp(prefix="watch-chunked-"))
    out.mkdir(parents=True, exist_ok=True)

    results: list[dict] = []
    for i, span in enumerate(segs):
        got = answer_span(watch, args.source, args.question, span, retries=args.retries,
                          pause=args.sleep, model=args.model, out=out)
        results += got
        if any(r.get("quota") for r in got):
            print("[chunked] daily quota reached; stopping. Remaining segments were not attempted.",
                  file=sys.stderr)
            for rest in segs[i + 1:]:
                results.append({"span": rest, "ok": False, "attempts": 0, "quota": True,
                                "reason": "not attempted: daily quota reached earlier in this run"})
            break
    report = out / "report.md"
    report.write_text(build_report(args.source, args.question, results, args.model), encoding="utf8")
    ok = sum(1 for r in results if r["ok"])
    print(f"report: {report}")
    print(f"segments answered: {ok}/{len(results)}")
    if ok == len(results):
        return 0
    return 3 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
