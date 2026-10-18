#!/usr/bin/env python3
"""Add and validate self-contained GLB review packages; no network or credentials."""
import argparse
import hashlib
import json
import math
import os
import pathlib
import re
import shutil
import struct
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[1]
LIBRARY = ROOT / 'library'
MAX_BYTES = 250 * 1024 * 1024


def inspect_glb(path):
    if path.stat().st_size > MAX_BYTES:
        raise ValueError('GLB exceeds 250 MiB')
    with path.open('rb') as source:
        header = source.read(20)
        if len(header) != 20:
            raise ValueError('Truncated GLB')
        magic, version, size, chunk_size, chunk_type = struct.unpack('<IIIII', header)
        if magic != 0x46546C67 or version != 2 or size != path.stat().st_size or chunk_type != 0x4E4F534A or chunk_size > size - 20:
            raise ValueError('Invalid GLB 2.0 header or length')
        document = json.loads(source.read(chunk_size))
    if not isinstance(document, dict) or not document.get('meshes'):
        raise ValueError('GLB has no meshes')
    asset = document.get('asset')
    if not isinstance(asset, dict) or asset.get('version') != '2.0':
        raise ValueError('Only glTF 2.0 is supported')
    resources = []
    for field in ('buffers', 'images', 'animations', 'meshes'):
        members = document.get(field, [])
        if not isinstance(members, list) or any(not isinstance(member, dict) for member in members):
            raise ValueError(f'GLB {field} must be an array of objects')
        if field in ('buffers', 'images'):
            resources.extend(members)
    required = document.get('extensionsRequired', [])
    if not isinstance(required, list) or any(not isinstance(extension, str) for extension in required):
        raise ValueError('GLB extensionsRequired must be an array of strings')
    for resource in resources:
        uri = resource.get('uri')
        if uri is not None and (not isinstance(uri, str) or not uri.startswith('data:')):
            raise ValueError('Package GLB must embed all textures and buffers')
    unsupported = set(required) & {'KHR_draco_mesh_compression', 'KHR_texture_basisu', 'EXT_meshopt_compression'}
    if unsupported:
        raise ValueError(f'Convert compressed GLB before adding: {sorted(unsupported)}')
    return document


def atomic_json(path, value):
    with tempfile.NamedTemporaryFile('w', dir=path.parent, delete=False) as output:
        temp = pathlib.Path(output.name)
        json.dump(value, output, indent=2, allow_nan=False)
        output.write('\n')
    os.replace(temp, path)


def validate_scene(scene):
    defaults = {'version': 1, 'model': None, 'camera': None, 'target': None,
                'lighting': 'studio', 'background': '#111923', 'exposure': 1,
                'grid': True, 'wireframe': False, 'turntable': False,
                'effect': 'none', 'effectColor': '#67e8ce', 'effectIntensity': 1,
                'mappings': {'Idle': '', 'Move': '', 'Ability': ''},
                'clip': '', 'time': 0, 'speed': 1, 'loop': True}
    if not isinstance(scene, dict) or scene.get('version') != 1 or set(scene) - set(defaults):
        raise ValueError('Invalid scene version or unknown fields')
    bounds = {'exposure': (.1, 3), 'effectIntensity': (0, 3), 'time': (0, 86400), 'speed': (.1, 3)}
    enums = {'lighting': {'studio', 'bright', 'night'}, 'effect': {'none', 'aura', 'sparks', 'rings'}}
    for key, value in scene.items():
        valid = True
        if key in bounds:
            lo, hi = bounds[key]
            valid = type(value) in (int, float) and math.isfinite(value) and lo <= value <= hi
        elif key in enums:
            valid = isinstance(value, str) and value in enums[key]
        elif key in ('grid', 'wireframe', 'turntable', 'loop'):
            valid = type(value) is bool
        elif key in ('background', 'effectColor'):
            valid = isinstance(value, str) and bool(re.fullmatch(r'#[0-9a-fA-F]{6}', value))
        elif key in ('camera', 'target'):
            valid = value is None or (isinstance(value, list) and len(value) == 3 and all(type(n) in (int, float) and math.isfinite(n) and abs(n) <= 1e9 for n in value))
        elif key == 'mappings':
            valid = isinstance(value, dict) and set(value) == {'Idle', 'Move', 'Ability'} and all(isinstance(v, str) and len(v) <= 512 for v in value.values())
        elif key == 'clip':
            valid = isinstance(value, str) and len(value) <= 512
        elif key == 'model':
            valid = value is None or (isinstance(value, str) and bool(re.fullmatch(r'library/[a-zA-Z0-9_-]+/model\.glb', value)))
        if not valid:
            raise ValueError(f'Invalid scene field: {key}')
    return scene


