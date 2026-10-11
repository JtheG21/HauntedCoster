---
id: TASK-0015
title: House Tiers and Upgrades
type: task
project: GAME-002
status: ready
priority: high
risk: low
owner: executor
milestone: M1
depends_on:
  - TASK-0014
branch: task/TASK-0015-House-Tiers-And-Upgrades
created: 2026-10-11
updated: 2026-10-11
tags:
  - workflow/task
  - milestone/m1
related:
  - "[[GAME-002 Haunted Collector/01 Game Design]]"
  - "[[GAME-002 Haunted Collector/02 Technical Architecture]]"
  - "[[ADR-0005-Haunted-Collector-Direction]]"
---
# TASK-0015: House Tiers and Upgrades

## Goal
Make the house functional progression: speed upgrade, tier 1 (space, editor unlock, crypt key), tier 2 (exhibit slots, capped offline income).

## Scope
- **In:** Upgrade UI; EconomyService purchase validation; visible house model per tier; offline income from saved lastSeen (capped, tier 2 only).
- **Out:** Editor itself (TASK-0017); cosmetics.

## Files expected to change
- `games/haunted/src/server/Services/EconomyService.luau`
- `games/haunted/src/shared/Config/Economy.luau`
- `games/haunted/src/shared/Rules/EconomyRules.luau`
- `games/haunted/src/client/UpgradeUI.client.luau`

## Acceptance criteria
- [ ] AC1: Purchases succeed only with funds and requirements; insufficient funds/locked show a reason; duplicate/spam purchase charged once
- [ ] AC2: Tier change visibly rebuilds the house and persists; tier 1 sets the editor and crypt unlock flags
- [ ] AC3: Speed upgrade applies on spawn and respawn
- [ ] AC4: Offline income: tier 2 only, capped, ignores future/invalid timestamps (spec)
- [ ] AC5: First upgrade reachable from one secured common in about 2 minutes with draft numbers (measured)
- [ ] AC6: scripts/check.sh passes

## Tests
- **Automated:** `scripts/check.sh` plus the specs named in the ACs (run in a fresh Play session, Server data model).
- **Studio playtest procedure:** in the GAME-002 place, start Play from a fresh profile and walk each AC in order. Record the results in the Implementation record, and say plainly which ones were not run.

## Risks / notes
Planned from [[INBOX-20261011-Haunted-Collector-Brief]]. Blocked on approval of [[ADR-0005-Haunted-Collector-Direction]]. Numbers come from the draft design and are tunable.

---
## Implementation record
*Prototype built in one integration commit, `17cb5ae` on `task/TASK-0011-Haunted-Scaffold-And-Player-Data`, which covers TASK-0011 to TASK-0018. The user approved building without per-task gates on 2026-10-11.*
- `scripts/check.sh`: all pass (StyLua, Selene, strict typecheck for both projects, Rojo builds, vault, Python tests).
- Unit specs: 37/37 pass headless ([[TEST-20261011-01]]). Server smoke in Run mode: clean.
- **Not yet verified with a player:** the `FullLoop` play scenario is written but hasn't run (the Studio window didn't load the place). The ACs below stay unchecked until it has run.
- Systems: [[SYS-Haunted-Player-Data]], [[SYS-Haunted-Capture-Loop]], [[SYS-Haunted-Ghost-Train]].

## Audits
*(links to AUD- notes)*

## Outcome
*(after merge: result, lessons, follow-ups)*
