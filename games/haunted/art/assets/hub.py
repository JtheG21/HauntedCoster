"""Hub wall and gates (TASK-0044). References: MIN-069 (stone piers, iron fencing, gates), MIN-067/070 (graveyard
architecture). Server colliders in server/World/HubBuilder.luau are unchanged (wall 10 high, pillars 3 x 14 x 3).
"""

import math

from hcart import core, paint, shapes
from hcart import palette as P

from assets.graveyard import _chip, _finish_stone

WOOD_SIGN = paint.hex3("5a3b26")


def hub_wall():
    """A 12-stud run (stretched along X to each arc segment): coped stone wall 3 high, iron railing above,
    a stone pier at the -X end."""
    stones = []
    body = shapes.box("Wall", (12.0, 1.5, 2.6), (0, 0, 1.3), bevel=0.06, material="Slate")
    core.subdivide(body, 2, simple=True)
    _chip(body, 0.05, 0.5, 2)
    coping = shapes.box("Coping", (12.0, 1.9, 0.4), (0, 0, 2.8), bevel=0.08, material="Slate")
    pier = shapes.box("Pier", (1.6, 2.1, 4.2), (-5.9, 0, 2.1), bevel=0.08, material="Slate")
    core.subdivide(pier, 1, simple=True)
    _chip(pier, 0.05, 0.4, 3)
    pcap = shapes.lathe("PierCap", [(0.0, 4.2), (1.35, 4.2), (1.35, 4.5), (0.6, 4.95), (0.0, 5.0)], 4, "Slate")
    core.transform(pcap, (-5.9, 0, 0), (0, 0, 45))
    stones += [body, coping, pier, pcap]
    stone = core.join(stones, "Stone")
    core.tag(stone, "Slate")
    _finish_stone([stone], 8, angle=35, studs=3.0)
    iron = [shapes.box("Rail", (12.0, 0.14, 0.14), (0, 0, 5.4), material="Metal")]
    for i in range(12):
        x = -5.0 + i * 0.95
        iron.append(shapes.cylinder(f"Bar{i}", 0.045, 2.8, (x, 0, 4.4), segments=5, material="Metal"))
        iron.append(shapes.lathe(f"Tip{i}", [(0.0, 5.75), (0.1, 5.88), (0.02, 6.2), (0.0, 6.24)], 4, "Metal"))
        core.transform(iron[-1], (x, 0, 0))
    rail = core.join(iron, "Iron")
    core.tag(rail, "Metal")
    core.uv_box(rail, 2.0)
    paint.paint([rail], lambda c, n, o: P.IRON, ao=0.4, ground=None, edge=0.5)
    return {"Kind": "prop", "LodDistance": 120, "Length": 12.0}


def hub_gate_pillar():
    """A 3 x 14 gothic gate pillar: stepped plinth, banded shaft with a lantern niche, gabled cap and finial."""
    import random

    rng = random.Random(14)
    courses = []
    z = 1.0
    k = 0
    while z < 12.5:
        hgt = min(1.35, 12.6 - z)
        w = 3.0 - (0.06 if k % 2 else 0.0)
        blk = shapes.box(f"Course{k}", (w + rng.uniform(-0.04, 0.04), w + rng.uniform(-0.04, 0.04), hgt - 0.06),
                         (rng.uniform(-0.03, 0.03), rng.uniform(-0.03, 0.03), z + hgt / 2), bevel=0.09, segments=2, material="Slate")
        _chip(blk, 0.04, 0.4, k)
        courses.append(blk)
        z += hgt
        k += 1
    niche_back = shapes.box("NicheBack", (1.3, 0.2, 1.9), (0, -1.42, 8.35), bevel=0.05, material="Slate")
    niche_arch = shapes.tube("NicheArch", [(-0.75 * math.cos(a), -1.55, 9.3 + 0.55 * math.sin(a)) for a in [m / 12 * math.pi for m in range(13)]],
                             0.12, 6, "Slate", cap_start=False, cap_end=False)
    niche_sill = shapes.box("NicheSill", (1.7, 0.45, 0.2), (0, -1.6, 7.35), bevel=0.04, material="Slate")
    shaft = core.join(courses + [niche_back, niche_arch, niche_sill], "Shaft")
    plinth = shapes.lathe("Plinth", [(0.0, 0.0), (2.5, 0.0), (2.5, 0.5), (2.2, 0.6), (2.2, 0.9), (1.9, 1.0), (0.0, 1.0)], 4, "Slate")
    band = shapes.lathe("Band", [(1.95, 5.0), (2.25, 5.1), (2.25, 5.4), (1.95, 5.5)], 4, "Slate", cap_bottom=False, cap_top=False)
    cap = shapes.lathe("Cap", [(0.0, 12.6), (2.3, 12.6), (2.4, 12.95), (2.0, 13.1), (1.0, 14.3), (0.25, 14.5), (0.0, 14.5)], 4, "Slate")
    for o in (plinth, band, cap):
        core.transform(o, rot=(0, 0, 45))
    finial = shapes.lathe("Finial", [(0.0, 14.4), (0.3, 14.5), (0.35, 14.8), (0.15, 15.0), (0.25, 15.4), (0.0, 16.1)], 8, "Slate")
    stone = core.join([shaft, plinth, band, cap, finial], "Stone")
    core.tag(stone, "Slate")
    _finish_stone([stone], 9, angle=35, studs=3.0)
    return {"Kind": "prop", "LodDistance": 160}


