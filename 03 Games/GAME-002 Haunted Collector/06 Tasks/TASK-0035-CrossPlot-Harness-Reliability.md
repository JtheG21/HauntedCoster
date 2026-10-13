---
id: TASK-0035
title: "CrossPlot Harness Reliability"
type: task
project: GAME-002
status: in_review
priority: high
risk: low
owner: executor
depends_on:
  - TASK-0034
branch: task/TASK-0035-CrossPlot-Harness-Reliability
related:
  - "[[TASK-0034-Post-Merge-Verification]]"
  - "[[TEST-20261012-11]]"
  - "[[TEST-20261012-12]]"
  - "[[TASK-0021-Anti-Cheat-Hardening]]"
created: 2026-10-12
updated: 2026-10-12
tags:
  - workflow/task
---

# CrossPlot Harness Reliability

## Goal
Make CrossPlot (2-player plot isolation) give a trustworthy result. Its "touching B's enabled front seat does seat A" control failed 2 of 3 runs, even with `TrainService` reverted ([[TEST-20261012-11]]). That control only proves touch-sitting works, which is client-simulated physics, not our code. The 2nd client also failed to launch ([[TEST-20261012-12]]). This is T2 of the 2026-10-12 audit plan (AUDIT-001).

## Scope
- **In:** `games/haunted/tests/scenarios/CrossPlot.luau` (seat section and result shape); 3 valid 2-player runs plus a negative control.
- **Out:** `TrainService`, plot ownership code, other scenarios.

## Files expected to change
- `games/haunted/tests/scenarios/CrossPlot.luau`

## Acceptance criteria
- [x] AC1 Touch is proven with an unguarded, enabled probe seat (up to 3 tries). If it never seats A, the parked-seat check is recorded as **inconclusive** (run flagged `infra`), never as a pass or a game failure.
- [x] AC2 The enabled-seat guard is tested deterministically: the server seats A in B's enabled front seat and A is ejected within about 1 s.
- [x] AC3 Negative control: with the owner-seat guard disabled in Studio's copy only, the AC2 check fails.
- [x] AC4 CrossPlot passes 3 of 3 runs with both clients joined. Runs where the 2nd client doesn't join are logged as infra and not counted.
- Evidence for AC1–AC4: [[TEST-20261012-13]] (3 valid runs at 22/22, touch probe seated A each time; negative control 21/22 failing only the AC2 check).

## Tests
- **Automated:** `scripts/check.sh`.
- **Studio playtest procedure:** `rojo serve haunted.project.json` from this branch, check the scenario source size in Studio, then `ExecuteMultiplayerTestAsync(2, { scenario = "CrossPlot", timeout = 240 })` from Edit inside `task.spawn`, three times.

## Risks / notes
- Proposed in chat on 2026-10-12. jg approved the replacement control and the start ("approve both, go ahead").
- Memory is tight on this 8 GB Mac: Claude uses about 1 GB and Studio about 0.7 GB. The leftover StudioMCP helpers are about 0.4 MB each, so they were left alone. If the 2nd client still won't start, the fallback is a manual 2-client run from Studio's Test tab.

---
## Implementation record
- Probe seat placed 12 studs from A's plot spawn; it is destroyed after the probe, which frees A.
- `finish()` now returns an `inconclusive` list. Any inconclusive check makes `ok` false and sets `infra = true`, so the run isn't counted.
- The touch-on-enabled-seat control is replaced by a server `Seat:Sit()` (AC2). The parked-seat touch check and the forced-parked check are unchanged.
- **Scope addition (same file, test-only):** the first runs failed "AC3: tier-1 B can (control)" with "Get closer" in 2 of 3 runs. The Ashen Gentleman roamed out of range because, unlike the Wraith, it was not pinned. It is now pinned before each try, and the two AC3 controls have distinct names. Without this, AC4 couldn't be met.
- **Harness:** automated 2-client launch works about 1 time in 4 on this Mac. The 2nd client stops at "file is in use by another Studio" in a saved place, or "could not open the place 'StartClient'" in an unsaved one. With jg's approval the remaining runs used manual Test-tab sessions with a temporary server Script, one fresh session each ([[TEST-20261012-13]]).
- `scripts/check.sh` passes.

## Audits

## Outcome
