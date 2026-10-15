"""Exports tagged mesh objects to `games/haunted/src/shared/ArtData/<asset>.model.json` (HCM1 StringValues)
and optionally an FBX for the later Studio import (jg's step; see 05 Engineering/Blender Pipeline.md)."""

from __future__ import annotations

import json
from pathlib import Path

import bmesh
import bpy

from . import codec, core

TEXTURED = {"Wood", "WoodPlanks", "Slate", "Rock", "Fabric", "Concrete", "Brick", "Cobblestone", "Metal", "CorrodedMetal",
            "Grass", "LeafyGrass", "Ground", "Mud", "Plaster", "Granite", "Marble", "Pebble", "Basalt", "Sand", "Limestone",
            "Sandstone", "Leather", "RoofShingles", "Plastic", "DiamondPlate", "Foil", "Asphalt", "Pavement", "Cardboard",
            "Carpet", "CeramicTiles", "ClayRoofTiles", "Rubber", "Salt", "Snow", "Ice", "Glacier", "CrackedLava"}


# Roblox material textures darken the vertex colour they multiply (measured in Studio 2026-10-13: Fabric reads
# roughly 35% darker than Plastic). Exported colours are lifted so painted values survive.
MATERIAL_GAIN = {"Fabric": 1.55, "Wood": 1.1}


def to_roblox(v) -> tuple[float, float, float]:
    """Blender (Z up, front -Y) -> Roblox (Y up, front -Z): a proper rotation, so winding is kept."""
    return (-v[0], v[2], v[1])


def mesh_arrays(obj: bpy.types.Object, with_uv: bool) -> tuple[list, list, list, list, list | None, int]:
    dg = bpy.context.evaluated_depsgraph_get()
    ev = obj.evaluated_get(dg)
    me = bpy.data.meshes.new_from_object(ev)
    me.transform(obj.matrix_world)
    bm = bmesh.new()
    bm.from_mesh(me)
    bmesh.ops.triangulate(bm, faces=bm.faces)
    bm.to_mesh(me)
    bm.free()
    if obj.matrix_world.determinant() < 0:
        me.flip_normals()
    col = me.color_attributes.get("Col")
    # Baked parts carry an atlas UV for their texture maps plus a world-scale "Tile" UV for Roblox material textures.
    uvl = (me.uv_layers.get("Tile") or me.uv_layers.active) if with_uv and me.uv_layers else None
    normals = me.corner_normals
    keymap: dict = {}
    pos, nrm, cols, uvs, faces = [], [], [], [], []
    for poly in me.polygons:
        tri = []
        for li in poly.loop_indices:
            vi = me.loops[li].vertex_index
            p = to_roblox(me.vertices[vi].co)
            n = to_roblox(normals[li].vector)
            if col is not None:
                c = col.data[li].color_srgb if col.domain == "CORNER" else col.data[vi].color_srgb
                rgb = (round(c[0] * 255), round(c[1] * 255), round(c[2] * 255))
            else:
                bc = obj.get("base_color", (0.8, 0.8, 0.8))
                rgb = tuple(round(x * 255) for x in bc)
            uv = tuple(uvl.data[li].uv) if uvl else None
            key = (tuple(round(x, 4) for x in p), tuple(round(x, 2) for x in n), rgb, tuple(round(x, 3) for x in uv) if uv else None)
            idx = keymap.get(key)
            if idx is None:
                idx = len(pos)
                keymap[key] = idx
                pos.append(p)
                nrm.append(n)
                cols.append(rgb)
                if uvl:
                    uvs.append(uv)
            tri.append(idx)
        faces.append(tuple(tri))
    bpy.data.meshes.remove(me)
    return pos, nrm, cols, faces, (uvs if uvl else None), len(faces)


