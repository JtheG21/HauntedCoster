---
id: GAME-002-ROADMAP
title: Roadmap
type: roadmap
project: GAME-002
status: proposed
created: 2026-10-11
updated: 2026-10-12
tags:
  - game/roadmap
related:
  - "[[GAME-002 Haunted Collector/01 Game Design]]"
  - "[[ADR-0005-Haunted-Collector-Direction]]"
---
# Roadmap: Haunted Collector (GAME-002), **proposed**

> Nothing is approved yet. Each task is a vertical slice that ends playable in Studio, so the loop can be tried as early as TASK-0014. Effort estimates are rough. Everything runs on the subscription, with **$0 paid API**.

## M1: Playable MVP loop
| Order | Task | Depends on | Playable result |
|---|---|---|---|
| 1 | [[TASK-0011-Haunted-Scaffold-And-Player-Data]] | — | New place syncs; profile loads and saves; plot assigned |
| 2 | [[TASK-0012-Graveyard-And-Landmarks]] | 0011 | Walk the graveyard with a flashlight; landmarks record clues |
| 3 | [[TASK-0013-Monsters-And-Capture]] | 0011, 0012 | Inspect and capture a monster |
| 4 | [[TASK-0014-Return-Trip-And-Containment]] | 0013 | **Core loop:** carry home, secure, earn income |
| 5 | [[TASK-0015-House-Tiers-And-Upgrades]] | 0014 | Buy speed and tier 1; the gate and editor unlock flag |
| 6 | [[TASK-0016-Starter-Ghost-Train]] | 0011, 0014 | Ride the starter loop; exhibits raise the payout |
| 7 | [[TASK-0017-Track-Editor]] | 0015, 0016 | Build, validate, save and ride a custom route |
| 8 | [[TASK-0018-Journal-Tutorial-And-Rare-Clue]] | 0012–0017 | Full first session per brief §12; Bell Wraith hook |

**Exit gate:** a recorded `TEST-` playtest walks the full brief §20 journey, including a persistence check in a published or API-enabled place. A `RETRO-` note follows.

**M1 status:** complete on 2026-10-11 ([[RETRO-M1-Playable-MVP-Loop]]). The persistence part of the exit gate moved to M2 ([[ADR-0006-M1-Tuning-And-Scope-Decisions]] §4).

## M2: Ready for public play
| Order | Task | Depends on | Result |
|---|---|---|---|
| 1 | [[TASK-0019-Persistence-And-Rejoin-Test]] | — | Real saving proven on rejoin |
| 2 | [[TASK-0020-Physical-Device-Checks]] | — | Controller and touch verified |
| 3 | [[TASK-0021-Anti-Cheat-Hardening]] | 0019 | Accepted M1 cheat paths closed |
| 4 | [[TASK-0022-M1-Polish]] | — | M1 UX and test gaps fixed |

Then: tune from playtest data and add sound (`roblox-sfx`).

## M3: World retrofit (proposed, [[ADR-0007-World-Retrofit-Direction]])
Brief from jg on 2026-10-12, audit in [[RSH-20261012-World-Retrofit-Audit]]. Nothing here is approved yet.

| Order | Task | Depends on | Result |
|---|---|---|---|
| 1 | [[TASK-0025-Clue-Hunting-Removal]] | — | Main loop without clues; rare and crypt on house tier |
| 2 | [[TASK-0026-Radial-Plot-Layout]] | 0025 | Six radial plots, ring road, cemetery re-laid as module 1 |
| 3 | [[TASK-0027-Habitat-Modules-And-Blockouts]] | 0026 | Four swappable habitats (three blockouts) |
| 4 | [[TASK-0028-Cemetery-Vignette-And-Atmosphere]] | 0027 | Purple sky, green haze, orange lights; cemetery benchmark |
| 5 | [[TASK-0029-Habitat-Rotation]] | 0027 | Shared 15-minute schedule with capture-safe swaps |
| 6 | [[TASK-0030-House-And-Train-Presentation]] | 0026 | Mansion tiers and train areas read as mini theme parks |
| 7 | [[TASK-0031-Failed-Capture-Retaliation]] | 0027 | Local chase and brief knockdown after a failed capture (scope per ADR-0007) |

## Later (not planned in detail)
- Haunted Forest and Mine region (brief §15). The woodland habitats in M3 may cover part of it.
