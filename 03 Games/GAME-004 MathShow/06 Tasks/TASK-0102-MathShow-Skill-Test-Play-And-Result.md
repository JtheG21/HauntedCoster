---
id: TASK-0102
title: "MathShow Skill Test Play And Result"
type: task
project: GAME-004
status: proposed
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

## Audits

## Outcome
