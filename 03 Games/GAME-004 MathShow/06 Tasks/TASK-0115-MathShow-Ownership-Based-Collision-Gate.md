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

## Progress (2026-11-01, code build 28c7561)

- **Built:** pure `tests/studio/CollisionRules.luau` (rotated-rect overlap area, owner resolution, manifest matching, pair comparison) with `tests/CollisionRules.spec.luau` (13 tests, headless specs 297 passed); empty `CollisionManifest.luau`; `CollisionCanary.luau` (plain-Instance fixtures in tests/studio, not in the menu path); `TextFit.luau` integration and `TextFit.runCanary()`.
- **Owner rule:** the nearest ancestor X whose path continues `X/Group/...` (the `Menu/Shard` anatomy: Group holds Shard, Glow, Flash and Content), otherwise the element's own path. The task text said `X/Group/Content`; I widened it to `X/Group/<anything>` because a control's own Shard would otherwise count as a foreign element to its own label.
- **Red run:** both planted faults flagged and the composition control passed at 5/5 viewports (committed `0e48bfc`, before the real menu).
- **Real-menu run:** 81 cross-owner overlaps per viewport (23 unique pairs), manifest empty, no layout changed. Stop report with screenshots in `docs/workflow/STUDIO-SYNC.md`. **Waiting on jg:** approve manifest entries row by row; layout fixes become a new task.
- **Not recorded:** `record-exec`, because the gate is not green. A fail record would use a revision.

