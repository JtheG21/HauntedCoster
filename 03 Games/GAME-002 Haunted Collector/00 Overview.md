---
id: GAME-002
title: Haunted Collector Overview
type: overview
project: GAME-002
status: in_progress
created: 2026-10-11
updated: 2026-10-11
tags:
  - game/overview
---
# GAME-002: Haunted Collector (working title)

**Phase:** M1, the playable MVP loop. **This is the studio's primary game** (user, 2026-10-11). GAME-001 is source material. **Playable prototype built** (commit 17cb5ae, not yet player-tested). **Code:** `games/haunted/` with `haunted.project.json`, synced to a separate place ([[ADR-0005-Haunted-Collector-Direction]]). **Task status:** `tasks/queue.json`

Pitch: hunt strange creatures in a dark graveyard, risk the trip home, and turn your collection into a rideable haunted train attraction you design yourself.

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

## How to playtest (Studio)
1. `rojo build haunted.project.json -o HauntedCollector.rbxl`, then open it in Studio (or `rojo serve haunted.project.json` into a new empty place). **Never sync it into the Rg1/place1 place.**
2. Press Play. The banner "progress is NOT saved" is expected in an unpublished place.
3. Follow the Objective panel: walk the lantern road north, investigate the Weeping Angel, Inspect a Wisp, Try Capture, press CATCH (Space / tap / A) in the green zone, run home and Secure at your purple pen.
4. Mansion menu (M): buy Speed, then Restore your house (250). Edit Track appears: tap to add/select points, Confirm.
5. Mansion > Exhibits: place a monster. Ride at the station. A bell clue follows; investigate the Bell Tower (south-east).
6. Automated: `game:GetService("StudioTestService"):ExecutePlayModeAsync({ scenario = "FullLoop" })` from the command bar (Edit mode) prints PASS/FAIL per check. Unit specs: `require(game.TestService.Tests.TestRunner).run()`.

## Systems
[[SYS-Haunted-Player-Data]] · [[SYS-Haunted-Capture-Loop]] · [[SYS-Haunted-Ghost-Train]] · Playtests: [[TEST-20261011-01]]

## Decisions
- [[ADR-0005-Haunted-Collector-Direction]]: approved (jg, 2026-10-11)

## Needs human review
- Review the draft economy numbers in the design note. They are guesses until playtested.
- Run the FullLoop scenario and a manual playtest (the Studio window didn't load the place during the build session).
- ADR-0005 open question 4 (migrating the old links).
