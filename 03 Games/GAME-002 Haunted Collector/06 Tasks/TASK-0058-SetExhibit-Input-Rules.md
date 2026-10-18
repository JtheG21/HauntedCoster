---
id: TASK-0058
title: "SetExhibit Input Rules"
type: task
project: GAME-002
status: in_review
priority: low
risk: low
owner: executor
depends_on: []
branch: task/TASK-0058-SetExhibit-Input-Rules
related:
  - "[[Task Intake]]"
  - "[[TASK-0038-Encounter-Review-Capture-Guards]]"
  - "[[TASK-0057-Overview-Evidence-Sync]]"
created: 2026-10-18
updated: 2026-10-18
tags:
  - workflow/task
---

# SetExhibit Input Rules

## Goal
Move the `SetExhibit` remote's input validation into a pure rule with a headless spec, as TASK-0038 did for `CaptureRules`, and use the task as the second measured task (Standard tier: Sonnet first audit).

## Scope
- **In:** `shared/Rules/ExhibitRules.luau` with `setRefusal(profile, slot, uid)` returning the player-facing refusal or nil; `ContainmentService.onSetExhibit` calls it; `tests/ExhibitRules.spec.luau`.
- **Out (non-goals):** behaviour changes, the `Remotes.allow` rate limit (stays in the service), the exhibit-update logic, other services. Any defect found becomes a follow-up for jg.
- **Keep unchanged:** the order and text of refusals ("Still loading", "Bad slot", "That exhibit slot is locked", "You don't own that monster"), `setExhibit` as the entry shared with the Studio scenarios.

## Intake
- **Category → workflow, depth:** Systems → [[Systems Workflow]], **Standard**
- **References:** none relevant in `10 References/`; the pattern is `CaptureRules.startRefusal` from TASK-0038.
- **Reuse:** adapt the TASK-0038 extraction and its negative-control spec style.
- **Decisions / assumptions / open questions:** Assumption: remote input validation here is Standard, not security-class, because the change preserves behaviour; if the diff goes beyond the extraction, the first audit moves to Opus. Open for jg: confirm that classification.
- **Measurement:** record executor and audit tokens with `orchestrator.py record-usage` where a figure exists, plus audit count and model.

## Files expected to change
- `games/haunted/src/shared/Rules/ExhibitRules.luau`, `games/haunted/src/server/Services/ContainmentService.luau`, `games/haunted/tests/ExhibitRules.spec.luau`

## Acceptance criteria
- [x] AC1 `ExhibitRules.setRefusal` holds the validation with the same order and text; the rate limit stays in the service.
- [x] AC2 Lune spec covers the all-clear case, each refusal, the order, NaN, slot 0 and a slot above the tier; a negative control fails it.
- [x] AC3 FullLoop and ExploitProbe pass in Studio; `scripts/check.sh` green; one Sonnet first audit; tokens recorded.

## Tests
- **Automated:** `scripts/check.sh`.
- **Studio playtest procedure:** `ExecutePlayModeAsync({ scenario = "FullLoop" })` and `ExploitProbe` per the Overview, after `studio-preflight`.

## Risks / notes
Behaviour must not change: compare refusal text and order against the current function before editing.

---
## Implementation record
- Added `shared/Rules/ExhibitRules.luau` (`setRefusal`, same order and text as before), `ContainmentService.onSetExhibit` now calls it (rate limit and update unchanged), and `tests/ExhibitRules.spec.luau` (6 tests; 172 specs total).
- Negative control: with the slot-range guard replaced by `if false`, 2 new tests failed (170 passed, 2 failed); restored, 172/0. `scripts/check.sh` ALL CHECKS PASSED (a first typecheck failure on mixed-type lists was fixed with `{ any }` annotations).
- AC3 (Studio, 2026-10-18): the real `HauntedCollector.rbxl` place (the only Studio instance; the stale ones were killed with jg's approval), synced by `rojo serve haunted.project.json` from this worktree; build stamp `770e359 2026-10-18T08:21:57Z` confirmed in Edit before the runs. `FullLoop` 85/85 (its SetExhibit checks cover a locked slot, an unowned monster and a valid set) and `ExploitProbe` 13/13, both equal to the 2026-10-12 baselines. Run in the background from Edit with the result read from `_G.scn`; a first direct call timed out and its result was lost, then both were rerun. DataStores were in memory mode (unpublished place). Reporting state: implemented and tested.
- Usage: no token figure available for the executor; the audit has not run.

## Audits

## Outcome
