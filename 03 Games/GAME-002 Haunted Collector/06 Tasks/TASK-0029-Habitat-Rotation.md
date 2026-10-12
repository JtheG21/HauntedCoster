---
id: TASK-0029
title: Habitat Rotation
type: task
project: GAME-002
status: proposed
priority: high
risk: high
owner: executor
milestone: M3
depends_on:
  - TASK-0027
branch: task/TASK-0029-Habitat-Rotation
created: 2026-10-12
updated: 2026-10-12
tags:
  - workflow/task
  - milestone/m3
related:
  - "[[ADR-0007-World-Retrofit-Direction]]"
  - "[[SYS-Haunted-Capture-Loop]]"
---
# TASK-0029: Habitat Rotation

## Goal
The active habitat follows a shared 15-minute, four-habitat schedule that every server computes from UTC time. A one-minute warning precedes each swap, new captures close near the end, and the swap never loses or duplicates a capture.

## Scope
- **In:**
  - Pure `RotationRules`: phase, current, next, warning, closing and swap times from an injected clock and config.
  - A `HabitatService` phase machine and a `HabitatState` leaf module (SODT `RoundState` pattern).
  - A HUD countdown using `GetServerTimeNow` deadlines.
  - New capture starts refused while closing.
  - The swap policy approved in ADR-0007 (players inside, open meters, fleeing escapes).
  - A short fog transition. The incoming module activates only after cleanup and validation.
- **Out:** cinematic transitions, cross-server messaging, per-habitat mechanics.

## Acceptance criteria
- [ ] AC1: Specs show the schedule is deterministic across servers (same clock → same habitat), with correct boundaries (warning at T-60, closing at T-15, swap at T-0), wrap-around, and config changes that apply without touching test settings.
- [ ] AC2: A swap while a player carries keeps the carry (same species, variant and deadline). Securing after the swap adds exactly one monster.
- [ ] AC3: A swap during an open meter session cancels it cleanly. No monster is created, and no claim or prompt is left behind.
- [ ] AC4: A swap during an escape chase follows the approved policy. The fleeing capture is neither duplicated nor silently deleted, and the chase or loss is reported to the player.
- [ ] AC5: Players still inside are handled per policy, and nobody ends up inside new geometry (scenario check).
- [ ] AC6: Capture starts are refused while closing, and normal play resumes after the swap.
- [ ] AC7: FullLoop, CrossPlot and ExploitProbe pass. `scripts/check.sh` passes.

## Tests
- **Automated:** `RotationRules.spec`, and a `HabitatRotation` scenario with a fast config passed through the StudioTestHook args (for example 40 s slots).
- **Not verifiable in Studio:** clock skew across real servers. Documented as residual risk.

---
## Implementation record

## Audits

## Outcome
