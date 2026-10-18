"""Tiles preview PNGs into one review sheet (row-major, in the given order), using Blender's bundled numpy.

  Blender -b --factory-startup -P games/haunted/art/tools/montage.py -- out.png a.png b.png ... [--cols 4] [--cell 300]
"""

import sys

import bpy
import numpy as np

argv = sys.argv[sys.argv.index("--") + 1 :]
cols, cell = 4, 300
if "--cols" in argv:
    i = argv.index("--cols")
    cols = int(argv[i + 1])
    del argv[i : i + 2]
if "--cell" in argv:
    i = argv.index("--cell")
    cell = int(argv[i + 1])
    del argv[i : i + 2]
out, files = argv[0], argv[1:]
rows = (len(files) + cols - 1) // cols
sheet = np.full((rows * cell, cols * cell, 4), 0.12, dtype=np.float32)
sheet[..., 3] = 1
for k, f in enumerate(files):
    img = bpy.data.images.load(f)
    w, h = img.size
    px = np.array(img.pixels[:], dtype=np.float32).reshape(h, w, 4)
    ys = (np.arange(cell) * h / cell).astype(int)
    xs = (np.arange(cell) * w / cell).astype(int)
    small = px[ys][:, xs]
    r, c = divmod(k, cols)
    sheet[(rows - 1 - r) * cell : (rows - r) * cell, c * cell : (c + 1) * cell] = small
    bpy.data.images.remove(img)
im = bpy.data.images.new("montage", cols * cell, rows * cell, alpha=True)
im.pixels = sheet.ravel()
im.filepath_raw = out
im.file_format = "PNG"
im.save()
print("MONTAGE", out)
