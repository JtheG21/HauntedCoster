---
id: TASK-0045
title: "Habitat Landmarks"
type: task
project: GAME-002
status: ready
priority: high
risk: medium
owner: executor
depends_on:
  - TASK-0041
branch: task/TASK-0045-Habitat-Landmarks
related:
  - "[[SYS-Haunted-Art-Direction]]"
  - "[[SYS-Haunted-Monetization-UI]]"
  - "[[3D Model Quality Baseline]]"
created: 2026-10-13
updated: 2026-10-13
tags:
  - workflow/task
---

# Habitat Landmarks

## Goal
Rebuild every habitat landmark as a finished, readable set piece.

Part of the overhaul jg requested on 2026-10-13 (3D asset overhaul, full UI overhaul, approved monetization scope). jg authorized the local design and implementation work, creating scoped tasks and testing in local Studio places; publishing, spending, live products, uploads and merges stay gated.

## Scope
- **In:** Cemetery, Cursed Woodland, Spider Woodland and Zombie Settlement landmark builders.
- **Out (non-goals):** Habitat layouts, zones and rotation rules.
- **Keep unchanged:** server authority, gameplay rules and tuning, existing interaction points and collisions, GAME-001.

## Intake
- **Category → workflow, depth:** Map → [[Map Workflow]], standard
- **References:** MODEL-MIN-067–070 (graveyard architecture), MIN-062 (remains), MIN-066 (nature).
- **Reuse:** existing builders keep their gameplay geometry; visuals move to the art pipeline from [[TASK-0042-Art-Pipeline-And-Direction]].
- **Branch stacking:** stacked on `task/TASK-0044-Environment-Kit-And-Ground` (queue field `stacked_on`); the queue dependency stays TASK-0041 because unmerged stacked work cannot be `done`.

## Files expected to change
- `games/haunted/art/assets/landmarks*.py`, `src/server/World/Props.luau`, `src/server/World/Habitats/*`.

## Acceptance criteria
- [ ] AC1 Weeping Angel, Bell Tower, Sealed Crypt, mausoleums, hearse, well, standing stones, hollow oak, dens, brood tree, cocoons, ruined chapel, old barn and cottages are rebuilt as finished landmark meshes.
- [ ] AC2 Landmark silhouettes stay readable from 80+ studs and keep their gameplay roles (crypt gate collision and client-side opening).
- [ ] AC3 Four-view and night captures compared with MIN-067-070; no landmark relies on glow to read.
- [ ] AC4 scripts/check.sh passes; HabitatSwap and HabitatRotation scenarios pass.

## Tests
- **Automated:** `scripts/check.sh`.
- **Studio playtest procedure:** local place `~/Roblox-Work/haunted/Overhaul.rbxl` built from this branch; scenarios named in the criteria; captures stored with the evidence.

## Risks / notes
- Runtime meshes use EditableMesh. Live use needs either jg's batch 3D import (an upload) or jg's 13+/ID verification plus the Creator Dashboard Mesh/Image API toggle ([[SYS-Haunted-Art-Direction]]).

---
## Implementation record

## Audits

## Outcome
