---
id: TASK-0016
title: Starter Ghost Train
type: task
project: GAME-002
status: ready
priority: high
risk: medium
owner: executor
milestone: M1
depends_on:
  - TASK-0011
  - TASK-0014
branch: task/TASK-0016-Starter-Ghost-Train
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
# TASK-0016: Starter Ghost Train

## Goal
A visible, rideable starter ghost train on each plot whose server-confirmed completion pays out based on displayed monsters.

## Scope
- **In:** Route representation (control points -> sampled spline); fixed starter route; track geometry builder; server-driven cart (anchored, CFrame); seat owner (+1 guest if cheap); exhibit slots and assigning owned monsters; payout + cooldown; payout breakdown UI.
- **Out:** Editing routes (TASK-0017).

## Files expected to change
- `games/haunted/src/shared/Rules/TrackRules.luau`
- `games/haunted/src/shared/Config/Track.luau`
- `games/haunted/src/server/Services/TrainService.luau`
- `games/haunted/src/client/RideUI.client.luau`

## Acceptance criteria
- [ ] AC1: Starter train visible on arrival and rideable before any unlock
- [ ] AC2: Cart follows the route by server CFrame; ride ends at the route end; leaving the seat cancels with no payout
- [ ] AC3: Payout computed server-side from tier, exhibits in range (rarity/variant weighted) and route quality; cooldown blocks spam; breakdown shown
- [ ] AC4: Only own monsters can be assigned to own slots
- [ ] AC5: TrackRules sampling and payout have passing specs
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
