---
id: TASK-0008
title: Prototype Telemetry
type: task
project: GAME-001
status: in_review
priority: medium
risk: low
owner: executor
milestone: M2
depends_on: 
  - TASK-0006
branch: task/TASK-0008-Prototype-Telemetry
created: 2026-10-10
updated: 2026-10-10
tags:
  - workflow/task
  - milestone/m2
related:
  - "[[01 Game Design]]"
  - "[[03 Roadmap]]"
---
# TASK-0008: Prototype Telemetry

## Goal
Server-side measurements needed by [[EXP-0001-M2-Validation-Experiments]]: time to first power use, gate wait times, Echo usage, match length, finale results.

## Scope
- **In:** `TelemetryService` (in-memory per server, printed summary at match end, optional AnalyticsService custom events if available). No personal data.
- **Out:** External analytics, dashboards.

## Files expected to change
- `src/server/Services/TelemetryService.luau` (new)
- `src/shared/TelemetryRules.luau` (new): pure aggregation
- `tests/luau/TelemetryRules.spec.luau` (new)

## Acceptance criteria
- [ ] Each match prints one structured summary line (JSON) with the listed metrics
- [ ] No usernames or user ids in logs (anonymised per-match index)
- [ ] Aggregation specs pass. `check.sh` passes

## Tests
- **Automated:** `scripts/check.sh` plus the new Luau specs (run in Studio: `require(game.TestService.Tests.TestRunner).run()`)
- **Studio playtest procedure:** Run 2 solo matches; copy the summary lines into a TEST note.

## Risks / notes
Follow [[Luau Standards]]: server-authoritative, validate every remote argument, debounce shared state before yielding.

---
## Implementation record
*Executor (Claude Code, main session), 2026-10-10, branch `task/TASK-0008-Prototype-Telemetry`*

**Files changed**
- `src/shared/TelemetryRules.luau` (new): `summarize` (count, median, max; ignores NaN and inf), `anonymize` (UserId → P1..Pn by match order), `buildSummary` (the per-match table; no ids or names)
- `src/server/Services/TelemetryService.luau` (new): opens a record when the Course starts and emits `[Telemetry] {json}` when the match returns to the Lobby. Collects: first power time (from the trial, once per player), trial timeouts, gate opens and wait times, shrine opens, Echo earned and spent per power, course, finale and total seconds, finishers, Speed/Teamwork/Combat (anonymised, with faction), eliminations, server script errors (`ScriptContext.Error`), ability rejections. Keeps the last 50 lines in memory (`getSummaries`)
- `tests/luau/TelemetryRules.spec.luau` (new, 6 tests)
- **Outside the listed files, declared (event hooks only, no behaviour change):** `MatchService.onStateChanged`, `EchoService.onEvent` (earned/spent), `ConvergenceGate.onEvent` (opened/shrine with wait seconds), `FinaleService.getLastOutcome`, `init.server.luau` wiring

**Design decisions**
- **Nothing leaves the server.** Lines go to the server output only. `AnalyticsService` custom events (optional in the task) are deliberately not used: the prototype doesn't need them, and sending data off-server is a decision for a later, approved milestone.
- Each player's onboarding result is reported once, in the first match they play, so first-power stats aren't double-counted.
- A leaver's ability rejections aren't counted (AbilityService clears the counter on leave).

**Check results:** `scripts/check.sh` ALL CHECKS PASSED. Specs 64/0 (fresh session). Playtest [[TEST-20261010-12]] (2 solo matches, summary lines copied verbatim).

## Audits

## Outcome
