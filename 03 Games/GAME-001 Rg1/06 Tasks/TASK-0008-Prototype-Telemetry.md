---
id: TASK-0008
title: Prototype Telemetry
type: task
project: GAME-001
status: archived
priority: medium
risk: low
owner: executor
milestone: M2
depends_on: 
  - TASK-0006
branch: task/TASK-0008-Prototype-Telemetry
created: 2026-10-10
updated: 2026-10-12
tags:
  - workflow/task
  - milestone/m2
related:
  - "[[GAME-001 Rg1/01 Game Design|01 Game Design]]"
  - "[[GAME-001 Rg1/03 Roadmap|03 Roadmap]]"
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
- Executed on `task/TASK-0008-Prototype-Telemetry` at `af72448` (2026-10-10): `TelemetryService`, `TelemetryRules`, 6 specs, event hooks. Evidence: [[TEST-20261010-12]]. The branch is kept, not merged.
- This run was never recorded through the orchestrator, so the `tasks/queue.json` history goes `ready` → `archived` without it.

## Audits
- [[AUD-20261010-TASK-0008-01]]: **fail** (1 major, 5 minor, 2 nit). The major finding: the first-power median can never exceed 30 s, so the EXP-0001 "<60 s" trigger always passes. No revision followed.

## Outcome
- **Archived** 2026-10-12 by jg (GAME-001 paused; GAME-002 is primary), after a failed first audit and without a revision. Nothing was merged. If GAME-001 telemetry is ever revived, start from the audit's findings.
