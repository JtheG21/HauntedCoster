---
id: TASK-0093
title: "MathShow Hud"
type: task
project: GAME-004
status: proposed
priority: medium
risk: medium
owner: executor
depends_on:
  - TASK-0092
branch: task/TASK-0093-MathShow-Hud
related:
  - "[[GAME-004 MathShow/00 Overview]]"
created: 2026-10-25
updated: 2026-10-25
tags:
  - workflow/task
---

# MathShow Hud

## Goal
Client HUD: question text, countdown timer, number input box, and correct/incorrect feedback, driven entirely by `RoundState` and `AnswerResult` events. Built in code, no assets.

## Scope
- **In:** `client/Hud` module(s), timer display synced to the server-provided `endsAt`, a text/number input that calls `SubmitAnswer`.
- **Out (non-goals):** leaderstats, Results/podium screen (TASK-0094).
- **Keep unchanged:** `server/`, `shared/`.

## Intake
- **Category → workflow, depth:** UI and graphics → [[UI Workflow]], standard.
- **References:** check `10 References/01 UI/` for any relevant timer/quiz HUD notes; GAME-002's `Theme.luau` for this repo's UI conventions if applicable.
- **Reuse:** none existing for a timed-input HUD; build fresh per DESIGN.md.
- **Decisions / assumptions / open questions:** Assumption — HUD trusts only server-sent `phase`/`endsAt`/`problemText` for its countdown, never a local clock guess, consistent with RoundService being server-authoritative.

## Files expected to change
- `games/mathshow/src/client/Hud/` (new)

## Acceptance criteria
- [ ] AC1 Timer counts down to the server's `endsAt`, not a client-local timer.
- [ ] AC2 Submitting an answer sends exactly one `SubmitAnswer` call per question; the input is disabled after submission.
- [ ] AC3 Feedback (correct/incorrect, points) renders on `AnswerResult` and clears for the next question.

## Tests
- **Automated:** `scripts/check.sh` (no new pure logic expected; confirm it still passes).
- **Studio playtest procedure:**
  1. `rojo serve mathshow.project.json`; join as one player; verify the HUD shows the problem, counts down, accepts one answer, and shows feedback each round.

## Risks / notes
None beyond needing TASK-0092's remotes finished first.

---
## Implementation record

## Audits

## Outcome
