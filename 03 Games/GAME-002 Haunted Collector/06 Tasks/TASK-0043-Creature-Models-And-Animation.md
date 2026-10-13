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
**References used:** MODEL-MIN-013–015 (dragon: anatomy, jaw, tapering tail), MIN-031 (layered creature versus a box assembly), MIN-037–044 (antlered creature, skeleton: tapered limbs, ribs, finger bones), MIN-048–053 (rat, zombie: features held on side and rear views), MIN-011/012 (focal face). Rejected: MODEL-BAD-006–012 (box hounds with sparkles).

**Built (commits 46f1225 and later on this branch):**
- `art/assets/creatures.py` + `hcart/anatomy.py`: Stitched Hound (metaball anatomy, digitigrade legs, two heads, teeth, stitched seams, button eye, collar and tag, bandaged tail; 8.3k tris), Lantern Wisp (curling tail, flame curl, hollow eyes, little lantern; 3.4k), Hollow Gentleman (tailored coat loft, waistcoat and buttons, beckoning glove, skull cane, floating top hat over an empty collar; 5.6k), Bell Wraith (patinated bell with glowing crack and eye slits, clapper heart, ragged shroud and ribbons, skeletal arms; 5.3k). Each has an Ashen ember-crack overlay. `props_small.py`: capture_jar.
- Server `World/MonsterModels.luau`: invisible Root + Hitbox + lights, tagged `Creature`; pens/exhibits set `ArtScale`/`Display`; the carried jar is art-dressed and tagged `CarriedCreature` (`CaptureService`).
- Client `Art/Creatures.luau`: builds art per species/variant and animates it every frame from the Root's measured speed (walk cycles, idles, jaw snaps, hat bob, ribbon sway) with `BulkMoveTo`; LOD swap at the asset's distance.
- Natural variants: Spectral = pale translucent body inside a ForceField shell plus motes; Ashen = charcoal Slate surface plus glowing ember cracks.
- `tests/scenarios/ArtShowcase.luau`: stages pens, exhibits and a carried jar for captures.

**Defects found and fixed in Studio:** client EditableMesh budget → server bake (TASK-0042); Fabric darkening → export gain; pen/exhibit art missing because the `Creature` tag replicated before the Root → attach waits for Root; Ashen too weak under warm light → darker tint, Slate, opaque.

**Evidence (`07 Playtests/assets/overhaul/`):** `blender-creature_*.jpg` (front, 3/4, side, rear, neutral), `blender-creature_*_ashen.jpg` (night, embers on), `blender-creature_hound_focus.jpg`, `T43-creatures-variants-studio-neutral.jpg` (all 4 × Normal/Spectral/Ashen in Studio), `T43-pen-residents-variants-game.jpg`, `T43-exhibit-game.jpg`, `T43-capture-jar-game.jpg`.

**Checks:** pre-commit `check.sh` steps pass (143 specs). Studio, stacked head: FullLoop 85/85 (twice, after the bake gating), CarryGuard 21/21, Retaliation 36/36. Client mesh memory with lamps + creatures 2.0–2.5 MB.

**Not verified:** animation was checked for errors and poses in stills only, not judged in motion by a person; triangle budgets were raised to ≤ 8.5k (Hound 8.3k) and recorded in [[SYS-Haunted-Art-Direction]].

## Audits

## Outcome
