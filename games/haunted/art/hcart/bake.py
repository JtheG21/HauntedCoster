"""Production bake: high-detail source -> game mesh + PBR texture maps (colour, normal, roughness, metalness).

An asset module opts in with a BAKE spec: texture sets, each with its parts. For every part, the listed source
objects (full-detail sculpt, stitches, rivets...) are baked onto a lighter copy of the first source. One UV atlas
per texture set; the maps are what SurfaceAppearance shows in Studio after jg's batch import (an upload, his step).

  BAKE = {"Creature": {"size": 2048, "metal": 0.0, "parts": {"Body": {"src": ["Body", "BodyStitches"], "tris": 6000}}}}

The source objects' painted "Col" attribute is the albedo; materials add the fine surface grain (burlap weave,
metal pitting) as colour and bump at texel resolution, which vertex colours cannot hold. After baking, the sources
are removed, the game parts keep their tags (rbx_part, pivot, material) plus rbx_baked, and their vertex colours are
re-sampled from the colour map so the runtime HCM1 path still shows the painted look.
"""

from __future__ import annotations

import math
from pathlib import Path

import bpy
import numpy as np

from . import core

KEEP_TAGS = ("rbx_material", "rbx_alpha", "rbx_part", "rbx_pivot", "rbx_lod", "rbx_detail", "base_color")
ROUGH = {"Fabric": 0.6, "SmoothPlastic": 0.14, "Metal": 0.38, "CorrodedMetal": 0.62}  # the concept reads as semi-glossy, grimy canvas


def _node(nt, kind, loc=(0, 0), **inputs):
    n = nt.nodes.new(kind)
    n.location = loc
    for k, v in inputs.items():
        n.inputs[k].default_value = v
    return n


def _grain(nt, kind: str):
    """Returns (colour factor socket, height socket) for the material's fine surface grain."""
    tc = nt.nodes.new("ShaderNodeTexCoord")
    if kind == "Fabric":
        # Burlap: two crossing thread bands with fibre noise; threads ~0.02 studs apart.
        w1 = _node(nt, "ShaderNodeTexWave", Scale=48.0, Distortion=1.6, Detail=2.0)
        w1.wave_type = "BANDS"
        w1.bands_direction = "X"
        w2 = _node(nt, "ShaderNodeTexWave", Scale=48.0, Distortion=1.6, Detail=2.0)
        w2.wave_type = "BANDS"
        w2.bands_direction = "Z"
        fib = _node(nt, "ShaderNodeTexNoise", Scale=220.0, Detail=6.0, Roughness=0.7)
        for w in (w1, w2, fib):
            nt.links.new(tc.outputs["Object"], w.inputs["Vector"])
        mul = _node(nt, "ShaderNodeMath")
        mul.operation = "MULTIPLY"
        nt.links.new(w1.outputs["Fac"], mul.inputs[0])
        nt.links.new(w2.outputs["Fac"], mul.inputs[1])
        mix = _node(nt, "ShaderNodeMix")
        mix.data_type = "FLOAT"
        mix.inputs["Factor"].default_value = 0.35
        nt.links.new(mul.outputs[0], mix.inputs["A"])
        nt.links.new(fib.outputs["Fac"], mix.inputs["B"])
        # Creases: worn folds in the sacking (ridged noise), layered over the weave.
        crease = _node(nt, "ShaderNodeTexNoise", Scale=9.0, Detail=4.0, Roughness=0.6)
        nt.links.new(tc.outputs["Object"], crease.inputs["Vector"])
        cr = _node(nt, "ShaderNodeMapRange")
        cr.inputs["From Min"].default_value = 0.42
        cr.inputs["From Max"].default_value = 0.58
        cr.clamp = True
        nt.links.new(crease.outputs["Fac"], cr.inputs["Value"])
        ridge = _node(nt, "ShaderNodeMath")
        ridge.operation = "PINGPONG"
        ridge.inputs[1].default_value = 0.5
        nt.links.new(cr.outputs["Result"], ridge.inputs[0])
        both = _node(nt, "ShaderNodeMix")
        both.data_type = "FLOAT"
        both.inputs["Factor"].default_value = 0.45
        nt.links.new(mix.outputs["Result"], both.inputs["A"])
        nt.links.new(ridge.outputs[0], both.inputs["B"])
        mix = both
        ramp = _node(nt, "ShaderNodeMapRange")
        ramp.inputs["From Min"].default_value = 0.0
        ramp.inputs["From Max"].default_value = 0.6
        ramp.inputs["To Min"].default_value = 0.9
        ramp.inputs["To Max"].default_value = 1.04
        nt.links.new(mix.outputs["Result"], ramp.inputs["Value"])
        return ramp.outputs["Result"], mix.outputs["Result"]
    if kind in ("Metal", "CorrodedMetal"):
        pit = _node(nt, "ShaderNodeTexNoise", Scale=160.0, Detail=8.0, Roughness=0.75)
        scr = _node(nt, "ShaderNodeTexWave", Scale=30.0, Distortion=12.0, Detail=4.0)
        for w in (pit, scr):
            nt.links.new(tc.outputs["Object"], w.inputs["Vector"])
        mix = _node(nt, "ShaderNodeMix")
        mix.data_type = "FLOAT"
        mix.inputs["Factor"].default_value = 0.25
        nt.links.new(pit.outputs["Fac"], mix.inputs["A"])
        nt.links.new(scr.outputs["Fac"], mix.inputs["B"])
        ramp = _node(nt, "ShaderNodeMapRange")
        ramp.inputs["From Min"].default_value = 0.3
        ramp.inputs["From Max"].default_value = 0.7
        ramp.inputs["To Min"].default_value = 0.8
        ramp.inputs["To Max"].default_value = 1.05
        nt.links.new(mix.outputs["Result"], ramp.inputs["Value"])
        return ramp.outputs["Result"], mix.outputs["Result"]
    return None, None


