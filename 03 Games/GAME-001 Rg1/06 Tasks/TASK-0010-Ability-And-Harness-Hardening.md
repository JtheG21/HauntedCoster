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
Scope extended 2026-10-10, while still proposed, with the deferrals from [[AUD-20261010-TASK-0006-01]], [[AUD-20261010-TASK-0007-01]] and [[AUD-20261010-TASK-0007-02]] (the M2 hardening pass before real-player tests).

## Scope
- **In:** the items in the acceptance criteria.
- **Out:** new gameplay. TASK-0002 N1 (Dash force and seated run in Play) is recorded as evidence on `main` without code changes ([[TEST-20261010-04]]).

## Files expected to change
- `tests/luau/multiclient/AbilityProbe.luau` (new)
- `tests/luau/multiclient/CollectibleRace.luau`
- `src/server/Services/StudioTestHook.luau`
- `src/server/Services/AbilityService.luau`
- `tests/test_orchestrator.py`
- `src/server/Services/FinaleService.luau`, `src/server/Abilities/FinaleModifiers.luau`, `src/server/Components/ConvergenceGate.luau`
- `src/server/Services/MatchService.luau`, `src/server/Services/TrialService.luau`
- `tests/luau/multiclient/FinaleRingOut.luau` (plus a 3-client variant)

## Acceptance criteria
- [ ] AbilityProbe multi-client scenario: client 2 observes client 1's Dash displacement (closes TASK-0002 AC2)
- [ ] StudioTestHook: JSONEncode wrapped in pcall; EndTest always called; scenario timeout (default 45 s); double start() guarded
- [ ] CollectibleRace: touches counted per player; legit-round waitFor result checked; unknown approach rejected
- [ ] AbilityService: diagnostics attribute cleared on PlayerRemoving; folder cast made sound
- [ ] orchestrator request-changes: tests cover in_review start state, CLI wiring and the revision-limit-to-blocked path
- [ ] Finale (AUD-0007-02 F1): survivors snapshotted at conclusion; a player leaving after the finale is decided can't change Combat
- [ ] Finale (AUD-0007-02 F3): ring-out check starts once a player has been seen on the deck (capped), replacing the fixed 1 s grace
- [ ] Finale (AUD-0007-01 F3): server-side position sanity check (a target can't teleport back after a knockback); character no-collide group in the arena; exploit probe recorded
- [ ] Finale (AUD-0007-02 nits): ownership hand-back failure logged; contribution listeners iterated over a copy; solo finale when a rival was dead at course end resolved
- [ ] Match flow (AUD-0006-01): respawn during Results, trial respawn at the trial pad, trial prompt refreshed after a rebalance, gate reset respects occupants and clone consumption, dead players in the snapshot, countdown hysteresis when MinPlayers > 1
- [ ] Evidence (AUD-0007-01 F6 / AUD-0007-02 F4): a 3-client finale run; G/V Echo spends through the real remote; a mid-finale leave and respawn; root-cause note on AddPlayers sessions
- [ ] Leftover minors from AUD-0003/0004/0005 reviewed at task start; each fixed or explicitly deferred with a reason
- [ ] scripts/check.sh passes

## Tests
- **Automated:** `scripts/check.sh`, plus multi-client runs of AbilityProbe and CollectibleRace with the raw JSON pasted into a TEST note
- **Studio playtest procedure:** see [[Multi-Client Testing]]

## Risks / notes
Low to medium risk: test infrastructure and small server guards, plus the finale anti-exploit check (needs care not to false-positive legitimate knockbacks). Large task; split it if the first audit shows that's needed.

---
## Implementation record

## Audits

## Outcome
