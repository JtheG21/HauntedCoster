---
id: TASK-0118
title: "MathShow Plaza Map: Brief + Mockup Intake"
type: task
project: GAME-004
status: backlog
priority: low
risk: low
owner: claude-code
depends_on: []
branch: task/TASK-0118-plaza-brief
related:
  - "[[SYS-Plaza-Map-Brief]]"
  - "[[REF-MAP-003-Night-festival-plaza-mood]]"
created: 2026-11-01
updated: 2026-11-01
tags:
  - workflow/task
---

# MathShow Plaza Map: Brief + Mockup Intake

## Goal
Record the plaza map decision table, a mood-only reference note and a place for mockups.

## Scope
- **In:** [[SYS-Plaza-Map-Brief]], [[REF-MAP-003-Night-festival-plaza-mood]], the Map Mockups README, index rows.
- **Out (non-goals):** anything under `games/`, building the map, mockup images.

## Intake
- **Category, depth:** docs, light.
- **References:** [[REF-MAP-003-Night-festival-plaza-mood]] (mood only).
- **Decisions:** jg, 2026-11-01: brief is a `system` note under `05 Systems/` because no design-notes type fits the validator.

## Files expected to change
- Brief, REF note, mockups README, indexes, `tasks/items/TASK-0118.json`.

## Acceptance criteria
- [ ] AC1 Brief, REF note and mockups README exist and pass `validate_vault.py` and `refs.py lint`.
- [ ] AC2 `scripts/check.sh` passes.

## Outcome
