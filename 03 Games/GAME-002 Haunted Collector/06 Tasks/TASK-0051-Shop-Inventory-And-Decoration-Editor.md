---
id: TASK-0051
title: "Shop, Inventory and Decoration Editor"
type: task
project: GAME-002
status: ready
priority: high
risk: high
owner: executor
depends_on:
  - TASK-0041
branch: task/TASK-0051-Shop-Inventory-And-Decoration-Editor
related:
  - "[[SYS-Haunted-Art-Direction]]"
  - "[[SYS-Haunted-Monetization-UI]]"
  - "[[3D Model Quality Baseline]]"
created: 2026-10-13
updated: 2026-10-13
tags:
  - workflow/task
---

# Shop, Inventory and Decoration Editor

## Goal
Build the shop, owned inventory, equipment and decoration editor journeys on the cosmetics backend.

Part of the overhaul jg requested on 2026-10-13 (3D asset overhaul, full UI overhaul, approved monetization scope). jg authorized the local design and implementation work, creating scoped tasks and testing in local Studio places; publishing, spending, live products, uploads and merges stay gated.

## Scope
- **In:** Shop, item details and previews, owned inventory, ghost appearance, capture effect, mansion theme, decoration editor; all interaction states.
- **Out (non-goals):** Live Robux products, prices needing approval.
- **Keep unchanged:** server authority, gameplay rules and tuning, existing interaction points and collisions, GAME-001.

## Intake
- **Category → workflow, depth:** UI/Systems → [[UI Workflow]], deep
- **References:** [[SYS-Haunted-Monetization-UI]] screen and state baselines.
- **Reuse:** existing builders keep their gameplay geometry; visuals move to the art pipeline from [[TASK-0042-Art-Pipeline-And-Direction]].
- **Branch stacking:** stacked on `task/TASK-0050-Cosmetic-Assets` (queue field `stacked_on`); the queue dependency stays TASK-0041 because unmerged stacked work cannot be `done`.

## Files expected to change
- `src/client/UI/{Shop*,Inventory*,DecorEditor*}.luau`, `src/client/Art/*`.

## Acceptance criteria
- [ ] AC1 Shop with categories, filters, item details, rotatable/replayable previews, truthful acquisition labels and no fake prices; Robux actions hidden until products are configured.
- [ ] AC2 Owned inventory with per-ghost skin/aura equipment, capture-effect selection, mansion theme apply and decoration palette; preview never changes the live world and cancel restores it.
- [ ] AC3 Hybrid decoration editor with snapping, rotation, bounded fine placement, live valid/invalid indication, Confirm/Cancel/Move/Rotate/Store/Exit and count limits.
- [ ] AC4 All five category journeys work locally including loading, unavailable, pending, duplicate-submit and rejoin states; multiplayer appearance checked with 2 players.
- [ ] AC5 scripts/check.sh passes.

## Tests
- **Automated:** `scripts/check.sh`.
- **Studio playtest procedure:** local place `~/Roblox-Work/haunted/Overhaul.rbxl` built from this branch; scenarios named in the criteria; captures stored with the evidence.

## Risks / notes
- Runtime meshes use EditableMesh. Live use needs either jg's batch 3D import (an upload) or jg's 13+/ID verification plus the Creator Dashboard Mesh/Image API toggle ([[SYS-Haunted-Art-Direction]]).

---
## Implementation record

## Audits

## Outcome
