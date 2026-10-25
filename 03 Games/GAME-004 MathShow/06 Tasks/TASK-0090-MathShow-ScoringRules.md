---
id: TASK-0090
title: "MathShow ScoringRules"
type: task
project: GAME-004
status: in_progress
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
- Worktree `~/Desktop/Rg1-worktrees/task-0090` on `task/TASK-0090-MathShow-ScoringRules`, cut from origin/main `ceafb9c`.
- Added `shared/ScoringConfig.luau` (BasePoints 100, SpeedBonusMax 100, RawLengthCap 16, DigitCap 6) and `shared/ScoringRules.luau` (`parseAnswer`, `score`), plus `tests/ScoringRules.spec.luau` (14 tests).
- Late correct answer (elapsed at or past timeLimit): base points, no bonus. jg chose this on 2026-10-25.
- `parseAnswer`: optional leading and trailing spaces only, so tabs and newlines are rejected. The raw length cap runs before the pattern match.
- `score`: a NaN, zero, negative or infinite timeLimit, or a NaN elapsed, gets base points with no bonus. Negative elapsed gets the full bonus.

## Audits
- None. Light tier: a green `scripts/check.sh` is the gate.

## Outcome
- `scripts/check.sh` exits 0 on this branch: StyLua, Selene, Luau types, Lune specs (MathShow 20 passed, 0 failed, including the 14 ScoringRules tests), Rojo build, JSON, queue, vault, refs, skills and Python tests.
- Spec asserts properties: parse rejections; the digit cap covers the largest ProblemConfig answer (400); every ProblemRules answer for tiers 1-3, seeds 1-200, parses back to itself; score is 0 for wrong or missing answers; the bonus never rises and reaches base at timeLimit; late, zero and NaN windows keep base; output is always whole, non-negative and NaN-free.
- Not run: Studio (pure module, no Instances). Not merged. Status left `in_progress` for jg's `/task-close`.
