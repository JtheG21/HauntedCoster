---
id: TASK-0005
title: Convergence Gate
type: task
project: GAME-001
status: in_progress
priority: high
risk: medium
owner: executor
milestone: M2
depends_on: 
  - TASK-0003
  - TASK-0004
branch: task/TASK-0005-Convergence-Gate
created: 2026-10-10
updated: 2026-10-10
tags:
  - workflow/task
  - milestone/m2
related:
  - "[[01 Game Design]]"
  - "[[03 Roadmap]]"
---
# TASK-0005: Convergence Gate

## Goal
The core cooperation mechanic: a gate that needs **2 different faction powers**. Everyone passing gets an **Echo charge** of the powers that opened it. A 20 s **Echo Shrine** fallback opens a slower bypass if nobody helps.

## Scope
- **In:** `ConvergenceGate` component (requirements computed from the factions present), Echo charge inventory (in-match only), Echo Shrine fallback, gate UI icons (which powers are needed).
- **Out:** Using Echo charges in the finale (TASK-0007), more gate types (M3).

## Files expected to change
- `src/server/Components/ConvergenceGate.luau` (new)
- `src/shared/GateRules.luau` (new): pure requirement and fallback logic
- `src/server/Services/EchoService.luau` (new)
- `src/client/GateHud.client.luau` (new)
- `tests/luau/GateRules.spec.luau` (new)

## Acceptance criteria
- [ ] The gate opens only when both required powers have been applied within a 10 s window
- [ ] If only one faction is in the match, requirements drop to that faction's power plus the shrine
- [ ] Each player passing an opened gate gets exactly 1 Echo charge per opening power (server inventory)
- [ ] The shrine bypass opens 20 s after the first player arrives if the gate is still closed
- [ ] Specs pass. `check.sh` passes

## Tests
- **Automated:** `scripts/check.sh` plus the new Luau specs (run in Studio: `require(game.TestService.Tests.TestRunner).run()`)
- **Studio playtest procedure:** 2 players (Shinobi + Ki): open the gate together; check Echo inventory; solo: shrine opens after 20 s.

## Risks / notes
Follow [[Luau Standards]]: server-authoritative, validate every remote argument, debounce shared state before yielding.

---
## Implementation record
*Executor (Claude Code, main session), 2026-10-10, branch `task/TASK-0005-Convergence-Gate`*

**Files changed**
- `src/shared/GateRules.luau` (new): pure `requirements`, `canOpen` (window, NaN or future guard), `shrineDue`, `awardFor`
- `src/server/Components/ConvergenceGate.luau` (new): 10 Hz loop over tagged gates; inputs via ObjectValue links (ShinobiPlate, KiTarget, PassZone, ApproachZone, Bypass); consumes inputs on opening; awards Echoes once per player per opening; Echo Shrine fallback; publishes `Required`, `State`, `ShrineAt` and `ShrineOpen` attributes
- `src/server/Services/EchoService.luau` (new): server inventory plus read-only `Echo_<Power>` Player attributes. `reset` for match end (TASK-0006)
- `src/client/GateHud.luau` (new; a ModuleScript like the other client modules, instead of `GateHud.client.luau`): billboard with needs, open state and shrine
- `tests/luau/GateRules.spec.luau` (new, 6 tests)
- **Outside the listed files (needed):** `src/shared/GateConfig.luau` (new tuning), `PressurePlate.luau` (`ClonePresent` attribute: only a clone counts as the Shinobi power, not a player standing), `KiBurst.luau` (tagged `KiTarget` hit above the wall-break threshold sets `LastKiHit`), both `init` scripts, and test fixtures `tests/luau/multiclient/GateFixture.luau` and `GateCoop.luau`

**Design decisions**
- Abilities and gates are decoupled through **server-set attributes** (`ClonePresent`, `LastKiHit`), so new factions plug in by setting an attribute.
- "Factions present" means everyone in the server for now. TASK-0006 will scope it to the match.
- Inputs are consumed when a gate opens, so one application can't keep reopening it.

**Check results:** `scripts/check.sh` ALL CHECKS PASSED. Specs 37/0 (fresh session). Playtest [[TEST-20261010-08]] (2-client scenario passed twice, real abilities and shrine verified).

## Audits

## Outcome
