---
id: TASK-0113
title: "MathShow Menu Tablet Viewport TextFit"
type: task
project: GAME-004
status: in_progress
priority: medium
risk: low
owner: claude-code
depends_on:
  - TASK-0112
branch: task/TASK-0113-menu-tablet-textfit
created: 2026-10-31
updated: 2026-10-31
tags:
  - workflow/task
---

## Goal
Extend the TextFit gate to the tablet viewports, and run TASK-0106 IdentityBoards beyond 844x390.

## Scope
- Add 1024x768 and 1180x820 to `SIZES` in `games/mathshow/tests/studio/TextFit.luau`.
- Give `IdentityBoards` a per-size pass for the five viewports.
- Record results in `docs/workflow/STUDIO-SYNC.md`.

## Not in scope
Layout fixes for rows that fail (open a new task for them). Running the 852-row audit (TASK-0114).
