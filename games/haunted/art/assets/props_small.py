"""Small gameplay props: the capture jar carried home on the player's back (replaces the ForceField ball).

Origin = jar centre (the server's CaptureJar part). References: MIN-065 (witchcraft props: jars, bottles),
MIN-064 (iron lantern construction).
"""

import math

from hcart import core, paint, shapes
from hcart import palette as P

JAR_GLASS = paint.hex3("bfe9e6")


def capture_jar():
    glass = shapes.lathe("Glass", [(0.0, -1.05), (0.62, -1.05), (0.82, -0.95), (0.9, -0.6), (0.9, 0.55), (0.78, 0.82), (0.55, 0.95),
                                   (0.55, 1.08), (0.0, 1.08)], 20, "SmoothPlastic", alpha=0.62, lod=False)
    core.smooth(glass, 60)
    iron = []
    for z in (-0.82, 0.0, 0.62):
        iron.append(shapes.lathe(f"Band{z}", [(0.92, z - 0.07), (0.96, z - 0.05), (0.96, z + 0.05), (0.92, z + 0.07)], 20, "Metal",
                                 cap_bottom=False, cap_top=False))
    for k in range(4):
        a = k * math.pi / 2 + math.pi / 4
        iron.append(shapes.tube(f"Strap{k}", [(math.cos(a) * 0.95, math.sin(a) * 0.95, -0.85), (math.cos(a) * 0.95, math.sin(a) * 0.95, 0.6)],
                                0.04, 5, "Metal"))
    lid = shapes.lathe("Lid", [(0.0, 0.98), (0.66, 0.98), (0.7, 1.05), (0.66, 1.22), (0.4, 1.3), (0.12, 1.34), (0.0, 1.34)], 16, "Metal")
    iron.append(lid)
    iron.append(shapes.tube("Handle", [(0.32 * math.cos(a), 0, 1.34 + 0.32 * math.sin(a)) for a in [k / 12 * math.pi for k in range(13)]],
                            0.05, 6, "Metal", cap_start=False, cap_end=False))
    base = shapes.lathe("Foot", [(0.0, -1.18), (0.7, -1.18), (0.78, -1.1), (0.7, -1.02), (0.0, -1.02)], 16, "Metal")
    iron.append(base)
    body = core.join(iron, "Iron")
    core.uv_box(body, 1.0)
    core.smooth(body, 35)
    paint.paint([body], lambda c, n, o: P.IRON, ao=0.5, ao_distance=0.6, ground=None, edge=0.5, crease=0.3)
    paint.gradient_solid(glass, paint.mix(JAR_GLASS, P.GHOST_DEEP, 0.4), JAR_GLASS, -1.0, 1.0)
    return {"Kind": "prop", "LodDistance": 50}


ASSETS = {"capture_jar": capture_jar}
