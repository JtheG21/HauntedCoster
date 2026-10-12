---
id: TASK-0019
title: Persistence and Rejoin Test
type: task
project: GAME-002
status: ready
priority: high
risk: high
owner: executor
milestone: M2
depends_on: []
branch: task/TASK-0019-Persistence-And-Rejoin-Test
created: 2026-10-11
updated: 2026-10-11
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
*(Executor: files changed, decisions, check output)*

## Audits
*(links to AUD- notes)*

## Outcome
*(after merge: result, lessons, follow-ups)*
