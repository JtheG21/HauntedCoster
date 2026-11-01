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
updated: 2026-11-01
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

## Audit fixes (2026-11-01, build 0b8c767)

- The audit findings are fixed: a tight settings allow-list, an explicit decoration list with per-instance counts, the sibling-only duplicate exemption, sticker frames in clip and collision, the GuiButton census before destroy, and tighter Edge, NEW BEST and VS exemptions. File:line table in `docs/workflow/STUDIO-SYNC.md`.
- Full gate at five viewports: TextFit 6,335 rows, 0 failures. IdentityBoards 109 rows per viewport, 0 failures, 0 GuiButtons.
- Exec record for this build is appended. Earlier records (73316be, 9ccb8eb) stay in history.

## Narrowed scope (2026-11-01, build 025b721)

- **Decision (jg):** the rule-based collision gate failed audit twice, so collision is removed from this task and rebuilt as [[TASK-0115-MathShow-Ownership-Based-Collision-Gate]]. Hit rects to 48 are [[TASK-0116-MathShow-Hit-Rect-48]].
- **Rules check:** docs/workflow/TASKS.md lists `changes_requested` (limit 2) -> `in_progress` via `start`, and `orchestrator.py` blocks only when revisions exceed `max_revisions` (2). At 2/2 a resubmission is allowed and one more failed audit blocks the task, so this task was re-scoped and resubmitted, not replaced. PR #168 stays on this branch.
- **Still in scope:** tap size (design units, 44), same-row interactive-overlap allow-list, sticker and label clipping, review-row gap, IdentityBoards census and margin, the 1,420-row reconciliation.
- **Out of scope now:** all collision checks. The log prints `collision: NOT COVERED -> TASK-0115` per viewport.
- **Gate (5 viewports):** TextFit 6,300 rows, 0 failures; header prints BuildStamp, category counts and the 669 + 284 = 953 reconciliation. IdentityBoards 109 rows, 0 failed, 0 GuiButtons per viewport. Details in `docs/workflow/STUDIO-SYNC.md`.
- **For Codex:** re-audit the narrowed scope only (`TextFit.luau` diff 0b8c767..HEAD).

## Handoff (Codex review, narrowed scope, 2026-11-01)
- **Task:** TASK-0114, final revision (2/2). Collision removed; tap, allow-list, clip, review-gap and census kept. Receiver: Codex, reviewer only, no edits.
- **Workspace:** `/Users/jg/Desktop/Rg1-worktrees/task-0114`, branch `task/TASK-0114-tap-target-audit`, PR #168. Range `0b8c767..HEAD` (code in `025b721`, docs in `40c3165`).
- **Inputs:** [[TASK-0115-MathShow-Ownership-Based-Collision-Gate]], [[TASK-0116-MathShow-Hit-Rect-48]], `docs/workflow/STUDIO-SYNC.md` (section "narrowed scope, build 025b721").
- **Focus:**
  - `games/mathshow/tests/studio/TextFit.luau`: is any collision, decoration or exemption logic left? Does `NOT COVERED` print once per viewport?
  - `TextFit.luau` `allowedSettingsPair` and `auxChecks`: do tap, same-row allow-list, clip (incl. FitSticker Frames) and review-gap still run unchanged?
  - `TextFit.luau` `run()`: are BuildStamp, zero-filled category counts and the 669+284=953 / 1,420 reconciliation printed before the row list, and does a mismatch fail the run?
  - `games/mathshow/tests/studio/IdentityBoards.luau`: census before destroy (unchanged in this range; confirm).
  - `STUDIO-SYNC.md` and the note: do the numbers match the log (6,300 rows, 264 clip, 0 failures)? Why clip rose from 261 to 264 is untraced.
- **Constraints:** no uploads, publishing or Studio writes. Rojo is stopped; ask jg before starting it.
- **Known non-task failures:** none. `check.sh`, `validate_queue`, `validate_vault` pass; CI green.
- **Unverified:** nothing in motion. The gate ran once in Studio (Play, Client); the log is in `~/Library/Logs/Roblox/`.
- **Report back:** verdict, findings with file:line, checks run, what is unverified.
