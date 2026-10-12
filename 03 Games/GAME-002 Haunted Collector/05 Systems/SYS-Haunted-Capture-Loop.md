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
  - games/haunted/src/shared/Rules/ChaseRules.luau
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
- Capture sessions: server clock, latency-compensated judge (`CaptureRules`), hits/misses by rarity, 20 s timeout. A miss startles the monster (an 8–14 stud hop in its zone, 0.8 s settle). Hits and misses are kept per player on the encounter between attempts.
- Carry: WalkSpeed ×0.6/0.7/0.8/0.9 by Running Shoes level, timer by rarity. On timeout: a 15 s chase. The monster flees (`ChaseRules`, never crossing a fence or entering the crypt), and the owner grabs it within 6 studs to resume with 20 s, once per capture. Chase expiry, death, despawn, leaving or the speed check send it to its habitat. Owned monsters are untouched.
- Secure only at the owner's pen; onboarding reward once; acclimation 30 s, then passive income; capped offline income at tier 2.

## Interfaces
| API / Remote | Direction | Args (validated) | Notes |
|---|---|---|---|
| `Inspect` prompt → `Inspect` event | S→C | payload | distance-checked |
| `CaptureStart` | C→S | monster Model | distance, ownership, capacity, crypt/flag gates |
| `CaptureRelease` | C→S | none | server timing; min gap 0.2 s |
| `CaptureCancel` | C→S | none | |
| `Grab` prompt on a fleeing monster | C→S | none | chase owner only; distance, deadline, rate limit 4/s |
| `SetExhibit` | C→S | slot, uid? | owned + unlocked slot |

## Tests
- Automated: `CaptureRules.spec`, `ChaseRules.spec`, `EconomyRules.spec`.
- Playtest: the `FullLoop` scenario (startle, chase, grab and expiry paths), plus `ExploitProbe`.

## History
- [[TASK-0011-Haunted-Scaffold-And-Player-Data]] to [[TASK-0018-Journal-Tutorial-And-Rare-Clue]]: built in prototype commit 17cb5ae (2026-10-11)
- [[TASK-0023-Round-20-Design-Changes]]: startle on miss, escape chase, carry penalty by level (2026-10-11)
