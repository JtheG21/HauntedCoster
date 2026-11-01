---
id: TASK-0116
title: "MathShow Hit Rect 48"
type: task
project: GAME-004
status: done
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

## Results (2026-11-01, code build db67a56)

- **Change:** every hit rect is at least 48 design px (`MenuTheme.HitMin`). `interactive()` centres a 48 px hit on a smaller control; the settings stepper buttons and row hits do the same. 29 of 49 hit rects grew, art and ids unchanged. `TextFit` `TAP_MIN` is 48.
- **Gate (5 viewports):** smallest tap target 230x48, 0 failures, TextFit 10,525 rows, collision 0 fails and 64 manifest hits, ledger 669/284, IdentityBoards 109 / 0 / 0 GuiButtons. Specs 304 passed. Table of old and new sizes in `docs/workflow/STUDIO-SYNC.md`.
- **Deviation:** settings row pitch 50 -> 54 (`MenuTheme.SettingPitch`), a visible 4 px spacing change per row, needed so 48 px hit rects on 0.5 degree rows do not overlap. Needs jg's visual OK.

