---
id: TASK-0114
title: "MathShow Tap Target + Unmeasured Rows Audit"
type: task
project: GAME-004
status: backlog
priority: medium
risk: low
owner: claude-code
depends_on:
  - TASK-0112
branch: task/TASK-0114-tap-target-audit
created: 2026-10-31
updated: 2026-10-31
tags:
  - workflow/task
---

## Goal
Measure the 852 rows the TextFit gate does not margin-measure, and check tap targets and off-shard labels.

## Scope
- Build the list from the gate output: element path, size, viewport.
- Tap targets: 44x44 minimum at 844x390.
- Stickers and off-shard labels: no clipping, no overlap, measured.

## Not in scope
Uploads, id or art changes, and tablet viewports (TASK-0113).
