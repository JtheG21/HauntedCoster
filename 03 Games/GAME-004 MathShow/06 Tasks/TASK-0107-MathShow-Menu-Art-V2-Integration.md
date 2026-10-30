---
id: TASK-0107
title: "MathShow Menu Art V2 Integration"
type: task
project: GAME-004
status: proposed
priority: medium
risk: medium
owner: executor
depends_on: []
branch: task/TASK-0107-menu-art-v2
related:
  - "[[GAME-004 MathShow/00 Overview]]"
created: 2026-10-27
updated: 2026-10-27
tags:
  - workflow/task
---

# MathShow Menu Art V2 Integration

## Goal
Swap the Art v2 shards into the built menu and restore the README text sizes (`Game-spec-UI-elementsV4.zip`, folder `design_handoff_mathshow_menu_v2`). Regenerate nothing else; no upload.

## Scope
- **In:** `client/Menu/MenuTheme.luau` numbers and image keys; the shared `ShapeProfiles.luau` and sliced `rectFits` already in PR 151 (this branch is stacked on it); `art/menu/` copies of the 17 PNGs and `UPLOAD_LIST.md`; the Studio TextFit gate and a diff table.
- **Out:** uploads, publish, new remotes, any art edits, the identity system (TASK-0106), rank ladder content.
- **Keep unchanged:** old image keys until the swap is verified; HUD; server code.

## Intake
- **Package check (this session, raster header read only):** 17 PNGs, every size matches the README table (largest side 960), none over 1024. README band-margin table lists the lowest margin as 7 px at the package level; the separate independent check reported 8.3 px, 38 band checks, 0 fail. I have not re-measured the bands myself.
- **Category -> workflow, depth:** UI art integration, standard.
- **References:** `10 References/01 UI`: nothing relevant (checked for TASK-0106; same set).
- **Reuse:** `Menu/Shard`, `TextFitRules`, `tests/studio/TextFit`.
- **Decisions:** the scope list comes from jg's pasted prompt (2026-10-27).

## Plan (Phase 1: awaiting jg approval)
1. Base: PR 151 branch (ShapeProfiles 59 profiles + sliced rectFits + 9 specs). Copy the 17 PNGs into `games/mathshow/art/menu/` unchanged.
2. `MenuTheme`: add `-v2` Image keys (placeholders `rbxassetid://0`), SliceCenters, `ScaleType.Slice` for rows and toasts (glow banner is 1.5x, the rest 2x), layout numbers (H2H 344x52 at left 456 top 2; count 200x184 at top 48; banner 48 tall at top 274; title 104 tall at top 44; toasts 46 tall; rows 38 tall centred in their old slots; row content inset 20; ladder badge x20, name x52, subject x150 w126; review Q x20, icon x46, answer column 66) and the README text sizes (review Q 13 / answers 16, ladder names 15, settings labels 16, h2h points 20, count 100 / 60, banner label 17, toast 18 / icon 16).
3. Title: back to a 46 px MATHSHOW with the tag inside the shard (tag 30,12-180,31; title 24,40-320,86); remove the top-edge sticker workaround only if the gate passes.
4. Run `scripts/studio-preflight.sh --game mathshow`, then the TextFit gate in a fresh Play session at 844x390, 1920x1080 and phone landscape; write the numbers diff table.
5. Extend `art/menu/UPLOAD_LIST.md` (75 + 17); never upload.

Flags:
1. **Stacked on PR 151** (a chore branch with no task ID): that PR's base would become part of this task, and `tasks/queue.json` here lacks TASK-0105/0106, so queue.json will conflict when the stacks merge.
2. **Known truncation:** the ladder subject "Calculus 1, second half" truncates at 126 px; I would use `AllowTruncate` on the subject label (the alternative is TextScaled Min 12). Your call.
3. **Margins:** the package reports 7 px at best for rows; the gate needs 6, so the margin is thin if the layout shifts by 1 px.
4. **Studio sync:** last session's Rojo plugin kept a stale script after reconnect; I will verify BuildStamp and file contents before trusting a gate run.
5. Old keys are removed only if nothing references them, in this PR.

## Acceptance criteria
- [x] AC1 Image keys, SliceCenters, layout numbers and text sizes in MenuTheme.
- [x] AC2 (code only; gate not run) Slice rows/toasts at stated heights; Title back to 46 px with tag inside (workaround removed only if the gate passes).
- [ ] AC3 TextFit gate passes at three viewports, or failures reported with margins.
- [x] AC4 (numbers table without gate margins) Diff table and truncation decision recorded.
- [x] AC5 Ids unset, upload list extended, nothing uploaded, check.sh green, specs above baseline.

## Tests
- **Automated:** `scripts/check.sh 2>&1 | tail -30`.
- **Studio:** `scripts/studio-preflight.sh --game mathshow`; TextFit in a fresh Play session.

