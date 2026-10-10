---
id: TASK-0004
title: Ki Burst
type: task
project: GAME-001
status: proposed
priority: high
risk: medium
owner: executor
milestone: M2
depends_on: 
  - TASK-0002
branch: task/TASK-0004-Ki-Burst
created: 2026-10-10
updated: 2026-10-10
tags:
  - workflow/task
  - milestone/m2
related:
  - "[[01 Game Design]]"
  - "[[03 Roadmap]]"
---
# TASK-0004: Ki Burst

## Goal
The Ki Vanguard *Ki Burst*: a charged blast that breaks `CrackedWall` parts and pushes `HeavyBlock` physics objects. This spike decides **network ownership** for pushable objects.

## Scope
- **In:** Ki Burst ability (charge 0.5–1.5 s → force scaled by charge), CrackedWall (break plus respawn), HeavyBlock (server-owned physics), knockback helper reused by the finale.
- **Out:** Player knockback tuning for the finale (TASK-0007), VFX polish.

## Files expected to change
- `src/server/Abilities/KiBurst.luau` (new)
- `src/server/Components/CrackedWall.luau` (new)
- `src/server/Components/HeavyBlock.luau` (new)
- `src/shared/KnockbackRules.luau` (new): pure force-by-charge math
- `tests/luau/KnockbackRules.spec.luau` (new)

## Acceptance criteria
- [ ] Only Ki players can activate it. The charge time is measured on the **server**, so a client can't claim a full charge
- [ ] CrackedWall in range breaks once and respawns after 10 s
- [ ] HeavyBlock moves the same way for all clients. Its network owner is the server (verified with `GetNetworkOwner`)
- [ ] Knockback math specs pass. `check.sh` passes
- [ ] The decision on network ownership is recorded in the implementation record (input for an ADR if non-trivial)

## Tests
- **Automated:** `scripts/check.sh` plus the new Luau specs (run in Studio: `require(game.TestService.Tests.TestRunner).run()`)
- **Studio playtest procedure:** Play: break a wall, push a block; 2-client view comparison of block position; exploit probe: spam activations and fake charge values → rejected.

## Risks / notes
Follow [[Luau Standards]]: server-authoritative, validate every remote argument, debounce shared state before yielding.

---
## Implementation record

## Audits

## Outcome
