---
id: TASK-0042
title: "Art Pipeline and Direction"
type: task
project: GAME-002
status: in_progress
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
updated: 2026-10-13
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

## Audits

## Outcome
