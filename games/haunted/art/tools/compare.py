"""Side-by-side reference comparison: builds an asset, renders it from cameras matched to each reference view, and
tiles reference | render rows into one sheet (the standard for judging a model against its approved concept).

  Blender -b --factory-startup -P games/haunted/art/tools/compare.py -- --asset creature_wisp \
      --ref "02 Research/assets/wisp-pilot/wisp-approved-concept.png" \
      --view "0,0,860,1287:yaw=-8,el=16,lens=50" --view "730,250,1222,1287:yaw=150,el=14,lens=50" \
      --out ~/Roblox-Work/haunted/art/previews/creature_wisp_compare.png [--height 700] [--samples 48]

Each --view is "x0,y0,x1,y1:yaw=..,el=..,lens=..[,fill=..][,dx=..][,dz=..]": the reference crop in pixels (top-left
origin) and the matching camera (yaw 0 = looking at the asset's front, -Y; positive yaw orbits toward +X).
`fill` is the fraction of the frame height the asset spans (default 0.94); dx/dz shift the framing centre (studs).
The neutral studio light and grey background imitate a concept render; this is a look comparison, not game lighting.
"""

import argparse
import math
import sys
from pathlib import Path

import bpy
import numpy as np
from mathutils import Vector

HERE = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(HERE))

from hcart import core, render  # noqa: E402


def parse_view(s: str) -> dict:
    crop, _, cam = s.partition(":")
    x0, y0, x1, y1 = (int(v) for v in crop.split(","))
    opts = {"yaw": 0.0, "el": 12.0, "lens": 50.0, "fill": 0.94, "dx": 0.0, "dz": 0.0}
    for kv in filter(None, cam.split(",")):
        k, v = kv.split("=")
        opts[k.strip()] = float(v)
    opts["crop"] = (x0, y0, x1, y1)
    return opts


def load_ref(path: Path):
    img = bpy.data.images.load(str(path))
    img.colorspace_settings.name = "Non-Color"  # raw sRGB values, so the sheet matches the original file
    w, h = img.size
    arr = np.array(img.pixels[:], dtype=np.float32).reshape(h, w, 4)[::-1]  # top row first
    bpy.data.images.remove(img)
    return arr


def resize(arr, h_out):
    h, w = arr.shape[:2]
    w_out = max(1, round(w * h_out / h))
    ys = (np.arange(h_out) * h / h_out).astype(int)
    xs = (np.arange(w_out) * w / w_out).astype(int)
    return arr[ys][:, xs]


def setup_scene(samples: int, bg=(0.155, 0.16, 0.175)):
    sc = bpy.context.scene
    for o in list(sc.objects):
        if o.type == "MESH" and "rbx_material" in o.keys() and "rbx_baked" not in o.keys():
            o.data.materials.clear()
            o.data.materials.append(render._material(o, False))
            if o.get("rbx_part") == "Ember":
                o.hide_render = True
    world = bpy.data.worlds.new("cmp")
    sc.world = world
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (*bg, 1)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.55
    for name, rot, energy in (("key", (42, 0, -35), 3.4), ("fill", (65, 0, 140), 0.35), ("rim", (15, 0, 190), 2.2)):
        ld = bpy.data.lights.new(name, "SUN")
        ld.energy = energy
        ld.angle = math.radians(12)
        lo = bpy.data.objects.new(name, ld)
        lo.rotation_euler = tuple(math.radians(a) for a in rot)
        sc.collection.objects.link(lo)
    sc.render.engine = "CYCLES"
    sc.cycles.samples = samples
    sc.cycles.use_denoising = True
    sc.render.film_transparent = False
    sc.view_settings.view_transform = "Standard"


def render_view(opts, w, h, tmp: Path):
    sc = bpy.context.scene
    pts = []
    for o in sc.objects:
        if o.type == "MESH" and not o.hide_render:
            pts += [o.matrix_world @ Vector(c) for c in o.bound_box]
    lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    centre = (lo + hi) / 2 + Vector((opts["dx"], 0, opts["dz"]))
    height = hi.z - lo.z
    cam_data = bpy.data.cameras.new("cmp")
    cam_data.lens = opts["lens"]
    cam_data.sensor_fit = "VERTICAL"
    cam = bpy.data.objects.new("cmp", cam_data)
    sc.collection.objects.link(cam)
    sc.camera = cam
    fov = 2 * math.atan(cam_data.sensor_height / (2 * cam_data.lens))
    dist = (height / opts["fill"]) / (2 * math.tan(fov / 2)) * 1.05
    a = math.radians(opts["yaw"] - 90)
    el = math.radians(opts["el"])
    cam.location = centre + Vector((math.cos(a) * math.cos(el), math.sin(a) * math.cos(el), math.sin(el))) * dist
    cam.rotation_euler = (centre - cam.location).to_track_quat("-Z", "Y").to_euler()
    sc.render.resolution_x = w
    sc.render.resolution_y = h
    sc.render.filepath = str(tmp)
    bpy.ops.render.render(write_still=True)
    img = bpy.data.images.load(str(tmp))
    img.colorspace_settings.name = "Non-Color"
    arr = np.array(img.pixels[:], dtype=np.float32).reshape(h, w, 4)[::-1]
    bpy.data.images.remove(img)
    tmp.unlink()
    bpy.data.objects.remove(cam)
    return arr


def main():
    argv = sys.argv[sys.argv.index("--") + 1:]
    p = argparse.ArgumentParser()
    p.add_argument("--asset", required=True)
    p.add_argument("--ref", required=True)
    p.add_argument("--view", action="append", required=True)
    p.add_argument("--out", required=True)
    p.add_argument("--height", type=int, default=700)
    p.add_argument("--samples", type=int, default=48)
    p.add_argument("--bake", action="store_true", help="render the baked game mesh + maps instead of the source")
    a = p.parse_args(argv)
    sys.argv = [sys.argv[0]]
    import build  # noqa: E402  (registry of asset generators)

    reg = build.registry()
    core.reset_scene()
    reg[a.asset]()
    if a.bake:
        print("BAKE", build.bake_asset(a.asset, reg))
    setup_scene(a.samples)
    ref = load_ref(Path(a.ref).expanduser())
    out = Path(a.out).expanduser()
    rows = []
    for i, s in enumerate(a.view):
        v = parse_view(s)
        x0, y0, x1, y1 = v["crop"]
        crop = resize(ref[y0:y1, x0:x1], a.height)
        h, w = crop.shape[:2]
        rnd = render_view(v, w, h, out.with_name(f"_cmp_{i}.png"))
        gap = np.ones((h, 8, 4), dtype=np.float32)
        rows.append(np.concatenate([crop, gap, rnd], axis=1))
    width = max(r.shape[1] for r in rows)
    rows = [np.pad(r, ((0, 0), (0, width - r.shape[1]), (0, 0)), constant_values=1.0) for r in rows]
    sheet = np.concatenate(rows, axis=0)[::-1]
    img = bpy.data.images.new("cmp_sheet", sheet.shape[1], sheet.shape[0], alpha=True)
    img.colorspace_settings.name = "Non-Color"
    img.pixels = sheet.ravel()
    img.filepath_raw = str(out)
    img.file_format = "PNG"
    img.save()
    print("COMPARE", out)


main()
