---
id: TASK-0091
title: "MathShow RoundRules"
type: task
project: GAME-004
status: done
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
- [x] AC1 `nextPhase` produces the exact cycle: Intermission(10s) → Question → Reveal(4s) → ... → Results(8s) → Intermission.
- [x] AC2 Transitions out of Question happen only after N questions have been served, matching config.
- [x] AC3 Spec asserts the phase sequence and durations as properties, not fixed `Random` values (per `05 Engineering/Luau Standards.md`).

## Tests
- **Automated:** `scripts/check.sh`
- **Studio playtest procedure:** n/a (pure module, no Instances).

## Risks / notes
None.

---
## Implementation record
- Worktree `~/Desktop/Rg1-worktrees/task-0091` on `task/TASK-0091-MathShow-RoundRules`, cut from `main` `bb5f1c2`.
- Added `shared/RoundConfig.luau` (IntermissionSeconds 10, RevealSeconds 4, ResultsSeconds 8, QuestionCount 6, DifficultyByQuestion {1,1,2,2,3,3}; jg approved these picks 2026-10-25), `shared/RoundRules.luau` (`nextPhase`, `difficultyFor`) and `tests/RoundRules.spec.luau` (6 tests).
- `nextPhase(phase, questionIndex)` returns the next phase and its duration. `questionIndex` is 0 in Intermission, 1..N in Question and Reveal, N in Results; the caller increments it on entering Question. Reveal moves to Results only at index N.
- Question duration is the ProblemConfig tier `timeLimit` for that question, so RoundService can pass the same value to `ScoringRules.score`.
- Input outside the contract (unknown phase, non-integer or out-of-range index, index that does not fit the phase) raises an error.

## Audits
- None. Light tier (risk low): a green `scripts/check.sh` is the gate.

## Outcome
- `scripts/check.sh` exits 0 on this branch (MathShow specs 20 -> 26 passed, 0 failed). A first run failed Luau types in the new spec; fixed by annotating the step table.
- Spec asserts properties: exact phase sequence and durations over a full cycle, Results only after question N, question durations equal `ProblemRules.generate(...).timeLimit`, non-decreasing difficulty, and errors for out-of-contract input.
- Not run: Studio (pure module, no Instances).
- Merged as PR #129 (`45a0583`); closed 2026-10-25. Executor token usage was not recorded (no start reading).
- For TASK-0092 (RoundService): call `nextPhase` with the index of the current phase and increment it when entering Question; use `difficultyFor(index)` to generate each problem.
