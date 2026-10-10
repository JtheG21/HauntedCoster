---
id: TASK-0005
title: Convergence Gate
type: task
project: GAME-001
status: proposed
priority: high
risk: medium
owner: executor
milestone: M2
depends_on: 
  - TASK-0003
  - TASK-0004
branch: task/TASK-0005-Convergence-Gate
created: 2026-10-10
updated: 2026-10-10
tags:
  - workflow/task
  - milestone/m2
related:
  - "[[01 Game Design]]"
  - "[[03 Roadmap]]"
---
# TASK-0005: Convergence Gate

## Goal
The core cooperation mechanic: a gate that needs **2 different faction powers**. Everyone passing gets an **Echo charge** of the powers that opened it. A 20 s **Echo Shrine** fallback opens a slower bypass if nobody helps.

## Scope
- **In:** `ConvergenceGate` component (requirements computed from the factions present), Echo charge inventory (in-match only), Echo Shrine fallback, gate UI icons (which powers are needed).
- **Out:** Using Echo charges in the finale (TASK-0007), more gate types (M3).

## Files expected to change
- `src/server/Components/ConvergenceGate.luau` (new)
- `src/shared/GateRules.luau` (new): pure requirement and fallback logic
- `src/server/Services/EchoService.luau` (new)
- `src/client/GateHud.client.luau` (new)
- `tests/luau/GateRules.spec.luau` (new)

## Acceptance criteria
- [ ] The gate opens only when both required powers have been applied within a 10 s window
- [ ] If only one faction is in the match, requirements drop to that faction's power plus the shrine
- [ ] Each player passing an opened gate gets exactly 1 Echo charge per opening power (server inventory)
- [ ] The shrine bypass opens 20 s after the first player arrives if the gate is still closed
- [ ] Specs pass. `check.sh` passes

## Tests
- **Automated:** `scripts/check.sh` plus the new Luau specs (run in Studio: `require(game.TestService.Tests.TestRunner).run()`)
- **Studio playtest procedure:** 2 players (Shinobi + Ki): open the gate together; check Echo inventory; solo: shrine opens after 20 s.

## Risks / notes
Follow [[Luau Standards]]: server-authoritative, validate every remote argument, debounce shared state before yielding.

---
## Implementation record

## Audits

## Outcome
