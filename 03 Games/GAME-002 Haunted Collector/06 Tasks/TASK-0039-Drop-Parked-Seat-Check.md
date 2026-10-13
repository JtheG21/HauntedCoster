---
id: TASK-0039
title: "Drop Parked Seat Check"
type: task
project: GAME-002
status: in_review
priority: low
risk: low
owner: executor
depends_on:
  - TASK-0038
branch: task/TASK-0039-Drop-Parked-Seat-Check
related:
  - "[[TASK-0035-CrossPlot-Harness-Reliability]]"
  - "[[TEST-20261012-13]]"
  - "[[TEST-20261012-17]]"
created: 2026-10-12
updated: 2026-10-12
tags:
  - workflow/task
---

# Drop Parked Seat Check

## Goal
Remove CrossPlot's "A forced into B's parked front seat doesn't keep it" check. It passed with the owner guard turned off ([[TEST-20261012-13]]), so it proved nothing; the enabled-seat check already covers the guard. Also record jg's 2026-10-12 decisions on the rest of the audit plan.

## Scope
- **In:** `games/haunted/tests/scenarios/CrossPlot.luau` (that one check); notes.
- **Out:** `TrainService` and every other check.

## Files expected to change
- `games/haunted/tests/scenarios/CrossPlot.luau`, this note, [[TEST-20261012-17]], the Roadmap and Overview.

## Acceptance criteria
- [ ] AC1 CrossPlot no longer runs the forced-parked-seat check; every other check is unchanged.
- [ ] AC2 The 2-player baseline and the 2026-10-12 decisions are recorded.
- [ ] AC3 `scripts/check.sh` passes.

## Tests
- **Automated:** `scripts/check.sh`.
- **Studio playtest procedure:** none for the deletion (test-only code removed; the remaining checks are untouched). Next CrossPlot run will show 21 checks instead of 22.

## Risks / notes
- jg, in chat on 2026-10-12: "drop the parked seat check". Same message: art is fine for now (expect a full revamp later); references on hold; device checks wait until the game is nearly finished, so they test the final systems. After a 6-client test failed to start, jg decided to build for a full server but test with at most 2 players in Studio for now.

---
## Implementation record

## Audits

## Outcome
