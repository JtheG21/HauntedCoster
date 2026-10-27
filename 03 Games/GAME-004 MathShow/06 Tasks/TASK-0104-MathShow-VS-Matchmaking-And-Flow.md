---
id: TASK-0104
title: "MathShow VS Matchmaking And Flow"
type: task
project: GAME-004
status: proposed
priority: medium
risk: high
owner: executor
depends_on:
  - TASK-0099
  - TASK-0100
branch: task/TASK-0104-MathShow-VS-Matchmaking-And-Flow
related:
  - "[[GAME-004 MathShow/00 Overview]]"
  - "[[TASK-0098-MathShow-Menu-Shell]]"
created: 2026-10-26
updated: 2026-10-26
tags:
  - workflow/task
---

# MathShow VS Matchmaking And Flow

## Goal
1v1 VS (screens 03b, 04, 05, 08, 09, 19b): in-server queue, separate 2-player match, head-to-head HUD, results, rematch, sudden death.

## Scope
- **In:** see the acceptance criteria; handoff `Game_spec_UI2elements.zip` (README, RULES_SPEC, ENGINEERING_NEEDS) and `MENU_TEXT_FIT_AUDIT.md` are the spec.
- **Out (non-goals):** work belonging to the other follow-up tasks; GAME-001..003.
- **Keep unchanged:** server authority (validate type, range, ownership, rate limit); the existing match flow unless this task says so.

## Intake
- **Category → workflow, depth:** UI + server, deep tier. Deep: Opus audit.
- **References:** `10 References/01 UI` (adapt, not copy); menu patterns from [[TASK-0098-MathShow-Menu-Shell]] (Shard, Fx, Preview, TextFit gate).
- **Decisions / assumptions:** Defaults for jg to veto: search timeout 60 s, rematch window 15 s, sudden-death 15 s. This is the largest task; split if the RoundService refactor needs its own task.
- **Plan status:** proposed 2026-10-26 from the TASK-0098 follow-up list; jg asked for all follow-ups to be built (2026-10-26).

## Files expected to change
- `games/mathshow/src/{server,shared,client}`, `games/mathshow/tests`, this note, `tasks/queue.json`.

## Acceptance criteria
- [ ] AC1 Server queue with timeout (60 s default), cancel and keep-waiting remotes, per-match state so VS does not touch the Group Battle loop (RoundService refactor behind the existing specs); forfeit on leave.
- [ ] AC2 Pure `MatchRules` (vsResult, headToHeadPct, searchPhase) with specs; screens render and pass the TextFit gate with 4- and 5-digit scores.
- [ ] AC3 A real 2-client Studio test (max 2 clients) of search, found, play, result and rematch is recorded; ModeEnabled.vs flips on only after it passes; Opus audit.

## Tests
- **Automated:** `scripts/check.sh` (baseline: MathShow 134 specs).
- **Studio playtest procedure:** `scripts/studio-preflight.sh --game mathshow`; fresh Play session; TextFit gate for new states; 2-client run where the task says so.

## Risks / notes
- Depends on the tasks listed above; do not start before they are done.

---
## Implementation record

## Audits

## Outcome
