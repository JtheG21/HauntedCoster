---
id: TASK-0103
title: "MathShow Blitz"
type: task
project: GAME-004
status: approved
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
Deep tier (server scoring, remotes, DataStore via ProfileService). Baseline: MathShow 187 specs. Branch also records `approve-merge` for TASK-0102.

- **Pure (shared/):** `BlitzRules` (`scoreText`, `isNewBest` (a tie is not a best), `bestText`, `reviewRows`, `difficultyFor` (questions 1-3 tier 1, 4-7 tier 2, 8-10 tier 3), strict `parseAnswerPayload` / `validStart`), `MenuConfig` Blitz settings (120 s run clock, 0.6 s to the next question). MathShow 187 -> 195 specs. `ModeEnabled.blitz` is now true.
- **Server:** `BlitzService` (`BlitzStart`, `BlitzAnswer` in; `BlitzState`, `AnswerAck`, `BlitzResult` out). All ten problems are generated and kept on the server at the start (`ProblemRules`, three difficulty tiers). `BlitzState` carries only the problem text, never an answer; the ack is `{ questionIndex }` whether the answer was right or wrong; the score, the answers and the solutions leave the server only in `BlitzResult` after question 10 or the run clock. Validation: exact payload, question index, once per question, clock plus 250 ms grace, 14 answers per 10 s, 4 starts per 10 s. The personal best goes through `ProfileService.apply` (it only ever rises). Leaving mid-run saves nothing and costs nothing.
- **Client:** `View` screens `blitz` (06: BLITZ . Q n / 10 with ten neutral pips, SCORE shown as a dash, one run clock TextScaled 36-60 plus bar, typed answer + LOCK IN, LOCKED IN toast, nothing about right or wrong) and `blitzreview` (07: score card with the TextScaled `n/10`, previous best line, NEW BEST sticker, two review columns with marks, PLAY AGAIN and MENU); `Menu/init` starts a run from START BLITZ, shows each `BlitzState`, sends one answer per question, disables Back during a run, and shows the review. The Blitz panel's BEST tag comes from the profile.
- **Deviations (gate-driven, Claude Design list):** the review rows use text at 9 px (question number) and 12 px (answers) instead of 13 and 16, and the score dash 18 px instead of 20: the 32 px row art has a deep bottom-left cut (10 px clear left of x 88, 14 px right of it). 38 px rows would hold the README sizes.

## Studio verification (Rojo via studio-sync, fresh Play)
- **Server through the remotes:** a run went question 1 -> 9 with `BlitzState` keys only `endsAt, problem, questionIndex, state, total`; every `AnswerAck` had the single key `questionIndex`; invalid payloads (wrong index, string, 1e9, 1.5, extra key) and a duplicate answer were ignored; flooding answers hit the 14 per 10 s limit; when the clock ran out (about 120 s) the run finished with `correct = 6` and `newBest = true` and printed `blitz ... correct=6 newBest=true`.
- **UI with the mouse:** PLAY -> BLITZ card -> START BLITZ opens question 1 (BLITZ . Q 1 / 10, SCORE dash, Q1 . BLITZ, clock 1:58 with the LEFT tag); typing then LOCK IN shows LOCKED IN and Q2 arrives 0.6 s later with no right/wrong; B did nothing during the run; answering the rest ended on the review (8/10, First Blitz score, NEW BEST, rows with answers); MENU returned to the main menu and the Blitz panel then showed BEST 8/10.
- **TextFit gate** with 06a-c and 07a-c added (4-digit/6-digit answers, "-123456", "99:59" and "10:00" clocks, 10/10 and 0/10 scores): 2412 rows, 0 failures.
- **Not verified:** PLAY AGAIN live; the review's motion; a 2-client run; real DataStore persistence; controller/touch.


## Audits
Deep tier, one Opus audit: **pass** (AUD-20261027-TASK-0103-01), no secrecy leak or exploit found. Fixed after it: the session is cleared before the profile write (a fault there can no longer block new runs), Blitz-specific unavailable copy. No change: the over-1e6 input (typed input caps at six digits). Left: a crafted client can run a Skill Test and a Blitz at once (gains nothing). MathShow specs 195.

## Outcome
- `scripts/check.sh` ALL CHECKS PASSED; MathShow 195 specs (baseline 187). Studio: server run, UI run and review, gate 2412 rows 0 failures. Opus audit pass.
- **Not verified:** PLAY AGAIN live, a 2-client run, real DataStore persistence, the review's motion, controller/touch.
- Pending for jg: merge decision. Claude Design list: 38 px review/ladder rows (README text sizes), taller toast and banner bands.
