#!/usr/bin/env python3
"""Rebuild local demo pixel payloads from preserved originals (Python 3.15+)."""
import argparse
import base64
from compression import zstd
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile

parser = argparse.ArgumentParser()
parser.add_argument('--image-python', required=True, help='Python interpreter with Pillow installed')
args = parser.parse_args()
root = Path(__file__).resolve().parent
project_path = root / 'demo.project.json'
project = json.loads(project_path.read_text())
convert = '''from PIL import Image
from pathlib import Path
import sys,json,base64
source,dest,w,h=sys.argv[1:]
image=Image.open(source).convert('RGBA').resize((int(w),int(h)),Image.Resampling.LANCZOS)
indexed=image.quantize(colors=128,method=Image.Quantize.FASTOCTREE)
Path(dest+'/indices').write_bytes(indexed.tobytes())
Path(dest+'/palette').write_bytes(bytes(indexed.getpalette('RGBA')))
'''
records = []
for name, filename, width, height in [
    ('ArtData', 'halloween-fidelity-desktop.png', 768, 682),
    ('PortraitArtData', 'halloween-fidelity-portrait.png', 576, 768),
    ('SpriteArtData', 'halloween-sprite-atlas.png', 768, 768),
    ('RootArtData', 'halloween-rooted-foliage-atlas.png', 1024, 342),
    ('TreeArtData', 'halloween-tree-curled-tip.png', 1024, 342),
]:
    source = root / 'art' / filename
    with tempfile.TemporaryDirectory(prefix='feedback-pixels-') as scratch:
        subprocess.run([args.image_python, '-c', convert, str(source), scratch, str(width), str(height)], check=True)
        indices = (Path(scratch) / 'indices').read_bytes()
        palette = (Path(scratch) / 'palette').read_bytes()
    assert len(indices) == width * height and len(palette) % 4 == 0
    assert max(indices) * 4 + 4 <= len(palette)
    compressed = zstd.compress(indices, level=12)
    assert zstd.decompress(compressed) == indices
    encoded = base64.b64encode(compressed).decode()
    folder = {'$className': 'Folder'}
    for key, value in [('Width', width), ('Height', height)]:
        folder[key] = {'$className': 'IntValue', '$properties': {'Value': value}}
    folder['Palette'] = {'$className': 'StringValue', '$properties': {'Value': base64.b64encode(palette).decode()}}
    for i, begin in enumerate(range(0, len(encoded), 24000), 1):
        folder[f'Chunk{i:03}'] = {'$className': 'StringValue', '$properties': {'Value': encoded[begin:begin + 24000]}}
    project['tree']['ReplicatedStorage']['FeedbackDemo'][name] = folder
    records.append({'folder': name, 'source': filename, 'source_sha256': hashlib.sha256(source.read_bytes()).hexdigest(),
                    'width': width, 'height': height, 'palette_entries': len(palette) // 4,
                    'indices_sha256': hashlib.sha256(indices).hexdigest(), 'compressed_bytes': len(compressed)})
project_path.write_text(json.dumps(project, indent=2) + '\n')
(root / 'art' / 'payload-provenance.json').write_text(json.dumps(records, indent=2) + '\n')
print('Verified and rebuilt desktop and portrait art payloads.')
