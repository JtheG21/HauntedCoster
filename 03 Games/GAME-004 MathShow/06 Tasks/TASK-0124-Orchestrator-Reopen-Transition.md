---
id: TASK-0124
title: "Orchestrator reopen transition"
type: task
project: GAME-004
status: approved
priority: low
risk: low
owner: codex
depends_on: []
branch: task/TASK-0124-orchestrator-reopen
related:
  - "[[TASK-0122-MathShow-Hub-Mode-Pads]]"
created: 2026-11-02
updated: 2026-11-02
tags:
  - workflow/task
---

# Orchestrator reopen transition

## Goal
Give approved re-scopes a proper transition. On TASK-0122 the orchestrator had no way from `blocked` to `review`, so jg approved a hand edit of the task file.

## Scope
- **In:** `orchestrator.py reopen <id> --to review --reason <text>`: allowed from `blocked`, `changes_requested` and `approved`; appends a history entry with the reason; refuses other states; tests in the orchestrator's test suite; a line in `docs/workflow/TASKS.md`.
- **Out (non-goals):** changing the revision counter or any other transition.

## Intake
- **Category, depth:** tooling, light.
- **Decision (jg, 2026-11-02):** raised in the approved rows Q1/Q2 on TASK-0122.
- **Implementation approval:** rows O1-O5 (jg, 2026-11-02), Codex owner. Reuse the existing CLI, task writer and note-sync helper; no new dependencies or reference implementation needed.

## Files expected to change
`scripts/orchestrator.py`, its tests, `docs/workflow/TASKS.md`, this note, `tasks/items/TASK-0124.json`.

## Acceptance criteria
- [x] AC1 `reopen` works from blocked, changes_requested and approved and appends history with the reason.
- [x] AC2 Other states are refused with a clear error.
- [x] AC3 Tests cover both; TASKS.md lists the command.

## Tests
`scripts/check.sh` (Python tests).

## Risks / notes
Light tier: no audit, merge needs jg.

---
## Implementation record
- Added `reopen <id> --to review --reason <text> [--by jg]`, restricted to blocked/changes_requested/approved. Reasons cannot be empty or whitespace. Appends exactly from/to/reason/by/at, preserves prior history, audit references and revision counts, and uses the existing task-note status sync.
- Six new orchestrator tests cover each allowed and refused state, reason and target errors, default/explicit attribution, note sync, serialized history/audit preservation and unchanged report files. `python3 -m unittest discover -s tests -p test_orchestrator.py -v`: 38 passed. `scripts/check.sh`: all 13 steps pass. Queue/vault validators: no errors or warnings.
- Only the five approved files changed. No game sources, Studio/Rojo operations or audit record. Dedicated branch starts from main at daf4c4f.

## Audits

## Outcome
Implemented and tested; ready for human merge approval after CI. Light-tier record-exec supplies the approval state without an audit. Merge is not authorized by this task.
