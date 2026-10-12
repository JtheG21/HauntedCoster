---
id: TASK-0019
title: Persistence and Rejoin Test
type: task
project: GAME-002
status: in_review
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
- **Part 2 (live, jg's private place "Haunted", 108419797534540):** jg confirmed the place in chat on 2026-10-12 ("ok you should be able to proceed"). New scenario `Persistence` with three phases, run from Edit ([[TEST-20261012-10]]):
  - `write` 9/9: test values saved; a second server's load refused while held; leaving released the lock.
  - `read` 4/4: every value survived leave and rejoin (AC1). The shutdown save then wrote one more coin and released the lock (AC2).
  - `lock` 7/7: after another server took the lock, the session wrote nothing and turned read-only.
  - Run 1 of `write` failed one check through a test bug (it expected the tutorial step it set, but the tutorial moves on by itself); fixed before the audit.

## Audits
- [[AUD-20261012-TASK-0019-01]]: pass (3 minor, 2 nit; minors 3 and 4 and nit 6 fixed, minor 2 accepted as intentional).

## Outcome
*(after merge: result, lessons, follow-ups)*
