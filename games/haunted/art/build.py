"""Builds Haunted Collector art assets headlessly.

  /Applications/Blender.app/Contents/MacOS/Blender -b --factory-startup -P games/haunted/art/build.py -- \
      --asset lamp_post [--asset ...|--all] [--render] [--night] [--noglow] [--export] [--fbx]

--export writes games/haunted/src/shared/ArtData/<asset>.model.json (runtime EditableMesh data);
--render writes preview sheets to ~/Roblox-Work/haunted/art/previews/; --fbx writes the import file for
jg's batch Studio import (an upload, so a human step). Asset generators live in art/assets/*.py and
register themselves in ASSETS.
"""

from __future__ import annotations

import argparse
import importlib
import json
import pkgutil
import sys
import time
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

import bpy  # noqa: E402

from hcart import core, export, render  # noqa: E402

GAME = HERE.parent
DATA = GAME / "src" / "shared" / "ArtData"
WORK = Path.home() / "Roblox-Work" / "haunted" / "art"


def registry() -> dict:
    import assets

    reg = {}
    for m in pkgutil.iter_modules(assets.__path__):
        mod = importlib.import_module(f"assets.{m.name}")
        for name, fn in getattr(mod, "ASSETS", {}).items():
            assert name not in reg, f"duplicate asset {name}"
            reg[name] = fn
    return reg


def main() -> None:
    argv = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
    p = argparse.ArgumentParser()
    p.add_argument("--asset", action="append", default=[])
    p.add_argument("--all", action="store_true")
    p.add_argument("--prefix", default=None)
    p.add_argument("--render", action="store_true")
    p.add_argument("--night", action="store_true")
    p.add_argument("--noglow", action="store_true")
    p.add_argument("--export", action="store_true")
    p.add_argument("--fbx", action="store_true")
    p.add_argument("--tile", type=int, default=400)
    p.add_argument("--views", default="0,40,90,180")
    p.add_argument("--focus", default=None, help="x,y,z,size (Blender space) for a close-up sheet")
    a = p.parse_args(argv)
    reg = registry()
    names = sorted(reg) if a.all else [n for n in sorted(reg) if a.prefix and n.startswith(a.prefix)] + a.asset
    report = []
    for name in names:
        if name not in reg:
            raise SystemExit(f"unknown asset {name}; known: {', '.join(sorted(reg))}")
        t = time.time()
        core.reset_scene()
        meta = reg[name]() or {}
        info = {"asset": name}
        if a.export:
            info.update(export.export_asset(name, DATA, meta=meta))
        if a.fbx:
            export.export_fbx(name, WORK / "fbx")
        views = tuple(int(v) for v in a.views.split(","))
        if a.render:
            (WORK / "previews").mkdir(parents=True, exist_ok=True)
            render.contact_sheet(WORK / "previews" / f"{name}.png", tile=a.tile, views=views)
        if a.night:
            render.contact_sheet(WORK / "previews" / f"{name}_night.png", tile=a.tile, night=True, views=views)
        if a.focus:
            f = tuple(float(v) for v in a.focus.split(","))
            render.contact_sheet(WORK / "previews" / f"{name}_focus.png", tile=a.tile, views=views, focus=f)
        if a.noglow:
            render.contact_sheet(WORK / "previews" / f"{name}_noglow.png", tile=a.tile, no_glow=True, views=views)
        info["seconds"] = round(time.time() - t, 1)
        info["tris_scene"] = sum(core.tri_count(o) for o in bpy.context.scene.objects if o.type == "MESH" and "rbx_material" in o.keys())
        report.append(info)
        print("ASSET", json.dumps(info))


if __name__ == "__main__":
    main()
