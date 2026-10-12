---
id: TASK-0027
title: Habitat Modules and Blockouts
type: task
project: GAME-002
status: done
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
- **References used:**
  - vfx_template `Validator` pattern (startup validation that returns readable problems instead of failing silently), via the code index guide [[vfx_template]]. Its source wasn't re-opened in this task; only the pattern was used, not its code.
  - Map references 5 and 6 (chunky, readable silhouettes) for the blockouts' proportions. Qualities only.
- **Built:**
  - `Habitats.luau`: Cursed Woodland, Spider Woodland and Zombie Settlement, with rosters weighted per ADR-0007. Also `setActive`, `anyZoneById`, and the rotation order in `List`.
  - `HabitatRules.validate` now also checks species ids and weights, duplicate landmark ids, and that a landmark sits inside the zone it names. The Bell Tower no longer claims the Crypt zone (it stands outside it, [[AUD-20261012-TASK-0026-01]] finding 5).
  - `World/Habitats/Kit.luau`: shared steps (ground, plaza, paths, gate lanterns, landmarks, free-ground tests, scatter, dark-zone candles). Cemetery now uses it. Woodland, SpiderWoodland and Settlement are blockouts built on it.
  - `HabitatService`: prebuilds all four into `ServerStorage.HabitatModules`. `activate` and `deactivate` run hooks: deactivating clears wild monsters (`EncounterService.clearWild`, which keeps fleeing escapes); activating repopulates (`EncounterService.populate`). It sets the `ActiveHabitat` Workspace attribute and the hub gate label.
  - Client: LocalWorld follows `ActiveHabitat` and re-opens the crypt gate locally when the cemetery comes back. The journal lists every habitat where a species lives.
  - Studio-only selector: `StudioTestHook.arg("habitat")` picks the starting module in test runs.
- **Audit follow-ups from TASK-0026:**
  - Finding 2: CrossPlot asserts the parked seat is Disabled, and adds a touch-only control on the enabled seat.
  - Finding 4: Reachability checks all plots × all gates.
- **Part counts:** Cemetery 463, Woodland 298, Spider Woodland 247, Settlement 135 (HabitatSwap).
- **Evidence:** [[TEST-20261012-03]].

## Audits
- [[AUD-20261012-TASK-0027-01]]: pass (5 minor, 2 nit). Finding 1 moved to TASK-0028, findings 2 and 3 to TASK-0029, the TEST note placeholder fixed.

## Outcome
- **Merge** approved by jg in chat on 2026-10-12 ("merge anything you need to to finish this up"). Merged through PR #21.
- **Result:** four interchangeable habitat modules behind one contract and validator. `HabitatService` prebuilds them and swaps one in at a time; the old module's wild monsters are cleared and the new roster spawns.
- **Lessons:** the Studio MCP plugin has its own module cache, so a Play session's services can't be driven from `execute_luau`; use scenario args. Screen captures in Play drop the MCP connection under memory pressure on this machine.
- **Follow-ups:** jg's visual review of the blockouts (AC4); captures retried in TASK-0028.

