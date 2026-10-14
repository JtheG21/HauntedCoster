---
id: TASK-0049
title: "Management, Track Editor and Journal UI"
type: task
project: GAME-002
status: in_progress
priority: high
risk: medium
owner: executor
depends_on:
  - TASK-0041
branch: task/TASK-0049-Management-Track-And-Journal-UI
related:
  - "[[SYS-Haunted-Art-Direction]]"
  - "[[SYS-Haunted-Monetization-UI]]"
  - "[[3D Model Quality Baseline]]"
created: 2026-10-13
updated: 2026-10-13
tags:
  - workflow/task
---

# Management, Track Editor and Journal UI

## Goal
Redesign Mansion management, train information, the track editor and the Journal/Bestiary in the new UI system.

Part of the overhaul jg requested on 2026-10-13 (3D asset overhaul, full UI overhaul, approved monetization scope). jg authorized the local design and implementation work, creating scoped tasks and testing in local Studio places; publishing, spending, live products, uploads and merges stay gated.

## Scope
- **In:** MansionUI, TrackEditor, JournalUI incl. collection progress and reward states.
- **Out (non-goals):** Shop and cosmetic inventory (TASK-0051).
- **Keep unchanged:** server authority, gameplay rules and tuning, existing interaction points and collisions, GAME-001.

## Intake
- **Category → workflow, depth:** UI → [[UI Workflow]], deep
- **References:** [[SYS-Haunted-Monetization-UI]] screen baseline (Mansion, Journal rows).
- **Reuse:** existing builders keep their gameplay geometry; visuals move to the art pipeline from [[TASK-0042-Art-Pipeline-And-Direction]].
- **Branch stacking:** stacked on `task/TASK-0048-UI-System-And-Core-HUD` (queue field `stacked_on`); the queue dependency stays TASK-0041 because unmerged stacked work cannot be `done`.

## Files expected to change
- `src/client/UI/{MansionUI,TrackEditor,JournalUI}.luau` and new screen modules.

## Acceptance criteria
- [ ] AC1 Mansion upgrades, owned ghosts, exhibits and train information, the track editor, and the Journal/Bestiary with habitat progress, natural variants and collection rewards are redesigned in the new system.
- [ ] AC2 Empty, loading, unavailable and error states exist for each screen.
- [ ] AC3 Captured at desktop and narrow sizes; controller and touch flows verified in emulation.
- [ ] AC4 scripts/check.sh passes; FullLoop passes.

## Tests
- **Automated:** `scripts/check.sh`.
- **Studio playtest procedure:** local place `~/Roblox-Work/haunted/Overhaul.rbxl` built from this branch; scenarios named in the criteria; captures stored with the evidence.

## Risks / notes
- Runtime meshes use EditableMesh. Live use needs either jg's batch 3D import (an upload) or jg's 13+/ID verification plus the Creator Dashboard Mesh/Image API toggle ([[SYS-Haunted-Art-Direction]]).

---
## Implementation record
- **Mansion:** modal with Upgrades (3D preview of the next house with the selected theme; Coin upgrades in gold buttons, distinct from cosmetics), Ghosts (roster with rarity, status and each ghost's look; an Appearance picker equips owned compatible skins and auras per ghost or restores the natural look), Exhibits (unchanged rules) and Customize (owned mansion themes and capture effects, Decorate my plot, Shop only on request).
- **Bestiary (Journal):** Creatures (a 3D preview per species, black silhouettes for the undiscovered, variant chips for obtainable natural variants), Habitats (species per hunting ground with caught progress) and Rewards (milestone progress bars, the reward item, server-confirmed Claim, Preview reward opens the Shop item).
- **Track editor:** restyled through the shared theme and registered with navigation; its layout is unchanged (not redesigned in this pass).
- **Not verified in Studio** (stall); device checks need jg.

## Audits

## Outcome
