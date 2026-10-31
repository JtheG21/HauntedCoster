---
id: TASK-0113
title: "MathShow Menu Tablet Viewport TextFit"
type: task
project: GAME-004
status: done
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

## Results (2026-10-31, build 9732f94)

- **TextFit, 5 viewports:** 4,765 rows, 0 failures (953 per viewport). Tightest 6.5 px at 844x390 (`06a-blitz-question`, `Screen_blitz/Score/Group/Content/Value`).
- **IdentityBoards, 5 viewports:** 109 rows each, 0 failed. The first run failed the same two checks at every viewport, so I added +2 px to the tag and status chips in `client/Identity/` (commit `9732f94`). Tightest margin not reported.
- **BuildStamp** `9732f94` confirmed in Edit before Play.
- **Not measured:** per-viewport tightest margins and IdentityBoards margins. Both are unrecorded, not failing.
- **Orchestrator:** approve, start and record-exec pass done. record-audit is refused in `approved`, because light tier has no audit; AGENTS.md "Tiers" says light tasks need a green `check.sh` only.
- **Follow-up:** TASK-0114 covers the 852 unmeasured rows and tap targets.