def validate_package(folder):
    if not folder.is_dir() or folder.is_symlink() or not re.fullmatch(r'[a-zA-Z0-9_-]+', folder.name):
        raise ValueError(f'Invalid package folder: {folder.name}')
    for name in ['model.glb', 'scene.json', 'manifest.json']:
        path = folder / name
        if path.is_symlink() or not path.is_file():
            raise ValueError(f'Missing or symlinked {name} in {folder.name}')
    inspect_glb(folder / 'model.glb')
    manifest = json.loads((folder / 'manifest.json').read_text())
    if not isinstance(manifest, dict):
        raise ValueError(f'Invalid manifest object: {folder.name}')
    scene = validate_scene(json.loads((folder / 'scene.json').read_text()))
    expected = f'library/{folder.name}/model.glb'
    if scene.get('version') != 1 or scene.get('model') != expected:
        raise ValueError(f'Scene version/model mismatch: {folder.name}')
    if manifest.get('version') != 1 or manifest.get('model') != expected or not isinstance(manifest.get('name'), str):
        raise ValueError(f'Invalid manifest: {folder.name}')
    digest = hashlib.sha256((folder / 'model.glb').read_bytes()).hexdigest()
    if manifest.get('sha256') != digest:
        raise ValueError(f'Model hash mismatch: {folder.name}; create a new package revision')
    return {'name': manifest['name'], 'model': expected}


def rebuild(library=LIBRARY, dry_run=False):
    library.mkdir(parents=True, exist_ok=True)
    entries = [validate_package(p) for p in sorted(library.iterdir()) if p.is_dir() and not p.name.startswith('.')]
    if not dry_run:
        atomic_json(library / 'index.json', entries)
    return entries


def add(source, slug, name=None, library=LIBRARY, scene_source=None):
    if not re.fullmatch(r'[a-zA-Z0-9_-]+', slug):
        raise ValueError('ID must contain only letters, numbers, underscores or hyphens')
    document = inspect_glb(source)
    destination = library / slug
    if destination.exists():
        raise ValueError(f'Package {slug} already exists. Use a new revision ID; existing files are never overwritten.')
    # Validate existing packages before writing anything.
    rebuild(library, dry_run=True)
    model = f'library/{slug}/model.glb'
    scene = {'version': 1, 'model': model}
    if scene_source:
        scene = validate_scene(json.loads(scene_source.read_text()))
        if not isinstance(scene, dict) or scene.get('version') != 1:
            raise ValueError('Unsupported scene version')
        scene['model'] = model
    with tempfile.TemporaryDirectory(dir=library, prefix='.staging-') as temp:
        staging = pathlib.Path(temp)
        shutil.copyfile(source, staging / 'model.glb')
        atomic_json(staging / 'scene.json', scene)
        atomic_json(staging / 'manifest.json', {'version': 1, 'name': name or slug, 'model': model, 'source_filename': source.name, 'sha256': hashlib.sha256(source.read_bytes()).hexdigest(), 'clips': [a.get('name', '') for a in document.get('animations', [])]})
        staging.rename(destination)
        # TemporaryDirectory handles an already moved directory without touching destination.
    rebuild(library)
    return destination


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    subs = parser.add_subparsers(dest='command', required=True)
    adding = subs.add_parser('add')
    adding.add_argument('source', type=pathlib.Path)
    adding.add_argument('--id', required=True)
    adding.add_argument('--name')
    adding.add_argument('--scene', type=pathlib.Path, help='Scene JSON exported by the viewer')
    checking = subs.add_parser('validate')
    checking.add_argument('--dry-run', action='store_true')
    args = parser.parse_args()
    try:
        if args.command == 'add':
            print(add(args.source, args.id, args.name, scene_source=args.scene))
        else:
            entries = rebuild(dry_run=args.dry_run)
            print(f'{len(entries)} packages valid' + (' (index unchanged)' if args.dry_run else ' (index rebuilt)'))
    except (ValueError, OSError, KeyError, TypeError) as exc:
        parser.exit(1, f'Library validation failed: {exc}\n')

if __name__ == '__main__':
    main()
