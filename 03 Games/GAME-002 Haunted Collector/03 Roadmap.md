---
id: GAME-002-ROADMAP
title: Roadmap
type: roadmap
project: GAME-002
status: in_progress
created: 2026-10-11
updated: 2026-10-12
tags:
  - game/roadmap
related:
  - "[[GAME-002 Haunted Collector/01 Game Design]]"
  - "[[ADR-0005-Haunted-Collector-Direction]]"
---
# Roadmap: Haunted Collector (GAME-002)

> Written as a proposal on 2026-10-11; since then jg has approved each task's plan and merge individually (see each task note). The roadmap as a whole was never approved as one document, so its status is `in_progress`, not `approved`. Each task is a vertical slice that ends playable in Studio, so the loop can be tried as early as TASK-0014. Effort estimates are rough. Everything runs on the subscription, with **$0 paid API**.

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
| 1 | [[TASK-0019-Persistence-And-Rejoin-Test]] | — | Real saving proven on rejoin (done, [[TEST-20261012-10]]) |
| 2 | [[TASK-0020-Physical-Device-Checks]] | — | Controller and touch verified. **Archived** in the queue (deferred by jg); returns as a new task that supersedes it (jg's decision, 2026-10-12) |
| 3 | [[TASK-0021-Anti-Cheat-Hardening]] | 0019 | Accepted M1 cheat paths closed (done, [[TEST-20261012-11]]) |
| 4 | [[TASK-0022-M1-Polish]] | — | M1 UX and test gaps fixed (done) |

Then: tune from playtest data and add sound (`roblox-sfx`).

## M3: World retrofit ([[ADR-0007-World-Retrofit-Direction]], approved by jg 2026-10-12)
Brief from jg on 2026-10-12, audit in [[RSH-20261012-World-Retrofit-Audit]]. **M3 status:** code complete and merged (TASK-0025 to TASK-0033, retro [[RETRO-M3-World-Retrofit]]); the habitat, house and train looks await jg's review.

| Order | Task | Depends on | Result |
|---|---|---|---|
| 1 | [[TASK-0025-Clue-Hunting-Removal]] | — | Main loop without clues; rare and crypt on house tier |
| 2 | [[TASK-0026-Radial-Plot-Layout]] | 0025 | Six radial plots, ring road, cemetery re-laid as module 1 |
| 3 | [[TASK-0027-Habitat-Modules-And-Blockouts]] | 0026 | Four swappable habitats (three blockouts) |
| 4 | [[TASK-0028-Cemetery-Vignette-And-Atmosphere]] | 0027 | Purple sky, green haze, orange lights; cemetery benchmark |
| 5 | [[TASK-0029-Habitat-Rotation]] | 0027 | Shared 15-minute schedule with capture-safe swaps |
| 6 | [[TASK-0030-House-And-Train-Presentation]] | 0026 | Mansion tiers and train areas read as mini theme parks |
| 7 | [[TASK-0031-Failed-Capture-Retaliation]] | 0027 | Local chase and brief knockdown after a failed capture (scope per ADR-0007) |

## Audit remediation (2026-10-12)
From the formal project audit (chat report, 2026-10-12). Each task was approved by jg in chat.

| Order | Task | Finding | Result |
|---|---|---|---|
| T1 | [[TASK-0034-Post-Merge-Verification]] | AUDIT-001 | Every single-player scenario passes on merged main ([[TEST-20261012-12]]) (done) |
| T2 | [[TASK-0035-CrossPlot-Harness-Reliability]] | AUDIT-001 | CrossPlot 3/3 valid runs with a deterministic seat control ([[TEST-20261012-13]]) (done) |
| T3 | [[TASK-0036-Persistence-Load-Failure]] | AUDIT-003 | Live load failures retry then readonly, never memory mode (done) |
| T4 | [[TASK-0037-Plot-Capacity]] | AUDIT-002, 012 | Max Players 6, tied to the 6 plots (done) |
| T5 | [[TASK-0038-Encounter-Review-Capture-Guards]] | AUDIT-009 | EncounterService reviewed; capture-start guards specced (done) |
| T6/T7 | `chore/doc-sync-and-links` | AUDIT-005, 006, 008, 014 | Overview and roadmap synced to the queue; 45 ambiguous links qualified (done) |
| T10/T11 | `chore/reference-images`, `chore/git-safety-port` | AUDIT-016 | Map screenshots moved to `10 References/02 Map`; Git checkout guard ported (done) |
| — | [[TASK-0039-Drop-Parked-Seat-Check]] | AUDIT-001 follow-up | Forced-parked-seat check dropped; 2-player baseline ([[TEST-20261012-17]]) (done) |

Decisions (jg, 2026-10-12): the current art is accepted for now, with a full revamp expected later (AUDIT-010; audio/VFX not started); map references on hold until jg adds more; the device checks (TASK-0020's replacement) wait until the game is nearly finished; 6-player profiling (AUDIT-015) waits until several devices can join, and until then Studio tests use at most 2 players while the game is built for a full 6-player server. Accepted risks, documented, no change: AUDIT-004 (save-failure edge cases), AUDIT-011 (per-server limits, client-performed ragdoll).

## Next major UI update — monetization baseline
Scope: [[SYS-Haunted-Monetization-UI|Monetization UI Baseline]], choices approved by jg on 2026-10-13 in [[ADR-0011-Monetization-UI-Scope]]. Include Shop/owned inventory/previews, all five cosmetic categories, equipment and exterior placement, and Journal collection reward states. Permanent catalog first; direct Robux plus earned Coins/rewards; premium currency and paid convenience deferred. Implementation tasks are not yet added to the queue. Baseline dependencies cover assets, prices, persistence, commerce, geometry and device verification.

## Later (not planned in detail)
- Haunted Forest and Mine region (brief §15). The woodland habitats in M3 may cover part of it.
