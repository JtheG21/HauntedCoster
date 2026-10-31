---
id: GAME-002
title: Haunted Collector Overview
type: overview
project: GAME-002
status: in_progress
created: 2026-10-11
updated: 2026-10-30
tags:
  - game/overview
---
# GAME-002: Haunted Collector (working title)

**Archived (paused 2026-10-25).** GAME-004 MathShow is the active game ([[AGENTS]]). Code: `archive/GAME-002-haunted-collector/`. TASK-0070 to TASK-0086 were archived unstarted.

**Last phase:** M1 (playable MVP loop) and M3 (world retrofit) are complete ([[RETRO-M1-Playable-MVP-Loop]], [[RETRO-M3-World-Retrofit]]). M2 is complete except the physical controller and touch checks: [[TASK-0020-Physical-Device-Checks]] is archived (deferred by jg) and returns as a new task. **Audit remediation (2026-10-12):** T1–T5 are done ([[TASK-0034-Post-Merge-Verification]] to [[TASK-0038-Encounter-Review-Capture-Guards]]). **Latest evidence:** specs 265/0 (headless and fresh Studio Server, 2026-10-18); Codex verification [[TEST-20261018-01]]: ExploitProbe 14/14, art bake 333 parts/0 failures; FullLoop failed and two-client appearance returned only 1/2 observer reports. Independent source findings: [[AUD-20261018-TASK-0069-02]]. The monetization baseline and salvaged art are merged, with runtime/visual gaps and proposed follow-ups TASK-0070–0085; no implementation is approved by those proposals. Earlier evidence: the scenario results below are from 2026-10-12; on the merged code FullLoop 85/85, ExploitProbe 13/13, CarryGuard 21/21, Retaliation 36/36, HabitatRotation 28/28, HabitatSwap 35/35, Reachability 28/23/23/23 ([[TEST-20261012-12]], [[TEST-20261012-16]]); CrossPlot (2 players) 22/22 in 3 of 3 valid runs ([[TEST-20261012-13]]). Real saving is proven in jg's private place ([[TEST-20261012-10]]); live load failures go readonly, never memory ([[TEST-20261012-14]]). Max Players is 6, one per plot ([[TEST-20261012-15]]). **Not yet verified:** physical devices (deferred to near the end), a 6-player session (Studio tests use at most 2 players for now; 2-player baseline in [[TEST-20261012-17]]), audio and VFX (none yet). Art is accepted for now; a full revamp is expected later. Open at pause: the verification and remediation work in [[Handoff to Codex 2026-10-18]] and the remaining audit items ([[GAME-002 Haunted Collector/03 Roadmap]]). Before the Rare capture finisher ships, the rights of the VFX Studio plugin assets need checking ([[TASK-0054-Rare-Capture-Finisher]]). **Code:** `archive/GAME-002-haunted-collector/` with its `haunted.project.json`, synced to a separate place ([[ADR-0005-Haunted-Collector-Direction]]). **Task status:** `tasks/queue.json`

Hook (Round 20): **"Build your haunted train."** Pitch: hunt strange creatures in a dark graveyard, risk the trip home, and turn your collection into a rideable haunted train attraction you design yourself.

## Documents
Shared art standard: [[3D Model Quality Baseline]] · [[3D Model Quality Gallery]] — minimum visual finish for every finished model request; existing prototypes do not establish the target.

Next UI update: [[SYS-Haunted-Monetization-UI|Monetization UI Baseline]] — all five cosmetic categories, permanent catalog, earned Coins/rewards plus direct Robux; skins/auras per ghost and capture effect per player. Scope approved in [[ADR-0011-Monetization-UI-Scope]]; detailed layout, prices, assets and backend readiness remain explicit. Historical evidence: [[RSH-20261013-Haunted-Monetization-Discovery]].

[[GAME-002 Haunted Collector/01 Game Design]] · [[GAME-002 Haunted Collector/02 Technical Architecture]] · [[GAME-002 Haunted Collector/03 Roadmap]] · source brief: [[INBOX-20261011-Haunted-Collector-Brief]]

## Tasks
Statuses are copied from `tasks/queue.json` (authoritative); `validate_vault.py` warns when a row disagrees.