def grime(nt, kind: str):
    """Texel-resolution darkening: local ambient occlusion, crevices (pointiness) and blotchy mottling."""
    ao = nt.nodes.new("ShaderNodeAmbientOcclusion")
    ao.only_local = True
    ao.samples = 16
    ao.inputs["Distance"].default_value = 0.12
    aor = _node(nt, "ShaderNodeMapRange")
    aor.inputs["To Min"].default_value = 0.55
    aor.inputs["To Max"].default_value = 1.0
    nt.links.new(ao.outputs["AO"], aor.inputs["Value"])
    geo = nt.nodes.new("ShaderNodeNewGeometry")
    pr = _node(nt, "ShaderNodeMapRange")
    pr.inputs["From Min"].default_value = 0.42
    pr.inputs["From Max"].default_value = 0.56
    pr.inputs["To Min"].default_value = 0.78
    pr.inputs["To Max"].default_value = 1.06
    nt.links.new(geo.outputs["Pointiness"], pr.inputs["Value"])
    tc = nt.nodes.new("ShaderNodeTexCoord")
    blot = _node(nt, "ShaderNodeTexNoise", Scale=7.0, Detail=5.0, Roughness=0.65)
    nt.links.new(tc.outputs["Object"], blot.inputs["Vector"])
    br = _node(nt, "ShaderNodeMapRange")
    br.inputs["From Min"].default_value = 0.35
    br.inputs["From Max"].default_value = 0.65
    br.inputs["To Min"].default_value = 0.86 if kind == "Fabric" else 0.88
    br.inputs["To Max"].default_value = 1.06
    nt.links.new(blot.outputs["Fac"], br.inputs["Value"])
    a = _node(nt, "ShaderNodeMath")
    a.operation = "MULTIPLY"
    nt.links.new(aor.outputs["Result"], a.inputs[0])
    nt.links.new(pr.outputs["Result"], a.inputs[1])
    b = _node(nt, "ShaderNodeMath")
    b.operation = "MULTIPLY"
    nt.links.new(a.outputs[0], b.inputs[0])
    nt.links.new(br.outputs["Result"], b.inputs[1])
    return b.outputs[0]


