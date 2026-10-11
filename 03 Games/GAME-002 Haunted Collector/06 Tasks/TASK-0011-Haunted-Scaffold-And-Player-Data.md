---
id: TASK-0011
title: Haunted Scaffold and Player Data
type: task
project: GAME-002
status: in_progress
priority: high
risk: medium
owner: executor
milestone: M1
depends_on: []
branch: task/TASK-0011-Haunted-Scaffold-And-Player-Data
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
# TASK-0011: Haunted Scaffold and Player Data

## Goal
Stand up the GAME-002 Rojo project and a safe, server-authoritative player profile and plot system that every later task builds on.

## Scope
- **In:** `haunted.project.json`; `games/haunted/{src,tests}`; check/typecheck/Rojo-build coverage for both projects; PlayerDataService (schema v1, UpdateAsync, session lock, retries, clamp/validate, never-drop migration, memory fallback + banner); PlotService (6 plots, assign/release, bounds, ownership helper); currency HUD.
- **Out:** Gameplay content; monetization; publishing (user creates and saves the new place locally).

## Files expected to change
- `haunted.project.json`
- `games/haunted/src/server/Services/PlayerDataService.luau`
- `games/haunted/src/server/Services/PlotService.luau`
- `games/haunted/src/shared/Config/`
- `games/haunted/src/shared/Rules/ProfileRules.luau`
- `games/haunted/tests/`
- `scripts/check.sh`
- `scripts/typecheck.sh`

## Acceptance criteria
- [ ] AC1: `rojo build haunted.project.json` succeeds and check.sh covers both projects (GAME-001 checks unchanged and still pass)
- [ ] AC2: On join a player gets a validated default or loaded Profile v1 and a free home plot; plot released on leave
- [ ] AC3: Saves use UpdateAsync with a session lock, retry with backoff, and run on leave, on a 60 s autosave and in BindToClose; overlapping saves are serialized
- [ ] AC4: Malformed or out-of-range saved values are clamped or reset per field and logged; unknown fields are preserved (no data loss on migration)
- [ ] AC5: With DataStores unavailable the game runs in memory-only mode with a visible banner; never reported as persisted
- [ ] AC6: ProfileRules (validate/clamp/migrate) have passing specs
- [ ] AC7: scripts/check.sh passes

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