def hub_gate_arch():
    """Ornate iron arch, 20 studs between pillar centres (stretched per gate), with scrollwork and a crest."""
    iron = []
    span = 20.0
    pts = [(-span / 2 + span * t, 0, 0.6 + 3.0 * math.sin(math.pi * t)) for t in [k / 28 for k in range(29)]]
    iron.append(shapes.tube("Top", pts, 0.16, 8, "Metal", resample=0))
    inner = [(-span / 2 + 0.8 + (span - 1.6) * t, 0, 0.3 + 2.2 * math.sin(math.pi * t)) for t in [k / 28 for k in range(29)]]
    iron.append(shapes.tube("Inner", inner, 0.1, 6, "Metal", resample=0))
    iron.append(shapes.box("Beam", (span, 0.3, 0.3), (0, 0, 0.0), bevel=0.04, material="Metal"))
    for k in range(13):
        t = k / 12
        x = -span / 2 + span * t
        h = 0.6 + 3.0 * math.sin(math.pi * t)
        iron.append(shapes.cylinder(f"Bar{k}", 0.06, h, (x, 0, h / 2), segments=5, material="Metal"))
        iron.append(shapes.lathe(f"Tip{k}", [(0.0, h + 0.05), (0.16, h + 0.22), (0.03, h + 0.7), (0.0, h + 0.74)], 4, "Metal"))
        core.transform(iron[-1], (x, 0, 0))
    for side in (-1, 1):
        for j, (cx, r) in enumerate(((side * 5.5, 0.8), (side * 2.4, 0.6))):
            curl = [(cx + r * math.cos(a) * (1 - 0.12 * a), 0, 1.4 + r * math.sin(a) * (1 - 0.12 * a)) for a in [m / 20 * math.tau * 1.3 for m in range(21)]]
            iron.append(shapes.tube(f"Scroll{side}{j}", curl, 0.06, 5, "Metal", cap_start=False))
    crest = shapes.lathe("Crest", [(0.0, 3.4), (0.55, 3.55), (0.65, 3.9), (0.3, 4.3), (0.45, 4.6), (0.0, 5.6)], 8, "Metal")
    iron.append(crest)
    obj = core.join(iron, "Iron")
    core.tag(obj, "Metal")
    core.uv_box(obj, 2.0)
    core.smooth(obj, 35)
    paint.paint([obj], lambda c, n, o: P.IRON, ao=0.4, ao_distance=0.8, ground=None, edge=0.55, mottle=0.1)
    return {"Kind": "prop", "LodDistance": 160, "Length": span}


def hub_gate_sign():
    """A hanging wooden sign, 9 x 1.8 face centred at the origin (the server lays the habitat name on it)."""
    board = shapes.box("Board", (9.0, 0.3, 1.8), (0, 0, 0), bevel=0.08, segments=2, material="Wood")
    core.subdivide(board, 2, simple=True)
    for v in board.data.vertices:
        v.co.z += 0.08 * math.sin(v.co.x * 0.9)
    core.displace_noise(board, 0.03, 0.4, 5)
    frame = [shapes.box(f"Band{s}", (0.25, 0.4, 2.0), (s * 4.2, 0, 0), bevel=0.03, material="Metal") for s in (-1, 1)]
    chains = []
    for s in (-1, 1):
        for i in range(4):
            z = 1.1 + i * 0.32
            if i % 2:
                ring = [(s * 3.6, 0.08 * math.cos(a), z + 0.14 * math.sin(a)) for a in [k / 8 * math.tau for k in range(9)]]
            else:
                ring = [(s * 3.6 + 0.08 * math.cos(a), 0, z + 0.14 * math.sin(a)) for a in [k / 8 * math.tau for k in range(9)]]
            chains.append(shapes.tube(f"L{s}{i}", ring, 0.035, 4, "Metal", cap_start=False, cap_end=False))
    wood = core.join([board], "Wood")
    core.tag(wood, "Wood")
    core.uv_box(wood, 3.0)
    core.smooth(wood, 40)
    paint.paint([wood], lambda c, n, o: WOOD_SIGN, ao=0.4, ground=None, edge=0.3, crease=0.4, mottle=0.12, mottle_scale=0.6)
    iron = core.join(frame + chains, "Iron")
    core.tag(iron, "Metal")
    core.uv_box(iron, 1.0)
    paint.paint([iron], lambda c, n, o: P.IRON, ao=0.3, ground=None, edge=0.5)
    return {"Kind": "prop", "LodDistance": 160}


ASSETS = {"hub_wall": hub_wall, "hub_gate_pillar": hub_gate_pillar, "hub_gate_arch": hub_gate_arch, "hub_gate_sign": hub_gate_sign}
