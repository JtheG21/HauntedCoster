---
id: TASK-0114
title: "MathShow Tap Target + Unmeasured Rows Audit"
type: task
project: GAME-004
status: review
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

## Results (2026-10-31, build 9ccb8eb)

- **Ledger:** 1,420 historical unmeasured rows reconcile (284 per viewport). The 669 measured rows per viewport also reconcile. New rows are counted separately in `docs/workflow/STUDIO-SYNC.md`.
- **Gate:** 0 failures at all five viewports for clip, collision, review-row gap, tap and overlap. Overlap has 8 allow-listed pairs per viewport (gamepad selection surface).
- **Review rows:** 36 tall, 38 pitch, minimum gap 2 px.
- **IdentityBoards:** 109 rows and 0 failures per viewport, 0 GuiButtons, tightest margin 6.75 design px (`[WWWWW]` tag; 7.0 at 844x390).
- **Tap rule:** design units (`AbsoluteSize` divided by the gate scale), minimum 44. The smallest control is 230x44 at every viewport, so it passes with no margin. This replaces the earlier screen-point rule, which did not follow a clean model in the Preview harness.
- **Status:** orchestrator record-exec pass. record-audit is for Codex.