def _source_material(obj, mode: str) -> bpy.types.Material:
    """Bake-source material. mode: 'color' (emits albedo), 'rough' (emits roughness), 'normal' (shading with bump)."""
    kind = obj.get("rbx_material", "SmoothPlastic")
    m = bpy.data.materials.new(f"{obj.name}_{mode}")
    m.use_nodes = True
    nt = m.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    col = nt.nodes.new("ShaderNodeVertexColor")
    col.layer_name = "Col"
    fac, height = _grain(nt, kind)
    if mode == "color":
        em = nt.nodes.new("ShaderNodeEmission")
        factor = grime(nt, kind)
        if fac is not None:
            m2 = _node(nt, "ShaderNodeMath")
            m2.operation = "MULTIPLY"
            nt.links.new(fac, m2.inputs[0])
            nt.links.new(factor, m2.inputs[1])
            factor = m2.outputs[0]
        mul = _node(nt, "ShaderNodeMix")
        mul.data_type = "RGBA"
        mul.blend_type = "MULTIPLY"
        mul.inputs["Factor"].default_value = 1.0
        nt.links.new(col.outputs["Color"], mul.inputs["A"])
        cf = nt.nodes.new("ShaderNodeCombineColor")
        for i in range(3):
            nt.links.new(factor, cf.inputs[i])
        nt.links.new(cf.outputs["Color"], mul.inputs["B"])
        nt.links.new(mul.outputs["Result"], em.inputs["Color"])
        nt.links.new(em.outputs["Emission"], out.inputs["Surface"])
    elif mode == "rough":
        # Dark grimy cloth goes matte; pale canvas keeps a slight sheen; fine grain varies it.
        em = nt.nodes.new("ShaderNodeEmission")
        base = ROUGH.get(kind, 0.6)
        lum = nt.nodes.new("ShaderNodeRGBToBW")
        nt.links.new(col.outputs["Color"], lum.inputs["Color"])
        dark = _node(nt, "ShaderNodeMapRange")
        dark.inputs["From Min"].default_value = 0.0
        dark.inputs["From Max"].default_value = 0.35
        dark.inputs["To Min"].default_value = min(1.0, base + (0.3 if kind == "Fabric" else 0.12))
        dark.inputs["To Max"].default_value = base
        nt.links.new(lum.outputs["Val"], dark.inputs["Value"])
        val = dark.outputs["Result"]
        if height is not None:
            mr = _node(nt, "ShaderNodeMapRange")
            mr.inputs["To Min"].default_value = -0.1
            mr.inputs["To Max"].default_value = 0.08
            nt.links.new(height, mr.inputs["Value"])
            add = _node(nt, "ShaderNodeMath")
            add.operation = "ADD"
            add.use_clamp = True
            nt.links.new(val, add.inputs[0])
            nt.links.new(mr.outputs["Result"], add.inputs[1])
            val = add.outputs[0]
        cf = nt.nodes.new("ShaderNodeCombineColor")
        for i in range(3):
            nt.links.new(val, cf.inputs[i])
        nt.links.new(cf.outputs["Color"], em.inputs["Color"])
        nt.links.new(em.outputs["Emission"], out.inputs["Surface"])
    else:
        bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
        if height is not None:
            bump = _node(nt, "ShaderNodeBump", Strength=0.85 if kind == "Fabric" else 0.45, Distance=0.006)
            nt.links.new(height, bump.inputs["Height"])
            nt.links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])
        nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    return m


def _set_material(obj, mat):
    obj.data.materials.clear()
    obj.data.materials.append(mat)


