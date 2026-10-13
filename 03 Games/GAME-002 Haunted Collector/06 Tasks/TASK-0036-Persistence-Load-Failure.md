---
id: TASK-0036
title: "Persistence Load Failure"
type: task
project: GAME-002
status: approved
priority: high
risk: medium
owner: executor
depends_on:
  - TASK-0035
branch: task/TASK-0036-Persistence-Load-Failure
related:
  - "[[TASK-0019-Persistence-And-Rejoin-Test]]"
  - "[[TEST-20261012-10]]"
  - "[[TEST-20261012-14]]"
created: 2026-10-12
updated: 2026-10-12
tags:
  - workflow/task
---

# Persistence Load Failure

## Goal
Stop a live server from silently handing a player a fresh, unsaved default profile. `PlayerDataService.isUnavailableError` matched error text ("403", "not allowed", "publish", "api services") anywhere. On a live server, such an error switched the whole server to memory mode, so that player's session (and everyone's after) was never saved. This is AUDIT-003 (T3 of the 2026-10-12 audit plan).

## Scope
- **In:** a pure `SessionLockRules.loadFailure(err, developmentPlace)`; `PlayerDataService` uses it for load errors and `GetDataStore` failures; specs.
- **Out:** save/lock logic, the readonly banner text, offline income (AUDIT-004 stays an accepted risk), any live DataStore test.

## Files expected to change
- `games/haunted/src/shared/Rules/SessionLockRules.luau`, `games/haunted/src/server/Services/PlayerDataService.luau`, `games/haunted/tests/SessionLockRules.spec.luau`

## Acceptance criteria
- [x] AC1 `loadFailure` returns `memory` only for DataStore-unavailable errors in a development place (Studio or `PlaceId == 0`). Every other error, and every error on a live server, is `retry`.
- [x] AC2 `PlayerDataService` uses it. A live server never enters memory mode. After the existing bounded retries (4) the player is `readonly` (existing banner), so no default profile is saved over real data. A live `GetDataStore` failure makes that load `readonly`, and the next load tries again.
- [x] AC3 Specs cover the development and live cases. A negative control (the old behaviour) fails the live spec.
- [x] AC4 Studio memory mode is unchanged: FullLoop passes in an unpublished place; `scripts/check.sh` passes.

- Evidence for AC1–AC4: [[TEST-20261012-14]] and the diff (AC2).

## Tests
- **Automated:** `scripts/check.sh` (3 new `SessionLockRules` specs).
- **Studio playtest procedure:** FullLoop in the unsaved `Place1` (memory mode). The live path can't run in Studio without a live server; it is covered by the pure specs. No DataStore writes.

## Risks / notes
- Approved in chat on 2026-10-12: jg accepted the recommended policy (memory only in development places; live: bounded retries, then readonly with the existing banner) and said "start T3".
- A published place playtested in Studio counts as a development place (`RunService:IsStudio()`), so it keeps the old memory fallback. Intended: Studio is never a live server.
- Residual: a live outage still costs that player's session progress (readonly), but never their saved data. Kicking with a "rejoin" message was the rejected alternative.

---
## Implementation record
- Specs first: 3 new specs failed (no function). Negative control: `loadFailure` returning `memory` regardless of place failed exactly the live spec ("expected retry, got memory"). Real rule: 117 passed, 0 failed.
- `PlayerDataService`: `isUnavailableError` removed; `DEVELOPMENT_PLACE = RunService:IsStudio() or game.PlaceId == 0`. `getStore` keeps the old Studio behaviour (any failure means memory) and only warns on a live server. `loadRecord` returns `readonly` (not `memory`) when there is no store on a live server.

## Audits
- [[AUD-20261012-TASK-0036-01]]: pass (Opus). Minor notes: a published place playtested in Studio still counts as a development place (intended); AC2 is evidenced by code review, not a test; two existing (non-regression) delays.

## Outcome
