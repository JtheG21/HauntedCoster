---
id: TASK-0103
title: "MathShow Blitz"
type: task
project: GAME-004
status: proposed
priority: medium
risk: high
owner: executor
depends_on:
  - TASK-0099
branch: task/TASK-0103-MathShow-Blitz
related:
  - "[[GAME-004 MathShow/00 Overview]]"
  - "[[TASK-0098-MathShow-Menu-Shell]]"
created: 2026-10-26
updated: 2026-10-26
tags:
  - workflow/task
---

# MathShow Blitz

## Goal
Solo Blitz (screens 06, 07 and 03a): 10 problems on one clock, scored at the end, personal best.

## Scope
- **In:** see the acceptance criteria; handoff `Game_spec_UI2elements.zip` (README, RULES_SPEC, ENGINEERING_NEEDS) and `MENU_TEXT_FIT_AUDIT.md` are the spec.
- **Out (non-goals):** work belonging to the other follow-up tasks; GAME-001..003.
- **Keep unchanged:** server authority (validate type, range, ownership, rate limit); the existing match flow unless this task says so.

## Intake
- **Category → workflow, depth:** UI + server, deep tier. Deep: Opus audit.
- **References:** `10 References/01 UI` (adapt, not copy); menu patterns from [[TASK-0098-MathShow-Menu-Shell]] (Shard, Fx, Preview, TextFit gate).
- **Decisions / assumptions:** Defaults for jg to veto: `BlitzClock` 120 s total; a tie in score is not a new best (strictly greater).
- **Plan status:** proposed 2026-10-26 from the TASK-0098 follow-up list; jg asked for all follow-ups to be built (2026-10-26).

## Files expected to change
- `games/mathshow/src/{server,shared,client}`, `games/mathshow/tests`, this note, `tasks/queue.json`.

## Acceptance criteria
- [ ] AC1 Server `BlitzService`: problem set per run, one total clock from config, answers validated server-side, no right/wrong shown until review; pure `BlitzRules` (scoreText, isNewBest, reviewRows, bestText) with boundary specs.
- [ ] AC2 Blitz best persists in the profile; screens 06/07 match the handoff (neutral pips, LOCKED IN toast, review columns, NEW BEST) and pass the TextFit gate with 99:59 / 10:00 and 10/10 fixtures.
- [ ] AC3 ModeEnabled.blitz flips to true only when the flow is complete; Opus audit.

## Tests
- **Automated:** `scripts/check.sh` (baseline: MathShow 134 specs).
- **Studio playtest procedure:** `scripts/studio-preflight.sh --game mathshow`; fresh Play session; TextFit gate for new states; 2-client run where the task says so.

## Risks / notes
- Depends on the tasks listed above; do not start before they are done.

---
## Implementation record

## Audits

## Outcome
