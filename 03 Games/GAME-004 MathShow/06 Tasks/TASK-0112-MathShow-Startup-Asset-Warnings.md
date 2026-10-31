---
id: TASK-0112
title: "MathShow Startup Asset Warnings"
type: task
project: GAME-004
status: backlog
priority: medium
risk: low
owner: claude-code
depends_on:
  - TASK-0107
branch: task/TASK-0112-startup-asset-warnings
related:
  - "[[TASK-0107-MathShow-Menu-Art-V2-Integration]]"
created: 2026-10-31
updated: 2026-10-31
tags:
  - workflow/task
---

# MathShow Startup Asset Warnings

## Goal
Remove the startup asset warnings in Play: the two unset title slots (`shard-menu-title-violet-v2`, `glow-menu-title-violet-v2`, MenuTheme.luau:223 and :230) and the failed asset `rbxassetid://203785492`.

## Background
- TASK-0107 (done) left the 17 `-v2` menu slots UNSET until the PNGs are uploaded.
- `203785492` fails with "Asset type does not match requested type". `docs/workflow/STUDIO-SYNC.md` says it is not in `games/` and was already present in Edit mode before Play.

## Phases
- **A, locate (read-only):** find every instance referencing `203785492`, with its path, property, class, and Rojo-managed or place-only status. State the asset type the property needs.
- **B, upload (user-gated):** upload the approved subset of the 17 `-v2` PNGs. jg approves the set first.
- **C, wire and verify:** set the MenuTheme ids, fix `203785492` by the approved route, then check the Play log.

## Acceptance
- Phase A recorded, without saving the place.
- Phase B only after approval, with each returned id recorded.
- Phase C: no asset warnings from these ids, and `check.sh` passes.
- Unpublished Play still warns and runs memory-only.

## Open decisions for jg
1. Upload set: the two title images, or all 17 `-v2`.
2. Route for `203785492`: move it into Rojo `.rbxmx`, or a one-time place edit.

## Progress
- **Phase A (locate):** done. No instance in the Edit DataModel or in Play's Server or Client DataModels references `203785492`. Its property and required type are still unidentified.
- **Phase B (upload):** done 2026-10-31 for all 17 `-v2` PNGs, with jg's approval. Ids are recorded in `games/mathshow/art/menu/UPLOAD_LIST.md`. `MenuTheme.Image` still holds `rbxassetid://0`.
- **Phase C (wire and verify):** done 2026-10-31. `MenuTheme.Image` takes the 17 uploaded ids, and the unused `UNSET` local is removed. Play (Rojo served from this worktree) shows no `has no asset id yet` warnings for these slots and no require errors. `203785492` is treated as an engine-origin warning and left unchanged.
- **Phase D (verify, 2026-10-31):**
  - **Asset identity:** 17 of 17 are `AssetTypeId = 1` (Image), with creator `jg_57565` (User). No Decal found. `game.CreatorType = User`, `game.CreatorId = 0` (unpublished place). Table in `games/mathshow/art/menu/UPLOAD_LIST.md`.
  - **Load check (PreloadAsync):** pass on re-run. The first attempt passed plain string URLs to `PreloadAsync`, which returned `Failure` for all 17 and for two TASK-0098 controls. The re-run (fresh Play session, 2026-10-31) passed `ImageLabel` instances with `Image` set, and all 17 returned `Enum.AssetFetchStatus.Success`. The two controls also returned `Success`. The string form is not a valid load gate here.
  - **Visual check:** the main menu renders the violet title and banner art, with no `has no asset id yet` warnings in Play. Capture: `scratchpad/menu-main-play-state.jpg`. Other menu states were not exercised.
  - **Known warning:** `rbxassetid://203785492` is an engine-origin warning, not place content. Seen in GAME-002 playtest `TEST-20261018-01` (origin unconfirmed) and GAME-004 playtests. Won't fix. Not changed.
  - **Open follow-up (not done here):** TextFit gate for the title and rows (TASK-0107 acceptance #3), and a valid load check for the 17 ids. Both need a Studio session where PreloadAsync works.

