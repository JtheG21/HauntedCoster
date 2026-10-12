---
id: GAME-002
title: Haunted Collector Overview
type: overview
project: GAME-002
status: in_progress
created: 2026-10-11
updated: 2026-10-12
tags:
  - game/overview
---
# GAME-002: Haunted Collector (working title)

**Phase:** M1 (the playable MVP loop) is **complete**: TASK-0011 to TASK-0018 are done, with merges approved by jg on 2026-10-11. Retro: [[RETRO-M1-Playable-MVP-Loop]] (approved by jg). **This is the studio's primary game** (user, 2026-10-11). GAME-001 is source material. Latest evidence: specs 51/0, FullLoop 56/56, Reachability 15/15, ExploitProbe 13/13, CrossPlot (2 players) 12/12 ([[TEST-20261011-04]], [[TEST-20261011-05]], [[TEST-20261011-06]]); fresh-profile first session in the real client ([[TEST-20261011-03]]). M1 decisions: [[ADR-0006-M1-Tuning-And-Scope-Decisions]]. Saving is **memory-only and unproven** until the M2 rejoin test. Physical controller and touch are also M2. **Next:** M2 ([[GAME-002 Haunted Collector/03 Roadmap]]): TASK-0019 to TASK-0022 are `ready`. **Code:** `games/haunted/` with `haunted.project.json`, synced to a separate place ([[ADR-0005-Haunted-Collector-Direction]]). **Task status:** `tasks/queue.json`

Hook (Round 20): **"Build your haunted train."** Pitch: hunt strange creatures in a dark graveyard, risk the trip home, and turn your collection into a rideable haunted train attraction you design yourself.

## Documents
[[GAME-002 Haunted Collector/01 Game Design]] · [[GAME-002 Haunted Collector/02 Technical Architecture]] · [[GAME-002 Haunted Collector/03 Roadmap]] · source brief: [[INBOX-20261011-Haunted-Collector-Brief]]

## Tasks
| Task | Status | Audit |
|---|---|---|
| [[TASK-0011-Haunted-Scaffold-And-Player-Data]] | in_progress | — |
| [[TASK-0012-Graveyard-And-Landmarks]] | ready (code in 17cb5ae) | — |
| [[TASK-0013-Monsters-And-Capture]] | ready (code in 17cb5ae) | — |
| [[TASK-0014-Return-Trip-And-Containment]] | ready (code in 17cb5ae) | — |
| [[TASK-0015-House-Tiers-And-Upgrades]] | ready (code in 17cb5ae) | — |
| [[TASK-0016-Starter-Ghost-Train]] | ready (code in 17cb5ae) | — |
| [[TASK-0017-Track-Editor]] | ready (code in 17cb5ae) | — |
| [[TASK-0018-Journal-Tutorial-And-Rare-Clue]] | ready (code in 17cb5ae) | — |
| [[TASK-0023-Round-20-Design-Changes]] | done, merge approved by jg (Round 20: startle, chase, carry penalty, starter scare) | [[AUD-20261011-TASK-0023-01]] fail, [[AUD-20261011-TASK-0023-02]] pass |
| [[TASK-0024-FullLoop-Landmark-Flake]] | done, merge approved by jg (landmark diagnostics; flake not reproduced) | [[AUD-20261011-TASK-0024-01]] pass |
| [[TASK-0025-Clue-Hunting-Removal]] to [[TASK-0031-Failed-Capture-Retaliation]] | proposed (M3 world retrofit, [[ADR-0007-World-Retrofit-Direction]] proposed) | — |

## How to playtest (Studio)
1. `rojo build haunted.project.json -o HauntedCollector.rbxl`, then open it in Studio (or `rojo serve haunted.project.json` into a new empty place). **Never sync it into the Rg1/place1 place.**
2. Press Play. The banner "progress is NOT saved" is expected in an unpublished place.
3. Follow the Objective panel: walk the lantern road north past the Weeping Angel, Inspect a Wisp (R), Try Capture, press CATCH (Space / tap / A) in the green zone, run home and Secure at your purple pen.
4. Mansion menu (M): buy Speed, then Restore your house (250). Edit Track appears: tap to add/select points, Confirm.
5. Mansion > Exhibits: place a monster. Ride at the station. With the Restored Manor the Sealed Crypt (south, behind the Bell Tower) opens: the Bell Wraith lives there. Clue hunting was removed in [[TASK-0025-Clue-Hunting-Removal]].
6. Automated: `game:GetService("StudioTestService"):ExecutePlayModeAsync({ scenario = "FullLoop" })` from the command bar (Edit mode) prints PASS/FAIL per check. Other scenarios are `Reachability`, `ExploitProbe`, and `CrossPlot` (run with `ExecuteMultiplayerTestAsync(2, …)`). `HoldForManual` keeps a session open for hands-on checks. Unit specs: `require(game.TestService.Tests.TestRunner).run()`.

## Systems
[[SYS-Haunted-Player-Data]] · [[SYS-Haunted-Capture-Loop]] · [[SYS-Haunted-Ghost-Train]] · Playtests: [[TEST-20261011-01]] · [[TEST-20261011-02]] (FullLoop 48/48)

## Decisions
- [[ADR-0005-Haunted-Collector-Direction]]: approved (jg, 2026-10-11)

## Needs human review
- Review the draft economy numbers in the design note. They are guesses until playtested.
- Hands-on playtest by the user. Keep the GAME-001 `rojo serve` away from this place (it injected a Baseplate that caused z-fighting).
- ADR-0005 open question 4 (migrating the old links).
