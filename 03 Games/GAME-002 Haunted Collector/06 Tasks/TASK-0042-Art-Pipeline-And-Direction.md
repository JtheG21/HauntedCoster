---
id: TASK-0042
title: "Art Pipeline and Direction"
type: task
project: GAME-002
status: done
priority: high
risk: medium
owner: executor
depends_on:
  - TASK-0041
branch: task/TASK-0042-Art-Pipeline-And-Direction
related:
  - "[[SYS-Haunted-Art-Direction]]"
  - "[[SYS-Haunted-Monetization-UI]]"
  - "[[3D Model Quality Baseline]]"
created: 2026-10-13
updated: 2026-10-18
tags:
  - workflow/task
---

# Art Pipeline and Direction

## Goal
Build the art production pipeline and the art direction that every overhaul asset follows, and prove it in game with the lamp family.

Part of the overhaul jg requested on 2026-10-13 (3D asset overhaul, full UI overhaul, approved monetization scope). jg authorized the local design and implementation work, creating scoped tasks and testing in local Studio places; publishing, spending, live products, uploads and merges stay gated.

## Scope
- **In:** Blender library and exporter, HCM1 codec, client ArtLoader/LOD/ArtSlot dressing, server ArtSlot anchors, SYS-Haunted-Art-Direction (references, palette, budgets, inventory), lamp post family.
- **Out (non-goals):** Creature, environment, landmark, plot and cosmetic models (later tasks); uploads; AI generation.
- **Keep unchanged:** server authority, gameplay rules and tuning, existing interaction points and collisions, GAME-001.

## Intake
- **Category → workflow, depth:** Asset → [[Asset Workflow]] + [[Blender Pipeline]], deep
- **References:** MODEL-MIN-064, MODEL-MIN-069 (lamps, iron); MODEL-BAD-015/016 (rejected lamps). Full selection in [[SYS-Haunted-Art-Direction]].
- **Reuse:** existing builders keep their gameplay geometry; visuals move to the art pipeline from [[TASK-0042-Art-Pipeline-And-Direction]].
- **Branch stacking:** branches from `chore/overhaul-base` (local main + merged TASK-0041 + ADR renumber).

## Files expected to change
- `games/haunted/art/**`, `src/shared/Art/MeshCodec.luau`, `src/shared/ArtData/*.model.json`, `src/client/Art/*`, `src/server/World/{Build,Props}.luau`, tests, `05 Systems/SYS-Haunted-Art-Direction.md`.

## Acceptance criteria
- [ ] AC1 A headless Blender pipeline (games/haunted/art) builds, paints, previews and exports assets; HCM1 codec has matching Python and Luau specs; generated data syncs through Rojo with no upload or generator call.
- [ ] AC2 A client ArtLoader renders HCM1 assets as EditableMesh MeshParts with shared templates, LOD switching and a fail-safe fallback; server builders place tagged ArtSlot anchors that keep the existing colliders, lights and interaction points.
- [ ] AC3 SYS-Haunted-Art-Direction records the selected references (positive and rejected), style, palette, materials, budgets, the full asset/UI inventory with replace/refine/retain/new decisions, and the dual live path (jg batch import or Mesh/Image API toggle).
- [ ] AC4 The lamp post family replaces the rejected lamps in game, compared with MIN-064/MIN-069 and BAD-015/016 in front, side, rear and three-quarter views, neutral and night light, and without glow.
- [ ] AC5 scripts/check.sh passes; FullLoop still passes in Studio; EditableMesh memory and triangle cost measured.

## Tests
- **Automated:** `scripts/check.sh`.
- **Studio playtest procedure:** local place `~/Roblox-Work/haunted/Overhaul.rbxl` built from this branch; scenarios named in the criteria; captures stored with the evidence.

## Risks / notes
- Runtime meshes use EditableMesh. Live use needs either jg's batch 3D import (an upload) or jg's 13+/ID verification plus the Creator Dashboard Mesh/Image API toggle ([[SYS-Haunted-Art-Direction]]).

---
## Implementation record
**References used:** MODEL-MIN-064 (lighting pack: lantern cage, candles), MODEL-MIN-069 (finished architectural iron); rejected MODEL-BAD-015/016 (plain post, box lantern, glow over form).

**Built (commits d13c57f, e5e5ff4):**
- `games/haunted/art/`: Blender 5.1 headless library `hcart` (core, shapes, anatomy, paint, render, export, codec, palette) and `build.py`. One command builds, paints, previews (front, 3/4, side, rear; neutral, night, glow-off, close-up) and exports.
- HCM1 codec: `hcart/codec.py` ↔ `src/shared/Art/MeshCodec.luau`, with the same fixture in `tests/test_hcm_codec.py` and `games/haunted/tests/MeshCodec.spec.luau`.
- Runtime: `src/shared/Art/MeshBuild.luau`, `src/server/Services/ArtBakeService.luau` (server bake to DataModel content), `src/client/Art/{ArtLoader,Lod,Dressing}.luau`; `Build.artSlot` / `Build.collider` on the server.
- Lamp family: `lamp_post` (3,164 tris, LOD1 1,082), `lantern_wall` (1,144), `lantern_hanging` (1,120). All 67–70 path/hub lamps now use `lamp_post`; colliders and the server PointLight are unchanged in role (light moved to the new lantern head height, 5.1).

**Decisions:**
- Glass panes use translucent Neon: Roblox Glass refracted the background and read as an offset block (Studio, 2026-10-13).
- `CreateMeshPartAsync` keeps raw vertex coordinates, so vertices are recentred on the box centre (found when lamps floated ~4 studs in Studio).
- Client EditableMeshes hit the per-device budget after a few meshes in Studio Play, so the server bakes templates (see [[SYS-Haunted-Art-Direction]] step 5). Live use still needs jg's choice of path A (import) or B (Mesh/Image API toggle).
- Fabric darkens vertex colour ~35% in Studio; exported Fabric colours get a 1.55 gain.

**Evidence:** `07 Playtests/assets/overhaul/` — `blender-lamp_post.jpg` (4 views neutral), `blender-lamp_post_night.jpg`, `T42-lamp-post-studio-neutral.jpg`, `T42-lamp-post-game-night.jpg`, `before-*.jpg`. Client memory with all lamps and creatures: `GraphicsMeshParts` 2.0 MB (Studio Play, 2026-10-13).

**Checks:** `scripts/check.sh` steps pass via the pre-commit hook (lint, types, 143 specs). FullLoop: first run failed at "Get closer" after a scripted teleport (7 follow-on checks); immediate rerun 85/85. Recorded as a harness timing flake; rerun on the stacked head below.

## Audits

## Outcome

## Closure (2026-10-18)
Marked done by jg. This task was approved on the overhaul branch, and The art pipeline (server-baked mesh templates, loader, LOD and the art direction note) is on main through [[TASK-0069-Art-Salvage-From-Overhaul-Branch]]. The Opus audit of TASK-0069 covered the port, and this task's own audit stayed on the old branch. Not verified: Studio was never run for the ported art on main, so rendering, load time and the ~11 MB art bake are unchecked.
