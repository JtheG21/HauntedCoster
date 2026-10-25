---
id: TASK-0090
title: "MathShow ScoringRules"
type: task
project: GAME-004
status: proposed
priority: medium
risk: low
owner: executor
depends_on:
  - TASK-0088
branch: task/TASK-0090-MathShow-ScoringRules
related:
  - "[[GAME-004 MathShow/00 Overview]]"
created: 2026-10-25
updated: 2026-10-25
tags:
  - workflow/task
---

# MathShow ScoringRules

## Goal
Pure answer parsing and speed-bonus scoring: `shared/ScoringRules` + `ScoringConfig`, `parseAnswer(string) -> number?` and `score(correct, elapsed, timeLimit) -> number`.

## Scope
- **In:** `shared/ScoringRules.luau`, `shared/ScoringConfig.luau`.
- **Out (non-goals):** problem generation, round state, remotes, leaderstats.
- **Keep unchanged:** everything outside `games/mathshow/src/shared/Scoring*`.

## Intake
- **Category → workflow, depth:** Systems → [[Systems Workflow]], light.
- **References:** none in `10 References/`.
- **Reuse:** none existing.
- **Decisions / assumptions / open questions:** Fact (DESIGN.md) — answers are integers only, parsed server-side from a string with a length cap; no eval of expressions. Wrong or no answer earns 0; no elimination in the slice.

## Files expected to change
- `games/mathshow/src/shared/ScoringRules.luau`
- `games/mathshow/src/shared/ScoringConfig.luau`
- `games/mathshow/tests/ScoringRules.spec.luau`

## Acceptance criteria
- [ ] AC1 `parseAnswer` rejects non-integer, oversized, or non-numeric strings without erroring; returns `nil`.
- [ ] AC2 `score` awards 0 for incorrect/missing answers and a monotonically decreasing speed bonus as `elapsed` approaches `timeLimit`.
- [ ] AC3 Spec covers the parse-rejection and scoring-boundary cases above.

## Tests
- **Automated:** `scripts/check.sh`
- **Studio playtest procedure:** n/a (pure module, no Instances).

## Risks / notes
`parseAnswer` is an injection-adjacent boundary (parses client-submitted strings) — assert properties, not just happy-path numbers; no `eval`/`loadstring` of any kind.

---
## Implementation record

## Audits

## Outcome
