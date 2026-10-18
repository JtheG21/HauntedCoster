"""Blender background conversion; run with Blender --background --factory-startup --python FILE -- SOURCE OUTPUT.glb."""
import pathlib
import sys
import bpy

args = sys.argv[sys.argv.index('--') + 1:]
if len(args) != 2:
    raise SystemExit('Expected SOURCE.fbx|obj OUTPUT.glb')
source, output = map(lambda value: pathlib.Path(value).expanduser().resolve(), args)
if source == output or output.exists():
    raise SystemExit('Output already exists; choose a new filename. Originals are never overwritten.')
if not source.is_file() or output.suffix.lower() != '.glb':
    raise SystemExit('Source must exist and output must be .glb')
bpy.ops.wm.read_factory_settings(use_empty=True)
if source.suffix.lower() == '.fbx':
    bpy.ops.import_scene.fbx(filepath=str(source))
elif source.suffix.lower() == '.obj':
    bpy.ops.wm.obj_import(filepath=str(source))
else:
    raise SystemExit('Only FBX and OBJ conversion is supported')
bpy.ops.export_scene.gltf(filepath=str(output), export_format='GLB', export_animations=True)
if not output.is_file():
    raise SystemExit('Blender did not produce the expected GLB')
print(f'Converted {source.name} -> {output}; review scale, materials, axes and animations before use.')