## Risks / notes
- Task ID allocated by hand-editing `tasks/queue.json`.

---
## Implementation record
Approved by jg 2026-10-27 (AllowTruncate for the "Calculus 1, second half" subject, stay stacked on PR 151). Orchestrator state is still `proposed` in the queue (no start/record-exec yet).

Built: the 17 PNGs in `art/menu/` (unchanged copies, `UPLOAD_LIST.md` extended, 75 + 17); `MenuTheme` (17 `-v2` keys at `rbxassetid://0`, `Slice` table, `RowHeight`, layout numbers, text sizes); `Shard` (applies `MenuTheme.Slice`: ScaleType.Slice, SliceCenter, SliceScale 0.5, and falls back to Stretch when a label swaps to a fixed-width key); `View` (toasts, title, settings rows, ladder, review rows, count, head-to-head, watching banner moved to the v2 keys and README positions); `tests/ShapeProfiles.spec.luau` (3 specs: v2 canvas sizes and slice flags, band counts, cap insets). `scripts/check.sh` green; MathShow specs 206 -> 209.

Decisions: settings rows keep their 44 px slot (the README gate table lists 520x44); ladder and review rows are 38 tall, centred in their old slots (review pitch stays 38, so rows now touch); the ladder subject width is 126 (104 on the current row beside the YOU tag) and truncates with `AllowTruncate` as jg chose; review answers sit at x 70 and 142 (16 px), my reading of "answer column 66"; the title tag moved inside the shard at y 21.5 and its `FitSticker` exemption is removed, so the gate now checks it; old image keys and HUD keys stay (the textured swap is unverified and HUD still uses `shard-row-*` / `shard-toast-*`).

Numbers changed (old -> new; gate margin not measured, see below):
| item | old | new |
|---|---|---|
| Text.Title | 40 | 46 |
| Text.LadderName | 10 | 15 |
| Text.SettingLabel | 15 | 16 |
| Text.WatchBanner | 15 | 17 |
| Text.Toast | 15 | 18 |
| New: ReviewQ / H2HPoints / CountDraw | 9 / 16 / 80 (inline) | 13 / 20 / 100 |
| Review answer text | 12 | 16 |
| Toast PadX / TextY / TextH | 36 / 15 / 15 | 24 / 14 / 18 |
| Layout.Title | box(52,52,330,88) | box(52,44,330,104) |
| Layout.Count | box(588,60,200,160) | box(588,48,200,184) |
| Layout.HeadToHead | box(456,6,344,44) | box(456,2,344,52) |
| Layout.WatchBanner | box(110,276,480,44) | box(110,274,480,48) |
| Ladder / review row height | 34 / 32 | 38 / 38 |
| Ladder name x,y,w,h; subject x,w | 50,11,94,10; 146,150 | 52,11,94,16; 150,126 |
| Ladder badge | x20 y6 size 22 | x20 y7 size 24 |
| Settings label x | 26 | 20 |

**Not done: the Studio TextFit gate (AC3).** Rojo connected and `BuildStamp` updated to 50afb77, but Studio kept the old script sources (Play showed `MenuTheme.Text.Title == 40` and no `Slice`). The same thing happened with TASK-0106's harness: Rojo applies non-script changes but existing scripts' `Source` is not updated in this Studio. Not resolved; no Studio edits were made to work around it. Until the gate runs, every text-fit margin and the placeholder-art look of the menu are unverified, and the README text sizes (ladder 15, settings 16, banner 17, toast 18, count 100) may fail the 6 px rule.

**TextFit gate attempt, 2026-10-30 (build-and-open): BLOCKED, gate not run.** Preflight OK on `task/TASK-0107-menu-art-v2`; `scripts/stamp.sh --game mathshow` wrote `07912ea 2026-10-30T23:15:49Z` and `rojo build mathshow.project.json` produced the place from HEAD. The old Studio refused SIGTERM (save prompt), so it was force-killed with jg's OK (unsaved changes discarded). Attempt 1: `open -a RobloxStudio <place>` at cold start launched Studio on the Home screen with no place open (`execute_luau` returned "Place is not open"). Attempt 2: `open -a RobloxStudio <place>` against the running Studio spawned a second RobloxStudio process with no window (the known "Initializing plugins" hang); it was killed. Stopped per the 2-attempt rule. AC1 (BuildStamp in Play console), AC2 (row counts and margins) and AC3 (UNCHECKED rows) are **not measured**; no margin is verified. `scripts/check.sh`: ALL CHECKS PASSED (AC4). Next: jg opens `MathShow-gate-0107.rbxl` by hand via File > Open (scratchpad copy, rebuild with `scripts/stamp.sh --game mathshow && rojo build mathshow.project.json -o <path>`), then the client run `require(game.Players.LocalPlayer.PlayerScripts.StudioTests.TextFit).run()` in a fresh Play session. No TEST note written, since there are no results to record.

## Audits

## Outcome
