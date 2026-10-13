"""Preview contact sheets: front, three-quarter, side and rear views in neutral light (and an optional night
pass close to the game's lighting). Used for iteration and as visual evidence next to Studio captures."""

from __future__ import annotations

import math
from pathlib import Path

import bpy
import numpy as np
from mathutils import Vector

ROUGH = {"SmoothPlastic": 0.35, "Plastic": 0.6, "Neon": 0.5, "Glass": 0.05, "Metal": 0.35, "CorrodedMetal": 0.6, "Wood": 0.75,
         "Slate": 0.85, "Rock": 0.9, "Fabric": 0.95, "Concrete": 0.9}


def _material(obj: bpy.types.Object, no_glow: bool) -> bpy.types.Material:
    kind = obj.get("rbx_material", "SmoothPlastic")
    alpha = float(obj.get("rbx_alpha", 0.0))
    m = bpy.data.materials.new(obj.name + "_prev")
    m.use_nodes = True
    nt = m.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    attr = nt.nodes.new("ShaderNodeVertexColor")
    attr.layer_name = "Col"
    nt.links.new(attr.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = ROUGH.get(kind, 0.7)
    if kind in ("Metal", "CorrodedMetal"):
        bsdf.inputs["Metallic"].default_value = 0.6
    if kind == "Neon" and not no_glow:
        nt.links.new(attr.outputs["Color"], bsdf.inputs["Emission Color"])
        bsdf.inputs["Emission Strength"].default_value = 3.0
    if alpha > 0 or kind == "Glass":
        a = 1 - (alpha if alpha > 0 else 0.5)
        bsdf.inputs["Alpha"].default_value = a
        m.blend_method = "BLEND" if hasattr(m, "blend_method") else None
    return m


def _bounds():
    pts = []
    for o in bpy.context.scene.objects:
        if o.type == "MESH" and not o.hide_render:
            pts += [o.matrix_world @ Vector(c) for c in o.bound_box]
    lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    return lo, hi


def contact_sheet(path: Path, tile: int = 400, night: bool = False, no_glow: bool = False, views=(0, 40, 90, 180),
                  elevation: float = 12.0, samples: int = 24, ground: bool = True, focus=None, show_parts=()) -> Path:
    sc = bpy.context.scene
    for o in sc.objects:
        if o.type == "MESH" and o.get("rbx_part") == "Ember":
            o.hide_render = "Ember" not in show_parts
    for o in list(sc.objects):
        if o.type == "MESH" and "rbx_material" in o.keys():
            o.data.materials.clear()
            o.data.materials.append(_material(o, no_glow))
    lo, hi = _bounds()
    centre = (lo + hi) / 2
    size = max((hi - lo).x, (hi - lo).y, (hi - lo).z)
    floor_z = lo.z
    if focus is not None:
        centre = Vector(focus[:3])
        size = focus[3]
    added = []
    if ground:
        bpy.ops.mesh.primitive_plane_add(size=max(size, 10) * 8, location=(centre.x, centre.y, floor_z - 0.001))
        g = bpy.context.object
        gm = bpy.data.materials.new("ground")
        gm.use_nodes = True
        gm.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.12, 0.13, 0.16, 1) if night else (0.45, 0.45, 0.47, 1)
        gm.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.9
        g.data.materials.append(gm)
        added.append(g)
    world = bpy.data.worlds.new("w")
    sc.world = world
    world.use_nodes = True
    bg = world.node_tree.nodes["Background"]
    bg.inputs["Color"].default_value = (0.02, 0.02, 0.05, 1) if night else (0.55, 0.57, 0.62, 1)
    bg.inputs["Strength"].default_value = 0.35 if night else 1.0
    def light(kind, rot, energy, color=(1, 1, 1), loc=(0, 0, 0)):
        ld = bpy.data.lights.new("l", kind)
        ld.energy = energy
        ld.color = color
        lo_ = bpy.data.objects.new("l", ld)
        lo_.rotation_euler = tuple(math.radians(a) for a in rot)
        lo_.location = loc
        sc.collection.objects.link(lo_)
        added.append(lo_)
    if night:
        light("SUN", (55, 0, 140), 0.6, (0.55, 0.6, 1.0))
        light("POINT", (0, 0, 0), size * size * 35, (1.0, 0.62, 0.3), tuple(centre + Vector((size * 0.9, -size * 0.9, size * 0.8))))
    else:
        light("SUN", (50, 0, 30), 3.0)
        light("SUN", (70, 0, 200), 0.8, (0.85, 0.9, 1.0))
    cam_data = bpy.data.cameras.new("cam")
    cam_data.lens = 60
    cam = bpy.data.objects.new("cam", cam_data)
    sc.collection.objects.link(cam)
    added.append(cam)
    sc.camera = cam
    sc.render.engine = "CYCLES"
    sc.cycles.samples = samples
    sc.cycles.use_denoising = True
    sc.render.resolution_x = tile
    sc.render.resolution_y = tile
    sc.render.film_transparent = False
    sc.view_settings.view_transform = "Standard"
    dist = size * 2.3
    tiles = []
    tmp = path.with_suffix("")
    for i, yaw in enumerate(views):
        a = math.radians(yaw - 90)  # yaw 0 = looking at the front (-Y face)
        el = math.radians(elevation)
        pos = centre + Vector((math.cos(a) * math.cos(el), math.sin(a) * math.cos(el), math.sin(el))) * dist
        cam.location = pos
        d = centre - pos
        cam.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
        f = f"{tmp}_{i}.png"
        sc.render.filepath = f
        bpy.ops.render.render(write_still=True)
        img = bpy.data.images.load(f)
        arr = np.array(img.pixels[:], dtype=np.float32).reshape(tile, tile, 4)
        tiles.append(arr)
        bpy.data.images.remove(img)
        Path(f).unlink()
    cols = 2 if len(tiles) == 4 else len(tiles)
    rows = math.ceil(len(tiles) / cols)
    sheet = np.ones((rows * tile, cols * tile, 4), dtype=np.float32)
    for i, t in enumerate(tiles):
        r, c = divmod(i, cols)
        sheet[(rows - 1 - r) * tile:(rows - r) * tile, c * tile:(c + 1) * tile] = t
    out = bpy.data.images.new("sheet", cols * tile, rows * tile, alpha=True)
    out.pixels = sheet.ravel()
    out.filepath_raw = str(path)
    out.file_format = "PNG"
    out.save()
    for o in added:
        bpy.data.objects.remove(o)
    for o in sc.objects:
        if o.type == "MESH" and o.get("rbx_part") == "Ember":
            o.hide_render = False
    return path
