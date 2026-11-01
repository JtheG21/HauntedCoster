---
id: TASK-0115
title: "MathShow Ownership-Based Collision Gate"
type: task
project: GAME-004
status: in_progress
priority: medium
risk: low
owner: claude-code
depends_on:
  - TASK-0114
branch: task/TASK-0115-ownership-collision
created: 2026-11-01
updated: 2026-11-01
tags:
  - workflow/task
---

## Goal
Rebuild the menu collision check around ownership instead of name heuristics, so cross-control overlaps are all compared and every exemption is explicit and counted.

## Scope
- Owner = nearest `<Control>/Group/Content` ancestor; skip pairs inside one owner.
- Compare all cross-owner pairs, including shard images, labels, stickers, Spark frames and visible Flash/Glow.
- Exemptions only through `CollisionManifest.luau`, exact path pairs plus a reason; log the hit count.
- Planted-fault canary fixture the gate must flag.

## Not in scope
Layout fixes for real collisions (new task per fix). Hit-rect sizing (TASK-0116).

## Origin
Registered 2026-11-01 when TASK-0114 dropped its collision gate after two failed audits (see [[TASK-0114-MathShow-Tap-Target-Unmeasured-Rows-Audit]]). Backlog only: no implementation, not approved.
