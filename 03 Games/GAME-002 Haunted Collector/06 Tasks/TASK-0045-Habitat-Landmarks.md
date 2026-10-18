---
id: TASK-0045
title: "Habitat Landmarks"
type: task
project: GAME-002
status: approved
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
- **References used:** MIN-067–070 (stepped bases, gothic gates, mausoleum and chapel forms, broken masonry), MIN-062 (remains), MIN-066 (nature). Qualities taken: chunky readable silhouettes, stone courses and chipped edges, iron cresting; nothing copied.
- **Art (`art/assets/landmarks.py`, Blender offline):** Weeping Angel (robed figure, hands over face, folded wings, stepped plinth), Bell Tower (buttressed course shaft, open belfry with lit bell, spire and cross), mausoleum (scaled 0.7–1.3), hearse (lacquer body, glass, gilt trim, spoked wheels, one off), well (stone ring, posts, roof, crank, bucket), hollow oak (hollow facing the clearing), den (mossy mound, burrow mouth, bones), brood tree (silk-whitened, limbs drooping along the server's diagonals), broken stump, chapel steeple (belfry, snapped spire), barn plank wall, sagging barn roof, hay bale, charred beam, ashlar crypt wall with spiked cresting, crypt gate leaf, coffin, standing stone (carved spiral, lichen), stone altar, hanging sign.
- **Server:** every landmark keeps its main footprint as invisible colliders and its anchor (labels, Reachability targets); art faces the old fronts. Crypt walls are art runs of ~8 studs with the buttress side out; the gate is an invisible collider with two hinged `crypt_gate_leaf` anchors (`GateRest`, `Swing`). The crypt's block sign became a lettered `sign_hanging`. Landmark labels sit above each landmark (bounds, or `LabelHeight`); world labels use Grenze Gotisch. Cottages (walls) and cocoons reuse TASK-0044 art.
- **Client:** `LocalWorld.setGate` clears the gate collider and tweens the leaves open for players whose tier unlocks the crypt; the gate label hides while open.
- **Checks:** `scripts/check.sh` passes. HabitatSwap 35/35, HabitatRotation 28/28, Reachability (all four habitats) pass ([[TASK-0044-Environment-Kit-And-Ground]] record).
- **Crypt (AC2):** tour at tier 1 (Restored Manor): `LocalOpen` true, collider off, both leaves dressed and swung open (`overhaul/T45-crypt-gate-open-sign.jpg`).
- **Evidence:** `overhaul/blender-sheet-landmarks{1,2,3}.jpg` (two views each), `T45-belltower-night.jpg`, `T45-hearse-oldrows-night.jpg`, `T44-cemetery-angel-path-night.jpg`.
- **Open issue (intermittent, not reproduced):** in one long tour session the hollow oak and brood tree meshes did not draw after the Woodland swap although baked (239/0), parented, on screen and with the right MeshSize; template clones drew a few minutes later. A fresh session starting in Woodland and a second tour (swap Cemetery → Woodland) both drew them at once. Suspected engine residency of DataModel-scoped mesh content under memory pressure on this 8 GB Mac; recorded as a risk for the live art path in [[SYS-Haunted-Art-Direction]] and to re-check in TASK-0052.

- **Footprint deviations (listed per [[AUD-20261013-TASK-0045-01]] finding 6, none changes reachability):** collidable details dropped with the part builds: hollow-oak roots, angel arms and wings, mausoleum columns and roof overhang, bell-tower belfry/spire/door/upper buttresses, hearse roof and wheels (body 6x12 to 5.2x11), well roof (ring radius 3 to 2.7), steeple cap; buttresses moved in 0.4 to match the art. The crypt gate is no longer `Solid`: sight passes between its bars (the old 0.25-transparent block blocked it).
- **Post-audit fixes (same commit as TASK-0044 revision 1):** standing stones face into the ring; a leaf streaming in after its gate re-applies the gate state; hinges 1 stud inside the gate edges; `LabelHeight` for the Brood Tree, Ruined Chapel and mausoleums; Hollow Oak collider capped at 21 (the art trunk); crypt sign board 0.26 thick; HabitatTour restores the starting habitat; `beam_fallen` 1728 to 432 tris; dead code removed.
- **AC3:** four-view sheets `overhaul/blender-sheet-lm4_{a,b}.jpg` and a night sheet `blender-sheet-lm4_night.jpg` (front/side, neutral and night). Compared with MIN-067-070: stepped bases, courses, iron cresting and broken masonry read as silhouettes at night; only the bell glow and lamps emit, no landmark relies on glow. Budget note: `crypt_wall` (2.7k, LOD1 0.96k) repeats about 20 times round the crypt.

## Audits
- [[AUD-20261013-TASK-0045-01]]: pass (12 minor/nit, fixed or recorded above).

## Outcome