def _unwrap(obj, margin: float):
    core.activate(obj)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=math.radians(60), island_margin=margin, area_weight=1.0, correct_aspect=True,
                             scale_to_bounds=False)
    bpy.ops.uv.pack_islands(margin=margin, rotate=True)
    bpy.ops.object.mode_set(mode="OBJECT")


def _sample_vertex_colours(obj, img):
    """Writes the colour map back into the "Col" attribute (nearest texel per face corner) for the HCM1 path."""
    w, h = img.size
    px = np.array(img.pixels[:], dtype=np.float32).reshape(h, w, 4)
    me = obj.data
    uv = me.uv_layers.active.data
    if "Col" in me.color_attributes:
        me.color_attributes.remove(me.color_attributes["Col"])
    attr = me.color_attributes.new("Col", "BYTE_COLOR", "CORNER")
    for i, loop in enumerate(uv):
        u, v = loop.uv
        x = min(w - 1, max(0, int(u * w)))
        y = min(h - 1, max(0, int(v * h)))
        r, g, b, _ = px[y, x]
        attr.data[i].color_srgb = (float(r), float(g), float(b), 1.0)  # byte image pixels are stored sRGB


def production(asset: str, spec: dict, tex_dir: Path, samples: int = 4) -> dict:
    """Bakes every texture set in `spec`; returns a report of game parts, triangles and map files."""
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    sc.cycles.samples = samples
    sc.cycles.use_denoising = False
    bake = sc.render.bake
    bake.use_selected_to_active = True
    bake.use_cage = False
    bake.cage_extrusion = 0.02
    bake.max_ray_distance = 0.06
    bake.margin = 6
    tex_dir.mkdir(parents=True, exist_ok=True)
    report = {"sets": {}}
    consumed = []
    for set_name, tset in spec.items():
        size = tset.get("size", 1024)
        parts = tset["parts"]
        lows, sources = [], []
        tags = {}
        for part, p in parts.items():
            srcs = [bpy.data.objects[n] for n in p["src"] if n in bpy.data.objects]
            main = srcs[0]
            tags[part] = {k: main[k] for k in KEEP_TAGS if k in main.keys()}
            low = core.duplicate(main, f"{part}__low")
            for k in list(low.keys()):
                del low[k]
            if p.get("tris"):
                core.decimate_to(low, p["tris"])
            core.smooth(low, p.get("smooth", 180))
            mat = bpy.data.materials.new(f"{set_name}:{part}")
            mat.use_nodes = True
            _set_material(low, mat)
            lows.append(low)
            sources += srcs
        for o in lows:
            o.select_set(False)
        merged = core.join(lows, f"{set_name}__atlas")
        for k in list(merged.keys()):
            del merged[k]
        _unwrap(merged, 0.0025 if size >= 2048 else 0.004)
        imgs = {
            "color": bpy.data.images.new(f"{asset}_{set_name}_color", size, size, alpha=False),
            "normal": bpy.data.images.new(f"{asset}_{set_name}_normal", size, size, alpha=False),
            "rough": bpy.data.images.new(f"{asset}_{set_name}_roughness", size, size, alpha=False),
        }
        for k in ("normal", "rough"):
            imgs[k].colorspace_settings.name = "Non-Color"
        image_nodes = []
        for mat in merged.data.materials:
            node = mat.node_tree.nodes.new("ShaderNodeTexImage")
            mat.node_tree.nodes.active = node
            image_nodes.append(node)
        src_set = [s for s in dict.fromkeys(sources)]
        for mode, img, kind in (("color", imgs["color"], "EMIT"), ("rough", imgs["rough"], "EMIT"), ("normal", imgs["normal"], "NORMAL")):
            for s in src_set:
                _set_material(s, _source_material(s, mode))
            for node in image_nodes:
                node.image = img
            for o in bpy.context.view_layer.objects:
                o.select_set(False)
            for s in src_set:
                s.hide_render = False
                s.select_set(True)
            merged.select_set(True)
            bpy.context.view_layer.objects.active = merged
            if kind == "NORMAL":
                bpy.ops.object.bake(type="NORMAL", normal_space="TANGENT")
            else:
                bpy.ops.object.bake(type="EMIT")
        files = {}
        for k, img in imgs.items():
            path = tex_dir / f"{img.name}.png"
            img.filepath_raw = str(path)
            img.file_format = "PNG"
            img.save()
            files[k] = str(path)
        metal = float(tset.get("metal", 0.0))
        mimg = bpy.data.images.new(f"{asset}_{set_name}_metalness", 4, 4, alpha=False)
        mimg.colorspace_settings.name = "Non-Color"
        mimg.pixels = [metal, metal, metal, 1.0] * 16
        mimg.filepath_raw = str(tex_dir / f"{mimg.name}.png")
        mimg.file_format = "PNG"
        mimg.save()
        files["metalness"] = mimg.filepath_raw
        _sample_vertex_colours(merged, imgs["color"])
        # Back to one object per game part, each with a preview PBR material using the baked maps.
        core.activate(merged)
        bpy.ops.object.mode_set(mode="EDIT")
        bpy.ops.mesh.select_all(action="SELECT")
        bpy.ops.mesh.separate(type="MATERIAL")
        bpy.ops.object.mode_set(mode="OBJECT")
        out_parts = {}
        for o in [o for o in bpy.context.scene.objects if o.name.startswith(f"{set_name}__atlas")]:
            mat_name = o.data.materials[0].name if o.data.materials else ""
            part = mat_name.split(":", 1)[1] if ":" in mat_name else o.name
            for s in list(bpy.data.objects):
                if s.name == part:
                    s.name = part + "__src"
            o.name = part
            o.data.name = part
            for k, v in tags.get(part, {}).items():
                o[k] = v
            o["rbx_baked"] = set_name
            o["rbx_maps"] = ";".join(f"{k}={v}" for k, v in files.items())
            _set_material(o, preview_material(part, imgs, metal))
            _add_tile_uv(o)
            out_parts[part] = core.tri_count(o)
        consumed += src_set
        report["sets"][set_name] = {"size": size, "parts": out_parts, "files": files}
    for o in dict.fromkeys(consumed):
        bpy.data.objects.remove(o)
    return report


