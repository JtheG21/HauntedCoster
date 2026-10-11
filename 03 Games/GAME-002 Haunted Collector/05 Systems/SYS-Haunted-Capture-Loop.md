---
id: SYS-Haunted-Capture-Loop
title: Haunted Capture Loop
type: system
project: GAME-002
status: in_progress
side: server
source:
  - games/haunted/src/server/Services/EncounterService.luau
  - games/haunted/src/server/Services/CaptureService.luau
  - games/haunted/src/server/Services/ContainmentService.luau
  - games/haunted/src/shared/Rules/CaptureRules.luau
related:
  - "[[GAME-002 Haunted Collector/02 Technical Architecture]]"
created: 2026-10-11
updated: 2026-10-11
tags:
  - game/system
---
# Haunted Capture Loop

## Purpose
Spawn and roam monsters, run the capture meter, carry the capture home under a timer, and turn secured monsters into income.

## Responsibilities
- Zone spawns (weights, per-zone max, `maxAlive` for rares), variant rolls (Spectral anywhere, Ashen crypt only).
- Inspect card (name, rarity, variant, est. income, lock reason).
- Capture sessions: server clock, latency-compensated judge (`CaptureRules`), hits/misses by rarity, 20 s timeout.
- Carry: WalkSpeed x0.7, timer by rarity, escape on timeout/death/despawn (monster respawns in its zone; owned monsters untouched).
- Secure only at the owner's pen; onboarding reward once; acclimation 30 s, then passive income; capped offline income at tier 2.

## Interfaces
| API / Remote | Direction | Args (validated) | Notes |
|---|---|---|---|
| `Inspect` prompt → `Inspect` event | S→C | payload | distance-checked |
| `CaptureStart` | C→S | monster Model | distance, ownership, capacity, crypt/flag gates |
| `CaptureRelease` | C→S | none | server timing; min gap 0.2 s |
| `CaptureCancel` | C→S | none | |
| `SetExhibit` | C→S | slot, uid? | owned + unlocked slot |

## Tests
- Automated: `CaptureRules.spec`, `EconomyRules.spec`.
- Playtest: `FullLoop` scenario (pending).

## History
- [[TASK-0011-Haunted-Scaffold-And-Player-Data]] to [[TASK-0018-Journal-Tutorial-And-Rare-Clue]]: built in prototype commit 17cb5ae (2026-10-11)
