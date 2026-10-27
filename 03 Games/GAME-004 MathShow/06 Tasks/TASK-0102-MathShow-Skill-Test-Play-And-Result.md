---
id: TASK-0102
title: "MathShow Skill Test Play And Result"
type: task
project: GAME-004
status: approved
priority: medium
risk: high
owner: executor
depends_on:
  - TASK-0099
  - TASK-0101
branch: task/TASK-0102-MathShow-Skill-Test-Play-And-Result
related:
  - "[[GAME-004 MathShow/00 Overview]]"
  - "[[TASK-0098-MathShow-Menu-Shell]]"
created: 2026-10-26
updated: 2026-10-26
tags:
  - workflow/task
---

# MathShow Skill Test Play And Result

## Goal
Server-authoritative Skill Test (screens 13, 14, 15): server issues questions per rank, validates answers, decides the result, persists best rank and cooldown.

## Scope
- **In:** see the acceptance criteria; handoff `Game_spec_UI2elements.zip` (README, RULES_SPEC, ENGINEERING_NEEDS) and `MENU_TEXT_FIT_AUDIT.md` are the spec.
- **Out (non-goals):** work belonging to the other follow-up tasks; GAME-001..003.
- **Keep unchanged:** server authority (validate type, range, ownership, rate limit); the existing match flow unless this task says so.

## Intake
- **Category → workflow, depth:** UI + server, deep tier. Deep: Opus audit.
- **References:** `10 References/01 UI` (adapt, not copy); menu patterns from [[TASK-0098-MathShow-Menu-Shell]] (Shard, Fx, Preview, TextFit gate).
- **Decisions / assumptions:** Defaults recorded for jg to veto: ranks 0-4 typed, 5-9 multiple choice; limits 20 s typed, 25 s multiple choice; quitting mid-test does not cost the cooldown, which starts at test end; a first test that clears nothing lands on PLASTIC (rank 0).
- **Plan status:** proposed 2026-10-26 from the TASK-0098 follow-up list; jg asked for all follow-ups to be built (2026-10-26).

## Files expected to change
- `games/mathshow/src/{server,shared,client}`, `games/mathshow/tests`, this note, `tasks/queue.json`.

## Acceptance criteria
- [ ] AC1 Server `SkillTestService` generates problems per rank (pure `SkillTestRules`/problem generator with specs), holds the answer server-side until reveal (no answer on the client), enforces two misses in a row ends the run, a per-rank time limit and the 5:00 retake cooldown.
- [ ] AC2 Result persists `bestRank` (never decreases) via the profile store; screens 13/14/15 (typed + multiple choice, rank strip, result with badgeSlam) match the handoff and pass the TextFit gate with the audit's stress fixtures (27-char calc problems, 14-char answers, negatives).
- [ ] AC3 Remote payloads listed for sender, handler and receiver; validated type, range, ownership, rate limit.
- [ ] AC4 Opus audit (DataStore, remotes); Studio run of a full test.

## Tests
- **Automated:** `scripts/check.sh` (baseline: MathShow 134 specs).
- **Studio playtest procedure:** `scripts/studio-preflight.sh --game mathshow`; fresh Play session; TextFit gate for new states; 2-client run where the task says so.

## Risks / notes
- Depends on the tasks listed above; do not start before they are done.

---
## Implementation record
Deep tier (DataStore, remotes). Baseline: MathShow 165 specs. Branch also records `approve-merge` for TASK-0101.