def _add_tile_uv(obj, studs_per_tile: float = 1.2):
    """A world-scale box-projected "Tile" UV (Roblox material textures); the atlas UV stays active for the maps."""
    me = obj.data
    atlas = me.uv_layers.active
    tile = me.uv_layers.new(name="Tile")
    mw = obj.matrix_world
    for poly in me.polygons:
        n = poly.normal
        ax = max(range(3), key=lambda i: abs(n[i]))
        for li in poly.loop_indices:
            p = mw @ me.vertices[me.loops[li].vertex_index].co
            u, v = (p.y, p.z) if ax == 0 else (p.x, p.z) if ax == 1 else (p.x, p.y)
            tile.data[li].uv = (u / studs_per_tile, v / studs_per_tile)
    me.uv_layers.active = atlas
    atlas.active_render = True


def preview_material(name, imgs, metal) -> bpy.types.Material:
    m = bpy.data.materials.new(f"{name}_pbr")
    m.use_nodes = True
    nt = m.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    c = nt.nodes.new("ShaderNodeTexImage")
    c.image = imgs["color"]
    nt.links.new(c.outputs["Color"], bsdf.inputs["Base Color"])
    r = nt.nodes.new("ShaderNodeTexImage")
    r.image = imgs["rough"]
    nt.links.new(r.outputs["Color"], bsdf.inputs["Roughness"])
    n = nt.nodes.new("ShaderNodeTexImage")
    n.image = imgs["normal"]
    nm = nt.nodes.new("ShaderNodeNormalMap")
    nt.links.new(n.outputs["Color"], nm.inputs["Color"])
    nt.links.new(nm.outputs["Normal"], bsdf.inputs["Normal"])
    bsdf.inputs["Metallic"].default_value = metal
    return m
