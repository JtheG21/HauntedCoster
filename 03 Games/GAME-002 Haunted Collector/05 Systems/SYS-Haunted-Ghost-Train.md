---
id: SYS-Haunted-Ghost-Train
title: Haunted Ghost Train
type: system
project: GAME-002
status: in_progress
side: server
source:
  - games/haunted/src/server/Services/TrainService.luau
  - games/haunted/src/shared/Rules/TrackRules.luau
  - games/haunted/src/client/UI/TrackEditor.luau
related:
  - "[[GAME-002 Haunted Collector/02 Technical Architecture]]"
created: 2026-10-11
updated: 2026-10-11
tags:
  - game/system
---
# Haunted Ghost Train

## Purpose
Each plot's rideable ghost train: track geometry from a validated route, server-driven rides and payouts, and the control-point editor.

## Responsibilities
- Closed Catmull-Rom loop through plot-local points; validation: 4–16 points, 60–320 studs, spacing ≥ 6, inside bounds, no self-crossing, ≤ 3 special pieces.
- Anchored cart moved by server CFrame; owner seat plus a guest seat; leaving the seat cancels with no payout.
- Payout = 40 × house multiplier × route quality (0.9–1.25) × (1 + exhibit bonus within 16 studs); 20 s cooldown between paid rides.
- First paid ride sets `bellHint`, which starts the Bell Wraith clue chain.

## Interfaces
| API / Remote | Direction | Args (validated) | Notes |
|---|---|---|---|
| `Ride` prompt | server | — | owner only |
| `SubmitRoute` | C→S | points, pieces | tier unlock, full re-validation, rounding re-checked |
| `RideState` | S→C | riding | UI only |

## Tests
- Automated: `TrackRules.spec` (10 cases).
- Playtest: `FullLoop` scenario (pending). Gamepad editor input is not supported yet.

## History
- [[TASK-0011-Haunted-Scaffold-And-Player-Data]] to [[TASK-0018-Journal-Tutorial-And-Rare-Clue]]: built in prototype commit 17cb5ae (2026-10-11)
