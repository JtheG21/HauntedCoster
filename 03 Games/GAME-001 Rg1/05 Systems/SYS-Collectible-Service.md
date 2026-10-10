---
id: SYS-Collectible-Service
title: Collectible Service
type: system
project: GAME-001
status: done
side: server
source:
  - src/server/Services/CollectibleService.luau
  - src/shared/CollectibleRules.luau
  - src/shared/CollectibleConfig.luau
created: 2026-10-10
updated: 2026-10-10
tags:
  - game/system
related:
  - "[[TASK-0001-Collectible-Pickup]]"
---
# Collectible Service

## Purpose
A prototype coin pickup that proves the workflow. It isn't the final design yet.

## Responsibilities
- Creates `leaderstats.Coins` (IntValue) for each player
- Spawns `Count` coins on a circle in `Workspace.Collectibles`
- Validates each Touched on the server through `CollectibleRules.canCollect`, awards `CoinValue`, hides the coin, and brings it back after `RespawnSeconds`

## Interfaces
| API / Remote | Direction | Args (validated) | Notes |
|---|---|---|---|
| `CollectibleService.start()` | server internal | n/a | Idempotent |
| *(no remotes)* | | | Pickup comes from server physics only |

## Data & state
Coin attribute `Active` (bool). No persistence.

## Trust boundary / security
The client can only influence its character's position. Known gaps (from [[AUD-20261010-TASK-0001-01]]): no pickup rate or teleport limit, and a generous 12-stud distance check.

## Tests
- Automated: `tests/luau/CollectibleRules.spec.luau` (7 tests, run in Studio)
- Playtest: [[TEST-20261010-01]]

## History
- [[TASK-0001-Collectible-Pickup]]: created (2026-10-10)
