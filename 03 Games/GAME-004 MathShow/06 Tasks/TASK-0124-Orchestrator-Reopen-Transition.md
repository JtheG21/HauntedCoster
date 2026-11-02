---
id: TASK-0124
title: "Orchestrator reopen transition"
type: task
project: GAME-004
status: backlog
priority: low
risk: low
owner: claude-code
depends_on: []
branch: chore/orchestrator-reopen
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

## Files expected to change
`scripts/orchestrator.py`, its tests, `docs/workflow/TASKS.md`, this note, `tasks/items/TASK-0124.json`.

## Acceptance criteria
- [ ] AC1 `reopen` works from blocked, changes_requested and approved and appends history with the reason.
- [ ] AC2 Other states are refused with a clear error.
- [ ] AC3 Tests cover both; TASKS.md lists the command.

## Tests
`scripts/check.sh` (Python tests).

## Risks / notes
Light tier: no audit, merge needs jg.

---
## Implementation record

## Audits

## Outcome
