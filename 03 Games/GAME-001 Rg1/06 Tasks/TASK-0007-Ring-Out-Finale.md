---
id: TASK-0007
title: Ring-Out Finale
type: task
project: GAME-001
status: ready
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

## Audits

## Outcome
