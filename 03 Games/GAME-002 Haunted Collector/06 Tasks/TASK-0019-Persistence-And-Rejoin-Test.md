---
id: TASK-0019
title: Persistence and Rejoin Test
type: task
project: GAME-002
status: in_progress
priority: high
risk: high
owner: executor
milestone: M2
depends_on: []
branch: task/TASK-0019-Persistence-And-Rejoin-Test
created: 2026-10-11
updated: 2026-10-12
tags:
  - workflow/task
  - milestone/m2
related:
  - "[[RETRO-M1-Playable-MVP-Loop]]"
  - "[[ADR-0006-M1-Tuning-And-Scope-Decisions]]"
---
# TASK-0019: Persistence and Rejoin Test

## Goal
Prove real DataStore saving: a profile saved in one session is restored on rejoin, with session locking and shutdown saves working, in a private API-enabled test place.

## Scope
- **In:** A private, unpublished-to-public test place with Studio API access to DataStores (set up by jg); rejoin, BindToClose, lock and newer-schema checks; specs for `isNewerSchema` and the repaired-field list; the schema-bump rule written down.
- **Out:** Publishing to the public, any spend, live experience changes.

## Files expected to change
- `games/haunted/src/server/Services/PlayerDataService.luau`
- `games/haunted/tests/ProfileRules.spec.luau`
- `03 Games/GAME-002 Haunted Collector/05 Systems/SYS-Haunted-Player-Data.md`

## Acceptance criteria
- [ ] AC1: Coins, owned monsters, house tier, speed, route, exhibits, clues and tutorial step survive leave and rejoin (TEST note with values before and after)
- [ ] AC2: A second server can't load a locked profile while the first holds it; the lock is released on leave and on shutdown
- [ ] AC3: A profile saved by a newer schema loads read-only and is never written (spec)
- [ ] AC4: The schema-bump rule for new species, variants and flags is documented in the SYS note
- [ ] AC5: scripts/check.sh passes

## Tests
- **Automated:** `scripts/check.sh` plus the specs and scenarios named in the ACs.
- **Who settles the evidence:** **jg** sets up the private API-enabled test place, and approves it before any run (no public publish, no spend). Claude runs the checks through the Studio MCP.

## Risks / notes
Proposed in [[RETRO-M1-Playable-MVP-Loop]]; created as `ready` with jg's approval on 2026-10-11. Needs a place with API access. That is a live-service setting, so jg does the setup. Never touch a public experience.

---
## Implementation record
- **Approval:** created `ready` with jg's approval on 2026-10-11; jg started it in chat on 2026-10-12 ("start TASK-0019 with the code and specs first"). Part 1 is code and specs only; the live rejoin and lock checks wait for jg's private API-enabled place.
- **References used:** none new; this is the existing `PlayerDataService` (TASK-0011).
- **Built (part 1):**
  - `SessionLockRules` (new, shared, pure): the `UpdateAsync` record transforms for load (claim, wait, take over), save (write only while we own the lock; release clears it) and release (only our own lock). `PlayerDataService` now calls these; behaviour unchanged.
  - `ProfileRules.persistenceFor`: a newer-schema profile loads read-only (used by `PlayerDataService`). `sanitize` now reports a clamped `tutorialStep` in the repaired list.
  - Specs: `SessionLockRules.spec` (8) and 4 new `ProfileRules.spec` cases (`isNewerSchema`, read-only newer schema, its fields survive sanitize, the repaired-field list).
  - Schema-bump rule written in [[SYS-Haunted-Player-Data]] (AC4). New species, variants and flags need a bump, because an older server's `sanitize` drops unknown ones.
- **Checks:** `scripts/check.sh` passes (specs 108/0). Negative controls: with the lost-lock check disabled, `SessionLockRules.spec` fails 1; with `isNewerSchema` off by one, `ProfileRules.spec` fails 2. Both were restored.
- **Still to do (part 2, needs jg's place):** AC1 leave and rejoin with values before and after, AC2 two servers and lock release on leave and shutdown, recorded in a TEST note.

## Audits
*(links to AUD- notes)*

## Outcome
*(after merge: result, lessons, follow-ups)*
