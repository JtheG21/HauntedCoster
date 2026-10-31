#!/usr/bin/env python3
"""Generates games/mathshow/src/shared/ShapeProfiles.luau from the shard PNG alpha channels (standard library only).

  python3 scripts/shape_profiles.py           report whether the file matches the PNGs (exit 1 if it doesn't)
  python3 scripts/shape_profiles.py --write   rewrite the profile rows, adding any shard PNG that has none

The format and meaning of a profile are described at the top of ShapeProfiles.luau.
"""

import argparse
import math
import re
import struct
import sys
import zlib
from pathlib import Path

GAME = Path(__file__).resolve().parents[1] / "games" / "mathshow"
TARGET = GAME / "src" / "shared" / "ShapeProfiles.luau"
ALPHA = 60
STEP = 4
FACTORS = {"shard-menu-problem-silver": 1.5}
ROW = re.compile(r'^P\["([^"]+)"\] = .*sliced = (true|false)', re.M)
# Identity shards are horizontal 9-slices (IdentityTheme.Slice), except the fixed-size intro card.
STRETCHED_IDENTITY = {"shard-id-intro-violet"}


def read_alpha(path: Path) -> tuple[int, int, list[bytes]]:
    """Alpha rows of an 8-bit, non-interlaced RGBA PNG."""
    data = path.read_bytes()
    pos, idat, w, h = 8, b"", 0, 0
    while pos < len(data):
        size, kind = struct.unpack(">I4s", data[pos : pos + 8])
        body = data[pos + 8 : pos + 8 + size]
        if kind == b"IHDR":
            w, h, depth, color, _, _, interlace = struct.unpack(">IIBBBBB", body)
            if (depth, color, interlace) != (8, 6, 0):
                raise ValueError(f"{path.name}: expected 8-bit non-interlaced RGBA")
        elif kind == b"IDAT":
            idat += body
        pos += 12 + size
    raw, rows, prev, i = zlib.decompress(idat), [], bytearray(w * 4), 0
    for _ in range(h):
        kind, cur = raw[i], bytearray(raw[i + 1 : i + 1 + w * 4])
        i += 1 + w * 4
        for x in range(w * 4):
            a = cur[x - 4] if x >= 4 else 0
            b = prev[x]
            c = prev[x - 4] if x >= 4 else 0
            if kind == 1:
                cur[x] = (cur[x] + a) & 255
            elif kind == 2:
                cur[x] = (cur[x] + b) & 255
            elif kind == 3:
                cur[x] = (cur[x] + (a + b) // 2) & 255
            elif kind == 4:
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                cur[x] = (cur[x] + (a if pa <= pb and pa <= pc else b if pb <= pc else c)) & 255
        rows.append(bytes(cur[3::4]))
        prev = cur
    return w, h, rows


def row(key: str, path: Path, sliced: bool) -> str:
    factor = FACTORS.get(key, 2)
    w, h, rows = read_alpha(path)
    canvas_w, canvas_h = int(w / factor), int(h / factor)
    left, right = [], []
    for band in range(math.ceil(h / factor / STEP)):
        lo, hi = -9999, 9999
        for y in range(int(band * STEP * factor), min(h, int((band + 1) * STEP * factor))):
            opaque = [x for x, alpha in enumerate(rows[y]) if alpha > ALPHA]
            if not opaque:
                lo, hi = 9999, -9999
                break
            lo, hi = max(lo, opaque[0]), min(hi, opaque[-1] + 1)
        left.append(9999 if lo == 9999 else math.ceil(lo / factor))
        if hi == -9999:
            right.append(-9999)
        else:
            right.append(canvas_w - math.floor(hi / factor) if sliced else math.floor(hi / factor))
    return (
        f'P["{key}"] = {{ w = {canvas_w}, h = {canvas_h}, step = {STEP}, sliced = {str(sliced).lower()}, '
        f"l = {{{','.join(map(str, left))}}}, r = {{{','.join(map(str, right))}}} }}"
    )


def generate(text: str) -> str:
    """`text` with its profile rows rebuilt. Existing rows keep their sliced flag."""
    sliced = {m[1]: m[2] == "true" for m in ROW.finditer(text)}
    pngs = {p.stem: p for p in sorted(GAME.glob("art/**/shard-*.png"))}
    for key in pngs:
        sliced.setdefault(key, key.startswith("shard-id-") and key not in STRETCHED_IDENTITY)
    missing = sorted(set(sliced) - set(pngs))
    if missing:
        raise ValueError(f"profiles with no PNG: {', '.join(missing)}")
    # dicts keep insertion order: existing rows stay where they are, and new shards follow them.
    rows = "\n".join(row(key, pngs[key], flag) for key, flag in sliced.items())
    return re.sub(r'^P\[".*(?:\n(?=P\[").*)*', lambda _: rows, text, count=1, flags=re.M)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--write", action="store_true")
    args = parser.parse_args()
    text = TARGET.read_text()
    want = generate(text)
    if want == text:
        print("shape profiles: up to date")
        return 0
    if args.write:
        TARGET.write_text(want)
        print(f"shape profiles: wrote {len(ROW.findall(want))} rows")
        return 0
    print("shape profiles: out of date, run scripts/shape_profiles.py --write", file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