def part_record(obj: bpy.types.Object, name: str, lod: int) -> tuple[dict, int]:
    mat = obj.get("rbx_material", "SmoothPlastic")
    pos, nrm, cols, faces, uvs, ntri = mesh_arrays(obj, mat in TEXTURED)
    gain = MATERIAL_GAIN.get(mat, 1.0)
    if gain != 1.0:
        cols = [tuple(min(255, round(c * gain)) for c in rgb) for rgb in cols]
    data = codec.encode(pos, nrm, cols, faces, uvs)
    mins = [min(p[i] for p in pos) for i in range(3)]
    maxs = [max(p[i] for p in pos) for i in range(3)]
    centre = [(mins[i] + maxs[i]) / 2 for i in range(3)]
    attrs = {
        "Part": obj.get("rbx_part", obj.name),
        "Material": mat,
        "Alpha": float(obj.get("rbx_alpha", 0.0)),
        "Lod": lod,
        "Tris": ntri,
        "CX": round(centre[0], 4),
        "CY": round(centre[1], 4),
        "CZ": round(centre[2], 4),
    }
    if "rbx_pivot" in obj.keys():
        pv = to_roblox(obj["rbx_pivot"])
        attrs.update({"PX": round(pv[0], 4), "PY": round(pv[1], 4), "PZ": round(pv[2], 4)})
    if obj.get("rbx_detail", False):
        attrs["Detail"] = True
    if "rbx_tags" in obj.keys():
        attrs["Tags"] = str(obj["rbx_tags"])
    return {"name": name, "className": "StringValue", "properties": {"Value": codec.to_text(data)}, "attributes": attrs}, ntri


def export_asset(asset: str, out_dir: Path, lod_ratio: float = 0.3, lod_min_tris: int = 400, meta: dict | None = None) -> dict:
    objs = [o for o in bpy.context.scene.objects if o.type == "MESH" and "rbx_material" in o.keys() and not o.hide_render]
    objs.sort(key=lambda o: o.name)
    children, total, total_lod = [], 0, 0
    names = set()
    for o in objs:
        name = o.name
        assert name not in names, f"duplicate part name {name}"
        names.add(name)
        rec, n = part_record(o, name, 0)
        children.append(rec)
        total += n
        if o.get("rbx_lod", True) and n >= lod_min_tris:
            lo = core.duplicate(o, name + "@lod1")
            core.add_modifier(lo, "DECIMATE", ratio=lod_ratio, use_collapse_triangulate=True)
            core.apply_modifiers(lo)
            rec1, n1 = part_record(lo, name + "@lod1", 1)
            rec1["attributes"]["Part"] = o.get("rbx_part", o.name)
            children.append(rec1)
            total_lod += n1
            bpy.data.objects.remove(lo)
        else:
            total_lod += n
    attrs = {"Asset": asset, "Format": "HCM1", "Tris": total, "TrisLod1": total_lod, "Parts": len(objs)}
    for k, v in (meta or {}).items():
        attrs[k] = v
    doc = {"className": "Folder", "attributes": attrs, "children": children}
    out_dir.mkdir(parents=True, exist_ok=True)
    path = out_dir / f"{asset}.model.json"
    path.write_text(json.dumps(doc, separators=(",", ":")))
    return {"asset": asset, "tris": total, "tris_lod1": total_lod, "parts": len(objs), "bytes": path.stat().st_size}


def export_glb(asset: str, out_dir: Path) -> Path:
    """glTF binary with PBR materials (baked maps), for Studio's 3D Importer (jg's step: an upload)."""
    out_dir.mkdir(parents=True, exist_ok=True)
    path = out_dir / f"{asset}.glb"
    for o in bpy.context.scene.objects:
        o.select_set(o.type == "MESH" and "rbx_material" in o.keys())
    bpy.ops.export_scene.gltf(filepath=str(path), use_selection=True, export_format="GLB", export_yup=True, export_texcoords=True,
                              export_normals=True, export_materials="EXPORT", export_vertex_color="ACTIVE", export_apply=True)
    return path


def export_fbx(asset: str, out_dir: Path) -> Path:
    out_dir.mkdir(parents=True, exist_ok=True)
    path = out_dir / f"{asset}.fbx"
    for o in bpy.context.scene.objects:
        o.select_set(o.type == "MESH" and "rbx_material" in o.keys())
    bpy.ops.export_scene.fbx(filepath=str(path), use_selection=True, apply_scale_options="FBX_SCALE_UNITS",
                             axis_forward="-Z", axis_up="Y", add_leaf_bones=False, bake_anim=False,
                             colors_type="SRGB", mesh_smooth_type="OFF", path_mode="COPY", embed_textures=True)
    return path
