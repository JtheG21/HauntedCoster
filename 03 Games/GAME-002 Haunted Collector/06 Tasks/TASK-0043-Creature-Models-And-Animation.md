---
id: TASK-0043
title: "Creature Models and Animation"
type: task
project: GAME-002
status: in_progress
priority: high
risk: medium
owner: executor
depends_on:
  - TASK-0041
branch: task/TASK-0043-Creature-Models-And-Animation
related:
  - "[[SYS-Haunted-Art-Direction]]"
  - "[[SYS-Haunted-Monetization-UI]]"
  - "[[3D Model Quality Baseline]]"
created: 2026-10-13
updated: 2026-10-13
tags:
  - workflow/task
---

# Creature Models and Animation

## Goal
Replace the four part-built creatures and their natural variants with finished, animated meshes.

Part of the overhaul jg requested on 2026-10-13 (3D asset overhaul, full UI overhaul, approved monetization scope). jg authorized the local design and implementation work, creating scoped tasks and testing in local Studio places; publishing, spending, live products, uploads and merges stay gated.

## Scope
- **In:** Wisp, Stitched Hound, Hollow Gentleman, Bell Wraith; Spectral and Ashen looks; client procedural animation; wild, carried, pen and exhibit display.
- **Out (non-goals):** Cosmetic skins and auras (TASK-0050); server movement rules.
- **Keep unchanged:** server authority, gameplay rules and tuning, existing interaction points and collisions, GAME-001.

## Intake
- **Category → workflow, depth:** Asset → [[Asset Workflow]], deep
- **References:** MODEL-MIN-013/014/015, MIN-031, MIN-037–044, MIN-048–053 (anatomy, finish); MODEL-BAD-006–012 (rejected hounds).
- **Reuse:** existing builders keep their gameplay geometry; visuals move to the art pipeline from [[TASK-0042-Art-Pipeline-And-Direction]].
- **Branch stacking:** stacked on `task/TASK-0042-Art-Pipeline-And-Direction` (queue field `stacked_on`); the queue dependency stays TASK-0041 because unmerged stacked work cannot be `done`.

## Files expected to change
- `games/haunted/art/assets/creatures*.py`, `src/client/Art/Creatures.luau`, `src/server/World/MonsterModels.luau`, services that build monster models.

## Acceptance criteria
- [ ] AC1 Wisp, Stitched Hound, Hollow Gentleman and Bell Wraith are rebuilt as finished meshes that meet or exceed MIN-013/031/037-044/048-053 and avoid BAD-006-012, inspected in four views, neutral and night light, without glow.
- [ ] AC2 Normal, Spectral and Ashen read as distinct natural identities on every species without hiding the form.
- [ ] AC3 Client-side procedural animation covers idle, roam, startle, carried, chase, retaliation and display poses; server movement, colliders, prompts and capture behaviour are unchanged.
- [ ] AC4 Wild, carried, contained and exhibited creatures all use the new art; LOD and triangle budgets hold with 8 wild plus full pens.
- [ ] AC5 scripts/check.sh passes; FullLoop, CarryGuard and Retaliation scenarios pass.

## Tests
- **Automated:** `scripts/check.sh`.
- **Studio playtest procedure:** local place `~/Roblox-Work/haunted/Overhaul.rbxl` built from this branch; scenarios named in the criteria; captures stored with the evidence.

## Risks / notes
- Runtime meshes use EditableMesh. Live use needs either jg's batch 3D import (an upload) or jg's 13+/ID verification plus the Creator Dashboard Mesh/Image API toggle ([[SYS-Haunted-Art-Direction]]).

---
## Implementation record

## Audits

## Outcome
