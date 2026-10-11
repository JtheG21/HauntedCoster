---
id: TASK-0003
title: Factions and Echo Clone
type: task
project: GAME-001
status: in_review
priority: high
risk: medium
owner: executor
milestone: M2
depends_on: 
  - TASK-0002
branch: task/TASK-0003-Factions-And-Echo-Clone
created: 2026-10-10
updated: 2026-10-10
tags:
  - workflow/task
  - milestone/m2
related:
  - "[[01 Game Design]]"
  - "[[03 Roadmap]]"
---
# TASK-0003: Factions and Echo Clone

## Goal
Players pick (or get auto-balanced into) a faction. The Shinobi *Echo Clone* spawns a clone that holds pressure plates for 6 s.

## Scope
- **In:** `FactionService` (assignment and balance, Shinobi/Ki only in M2), a faction attribute on the player, the Echo Clone ability through the framework, a `PressurePlate` component.
- **Out:** Other factions, faction visuals beyond a colour tint, finale decoy behaviour (TASK-0007).

## Files expected to change
- `src/shared/FactionConfig.luau` (new)
- `src/server/Services/FactionService.luau` (new)
- `src/server/Abilities/EchoClone.luau` (new)
- `src/server/Components/PressurePlate.luau` (new)
- `tests/luau/FactionRules.spec.luau` (new)

## Acceptance criteria
- [ ] Auto-balance keeps faction counts within 1 of each other
- [ ] Only Shinobi players can activate Echo Clone (server-checked)
- [ ] The clone holds a pressure plate active for exactly its duration (6 s ±0.2 s), then despawns
- [ ] Max 1 clone per player. Clones are cleaned up on leave or respawn
- [ ] Specs for balance rules pass. `check.sh` passes

## Tests
- **Automated:** `scripts/check.sh` plus the new Luau specs (run in Studio: `require(game.TestService.Tests.TestRunner).run()`)
- **Studio playtest procedure:** Play 2 players: verify assignment balance; Shinobi spawns a clone on a plate → door opens for 6 s; a Ki player cannot trigger the clone (exploit probe).

## Risks / notes
Follow [[Luau Standards]]: server-authoritative, validate every remote argument, debounce shared state before yielding.

---
## Implementation record
*Executor (Claude Code, main session), 2026-10-10, branch `task/TASK-0003-Factions-And-Echo-Clone`*

**Files changed**
- `src/shared/FactionConfig.luau` (new): 4 original factions (ADR-0003). `Active = { "Shinobi", "Ki" }` for M2
- `src/shared/FactionRules.luau` (new, **not in the spec list** but implied by its spec): pure `pickBalanced`, `isBalanced`
- `src/server/Services/FactionService.luau` (new): assigns on join, `Faction` Player attribute (public), `setFaction` (server-only, active factions only), `requires(faction)` eligibility helper
- `src/server/Abilities/EchoClone.luau` (new): clone at the root position, `PlateActivator` tag, 6 s life, max 1 per player, removed on leave and respawn
- `src/server/Components/PressurePlate.luau` (new): 10 Hz `GetPartBoundsInBox` polling (standing contact; Touched is unreliable for this), optional `Door` ObjectValue link
- `src/shared/AbilityConfig.luau`: `EchoClone` ability (E, cooldown 8 s) and tuning. **Plus** a comment fix from TASK-0002 audit N1 (the force-margin claim replaced with a measured fact)
- `src/server/init.server.luau`: wiring
- `tests/luau/FactionRules.spec.luau` (new, 6 tests), `tests/luau/multiclient/FactionBalance.luau` (new)

**Design decisions**
- Players also activate plates (anyone can stand on one). The clone lets a Shinobi *leave* while the plate stays held. That's the cooperation hook for Convergence Gates.
- Eligibility comes from the faction (`FactionService.requires`) and is checked by AbilityService **before** the cooldown, so a rejected Ki request doesn't burn anything.
- Known client-side limitation (M2): every player sees every ability key (Q and E). Ineligible presses are rejected by the server. Faction-aware input or UI belongs in M3.

**Check results:** `scripts/check.sh` ALL CHECKS PASSED. Luau specs 22/0. Playtest [[TEST-20261010-05]].

## Audits

## Outcome
