---
id: TASK-0089
title: "MathShow ProblemRules"
type: task
project: GAME-004
status: done
priority: medium
risk: low
owner: executor
depends_on:
  - TASK-0088
branch: task/TASK-0089-MathShow-ProblemRules
related:
  - "[[GAME-004 MathShow/00 Overview]]"
created: 2026-10-25
updated: 2026-10-25
tags:
  - workflow/task
---

# MathShow ProblemRules

## Goal
Pure problem generation: `shared/ProblemRules` + `ProblemConfig`, `generate(seed, difficulty) -> Problem { text, answer, timeLimit }`, covering add/sub/mul/div with integer answers across 3 difficulty tiers.

## Scope
- **In:** `shared/ProblemRules.luau`, `shared/ProblemConfig.luau`, deterministic generation from `Random.new(seed)`.
- **Out (non-goals):** scoring, round state machine, remotes, UI.
- **Keep unchanged:** everything outside `games/mathshow/src/shared/Problem*`.

## Intake
- **Category → workflow, depth:** Systems → [[Systems Workflow]], light.
- **References:** none in `10 References/`.
- **Reuse:** none existing; new pure-logic module per `games/mathshow/DESIGN.md`.
- **Decisions / assumptions / open questions:** Assumption — integer-only answers and a length cap on operands per tier, per DESIGN.md "Rules that matter."

## Files expected to change
- `games/mathshow/src/shared/ProblemRules.luau`
- `games/mathshow/src/shared/ProblemConfig.luau`
- `games/mathshow/tests/ProblemRules.spec.luau`

## Acceptance criteria
- [x] AC1 `generate(seed, difficulty)` is deterministic for a fixed seed/difficulty pair. Evidence: `ProblemRules.spec.luau` "generate is deterministic..." (20 seeds x 3 tiers).
- [x] AC2 All three difficulty tiers produce integer answers only. Evidence: `ProblemRules.spec.luau` "integer answers only" (200 seeds x 3 tiers).
- [x] AC3 Spec covers add/sub/mul/div and all 3 tiers. Evidence: `ProblemRules.spec.luau` "covers add, sub, mul and div" (200 seeds x 3 tiers, all four ops seen).

## Tests
- **Automated:** `scripts/check.sh`
- **Studio playtest procedure:** n/a (pure module, no Instances).

## Risks / notes
None beyond TASK-0088's spec-template risk, which should already be resolved by this point.

---
## Implementation record
**Files changed:**
- `games/mathshow/src/shared/ProblemConfig.luau` — frozen `Tiers` table (1-3), each with `addSubMin/Max`, `factorMin/Max`, `timeLimit`. Numbers are an assumption (not in DESIGN.md): tier 1 (1-10, 15s), tier 2 (5-30 add/sub, 2-12 factors, 12s), tier 3 (10-50 add/sub, 3-20 factors, 9s). Reversible — RoundService/jg can retune without touching ProblemRules.
- `games/mathshow/src/shared/ProblemRules.luau` — `generate(seed, difficulty) -> Problem`. `Random.new(seed)` picks one of add/sub/mul/div then rolls operands from the tier. Sub always swaps to a non-negative answer (no elimination in the slice, per DESIGN.md). Div is built as `a*b / b` so it's always exact. Unknown `difficulty` errors.
- `games/mathshow/tests/ProblemRules.spec.luau` — determinism (same seed+difficulty twice), integer-only answers, all 4 ops present per tier (200-seed sample), non-negative subtraction, exact division, and tier timeLimits + the difficulty-4 error path.

**Decision (assumption, reversible):** exact operand ranges and timeLimits per tier aren't specified in DESIGN.md beyond "ramps by question index" — picked reasonable values (above) that a future RoundRules/balance pass can change without touching this module's contract.

**Check output:** `scripts/check.sh` — ALL CHECKS PASSED (StyLua, Selene, Luau types, Lune specs 271/0 [265 HauntedCollector + 6 MathShow], 3x Rojo build, JSON, task queue, vault, refs lint, skills, 163 Python tests).

## Audits
Light tier — relies on green `check.sh` (`04 Agents/Task Intake.md` depth tiers); no audit subagent.

## Outcome
ProblemRules and ProblemConfig are in place with a full spec. TASK-0090 (ScoringRules) and TASK-0091 (RoundRules) can proceed independently (both only depend on TASK-0088); TASK-0092 (RoundService) depends on all three.
