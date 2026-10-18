---
id: TASK-0046
title: "Mansion, Plot and Ghost Train Art"
type: task
project: GAME-002
status: archived
priority: high
risk: medium
owner: executor
depends_on:
  - TASK-0041
branch: task/TASK-0046-Mansion-Plot-And-Train-Art
related:
  - "[[SYS-Haunted-Art-Direction]]"
  - "[[SYS-Haunted-Monetization-UI]]"
  - "[[3D Model Quality Baseline]]"
created: 2026-10-13
updated: 2026-10-18
tags:
  - workflow/task
---

# Mansion, Plot and Ghost Train Art

## Goal
Rebuild the player plot: mansion tiers, pen, station, ghost train, track, exhibits, trophies and entrance.

Part of the overhaul jg requested on 2026-10-13 (3D asset overhaul, full UI overhaul, approved monetization scope). jg authorized the local design and implementation work, creating scoped tasks and testing in local Studio places; publishing, spending, live products, uploads and merges stay gated.

## Scope
- **In:** PlotBuilder visuals, TrainService cart/track visuals (client-built), exhibit plinths, trophies, beacon.
- **Out (non-goals):** Mansion themes (TASK-0050), decoration placement (TASK-0047/0051).
- **Keep unchanged:** server authority, gameplay rules and tuning, existing interaction points and collisions, GAME-001.

## Intake
- **Category → workflow, depth:** Asset → [[Asset Workflow]], deep
- **References:** MODEL-MIN-057–059 (vehicle finish), MIN-069 (architecture); MODEL-BAD-013/014 (cart), MODEL-BAD-017 (shack).
- **Reuse:** existing builders keep their gameplay geometry; visuals move to the art pipeline from [[TASK-0042-Art-Pipeline-And-Direction]].
- **Branch stacking:** stacked on `task/TASK-0045-Habitat-Landmarks` (queue field `stacked_on`); the queue dependency stays TASK-0041 because unmerged stacked work cannot be `done`.

## Files expected to change
- `games/haunted/art/assets/{mansion,train,plot}.py`, `src/server/World/PlotBuilder.luau`, `src/server/Services/TrainService.luau`, `src/client/Art/*`.

## Acceptance criteria
- [ ] AC1 The three mansion tiers, containment pen, station and canopy, ghost-train cart, track rails and supports, Scare Arch, Fog Tunnel, exhibit plinths, trophies, beacon and plot entrance are rebuilt; BAD-013/014/017 are not repeated.
- [ ] AC2 Tier upgrades, house boxes used by decorations, ride, exhibits, pen pads and prompts behave as before.
- [ ] AC3 Cart and track compared with MIN-057-059 (vehicle finish) and the house tiers with MIN-069 in four views.
- [ ] AC4 scripts/check.sh passes; FullLoop and Persistence scenarios pass.

## Tests
- **Automated:** `scripts/check.sh`.
- **Studio playtest procedure:** local place `~/Roblox-Work/haunted/Overhaul.rbxl` built from this branch; scenarios named in the criteria; captures stored with the evidence.

## Risks / notes
- Runtime meshes use EditableMesh. Live use needs either jg's batch 3D import (an upload) or jg's 13+/ID verification plus the Creator Dashboard Mesh/Image API toggle ([[SYS-Haunted-Art-Direction]]).

---
## Implementation record

## Audits

## Outcome

## Closure (2026-10-18)
Archived by jg, superseded by [[TASK-0069-Art-Salvage-From-Overhaul-Branch]]. The mansion tiers, plot dressing and ghost-train art (commit 3457e64 of the overhaul branch) were carried to main by [[TASK-0069-Art-Salvage-From-Overhaul-Branch]]. The PlotBuilder theme-tint and decoration changes (a5f0aaa) were left for the monetization tasks, which rebuilt them. The Opus audit of TASK-0069 covered the port, not a fresh review of this task. Studio was never run for the ported art.
