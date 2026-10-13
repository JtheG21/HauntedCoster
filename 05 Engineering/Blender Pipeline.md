---
id: ENG-Blender-Pipeline
title: Blender Pipeline
type: index
status: approved
created: 2026-10-12
updated: 2026-10-12
tags:
  - engineering/pipeline
related:
  - "[[Asset Workflow]]"
  - "[[Resource Catalog]]"
---
# Blender ↔ Roblox Studio pipeline

How meshes, rigs and animations move between Blender and Studio. Process: [[Asset Workflow]].

**Status:**
- Export settings come from Roblox's docs (local clone `~/Code/creator-docs`: `art/blender.md`, `art/modeling/export-requirements.md` and `specifications.md`, read 2026-10-12).
- The exporter script is tested headlessly.
- **The Studio import is verified** ([[LES-0007-Blender-Studio-Scale]]): exact scale and orientation in FBX and glb. FBX is the default format. Approved by jg, 2026-10-12.

## Tool choices (checked live on GitHub, 2026-10-12)
| Need | Use | Why / caveats |
|---|---|---|
| **Static meshes and props** (most of our work) | Plain Blender export plus Studio's **3D Importer**, scripted with `scripts/blender/export_for_roblox.py` | No add-on to install or maintain. One command does the audit and export, so it costs little usage. Built-in Blender, so licence isn't a concern |
| **Animations** (when we have rigs) | **RBXMonkey / Blender Animations Plugin**, [cautioned/blender-animations-plugin](https://github.com/cautioned/blender-animations-plugin) (108★, pushed 2026-10-09, GPL-3.0) | The community standard: a Blender add-on plus a Studio plugin with live sync, rig import and animation export. GPL only matters if we copy its code, which we don't; using the tool is fine. The Studio plugin needs network permission. Install only when an animation task is approved |
| Bulk upload with asset-ID reuse | [TylerAtStarboard/Roblox-BlenderBridge](https://github.com/TylerAtStarboard/Roblox-BlenderBridge) (26★, MIT) | No API key; it re-uploads as new versions of the same asset. Small and young, and needs a Studio beta feature. **Revisit if we import many meshes** |
| Direct upload from Blender | [Roblox/roblox-blender-plugin](https://github.com/Roblox/roblox-blender-plugin) (official, 245★, MIT) | Uploads through the Open Cloud API, which needs a key and OAuth. **Not adopted:** uploads are jg's step, and keys stay out of this workflow |
| Avatar import and Roblox modelling helpers | [Gl2imm/RBX_Toolbox](https://github.com/Gl2imm/RBX_Toolbox) (99★, GPL-3.0, Blender 4.5+) | Only useful for avatar and accessory work, which isn't planned |

Excluded: `.mesh` exporters (an RBXMesh format the importer doesn't need); unlicensed animation forks; AI agent repos (out of scope).

## The fast path: Blender to Studio
1. **Once per `.blend`:** Scene > Units > **Unit System: None**, Rotation: Degrees. 1 Blender unit is then 1 stud.
2. **Model:**
   - Real size in studs, with the origin at the base centre and the front facing −Y in Blender.
   - Apply scale and rotation (Ctrl+A).
   - Use quads, and stay at **20,000 triangles or fewer per mesh**.
3. **Export (one command):**
   ```
   /Applications/Blender.app/Contents/MacOS/Blender --background model.blend \
     --python scripts/blender/export_for_roblox.py -- --out ~/Roblox-Work/exports [--format glb] [--per-object] [--anim]
   ```
   - The script audits first: triangles over the limit, unapplied scale, n-gons, missing UVs, scene units. It refuses to export on a hard error.
   - The FBX settings it applies: **Apply Scalings = FBX Unit Scale**, Forward Z, Up Y, **Add Leaf Bones off**, Bake Animation only with `--anim`, Path Mode Copy with embedded textures.
   - `--per-object` writes one file per top-level object, so each becomes its own MeshPart.
4. **Import in Studio** (File > Import 3D, which is **jg's step**: it uploads to the account):
   - World Forward: **Front**; World Up: **Top**; Scale Unit: **Stud**.
   - **Insert Using Scene Position** if the Blender placement matters. **Import Only as a Model** for multi-part assets.
   - Creator: the group that owns the game.
5. In Studio:
   - Set `CollisionFidelity` (Box, Hull or Default) and `RenderFidelity = Automatic`.
   - Set `CanCollide` false for decor.
   - Reuse one MeshId for copies.
   - Then reference the asset from code. Wire behaviour in Luau, not in the mesh.

**Format: FBX by default** (verified: flat, object-named MeshParts). glb is equally accurate, but nests each object in its own Model and names parts after the mesh data ([[LES-0007-Blender-Studio-Scale]]).

## Studio to Blender (editing an existing Roblox asset)
- In Studio, right-click the part or model, choose **Export Selection** and save it as `.obj`. Avatars and rigs go through the animation plugin's rig export.
- **Blender import:** Scale 1, Forward Axis **Z**, Up Axis **Y**.
- Round trip: edit, then export with the script, then re-import. Re-importing creates a **new** asset ID unless a versioning tool such as BlenderBridge is used.

## Do
- Keep the source `.blend` and the export command together. Exports are disposable; the `.blend` is the source of truth. Store them outside the vault: `~/Roblox-Work/<game>/art/`, not in Git.
- Name objects in Blender the way they should appear in Studio. The names carry over.
- Check new assets at gameplay distance next to a character before dressing a whole area with them.
- Batch imports. One import session per asset set keeps uploads and usage low.

## Don't
- **Don't change Blender's Unit Scale to 0.01 or export at Scale 0.01.** Both work, but break round trips and cause camera and modifier problems (Roblox docs). Use FBX Unit Scale.
- **Don't leave scale or rotation unapplied.** Studio bakes it in oddly, and collisions and pivots go wrong.
- **Don't export leaf bones**, and don't bake animation for static meshes.
- **Don't exceed 20,000 triangles per mesh**, and don't rely on n-gons. Split big assets into several meshes.
- **Don't trust tutorials or downloaded files' scale settings.** The Roblox docs warn they are often inconsistent. Test one cube first.
- **Don't upload without jg**: neither the importer nor any Open Cloud plugin. Never store an Open Cloud key in the repo.
- **Don't run AI mesh generation** (Studio MCP `generate_mesh` and similar) without approval.
- **Don't import a whole scene as one mesh.** Collisions and streaming suffer. Use `--per-object` or Import Only as a Model.
- **Don't put scripts in imported models.** Wire them from code.

## Verification
Done on 2026-10-12. See [[LES-0007-Blender-Studio-Scale]]. Re-run the test (`~/Roblox-Work/blender-scale-test/`) after a Blender or Studio importer update.
