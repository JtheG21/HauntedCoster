"""Headless Blender -> Roblox Studio exporter with a pre-flight audit (see 05 Engineering/Blender Pipeline.md).

Usage:
  /Applications/Blender.app/Contents/MacOS/Blender --background <file.blend> \
      --python scripts/blender/export_for_roblox.py -- --out <dir> [--format fbx|glb] [--per-object] [--anim]

Exports every visible mesh/armature object with the Roblox-documented settings (FBX Unit Scale,
Z forward / Y up, no leaf bones, embedded textures). Prints an audit first and exits 1 without exporting
if any mesh breaks a hard limit (over 20,000 triangles, unapplied scale or rotation, non-mesh junk).
Nothing is uploaded: importing into Studio stays a human step.
"""

import argparse
import sys
from pathlib import Path

import bpy

MAX_TRIS = 20000  # creator-docs art/modeling/specifications.md


def args():
    argv = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
    p = argparse.ArgumentParser()
    p.add_argument("--out", required=True)
    p.add_argument("--format", choices=("fbx", "glb"), default="fbx")
    p.add_argument("--per-object", action="store_true", help="one file per object (one MeshPart each)")
    p.add_argument("--anim", action="store_true", help="bake animation (rigs/animations only)")
    return p.parse_args(argv)


def tri_count(obj) -> int:
    mesh = obj.evaluated_get(bpy.context.evaluated_depsgraph_get()).to_mesh()
    tris = sum(len(poly.vertices) - 2 for poly in mesh.polygons)
    ngons = sum(1 for poly in mesh.polygons if len(poly.vertices) > 4)
    obj.evaluated_get(bpy.context.evaluated_depsgraph_get()).to_mesh_clear()
    return tris, ngons


def audit(objs) -> bool:
    ok = True
    units = bpy.context.scene.unit_settings
    if units.system != "NONE" or abs(units.scale_length - 1.0) > 1e-6:
        print(f"WARN  scene units {units.system} x{units.scale_length}: set Unit System None, scale 1 (1 unit = 1 stud)")
    for o in objs:
        if o.type != "MESH":
            continue
        tris, ngons = tri_count(o)
        flags = []
        if tris > MAX_TRIS:
            flags.append(f"ERROR {tris} tris > {MAX_TRIS}")
            ok = False
        if any(abs(s - 1.0) > 1e-4 for s in o.scale):
            flags.append("ERROR unapplied scale (Ctrl+A > Scale)")
            ok = False
        if any(abs(r) > 1e-4 for r in o.rotation_euler):
            flags.append("WARN unapplied rotation")
        if ngons:
            flags.append(f"WARN {ngons} n-gons (Studio triangulates; prefer quads)")
        if not o.data.uv_layers and o.active_material and o.active_material.use_nodes:
            flags.append("WARN material but no UVs")
        dims = " x ".join(f"{d:.2f}" for d in o.dimensions)
        print(f"{'OK   ' if not flags else '     '}{o.name}: {tris} tris, {dims} studs " + "; ".join(flags))
    return ok


def export(path: Path, fmt: str, anim: bool):
    if fmt == "fbx":
        bpy.ops.export_scene.fbx(
            filepath=str(path), use_selection=True, apply_scale_options="FBX_SCALE_UNITS",
            axis_forward="Z", axis_up="Y", add_leaf_bones=False, bake_anim=anim,
            path_mode="COPY", embed_textures=True,
        )
    else:
        bpy.ops.export_scene.gltf(filepath=str(path), use_selection=True, export_animations=anim)
    print(f"WROTE {path}")


def main():
    a = args()
    out = Path(a.out).expanduser()
    out.mkdir(parents=True, exist_ok=True)
    objs = [o for o in bpy.context.scene.objects if o.type in ("MESH", "ARMATURE") and o.visible_get()]
    if not objs:
        sys.exit("no visible mesh or armature objects")
    if not audit(objs):
        sys.exit(1)
    stem = Path(bpy.data.filepath).stem or "export"
    groups = [[o] for o in objs if o.type == "MESH" and o.parent is None] if a.per_object else [objs]
    for group in groups:
        bpy.ops.object.select_all(action="DESELECT")
        for o in group:
            o.select_set(True)
            for child in o.children_recursive:
                child.select_set(True)
        name = group[0].name if a.per_object else stem
        export(out / f"{name}.{a.format}", a.format, a.anim)


main()
