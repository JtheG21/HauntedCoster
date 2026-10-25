---
id: TASK-0091
title: "MathShow RoundRules"
type: task
project: GAME-004
status: proposed
priority: medium
risk: low
owner: executor
depends_on:
  - TASK-0088
branch: task/TASK-0091-MathShow-RoundRules
related:
  - "[[GAME-004 MathShow/00 Overview]]"
created: 2026-10-25
updated: 2026-10-25
tags:
  - workflow/task
---

# MathShow RoundRules

## Goal
Pure phase state machine: `shared/RoundRules` + `RoundConfig`, `nextPhase(phase, questionIndex) -> (Phase, duration)` covering Intermission (10s) → Question → Reveal (4s) → repeat for N questions → Results (8s) → back to Intermission.

## Scope
- **In:** `shared/RoundRules.luau`, `shared/RoundConfig.luau`, the phase/duration transition table from `games/mathshow/DESIGN.md` "Core loop."
- **Out (non-goals):** remotes, timing against real server clock, UI.
- **Keep unchanged:** everything outside `games/mathshow/src/shared/Round*`.

## Intake
- **Category → workflow, depth:** Systems → [[Systems Workflow]], light.
- **References:** `games/hike-or-die/src/shared/Rules/RoundRules.luau` exists for a different game's phase machine — inspect for pattern reuse, don't copy its balance or game-specific phases.
- **Reuse:** adapt the general shape of a pure, no-Instance phase-rules module; replace game-specific phases/durations per MathShow's own loop.
- **Decisions / assumptions / open questions:** Fact (DESIGN.md) — difficulty ramps by question index within a match; no elimination in the slice.

## Files expected to change
- `games/mathshow/src/shared/RoundRules.luau`
- `games/mathshow/src/shared/RoundConfig.luau`
- `games/mathshow/tests/RoundRules.spec.luau`

## Acceptance criteria
- [ ] AC1 `nextPhase` produces the exact cycle: Intermission(10s) → Question → Reveal(4s) → ... → Results(8s) → Intermission.
- [ ] AC2 Transitions out of Question happen only after N questions have been served, matching config.
- [ ] AC3 Spec asserts the phase sequence and durations as properties, not fixed `Random` values (per `05 Engineering/Luau Standards.md`).

## Tests
- **Automated:** `scripts/check.sh`
- **Studio playtest procedure:** n/a (pure module, no Instances).

## Risks / notes
None.

---
## Implementation record

## Audits

## Outcome