- **Pure (shared/):** `SkillRules` (kind per rank, time limits, `advance` for a run, `outcome` for the result, strict `validAnswer` / `parseAnswerPayload` / `validStart`), `SkillProblemRules` (one generator per rank 0-9, deterministic from (rank, seed); integer answers, no negative typed answers, text at most 30 characters, four distinct choices with `correctIndex`), `MenuConfig` Skill settings. MathShow 165 -> 185 specs; each rank is checked over 200 seeds.
- **Server:** `SkillTestService` (`SkillStart`, `SkillAnswer` in; `SkillState`, `SkillResult` out). The server checks the cooldown from the stored profile, issues one question at a time, validates every answer (attempt, type, range, once per question, time with a 250 ms grace, 6 per 5 s), reveals the correct value only in `reveal`, ends the run at two misses in a row or rank 9, and persists `bestRank`, `lastTestRank` and `lastTakenAt` through `ProfileService.apply`. `ModeRules.secondaryState("skilltest")` is now open and the server checks it too.
- **jg defaults used (veto if wrong):** ranks 0-4 typed, 5-9 multiple choice; 20 s typed, 25 s choice; a miss repeats the rank with a new question; the cooldown (5:00) starts when a run ends, so leaving mid-run costs nothing; a first test that clears nothing lands on PLASTIC.
- **Client:** `View` screens `skill` (13 typed with the digits-only box and LOCK IN, 14 choice with select-then-lock, rank strip, MISSES slots, measured problem size, timer bar, seconds, green/red/silver toasts, reveal colours and marks) and `skillresult` (15 first/up/held with the badge row, old and new badges on the tier glow, `badgeSlam`); `Menu/init` starts a run, renders each `SkillState`, counts the clock down, sends one `SkillAnswer` per question, disables Back during a run, and shows the result then DONE -> Practice (which shows the retake clock). Changed: stale toasts are cleared on every render.
- **Deviation:** the problem tag sits at (60, 40) and the text starts at y 60 (integer) / 55 (choice, max 64 px): the problem shard has a tab cut out of its top left, anything higher is inside it.

## Studio verification (Rojo via studio-sync, fresh Play)
- **Server, driven through the remotes:** ranks advance only on correct answers; a correct answer on rank 0 and 1, then two misses on rank 2 ended the run (`cleared = 1`, `first`, `best = 1`) and set `retryAt`; a second `SkillStart` answered `cooldown`; with solved ranks 0-4 the run reached rank 5 (four choices, no marker, `correctIndex` only in the reveal) and ended after two wrong choices (`cleared = 4`). Wrong attempt number, string, 1e9, 1.5, an extra key, a choice of 9 and a duplicate answer were all ignored, with exactly one reveal per question. Flooding answers hits the 6 per 5 s limit and the question times out as a miss (verified by accident).
- **Timeout:** a question left alone for 20 s revealed NOT QUITE . 1 MISS and asked a new question of the same rank.
- **UI with the mouse:** PRACTICE -> TAKE TEST -> START -> question 1 (RANK 1 . PLASTIC . 20S, the clock counting down); typing "1a2" keeps "12"; LOCK IN reveals `32 + 41 = 73` with CORRECT and NEXT UP; two wrong answers end the run and open 15c (SKILL TEST . FIRST RANK, YOU'RE RANKED, PLASTIC, Retake in 05:00); at rank 6 a choice click selects (white, LOCK IN enabled), LOCK IN sends and the reveal shows CORRECT with the choices no longer buttons.
- **TextFit gate** with 13a/b/c, 14a/b/c/d, 15a-d added: 1977 rows, 0 failures (stress: 27-character problems, a 14-digit choice, a two-line problem).
- Capture of 14c (reveal, wrong pick): green A with a check, red B with a cross, others dimmed, red toast, MISSES slot 1 used, NEXT UP and 0.
- **Not verified:** a real 2-client run; the 15a signature motion visually (flash, badgeSlam in the result); controller and touch; real DataStore persistence (memory mode); gamepad A/Y locking.


## Audits
Deep tier, one Opus audit: **pass** (AUD-20261027-TASK-0102-01). Fixed after it: a finished run is persisted when the player leaves during the last reveal, choice distractors come from a shuffled -6..+6 window, SkillState payload type checks on the client, `SkillRules.finish`, a comment on rank 9. The typed-input concern needed no change (`sanitizeInput` caps at six digits). MathShow specs 187; Studio smoke re-run clean.

## Outcome
- `scripts/check.sh` ALL CHECKS PASSED; MathShow 187 specs (baseline 165). Studio: server flow, validation, timeout, UI and result paths, gate 1977 rows 0 failures. Opus audit pass.
- **Not verified:** a real 2-client run, real DataStore persistence, the result screen's motion visually, controller/touch.
- Pending for jg: merge decision.
