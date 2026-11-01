---
id: TASK-0046
title: "Mansion, Plot and Ghost Train Art"
type: task
project: GAME-002
status: in_progress
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
updated: 2026-10-13
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
- **References used:** MIN-069 (architecture kit: plinths, trims, gables, finials), MIN-054-056 (haunted houses), MIN-057-059 (vehicle finish: body, wheels, lamps, consistent detail). BAD-013/014 (flat cart platform with posts) and BAD-017 (box shack) not repeated: the cart is a lacquered coffin-gondola with brass trim, cushions, skull figurehead, lamp and spoked wheels; the shack has board-and-gap planks, rubble footing, a patched sagging roof, a tin lean-to and a stovepipe.
- **Commit:** `3457e64`. Art: `art/assets/mansion.py` (house_t0/1/2: 6.2k/7.8k/14k tris, LOD1 2.0k/3.2k/5.5k), `art/assets/plot.py` (cart 3.7k, Scare Arch 4.3k, Fog Tunnel 2.4k, station 3.4k, pen 3.5k, plot wall run 344, tie 116, trestle 796, marker 124, plinth 722, trophy 836, sign 604).
- **House:** every `PlotDecor.Houses` box stays a collider (the PlotDecor spec keeps proving the house is clear of gameplay areas), the main gable roofs collide as before, one art anchor `HouseArt` per tier; lights at the art's lit windows and door, the mansion's purple tower lamp. Theme slots are separate parts (Walls, Trim, Roof, Stone, Brick, Glass, Lamp, Wood, Iron) for TASK-0050.
- **Plot and train:** walls, sign (owner name lettered on the board and kept on the billboard), pen, exhibit plinths, entrance pillars/arch/lanterns and trophies are art over the old colliders; the cart art is welded to an anchor in the moving cart; ties under every segment, a trestle every fourth, markers at control points; Scare Arch and Fog Tunnel keep their light and fog. Part names scenarios use are kept (`GhostCart`, `FrontSeat`, `GuestSeat`, `Rail`, `Station`, `PenPad`, `ArchSkull`).
- **Deviations:** porch columns, balusters, chimneys, windows and the old station canopy were non-colliding or decorative and are art only; exhibit pedestals are invisible colliders (locked slots say so on their label instead of fading).
- **Evidence:** `overhaul/blender-sheet-houses.jpg` (four views per tier), `overhaul/blender-sheet-plot-train.jpg`.

- **History note:** commit `a5f0aaa` (labelled TASK-0046, 2026-10-13 21:27, made by another agent session, not this executor) holds `Config/Cosmetics.luau` and the PlotBuilder theme-tint/decoration hooks, which are TASK-0047 work; the rest of TASK-0047 is `199a82b`. History was not rewritten.

## Audits

## Outcome
