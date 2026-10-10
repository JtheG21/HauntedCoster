---
id: TASK-0009
title: Multi-Client Test Harness
type: task
project: GAME-001
status: proposed
priority: medium
risk: low
owner: executor
milestone: M2
depends_on: []
branch: task/TASK-0009-Multi-Client-Test-Harness
created: 2026-10-10
updated: 2026-10-10
tags:
  - workflow/task
  - milestone/m2
related:
  - "[[01 Game Design]]"
  - "[[03 Roadmap]]"
---
# TASK-0009: Multi-Client Test Harness

## Goal
Find a **repeatable** way to run 2–4 client tests, because the automated attempt in [[TEST-20261010-02]] was blocked. Candidates: Studio's Test → Server & Clients with a documented manual script; the StudioTestService API; open-source runners (investigate only).

## Scope
- **In:** Research, a short written procedure, and if possible a server-side test script that drives characters (PivotTo) and asserts outcomes.
- **Out:** Installing new tools without approval.

## Files expected to change
- `tests/luau/multiclient/README.md` (new)
- `tests/luau/multiclient/CollectibleRace.server.luau` (new, optional)

## Acceptance criteria
- [ ] A documented procedure that a human can run in ≤5 min, or an automated method that Claude can run
- [ ] [[TEST-20261010-02]] executed with it (pass or a filed BUG)
- [ ] Any tool needing install is listed for approval, not installed

## Tests
- **Automated:** `scripts/check.sh` plus the new Luau specs (run in Studio: `require(game.TestService.Tests.TestRunner).run()`)
- **Studio playtest procedure:** Run the procedure on TASK-0001 coins (two players, one coin).

## Risks / notes
Follow [[Luau Standards]]: server-authoritative, validate every remote argument, debounce shared state before yielding.

---
## Implementation record

## Audits

## Outcome
