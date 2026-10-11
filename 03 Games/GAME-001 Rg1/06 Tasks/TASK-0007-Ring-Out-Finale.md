---
id: TASK-0007
title: Ring-Out Finale
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
  - TASK-0006
branch: task/TASK-0007-Ring-Out-Finale
created: 2026-10-10
updated: 2026-10-10
tags:
  - workflow/task
  - milestone/m2
related:
  - "[[01 Game Design]]"
  - "[[03 Roadmap]]"
---
# TASK-0007: Ring-Out Finale

## Goal
A last-one-standing **ring-out** arena: knock rivals off using your own power plus earned Echo charges. Results by category (Speed, Teamwork, Combat).

## Scope
- **In:** Arena zone with ring-out detection, finale versions of the powers (Clone = decoy that absorbs one hit; Ki Burst = player knockback), spending Echo charges, category result computation.
- **Out:** Health-bar combat, the global Faction War (M4).

## Files expected to change
- `src/server/Services/FinaleService.luau` (new)
- `src/shared/ResultRules.luau` (new): pure category winners
- `src/server/Abilities/FinaleModifiers.luau` (new)
- `src/client/ResultsHud.client.luau` (new)
- `tests/luau/ResultRules.spec.luau` (new)

## Acceptance criteria
- [ ] Falling below the arena, or out of bounds, eliminates a player once (server-detected)
- [ ] The last remaining player wins Combat. A simultaneous last elimination is a draw (spec-covered)
- [ ] Speed = first obby finisher, Teamwork = most gate contributions. Ties are handled deterministically
- [ ] Knockback is applied on the server only. A client can't apply force to others
- [ ] `check.sh` passes

## Tests
- **Automated:** `scripts/check.sh` plus the new Luau specs (run in Studio: `require(game.TestService.Tests.TestRunner).run()`)
- **Studio playtest procedure:** 2–4 clients: finale with knockbacks; verify the results screen; exploit probe: client-side velocity changes on others have no effect.

## Risks / notes
Follow [[Luau Standards]]: server-authoritative, validate every remote argument, debounce shared state before yielding.

---
## Implementation record
*Executor (Claude Code, main session), 2026-10-10, branch `task/TASK-0007-Ring-Out-Finale`*

**Files changed**
- `maps/finale_arena.json` (new): roblox-map spec for the arena, proven offline (P9 pass, a 0.45 s fall to the ring-out)
- `src/shared/FinaleConfig.luau` (new): arena layout, ring-out depth and bounds, knockback, Echo burst strength, guard time, 60 s limit
- `src/shared/ResultRules.luau` (new): `isRingOut` (NaN = out), `finaleOver`, `combat` (one survivor wins; a simultaneous last elimination or a time-out = a sorted draw; solo fall = no winner), `speed`, `teamwork` (ties → earlier finisher → lower UserId)
- `src/server/Services/FinaleService.luau` (new): builds the greybox arena, eliminates once per player (10 Hz poll; one poll = simultaneous), spectate pad, guards, Teamwork tally, category results (`Result_*` attributes plus a summary line)
- `src/server/Abilities/FinaleModifiers.luau` (new): server-only knockback (a short LinearVelocity on the target, like Dash) for alive finale players in front of the attacker; guard absorbs one hit; `EchoBurst` / `EchoGuard` spends
- `src/client/ResultsHud.luau` (new, a ModuleScript like the other client modules, not `.client.luau`): finale status, Echo charges with keys, results panel
- `tests/luau/ResultRules.spec.luau` (new, 11 tests); `tests/luau/multiclient/FinaleRingOut.luau` (new)
- **Outside the listed files, declared:** `MatchService` (`setFinale` hook: begin, isOver, results, respawn, maxSeconds; placeholder kept when nothing is wired), `MatchConfig` comment, `EchoService.spend`, `KiBurst.setOnBurst` plus `LastKiHitBy`, `EchoClone.setOnClone`, `PressurePlate` `CloneOwner`, `ConvergenceGate.onContribution` (clone owner and Ki hitter credited once per opening), `AbilityConfig` (EchoBurst G, EchoGuard V), `MatchHud` (defers to the results panel), both `init` scripts

**Design decisions (proposed defaults, need confirmation)**
- Echo charges **add** to your own power (design open question 3), as separate abilities: G = borrowed Ki Burst at 60% strength, V = borrowed guard. Any faction can spend any charge it holds, its own faction's included.
- The finale Echo Clone = a **guard** that absorbs the next knockback within 6 s (the clone part also appears).
- Knockback hits only players (finale only, alive participants). Obby shoving between rivals is still out of scope.
- A solo player who falls wins nothing in Combat. A time-out with several survivors is a draw.
- Faction points from results are not written (M4 Faction War).

**Check results:** `scripts/check.sh` ALL CHECKS PASSED. Specs 57/0 (fresh session). Playtest [[TEST-20261010-11]] (solo plus a 2-client `FinaleRingOut` pass; the failed runs are listed there).

## Audits
- [[AUD-20261010-TASK-0007-01]]: attempt 1, **fail** (1 major, 5 minor, 3 nit). Major F1: the finale keeps eliminating after it is decided, so a second fall 0.1 s later overwrites the result ("nobody survived" instead of the last player standing).

## Outcome
