---
id: TASK-0006
title: Match Flow and Onboarding
type: task
project: GAME-001
status: proposed
priority: high
risk: low
owner: executor
milestone: M2
depends_on: 
  - TASK-0002
branch: task/TASK-0006-Match-Flow-And-Onboarding
created: 2026-10-10
updated: 2026-10-10
tags:
  - workflow/task
  - milestone/m2
related:
  - "[[01 Game Design]]"
  - "[[03 Roadmap]]"
---
# TASK-0006: Match Flow and Onboarding

## Goal
A round manager (lobby → course → finale → results → lobby) and the 30 s onboarding trial, so a new player uses a power within 60 s.

## Scope
- **In:** `MatchService` state machine, minimum players and countdown, teleport between zones, trial area for first-time players (session-only flag in M2), results placeholder.
- **Out:** Persistence of the 'tutorial done' flag, matchmaking across servers.

## Files expected to change
- `src/shared/MatchRules.luau` (new): pure state transitions
- `src/server/Services/MatchService.luau` (new)
- `src/server/Services/TrialService.luau` (new)
- `src/client/MatchHud.client.luau` (new)
- `tests/luau/MatchRules.spec.luau` (new)

## Acceptance criteria
- [ ] State transitions follow MatchRules only (spec-covered). An invalid transition is rejected
- [ ] Players joining mid-match wait in the lobby. Players leaving don't break the round
- [ ] A first-time player is sent through the trial and prompted to use their power
- [ ] A match with 1 player can run end to end (solo testing)
- [ ] `check.sh` passes

## Tests
- **Automated:** `scripts/check.sh` plus the new Luau specs (run in Studio: `require(game.TestService.Tests.TestRunner).run()`)
- **Studio playtest procedure:** Play solo: trial → lobby → course → finale → results → lobby loop twice without errors.

## Risks / notes
Follow [[Luau Standards]]: server-authoritative, validate every remote argument, debounce shared state before yielding.

---
## Implementation record

## Audits

## Outcome
