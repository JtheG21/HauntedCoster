---
id: TASK-0002
title: Ability Framework
type: task
project: GAME-001
status: proposed
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

## Audits

## Outcome
