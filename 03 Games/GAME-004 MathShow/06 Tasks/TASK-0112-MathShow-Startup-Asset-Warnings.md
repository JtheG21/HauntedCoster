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
