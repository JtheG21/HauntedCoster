---
id: TASK-0116
title: "MathShow Hit Rect 48"
type: task
project: GAME-004
status: in_progress
priority: medium
risk: low
owner: claude-code
depends_on:
  - TASK-0114
branch: task/TASK-0116-hit-rect-48
created: 2026-11-01
updated: 2026-11-01
tags:
  - workflow/task
---

## Goal
Raise every hit rect to at least 48 design units without changing art, then re-run the gate.

## Scope
- Find every hit rect under 48 design units from the gate's tap rows.
- Enlarge the hit area only; keep art, ids and visible layout.
- Raise `TAP_MIN` to 48 in `TextFit.luau` and re-run the full gate.

## Not in scope
Collision checks (TASK-0115), art, server, new viewports.

## Origin
Registered 2026-11-01 when TASK-0114 dropped its collision gate after two failed audits (see [[TASK-0114-MathShow-Tap-Target-Unmeasured-Rows-Audit]]). Backlog only: no implementation, not approved.
