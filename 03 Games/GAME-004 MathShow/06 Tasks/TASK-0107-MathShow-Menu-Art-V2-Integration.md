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
- [ ] AC1 Image keys, SliceCenters, layout numbers and text sizes in MenuTheme.
- [ ] AC2 Slice rows/toasts at stated heights; Title back to 46 px with tag inside (workaround removed only if the gate passes).
- [ ] AC3 TextFit gate passes at three viewports, or failures reported with margins.
- [ ] AC4 Diff table and truncation decision recorded.
- [ ] AC5 Ids unset, upload list extended, nothing uploaded, check.sh green, specs above baseline.

## Tests
- **Automated:** `scripts/check.sh 2>&1 | tail -30`.
- **Studio:** `scripts/studio-preflight.sh --game mathshow`; TextFit in a fresh Play session.

## Risks / notes
- Task ID allocated by hand-editing `tasks/queue.json`.

---
## Implementation record

## Audits

## Outcome
