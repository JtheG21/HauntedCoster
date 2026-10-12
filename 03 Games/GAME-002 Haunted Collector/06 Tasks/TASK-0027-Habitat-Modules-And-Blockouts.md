---
id: TASK-0027
title: Habitat Modules and Blockouts
type: task
project: GAME-002
status: proposed
priority: high
risk: medium
owner: executor
milestone: M3
depends_on:
  - TASK-0026
branch: task/TASK-0027-Habitat-Modules-And-Blockouts
created: 2026-10-12
updated: 2026-10-12
tags:
  - workflow/task
  - milestone/m3
related:
  - "[[ADR-0007-World-Retrofit-Direction]]"
  - "[[TASK-0026-Radial-Plot-Layout]]"
---
# TASK-0027: Habitat Modules and Blockouts

## Goal
Four interchangeable habitat modules share the same footprint and gates: Ghost Cemetery, Cursed Woodland, Spider Woodland and Zombie Settlement. One is active at a time, and a module can be swapped in and out cleanly. Rotation timing is not part of this task.

## Scope
- **In:**
  - Blockouts for Woodland, Spider Woodland and Zombie Settlement, each with distinct ground forms and silhouettes, its own path network linking the three gates, spawn zones, and two medium landmark placeholders.
  - A module registry and startup validator (adapted from vfx_template `Validator`): footprint, corridors kept clear, zones inside the disc, landmark slots, unique zone ids, roster weights.
  - The lifecycle: prebuild all four, `activate(id)` (parent, start spawning) and `deactivate()` (stop spawning, clear wild encounters, unparent).
  - `EncounterService` reads the active module's zones.
  - A Studio-only selector (StudioTestHook arg / server attribute) for testing.
- **Out:** the clock schedule, warnings and capture-safe swapping (TASK-0029); detailed art (TASK-0028 does the cemetery only); habitat-specific mechanics.

## Acceptance criteria
- [ ] AC1: All four modules pass the validator, and a deliberately broken module fails it (spec).
- [ ] AC2: Reachability runs for each module: every zone centre and landmark is reachable from every gate, and the gates stay clear.
- [ ] AC3: `deactivate → activate` leaves no wild encounter, prompt or geometry from the old module, and the new module spawns only its roster (scenario).
- [ ] AC4: Each habitat is readable as itself in Studio captures (ground, silhouettes, landmarks), recorded in a `TEST-` note for jg's review.
- [ ] AC5: FullLoop passes with the cemetery active. `scripts/check.sh` passes.

## Tests
- **Automated:** `scripts/check.sh`; a `HabitatModules` spec (validator); Reachability with a `habitat` arg for all four; a new `HabitatSwap` scenario (basic lifecycle, no captures).
- **Who settles the evidence:** scenarios (Claude). The captures are reviewed by jg.

## Risks / notes
Part count: four prebuilt modules stay in memory. Measure the part count per module and keep blockouts lean.

---
## Implementation record

## Audits

## Outcome
