---
id: TASK-0136
title: "MathShow Daily Ramp Reachability"
type: task
project: GAME-004
status: in_progress
priority: medium
risk: low
owner: claude-code
depends_on: []
branch: task/TASK-0136-daily-ramp
related: []
created: 2026-11-03
updated: 2026-11-03
tags:
  - workflow/task
---

# MathShow Daily Ramp Reachability

## Goal
In the TASK-0123 private playtest the Mac avatar could not walk from spawn to the Daily pad without jumping and stopped at a dark wall. Make every plaza-to-pad route walkable (no rise above 1.0 stud, at least 12 studs wide) and guard it with a deterministic test.

## Scope
- **In:** `scripts/build_hub.py` route geometry, generated `Hub.rbxmx`, `tests/test_hub_routes.py`, `scripts/check.sh`, evidence log.
- **Out (non-goals):** art beyond ramp/path geometry, pad logic, Glyph logic, menu, publishing, iPad, merging.
- **Keep unchanged:** Daily ModePad tag, attributes and size; Observatory on the highest terrace.

## Intake
- **Category, depth:** map geometry, standard. References: none beyond project conventions.
- **Decisions:** rows R0-R5 approved by jg, 2026-11-03.

## Files expected to change
See `files_owned` in `tasks/items/TASK-0136.json`.

## Acceptance criteria
See the task file; checked off in the Outcome once measured.

---
## Implementation record

## Diagnosis (R1)
_pending_

## Outcome
_pending_
