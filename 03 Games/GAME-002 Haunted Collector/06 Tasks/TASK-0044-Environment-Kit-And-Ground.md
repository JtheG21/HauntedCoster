---
id: TASK-0044
title: "Environment Kit and Ground"
type: task
project: GAME-002
status: archived
priority: high
risk: medium
owner: executor
depends_on:
  - TASK-0041
branch: task/TASK-0044-Environment-Kit-And-Ground
related:
  - "[[SYS-Haunted-Art-Direction]]"
  - "[[SYS-Haunted-Monetization-UI]]"
  - "[[3D Model Quality Baseline]]"
created: 2026-10-13
updated: 2026-10-18
tags:
  - workflow/task
---

# Environment Kit and Ground

## Goal
Rebuild the shared environment kit, vegetation and ground so the hub and all four habitats meet the reference floor.

Part of the overhaul jg requested on 2026-10-13 (3D asset overhaul, full UI overhaul, approved monetization scope). jg authorized the local design and implementation work, creating scoped tasks and testing in local Studio places; publishing, spending, live products, uploads and merges stay gated.

## Scope
- **In:** Trees incl. TASK-0041 haunted trees, roots, rocks, graves, fences, gates, walls, candles, pumpkins, mist, hub wall, gates and road, ground and paths.
- **Out (non-goals):** Landmarks (TASK-0045), plot assets (TASK-0046).
- **Keep unchanged:** server authority, gameplay rules and tuning, existing interaction points and collisions, GAME-001.

## Intake
- **Category → workflow, depth:** Map/Asset → [[Map Workflow]] + [[Asset Workflow]], deep
- **References:** MODEL-MIN-010, MIN-054–056, MIN-060–070; MODEL-BAD-001–005 (rejected haunted trees); [[Haunted Trees -- Visual Reference]].
- **Reuse:** existing builders keep their gameplay geometry; visuals move to the art pipeline from [[TASK-0042-Art-Pipeline-And-Direction]].
- **Branch stacking:** stacked on `task/TASK-0043-Creature-Models-And-Animation` (queue field `stacked_on`); the queue dependency stays TASK-0041 because unmerged stacked work cannot be `done`.

## Files expected to change
- `games/haunted/art/assets/{trees,graveyard,ground}.py`, `src/server/World/{Props,HubBuilder,HauntedTree}.luau`, `src/server/World/Habitats/*`, `src/client/HauntedTrees.luau`.

## Acceptance criteria
- [ ] AC1 Trees (dead, pine, haunted with faces, brood), roots, rocks, graves, fences, gates, walls, candles, pumpkins, mist and the hub wall/gates/road are rebuilt to meet MIN-010/054-056/060-070 and avoid BAD-001-005.
- [ ] AC2 TASK-0041 haunted trees keep their gaze behaviour, palette rules and face controls with the new trunk and face art.
- [ ] AC3 Ground and paths read as terrain rather than flat discs, with collisions and walk heights unchanged.
- [ ] AC4 Each habitat and the hub are captured at gameplay distance in game lighting, before and after.
- [ ] AC5 scripts/check.sh passes; Reachability and HauntedTrees scenarios pass.

## Tests
- **Automated:** `scripts/check.sh`.
- **Studio playtest procedure:** local place `~/Roblox-Work/haunted/Overhaul.rbxl` built from this branch; scenarios named in the criteria; captures stored with the evidence.

## Risks / notes
- Runtime meshes use EditableMesh. Live use needs either jg's batch 3D import (an upload) or jg's 13+/ID verification plus the Creator Dashboard Mesh/Image API toggle ([[SYS-Haunted-Art-Direction]]).

---
## Implementation record
- **Commits:** `1a178b6` (kit, terrain ground, haunted-tree meshes), `fb9dfcc` (habitat decor, layout-preserving RNG burns, vertical stretch). Stacked on TASK-0043; the TASK-0043 audit fixes ride in a separate commit on this branch.
- **Art (Blender, offline):** dead trees, pines, rocks, fallen log, haunted trunks (Pillar/Broad/Angular, faced and plain) carved to the TASK-0041 face layout with bark lids and jaw; graveyard kit (headstone, Celtic cross, obelisk, leaning slab, mound, pumpkins, candles, iron fence panel/post, gate pillar/arch, ruined wall, edge stones); hub wall, gate pillars, arch, hanging sign; habitat decor (torn web sheets, cocoons, ruined brick walls, broken picket fence). References MIN-010, MIN-054–056, MIN-060–070; BAD-001–005 avoided (no flat-faced primitive trunks, faces carved into bark).
- **Server:** builders keep their gameplay footprints as invisible colliders (attribute `Solid`, which `TreeSight` treats as blocking) plus `ArtSlot` anchors; lights and prompts unchanged. `Props.burn` keeps each builder's seeded draw count identical to the old part builders, so validated layouts don't move.
- **Ground:** `GroundPainter` turns ground discs and path strips into terrain at the same top height (measured: block fills surface 2 studs above the fill top; `FillCylinder` rounds up a voxel, so discs are written as voxels). Hunting habitats and plots use LeafyGrass (no blades over graves and creatures); the outer ground keeps grass blades (`Terrain.Decoration`).
- **Checks:** `scripts/check.sh` passes (specs 143/0).
- **Scenarios (local `Overhaul.rbxl`, synced by rebuild, stacked head):** Reachability Cemetery 28/28, Woodland 23/23, SpiderWoodland 23/23, Settlement 23/23; HabitatSwap 35/35 (parts: Cemetery 933, Woodland 348, SpiderWoodland 204, Settlement 178); HabitatRotation 28/28.
- **HauntedTrees (AC2):** 1 player: looking at a faced tree froze it immediately and both sight lines were clear through the new trunk colliders (checked live). 2 players: 23/28; all 5 failures are latency windows (freeze seen after >1.5 s, resume 2.1–2.7 s against ≤2.2 s) while Studio held ~3.9 GB in Edit alone plus two client processes on this 8 GB Mac. Not counted as a pass; re-run in TASK-0052 on a quieter machine state.
- **Evidence (AC4):** before: [[TEST-20261012-03]] captures (cemetery daylight, woodland, spider woodland, settlement night) and `overhaul/before-hub-night.jpg`; after: `07 Playtests/assets/overhaul/T44-*.jpg` and the TASK-0045 landmark captures (same session).
- **Not verified:** grass/terrain on devices; frame time with 6 players (Studio cap is 2).

## Audits

## Outcome

## Closure (2026-10-18)
Archived by jg, superseded by [[TASK-0069-Art-Salvage-From-Overhaul-Branch]]. Its code and art were carried to main by [[TASK-0069-Art-Salvage-From-Overhaul-Branch]] as they stood on the overhaul branch, including the unresolved revision request, so the environment kit and ground were never re-reviewed after the changes were requested. The Opus audit of TASK-0069 covered the port, not a fresh review of this task. Studio was never run for the ported art.