| Task | Status (queue) | Audits |
|---|---|---|
| [[TASK-0011-Haunted-Scaffold-And-Player-Data]] | done (project scaffold, player data) | [[AUD-20261011-TASK-0011-01]] fail, [[AUD-20261011-TASK-0011-02]] pass |
| [[TASK-0012-Graveyard-And-Landmarks]] | done (graveyard, landmarks) | [[AUD-20261011-TASK-0012-01]] fail, [[AUD-20261011-TASK-0012-02]] fail, [[AUD-20261011-TASK-0012-03]] fail, [[AUD-20261011-TASK-0012-04]] pass |
| [[TASK-0013-Monsters-And-Capture]] | done (monsters, capture) | [[AUD-20261011-TASK-0013-01]] fail, [[AUD-20261011-TASK-0013-02]] pass |
| [[TASK-0014-Return-Trip-And-Containment]] | done (return trip, containment) | [[AUD-20261011-TASK-0014-01]] fail, [[AUD-20261011-TASK-0014-02]] pass |
| [[TASK-0015-House-Tiers-And-Upgrades]] | done (house tiers, upgrades) | [[AUD-20261011-TASK-0015-01]] fail, [[AUD-20261011-TASK-0015-02]] pass |
| [[TASK-0016-Starter-Ghost-Train]] | done (starter ghost train) | [[AUD-20261011-TASK-0016-01]] fail, [[AUD-20261011-TASK-0016-02]] pass |
| [[TASK-0017-Track-Editor]] | done (track editor) | [[AUD-20261011-TASK-0017-01]] fail, [[AUD-20261011-TASK-0017-02]] fail, [[AUD-20261011-TASK-0017-03]] pass |
| [[TASK-0018-Journal-Tutorial-And-Rare-Clue]] | done (journal, tutorial) | [[AUD-20261011-TASK-0018-01]] fail, [[AUD-20261011-TASK-0018-02]] pass |
| [[TASK-0019-Persistence-And-Rejoin-Test]] | done (real saving proven on rejoin; session lock spec-tested; schema-bump rule) | [[AUD-20261012-TASK-0019-01]] pass |
| [[TASK-0020-Physical-Device-Checks]] | archived (physical device checks; deferred by jg, to return as a new task) | — |
| [[TASK-0021-Anti-Cheat-Hardening]] | done (carry speed budget, deadline and teleport checks on secure, crypt gating by species, Ashen respawns in the crypt; CrossPlot seat check open) | [[AUD-20261012-TASK-0021-01]] pass |
| [[TASK-0022-M1-Polish]] | done (M1 polish) | [[AUD-20261011-TASK-0022-01]] fail, [[AUD-20261011-TASK-0022-02]] pass |
| [[TASK-0023-Round-20-Design-Changes]] | done (Round 20: startle, chase, carry penalty, starter scare) | [[AUD-20261011-TASK-0023-01]] fail, [[AUD-20261011-TASK-0023-02]] pass |
| [[TASK-0024-FullLoop-Landmark-Flake]] | done (landmark diagnostics; flake not reproduced) | [[AUD-20261011-TASK-0024-01]] pass |
| [[TASK-0025-Clue-Hunting-Removal]] | done (clue hunting removed; crypt and Bell Wraith need the Restored Manor) | [[AUD-20261012-TASK-0025-01]] fail, [[AUD-20261012-TASK-0025-02]] pass |
| [[TASK-0026-Radial-Plot-Layout]] | done (six plots around the hub; the cemetery is the first habitat module) | [[AUD-20261012-TASK-0026-01]] pass |
| [[TASK-0027-Habitat-Modules-And-Blockouts]] | done (four habitat modules, swap lifecycle; blockout look awaits jg's review) | [[AUD-20261012-TASK-0027-01]] pass |
| [[TASK-0028-Cemetery-Vignette-And-Atmosphere]] | done (twilight sky, lamp family, cemetery vignette; look awaits jg) | [[AUD-20261012-TASK-0028-01]] pass |
| [[TASK-0029-Habitat-Rotation]] | done (15-minute rotation, capture-safe swaps) | [[AUD-20261012-TASK-0029-01]] fail, [[AUD-20261012-TASK-0029-02]] pass |
| [[TASK-0030-House-And-Train-Presentation]] | done (house tiers, plot dressing, station canopy; look awaits jg) | [[AUD-20261012-TASK-0030-01]] pass |
| [[TASK-0031-Failed-Capture-Retaliation]] | done (retaliation on the final miss; follow-ups listed) | [[AUD-20261012-TASK-0031-01]] pass |
| [[TASK-0032-Retaliation-Hardening]] | done (TASK-0031 audit follow-ups: protected tick and fled handlers, counters cleared on fled) | [[AUD-20261012-TASK-0032-01]] pass |
| [[TASK-0033-Retaliation-Begin-Cleanup]] | done (a failed `begin` releases every monster it had set) | [[AUD-20261012-TASK-0033-01]] fail, [[AUD-20261012-TASK-0033-02]] pass |
| [[TASK-0034-Post-Merge-Verification]] | done (post-merge scenario run on main; CrossPlot blocked by the harness) | [[AUD-20261012-TASK-0034-01]] pass |
| [[TASK-0035-CrossPlot-Harness-Reliability]] | done (deterministic CrossPlot seat control; 3/3 valid runs) | [[AUD-20261012-TASK-0035-01]] pass |
| [[TASK-0036-Persistence-Load-Failure]] | done (live load failures retry then readonly, never memory mode) | [[AUD-20261012-TASK-0036-01]] pass |
| [[TASK-0037-Plot-Capacity]] | done (6-player cap tied to the 6 plots) | [[AUD-20261012-TASK-0037-01]] pass |
| [[TASK-0038-Encounter-Review-Capture-Guards]] | done (EncounterService review; capture-start guards as a pure rule) | [[AUD-20261012-TASK-0038-01]] pass |
| [[TASK-0039-Drop-Parked-Seat-Check]] | done (forced-parked-seat check dropped; decisions recorded) | [[AUD-20261012-TASK-0039-01]] pass |
| [[TASK-0041-Interactive-Haunted-Trees]] | done (Woodland haunted trees: global gaze freeze; [[TEST-20261013-01]] 28/28 two-player) | [[AUD-20261013-TASK-0041-01]] pass with notes; [[AUD-20261013-TASK-0041-02]] delta pass |
| [[TASK-0053-Sequence-Runner]] | done (pure sequence core, client player and demo; AC3 waived by jg) | [[AUD-20261017-TASK-0053-01]] pass |
| [[TASK-0054-Rare-Capture-Finisher]] | done (Rare finisher sequence with orbiting orb; plugin asset rights unverified) | [[AUD-20261017-TASK-0054-01]] pass |
| [[TASK-0055-Rare-Capture-Hookup]] | done (a Rare capture fires the finisher to that player and extends the carry timer; checked in the real place) | [[AUD-20261017-TASK-0055-01]] pass |
| [[TASK-0056-Studio-Test-Pads]] | done (UI, VFX and surface test pads with a Play scenario; [[Studio Test Pads]]) | [[AUD-20261017-TASK-0056-01]] pass |

## How to playtest (Studio)
1. `rojo build haunted.project.json -o HauntedCollector.rbxl`, then open it in Studio (or `rojo serve haunted.project.json` into a new empty place). **Never sync it into the Rg1/place1 place.**
2. Press Play. The banner "progress is NOT saved" is expected in an unpublished place.
3. Follow the Objective panel: walk the lantern road north past the Weeping Angel, Inspect a Wisp (R), Try Capture, press CATCH (Space / tap / A) in the green zone, run home and Secure at your purple pen.
4. Mansion menu (M): buy Speed, then Restore your house (250). Edit Track appears: tap to add/select points, Confirm.
5. Mansion > Exhibits: place a monster. Ride at the station. With the Restored Manor the Sealed Crypt (south, behind the Bell Tower) opens: the Bell Wraith lives there. Clue hunting was removed in [[TASK-0025-Clue-Hunting-Removal]].
6. Automated: `game:GetService("StudioTestService"):ExecutePlayModeAsync({ scenario = "FullLoop" })` from the command bar (Edit mode) prints PASS/FAIL per check. 2-player: `HauntedTrees` (`ExecuteMultiplayerTestAsync(2, { scenario = "HauntedTrees", habitat = "Woodland" })`). Other single-player scenarios: `Reachability`, `ExploitProbe`, `CarryGuard`, `Retaliation`, `HabitatRotation`, `HabitatSwap`. `HoldForManual` keeps a session open for hands-on checks. Unit specs: `require(game.TestService.Tests.TestRunner).run()`.
7. `CrossPlot` (2 players): `ExecuteMultiplayerTestAsync(2, …)` rarely gets its 2nd client on an 8 GB Mac. Use Test → Clients and Servers → 2 Players, one fresh session per run, and run the scenario from a temporary server Script that first pins the Cemetery ([[TEST-20261012-13]]). Scratch places must not keep the template SpawnLocation ([[TEST-20261012-15]]).

## Systems
[[SYS-Haunted-Player-Data]] · [[SYS-Haunted-Capture-Loop]] · [[SYS-Haunted-Ghost-Train]] · Playtests: [[TEST-20261011-01]] · [[TEST-20261011-02]] (FullLoop 48/48)

## Decisions
- [[ADR-0005-Haunted-Collector-Direction]]: approved (jg, 2026-10-11)
- [[ADR-0006-M1-Tuning-And-Scope-Decisions]]: approved
- [[ADR-0007-World-Retrofit-Direction]]: approved
- [[ADR-0010-Client-Reported-Gaze]]: **proposed**, awaiting jg

## Needs human review
- Review the draft economy numbers in the design note. They are guesses until playtested.
- Hands-on playtest by the user. Keep the GAME-001 `rojo serve` away from this place (it injected a Baseplate that caused z-fighting).
- ADR-0005 open question 4 (migrating the old links): done 2026-10-12, the 45 ambiguous links are qualified (GAME-001 notes link to `GAME-001 Rg1/…`).
- The habitat, house and train looks (TASK-0027, 0028, 0030) await jg's review.
- The haunted-tree look ([[TASK-0041-Interactive-Haunted-Trees]], [[TEST-20261013-01]] screenshots) and [[ADR-0010-Client-Reported-Gaze]] await jg's review.
