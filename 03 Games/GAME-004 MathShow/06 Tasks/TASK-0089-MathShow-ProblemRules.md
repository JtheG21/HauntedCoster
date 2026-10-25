---
id: TASK-0089
title: "MathShow ProblemRules"
type: task
project: GAME-004
status: proposed
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
- [ ] AC1 `generate(seed, difficulty)` is deterministic for a fixed seed/difficulty pair.
- [ ] AC2 All three difficulty tiers produce integer answers only.
- [ ] AC3 Spec covers add/sub/mul/div and all 3 tiers.

## Tests
- **Automated:** `scripts/check.sh`
- **Studio playtest procedure:** n/a (pure module, no Instances).

## Risks / notes
None beyond TASK-0088's spec-template risk, which should already be resolved by this point.

---
## Implementation record

## Audits

## Outcome
