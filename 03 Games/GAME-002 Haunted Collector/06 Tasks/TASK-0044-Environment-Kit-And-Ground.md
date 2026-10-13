---
id: TASK-0044
title: "Environment Kit and Ground"
type: task
project: GAME-002
status: ready
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
updated: 2026-10-13
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

## Audits

## Outcome
