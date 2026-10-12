---
id: TASK-0033
title: Retaliation Begin Cleanup
type: task
project: GAME-002
status: proposed
priority: low
risk: low
owner: executor
milestone: M3
depends_on:
  - TASK-0032
branch: task/TASK-0033-Retaliation-Begin-Cleanup
created: 2026-10-12
updated: 2026-10-12
tags:
  - workflow/task
  - milestone/m3
related:
  - "[[TASK-0032-Retaliation-Hardening]]"
  - "[[AUD-20261012-TASK-0032-01]]"
  - "[[TASK-0031-Failed-Capture-Retaliation]]"
  - "[[SYS-Haunted-Capture-Loop]]"
---
# TASK-0033: Retaliation Begin Cleanup

## Goal
Close finding 1 of [[AUD-20261012-TASK-0032-01]]. Today `RetaliationService.begin` marks each pursuer with `setPursuing(e, player)` in a loop and only then creates `pursuits[player]`. If anything errors in between, the monsters already marked have no pursuit record, so neither the tick nor the tick-error recovery ever releases them. They stay `pursuing`, can't be captured and have Inspect off until the next habitat swap. `onFled`'s `pcall` (TASK-0032) removes only the target.

## Scope
- **In:**
  - `RetaliationService.begin`: an error part-way through must not leave any monster marked as pursuing. Two options: create the pursuit record first and add each pursuer as it is set (the tick and `abandonAll` then cover it), or `pcall` the selection loop, release every monster already set, and re-raise. The executor picks one and notes why.
  - A test-only hook that makes `begin` fail after the first pursuer is set (like `failNextTickForTest`). It must not be reachable from any remote.
  - A `Retaliation` scenario step for that failure. It also covers the "erroring `onFled` handler" path that [[TEST-20261012-08]] left to code review (finding 2).
- **Out:** tuning numbers, new behaviour, and any change to `onFled` beyond what the test needs.

## Files expected to change
- `games/haunted/src/server/Services/RetaliationService.luau`
- `games/haunted/tests/scenarios/Retaliation.luau`

## Acceptance criteria
- [ ] AC1: If `RetaliationService.begin` errors after marking some monsters as pursuing, every monster it marked is released (`pursuing` cleared, Inspect enabled), and no half-built pursuit record is left.
- [ ] AC2: The error still reaches `CaptureService.onFled`'s `pcall`: it is warned, and the target falls back to the slipped-away removal.
- [ ] AC3: The Retaliation scenario injects a failure inside `begin` after the first pursuer is set, then checks that no monster is left pursuing and the target was removed.
- [ ] AC4: Normal pursuits are unchanged. Retaliation, FullLoop and ExploitProbe pass, and `scripts/check.sh` passes.

## Tests
- **Automated:** `scripts/check.sh`.
- **Studio playtest procedure:** run `Retaliation`, `FullLoop` and `ExploitProbe` from Edit with `_G.scnChain` in a fresh Play session on `HauntedCollector.rbxl`. First check that Rojo is serving this branch's sources: the running server serves the main checkout (see [[TEST-20261012-08]]).

## Risks / notes
- References: none new. The pattern is the TASK-0032 tick recovery (`abandonAll`).
- Proposed on 2026-10-12 at jg's request ("create TASK-0033 for the begin() follow-up"). Starting it needs jg's approval.

---
## Implementation record
*(Executor: files changed, decisions, check output)*

## Audits
*(links to AUD- notes)*

## Outcome
*(after merge: result, lessons, follow-ups)*
