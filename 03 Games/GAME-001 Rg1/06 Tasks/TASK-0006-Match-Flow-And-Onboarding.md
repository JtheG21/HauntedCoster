---
id: TASK-0006
title: Match Flow and Onboarding
type: task
project: GAME-001
status: approved
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
*Executor (Claude Code, main session), 2026-10-10, branch `task/TASK-0006-Match-Flow-And-Onboarding`*

**Files changed**
- `src/shared/MatchRules.luau` (new): the transition table (`transition` rejects unknown or invalid moves), `canJoinMatch`, `courseOver`, `shouldCountdown`
- `src/shared/MatchConfig.luau` (new): timings, greybox zone positions, trial power and prompt per faction
- `src/server/Services/MatchService.luau` (new): a 5 Hz tick; state only via `MatchRules.transition`; snapshots match players at start; mid-match joiners wait; an empty match falls back to the lobby; placeholder zone pads (`Workspace.MatchZones`); respawns return players to their phase zone; publishes `MatchState`, `PhaseEndsAt` (server time) and `LastResults`
- `src/server/Services/TrialService.luau` (new): session-only trial; finished by the faction power (`AbilityService.onActivated`) or a 30 s timeout; records `FirstPowerSeconds`
- `src/client/MatchHud.luau` (new, a ModuleScript like the other client modules): phase banner with a countdown (`Workspace:GetServerTimeNow()`), trial prompt, results
- `tests/luau/MatchRules.spec.luau` (new, 7 tests); `tests/luau/multiclient/MatchJoinLeave.luau` (new)
- **Folded in from earlier audits (outside the listed files):** `AbilityService.onActivated`; `ConvergenceGate.setPresentProvider` and `resetAll` (gates count the match's factions; per-match reset of awards and shrines); `FactionService.setSwitchGuard` and `rebalance()` (rebalance only switches players not in a match; re-run at match end); `EchoService.reset` clears every `Echo_` attribute; both `init` scripts. `CLAUDE.md`: spec-running instructions updated to fresh Play sessions (LES-0005)

**Design decisions**
- `MinPlayers = 1` so a solo match runs end to end (AC4). Raise it for public play.
- Finale and results are placeholders (10 s and 8 s). The finale itself is TASK-0007. Results show only Speed for now.
- Countdown text uses server time (`GetServerTimeNow`), which fixes the clock-mismatch idea flagged for the gate HUD.

**Check results:** `scripts/check.sh` ALL CHECKS PASSED. Specs 46/0 (fresh session). Playtest [[TEST-20261010-10]].

## Audits
- [[AUD-20261010-TASK-0006-01]]: attempt 1, **pass** (6 minor, 4 nit). Minors: respawn in Results goes to CourseStart; trial player respawns at default spawn; trial prompt goes stale after a rebalance; gate reset ignores occupants and clone consumption; dead players miss the snapshot and the countdown flaps with MinPlayers > 1; scope or CLAUDE.md on a task branch

## Outcome
