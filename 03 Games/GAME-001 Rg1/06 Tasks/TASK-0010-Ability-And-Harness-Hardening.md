---
id: TASK-0010
title: Ability and Harness Hardening
type: task
project: GAME-001
status: proposed
priority: medium
risk: low
owner: executor
milestone: M2
depends_on: []
branch: task/TASK-0010-Ability-And-Harness-Hardening
created: 2026-10-10
updated: 2026-10-10
tags:
  - workflow/task
  - milestone/m2
related:
  - "[[AUD-20261010-TASK-0002-02]]"
  - "[[AUD-20261010-TASK-0009-01]]"
---
# TASK-0010: Ability and harness hardening (audit follow-ups)

## Goal
Close the remaining minor and nit findings from [[AUD-20261010-TASK-0002-02]] (N2–N4, plus AC2 evidence) and [[AUD-20261010-TASK-0009-01]] (findings 1, 3, 6–8), so TASK-0003/0004 build on solid ground.

## Scope
- **In:** the items in the acceptance criteria.
- **Out:** new gameplay. TASK-0002 N1 (Dash force and seated run in Play) is recorded as evidence on `main` without code changes (TEST-20261010-04, pending).

## Files expected to change
- `tests/luau/multiclient/AbilityProbe.luau` (new)
- `tests/luau/multiclient/CollectibleRace.luau`
- `src/server/Services/StudioTestHook.luau`
- `src/server/Services/AbilityService.luau`
- `tests/test_orchestrator.py`

## Acceptance criteria
- [ ] AbilityProbe multi-client scenario: client 2 observes client 1's Dash displacement (closes TASK-0002 AC2)
- [ ] StudioTestHook: JSONEncode wrapped in pcall; EndTest always called; scenario timeout (default 45 s); double start() guarded
- [ ] CollectibleRace: touches counted per player; legit-round waitFor result checked; unknown approach rejected
- [ ] AbilityService: diagnostics attribute cleared on PlayerRemoving; folder cast made sound
- [ ] orchestrator request-changes: tests cover in_review start state, CLI wiring and the revision-limit-to-blocked path
- [ ] scripts/check.sh passes

## Tests
- **Automated:** `scripts/check.sh`, plus multi-client runs of AbilityProbe and CollectibleRace with the raw JSON pasted into a TEST note
- **Studio playtest procedure:** see [[Multi-Client Testing]]

## Risks / notes
Low risk. Test infrastructure and small server guards.

---
## Implementation record

## Audits

## Outcome
