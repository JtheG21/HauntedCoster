---
id: TASK-0015
title: House Tiers and Upgrades
type: task
project: GAME-002
status: done
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
- *(Superseded below: FullLoop has since run, see revision 1.)*

### Revision 1 (with TASK-0011, `5878f6d`, merged in PR #2)
- Double purchase fixed: the server rejects a request whose level doesn't match before charging; the client sends one request at a time. FullLoop checks a duplicate costs nothing, plus respawn and house-model checks. Prices per ADR-0006.
- Evidence: [[TEST-20261011-03]] (first upgrade 51 s after the first secure; tier 1 bought in the real client), [[TEST-20261011-04]] (FullLoop 56/56).
- Systems: [[SYS-Haunted-Player-Data]], [[SYS-Haunted-Capture-Loop]], [[SYS-Haunted-Ghost-Train]].

## Audits
- [[AUD-20261011-TASK-0015-01]]: fail (1 major: double-purchase coin loss), revision 1
- [[AUD-20261011-TASK-0015-02]]: **pass** (1 minor, 2 nit): the first upgrade comes about 51 s after the first secure, against a target of about 2 min (retune at the retro). Nits: a stale-snapshot 'Already upgraded' reply is hidden in the Mansion UI; notes were stale.

## Outcome
- **Result:** merge approved by jg on 2026-10-11 after [[AUD-20261011-TASK-0015-02]] passed.
- **Follow-ups:** the first upgrade comes about 51 s after the first secure, against about 2 min (retune at the M1 retro). Show the 'Already upgraded' reply in the Mansion UI. Persistence of tier and speed moves to M2 (ADR-0006 §4).
