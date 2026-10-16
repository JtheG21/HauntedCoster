"""TEMPLATE: copy to art/assets/<name>.py and fill in the TODOs. Not registered (lives outside art/assets/).

<Creature name> (TASK-####, YYYY-MM-DD). Built from a sourced base mesh following
05 Engineering/Creature Art Pipeline.md; the Lantern Wisp (assets/wisp_meshy.py) is the worked example.

Source mesh: ~/Roblox-Work/haunted/art/<source>/<file>.glb (not in the repo; override with <ENV_VAR>).
Credit: <e.g. "Base model generated with Meshy (CC BY 4.0)">; also record it in SYS-Haunted-Art-Direction.
"""

from mathutils import Matrix, Vector

from hcart import core, paint, sourced, surface

H = paint.hex3
SOURCE = sourced.source_path("~/Roblox-Work/haunted/art/<source>/<file>.glb", "<ENV_VAR>")  # TODO

# Measured in source units, front facing -Y (TODO: measure on a front render or in Blender).
NECK = Vector((0.0, 0.0, 0.5))  # neck pivot; the head turns about this
EYES_XZ = [(-0.1, 0.8), (0.1, 0.8)]  # eye centres seen from the front
EYE_R = 0.04
SCALE = 4.0  # source units -> design units
ORIGIN = Vector((0.0, 0.0, 0.0))  # source point that becomes the design origin

# Palette (TODO): the creature's own colours. Shared painters take a palette dict, e.g. surface.SACKING.
CLOTH = H("bcdcd4")
THREAD = H("2f241c")


def build():
    body = sourced.load_glb(SOURCE)
    pieces = sourced.separate_loose(body)
    body = pieces[0]
    body.name = "Body"
    # TODO: name or join the other loose pieces (props, accessories) as their own parts.

    tree = sourced.bvh(body)
    eyes_at = sourced.hits_from_front(tree, EYES_XZ)
    eyes = sourced.split_faces(body, lambda c, n: any((c - p).length < EYE_R for p in eyes_at), "Eyes", "SmoothPlastic")

    # Into design units.
    m = Matrix.Scale(SCALE, 4) @ Matrix.Translation(-ORIGIN)
    parts = [o for o in (body, eyes) if o]
    for o in parts:
        o.matrix_world = m @ o.matrix_world
        core.apply_transform(o)
    neck = m @ NECK

    relief = sourced.Relief(body, scale=0.012)

    def cloth(p, n, o, cv, op):
        c = surface.burlap(p, n, max(-1.0, min(1.0, cv * 4.0)), op, CLOTH, None, 3.0)
        return surface.relief_stitches(c, relief(p), THREAD, surface.SACKING["crevice"])

    for o in parts:
        core.uv_box(o, 1.2)
    surface.vertex_paint([body], cloth, ao_samples=20, ao_distance=0.45)
    if eyes:
        surface.vertex_paint([eyes], lambda p, n, o, cv, op: paint.mix(H("b3c4bd"), H("2e3d3e"), 1 - op), ao_samples=10, ao_distance=0.2)

    # Head split after painting, so the colours carry over. TODO: tune the candidate and band tests.
    head = sourced.split_head(
        body,
        is_candidate=lambda c: c.z > neck.z,
        is_band=lambda c: neck.z - 0.12 < c.z <= neck.z and (c.xy - neck.xy).length < 0.25,
    )
    core.tag(body, "Fabric", part="Body")
    core.tag(head, "Fabric", part="Head", pivot=tuple(neck))
    core.smooth(head, 180)
    if eyes:
        core.tag(eyes, "SmoothPlastic", part="Face", pivot=tuple(neck), lod=False)
    core.smooth(body, 180)

    sourced.fit_to_height(5.0, 0.0)  # TODO: game height in studs, lowest point above the ground
    print("PARTS", sourced.tri_report())
    return {"Kind": "creature", "Species": "TODO", "LodDistance": 60, "Credit": "TODO"}


ASSETS = {"creature_TODO": build}

# Creature budget 8,500 LOD0 / 6,000 LOD1 (tests/test_art_budgets.py). Maps <= 1024.
BAKE = {"creature_TODO": {
    "Creature": {"size": 1024, "metal": 0.0, "parts": {
        "Body": {"src": ["Body"], "tris": 3000},
        "Head": {"src": ["Head"], "tris": 3000, "keep": sourced.keep_near(["Eyes"], "Head")},
        "Eyes": {"src": ["Eyes"], "tris": 600},
    }},
}}
