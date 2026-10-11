---
id: TASK-0002
title: Ability Framework
type: task
project: GAME-001
status: done
priority: high
risk: medium
owner: executor
milestone: M2
depends_on: []
branch: task/TASK-0002-Ability-Framework
created: 2026-10-10
updated: 2026-10-10
tags:
  - workflow/task
  - milestone/m2
related:
  - "[[01 Game Design]]"
  - "[[03 Roadmap]]"
---
# TASK-0002: Ability Framework

## Goal
A reusable, server-authoritative ability system: the client *requests* an ability, the server validates it and applies it. This is the spike for the M2 riskiest assumption R2 (powers replicate reliably and resist exploits).

## Scope
- **In:** `AbilityRemote` (RemoteEvent created by the server), per-player cooldown and rate limit, range and target validation, an ability registry, one test ability (`Dash`) to prove the pipeline, a client input binding (keyboard plus a touch button).
- **Out:** Faction abilities, VFX polish, persistence.

## Files expected to change
- `src/shared/AbilityConfig.luau` (new): ids, cooldowns, ranges
- `src/shared/AbilityRules.luau` (new): pure `canActivate(state)` cooldown/rate/range checks
- `src/server/Services/AbilityService.luau` (new)
- `src/client/AbilityInput.client.luau` (new)
- `tests/luau/AbilityRules.spec.luau` (new)

## Acceptance criteria
- [ ] The server creates the remote. Clients can't create or replace it
- [ ] Activating Dash with the keybind or touch button moves the character on the server, visible to other clients
- [ ] Requests during cooldown, over the rate limit (>5/s), with wrong types or unknown ids are rejected and don't error
- [ ] Pure rules have passing specs (cooldown boundary, rate limit, NaN/nil args)
- [ ] `scripts/check.sh` passes

## Tests
- **Automated:** `scripts/check.sh` plus the new Luau specs (run in Studio: `require(game.TestService.Tests.TestRunner).run()`)
- **Studio playtest procedure:** Studio: Play 1 player → Dash works. Command-bar exploit probe: fire the remote 20× in 1 s and with junk args → server log shows rejections, no errors. 2-client check if TASK-0009 provides a method; otherwise manual per [[TEST-20261010-02]] style.

## Risks / notes
Follow [[Luau Standards]]: server-authoritative, validate every remote argument, debounce shared state before yielding.

---
## Implementation record
*Executor (Claude Code, main session), 2026-10-10, branch `task/TASK-0002-Ability-Framework`*

**Files changed**
- `src/shared/AbilityConfig.luau` (new): remote name, rate limit (5 per 1 s), Dash cooldown 1 s, speed 60, duration 0.2 s
- `src/shared/AbilityRules.luau` (new): pure `validateRequest`, `checkRate` (sliding window, bounded memory), `canActivate`, `horizontalDirection`
- `src/server/Services/AbilityService.luau` (new): server-created remote, registry with an optional `canUse` (for factions later), rate → validate → eligibility → cooldown → character checks, handler in `pcall`, rejection counter attribute `AbilityRejections`, throttled warnings
- `src/server/Abilities/Dash.luau` (new): test ability. **One more file than the spec listed:** it sets the `Abilities/<Name>.luau` pattern that TASK-0003/0004 use
- `src/client/AbilityInput.luau` (new): `ContextActionService` key plus touch button per ability. **Deviation:** a ModuleScript required from `init.client.luau` rather than a nested `.client.luau` LocalScript (consistent with the server pattern)
- `src/server/init.server.luau`, `src/client/init.client.luau`: start the services
- `tests/luau/AbilityRules.spec.luau` (new): 7 tests

**Design decisions**
- **Clients send only an ability id.** Direction, force and targets are always decided on the server.
- The rate limit is checked **first** and counts rejected requests, so spam is cheap to drop.
- The cooldown is committed before the handler runs, so a yielding handler can't be re-entered.
- **Replication finding (spike, R2):** the player's client owns its character's physics, so the server adds a short-lived `LinearVelocity` constraint instead of writing velocity. The owning client simulates it, and the server observed the displacement. This is the pattern for movement abilities. Pushable objects get their own ownership decision in TASK-0004.

**Check results**
- `scripts/check.sh`: ALL CHECKS PASSED (StyLua, Selene, types: no type errors, Rojo build, JSON, queue, vault 0/0, 30 Python tests)
- Luau specs: `[TestRunner] 16 passed, 0 failed`
- Playtest and exploit probes: [[TEST-20261010-03]]. All probes rejected, no errors.

**Not yet verified:** a second client seeing the Dash (needs [[TASK-0009-Multi-Client-Test-Harness]]); the touch button on a real device.

### Revision 1: audit follow-ups (requested by jg, 2026-10-10)
- **F1:** the rejection counter moved off the replicated Player attribute to a server-only `ServerStorage.AbilityDiagnostics` attribute `Rejections_<UserId>`
- **F2:** `canUse` runs in `pcall`. An error counts as a rejection (`eligibility_error`), and the type documents "must not yield"
- **F3:** `Dash.MaxForce = 40000` (config) replaces `math.huge`. Abilities are rejected while seated (`humanoid.SeatPart`) unless the registration sets `allowSeated`
- **F4:** specs add NaN, boolean and Vector3 ids → `bad_type`
- **F5 (nit):** requests after the player has left return early, with no state recreated
- **Tooling (outside scope, disclosed):** `orchestrator.py request-changes` (in_review/approved → changes_requested, counts as a revision) plus 1 test, needed to route this post-audit change honestly

**Checks:** `scripts/check.sh` ALL CHECKS PASSED (31 Python tests). Luau `AbilityRules` specs **7/7** in Studio, run by loading the branch's files into a temporary ServerStorage folder (Studio was synced to another branch). The folder was removed afterwards.
**Not runtime-tested yet:** F1/F2/F3/F5 service behaviour in a Play session, because Studio isn't synced to this branch. **Plan:** after merge, add an `AbilityProbe` multi-client scenario (see the multi-client testing how-to added by TASK-0009) covering the 2nd-client Dash view (AC2), the seated rejection and the diagnostics counter.

## Audits
- [[AUD-20261010-TASK-0002-01]]: attempt 1, **pass** (4 minor, 2 nit)
- [[AUD-20261010-TASK-0002-02]]: attempt 2 (revision 1 delta), **pass**: F1–F5 fixed. New: N1 minor (Dash force/seated not run in Play), N2–N4 nits

## Outcome
Merged to `main` on 2026-10-10 (merge approved by jg). Audits: attempt 1 pass, attempt 2 (revision 1) pass. Audit N1 runtime evidence: [[TEST-20261010-04]] (force cap and seated rejection confirmed). Still open: the AC2 second-client view and the remaining nits are in [[TASK-0010-Ability-And-Harness-Hardening]].
