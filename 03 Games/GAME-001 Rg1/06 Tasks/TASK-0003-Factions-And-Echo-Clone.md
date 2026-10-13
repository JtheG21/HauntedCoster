---
id: TASK-0003
title: Factions and Echo Clone
type: task
project: GAME-001
status: done
priority: high
risk: medium
owner: executor
milestone: M2
depends_on: 
  - TASK-0002
branch: task/TASK-0003-Factions-And-Echo-Clone
created: 2026-10-10
updated: 2026-10-12
tags:
  - workflow/task
  - milestone/m2
related:
  - "[[GAME-001 Rg1/01 Game Design|01 Game Design]]"
  - "[[GAME-001 Rg1/03 Roadmap|03 Roadmap]]"
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

### Revision 1 (after [[AUD-20261010-TASK-0003-01]] fail)
- **Major fixed:** `FactionService` rebalances on `PlayerRemoving` (pure `FactionRules.rebalanceMove`). It moves the most recent joiner from the largest to the smallest faction until counts are within 1
- **Minor 2:** Echo Clone moved from **E to F** (E is the default ProximityPrompt key). Faction-aware input is still M3
- **Minor 3:** doors open while **any** linked plate is active. Removing an active plate closes its door (cached plate→door; a bug in the first revision attempt was found by playtest and fixed)
- **Minor 4:** +3 `rebalanceMove` specs, plus the `FactionRebalance` multi-client scenario (a real leave via Kick)
- **Nit 8:** a live clone is removed when the owner's faction changes. **Nit 9 (partial, corrected per [[AUD-20261010-TASK-0003-02]]):** the *new* `FactionRebalance` scenario uses FactionConfig and FactionRules, but `FactionBalance.luau` still hardcodes them (deferred)
- **Minor 5:** evidence taken against committed builds with hashes ([[TEST-20261010-07]])
- Not addressed (nits, logged for a hardening task): 6 (OverlapParams per tick), 7 (clone CanQuery)

**Checks:** `scripts/check.sh` ALL CHECKS PASSED. Specs **31/0 in a fresh session**. Playtest [[TEST-20261010-07]]. Lesson [[LES-0005-Edit-Mode-Require-Cache]].

## Audits
- [[AUD-20261010-TASK-0003-02]]: attempt 2 (revision 1), **pass**: major fixed. Nits: rebalance overrides `setFaction` (guard in TASK-0006), a re-linked or moved active plate leaves its old door open, FactionBalance hardcodes names
- [[AUD-20261010-TASK-0003-01]]: attempt 1, **fail**. Major: no rebalance after leaves (gates become unsolvable). Minors: E-key/ProximityPrompt clash, shared-door conflict, specs miss service and leave paths, playtest on an uncommitted tree

## Outcome
Merged to `main` on 2026-10-10 (merge approved by jg) after revision 1. Remaining nits (`setFaction` guard vs rebalance, re-linked door, FactionBalance names, OverlapParams per tick, clone CanQuery) are candidates for a hardening task.
