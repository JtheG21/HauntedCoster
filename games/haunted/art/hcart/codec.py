"""HCM1: the compact mesh format Haunted Collector ships for runtime EditableMesh art.

Pure Python (no bpy) so it is unit-tested by `python3 -m unittest` in scripts/check.sh. The Luau decoder is
`games/haunted/src/shared/Art/MeshCodec.luau`; both must change together (spec: tests/MeshCodec.spec.luau).

Layout, little-endian:
  b"HCM1"
  u32 vertex_count, u32 face_count, u8 flags (bit0 = has UVs)
  f32 x3 bbox min, f32 x3 bbox size            (Roblox space, studs)
  positions  vertex_count x 3 x u16            quantised across the bbox
  normals    vertex_count x 2 x u8             octahedral
  colors     vertex_count x 3 x u8             sRGB
  uvs        vertex_count x 2 x i16 (if flag)  value * 256
  faces      face_count x 3 x u16              vertex indices (triangles)
The whole buffer is base64 text so Rojo can carry it in a StringValue.
"""

from __future__ import annotations

import base64
import math
import struct

MAGIC = b"HCM1"
MAX_VERTS = 60000  # EditableMesh limit (creator-docs EditableMesh.yaml)
MAX_FACES = 20000
UV_SCALE = 256.0


def _clamp(v: float, lo: float, hi: float) -> float:
    return lo if v < lo else hi if v > hi else v


def oct_encode(n: tuple[float, float, float]) -> tuple[int, int]:
    x, y, z = n
    length = abs(x) + abs(y) + abs(z) or 1.0
    x, y, z = x / length, y / length, z / length
    if z < 0:
        x, y = (1 - abs(y)) * (1 if x >= 0 else -1), (1 - abs(x)) * (1 if y >= 0 else -1)
    return (round((_clamp(x, -1, 1) * 0.5 + 0.5) * 255), round((_clamp(y, -1, 1) * 0.5 + 0.5) * 255))


def oct_decode(a: int, b: int) -> tuple[float, float, float]:
    x = a / 255 * 2 - 1
    y = b / 255 * 2 - 1
    z = 1 - abs(x) - abs(y)
    if z < 0:
        x, y = (1 - abs(y)) * (1 if x >= 0 else -1), (1 - abs(x)) * (1 if y >= 0 else -1)
    length = math.sqrt(x * x + y * y + z * z) or 1.0
    return (x / length, y / length, z / length)


def encode(
    positions: list[tuple[float, float, float]],
    normals: list[tuple[float, float, float]],
    colors: list[tuple[int, int, int]],
    faces: list[tuple[int, int, int]],
    uvs: list[tuple[float, float]] | None = None,
) -> bytes:
    n = len(positions)
    if n == 0 or not faces:
        raise ValueError("empty mesh")
    if n > MAX_VERTS or len(faces) > MAX_FACES:
        raise ValueError(f"mesh over EditableMesh limits: {n} verts, {len(faces)} faces")
    if len(normals) != n or len(colors) != n or (uvs is not None and len(uvs) != n):
        raise ValueError("attribute arrays must match the vertex count")
    mins = [min(p[i] for p in positions) for i in range(3)]
    maxs = [max(p[i] for p in positions) for i in range(3)]
    size = [max(maxs[i] - mins[i], 1e-4) for i in range(3)]
    out = bytearray(MAGIC)
    out += struct.pack("<IIB", n, len(faces), 1 if uvs is not None else 0)
    out += struct.pack("<6f", *mins, *size)
    for p in positions:
        out += struct.pack("<3H", *(round((p[i] - mins[i]) / size[i] * 65535) for i in range(3)))
    for nm in normals:
        out += struct.pack("<2B", *oct_encode(nm))
    for c in colors:
        out += struct.pack("<3B", *(int(_clamp(v, 0, 255)) for v in c))
    if uvs is not None:
        for u, v in uvs:
            out += struct.pack("<2h", int(_clamp(round(u * UV_SCALE), -32768, 32767)), int(_clamp(round(v * UV_SCALE), -32768, 32767)))
    for f in faces:
        if max(f) >= n or min(f) < 0:
            raise ValueError(f"face index out of range: {f}")
        out += struct.pack("<3H", *f)
    return bytes(out)


def decode(data: bytes) -> dict:
    if data[:4] != MAGIC:
        raise ValueError("not an HCM1 buffer")
    n, nf, flags = struct.unpack_from("<IIB", data, 4)
    o = 13
    vals = struct.unpack_from("<6f", data, o)
    o += 24
    mins, size = vals[:3], vals[3:]
    positions = []
    for _ in range(n):
        q = struct.unpack_from("<3H", data, o)
        o += 6
        positions.append(tuple(mins[i] + q[i] / 65535 * size[i] for i in range(3)))
    normals = []
    for _ in range(n):
        normals.append(oct_decode(*struct.unpack_from("<2B", data, o)))
        o += 2
    colors = []
    for _ in range(n):
        colors.append(struct.unpack_from("<3B", data, o))
        o += 3
    uvs = None
    if flags & 1:
        uvs = []
        for _ in range(n):
            u, v = struct.unpack_from("<2h", data, o)
            uvs.append((u / UV_SCALE, v / UV_SCALE))
            o += 4
    faces = []
    for _ in range(nf):
        faces.append(struct.unpack_from("<3H", data, o))
        o += 6
    if o != len(data):
        raise ValueError("trailing bytes")
    return {"positions": positions, "normals": normals, "colors": colors, "uvs": uvs, "faces": faces, "min": mins, "size": size}


def to_text(data: bytes) -> str:
    return base64.b64encode(data).decode("ascii")


def from_text(text: str) -> bytes:
    return base64.b64decode(text)
