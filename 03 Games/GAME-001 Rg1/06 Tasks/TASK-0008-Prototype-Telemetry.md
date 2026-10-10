---
id: TASK-0008
title: Prototype Telemetry
type: task
project: GAME-001
status: proposed
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

## Audits

## Outcome
