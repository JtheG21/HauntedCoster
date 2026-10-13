---
id: TASK-0004
title: Ki Burst
type: task
project: GAME-001
status: done
priority: high
risk: medium
owner: executor
milestone: M2
depends_on: 
  - TASK-0002
branch: task/TASK-0004-Ki-Burst
created: 2026-10-10
updated: 2026-10-12
tags:
  - workflow/task
  - milestone/m2
related:
  - "[[GAME-001 Rg1/01 Game Design|01 Game Design]]"
  - "[[GAME-001 Rg1/03 Roadmap|03 Roadmap]]"
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
*Executor (Claude Code, main session), 2026-10-10, branch `task/TASK-0004-Ki-Burst`, **stacked on `task/TASK-0003-Factions-And-Echo-Clone`** (branched from it so the shared Components folder doesn't disappear, which crashes Rojo; see [[LES-0003-Rojo-Crash-On-Branch-Switch]]). It must merge after TASK-0003.*

**Files changed**
- `src/server/Abilities/KiBurst.luau` (new): `KiCharge` (key down) records a server timestamp. `KiBurst` (key up) computes the charge server-side, queries a 12-stud radius in front, breaks walls (fraction ≥ 0.5), pushes blocks, shows a short flash, and writes server-only diagnostics
- `src/server/Components/CrackedWall.luau` (new): break once, restore after 10 s
- `src/server/Components/HeavyBlock.luau` (new): unanchor plus **server network ownership**, push with `ApplyImpulse(velocity × mass)`
- `src/shared/KnockbackRules.luau` (new): `chargeFraction`, `lerp`, `pushDirection`, `inFront` (reused by the finale)
- `tests/luau/KnockbackRules.spec.luau` (new, 6 tests)
- **Outside the listed files (needed):** `src/shared/AbilityConfig.luau` (Ki entries, `releaseId`, rewritten as a typed table after a bad edit, same values), `src/client/AbilityInput.luau` (hold-to-charge: fires `releaseId` on key up; skips abilities without a key), `src/server/init.server.luau`

**Network-ownership decision (spike outcome, AC5):** shared pushable objects are **server-owned** (`SetNetworkOwner(nil)`). Pushes are applied on the server, so a client can't move or fling them by local simulation, and every client sees the server's result. Trade-off: slight latency for the pusher. That's acceptable for puzzle objects. Character movement stays client-owned (TASK-0002 LinearVelocity pattern). Small enough for an implementation record. An ADR follows if physics ownership becomes contested.

**Check results:** `scripts/check.sh` ALL CHECKS PASSED. Specs 28/0. Playtest [[TEST-20261010-06]].

## Audits
- [[AUD-20261010-TASK-0004-01]]: attempt 1, **pass** (8 minor, 3 nit). Notable minors: wall range uses the part centre (F1), pushes de-duplicated per part, not per assembly (F2), restore resets CanQuery to true (F3), charge not cleared on death or faction change (F7), release fires after an unregistered key-down (F8). Proposed for a hardening task

## Outcome
Merged to `main` on 2026-10-10 (merge approved by jg). Built stacked on TASK-0003. Audit minors F1–F8 are candidates for a hardening task (wall range by centre, per-assembly push dedupe, CanQuery restore, stale charge, release without key-down).
