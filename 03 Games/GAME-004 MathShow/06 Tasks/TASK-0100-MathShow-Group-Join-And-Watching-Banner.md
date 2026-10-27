---
id: TASK-0100
title: "MathShow Group Join And Watching Banner"
type: task
project: GAME-004
status: in_progress
priority: medium
risk: medium
owner: executor
depends_on:
  - TASK-0098
branch: task/TASK-0100-MathShow-Group-Join-And-Watching-Banner
related:
  - "[[GAME-004 MathShow/00 Overview]]"
  - "[[TASK-0098-MathShow-Menu-Shell]]"
created: 2026-10-26
updated: 2026-10-26
tags:
  - workflow/task
---

# MathShow Group Join And Watching Banner

## Goal
Make JOIN SHOW real on the server: players opt in to the Group Battle match, late joiners watch and join the next one (screen 10).

## Scope
- **In:** see the acceptance criteria; handoff `Game_spec_UI2elements.zip` (README, RULES_SPEC, ENGINEERING_NEEDS) and `MENU_TEXT_FIT_AUDIT.md` are the spec.
- **Out (non-goals):** work belonging to the other follow-up tasks; GAME-001..003.
- **Keep unchanged:** server authority (validate type, range, ownership, rate limit); the existing match flow unless this task says so.

## Intake
- **Category → workflow, depth:** UI + server, deep tier. Deep: Opus audit.
- **References:** `10 References/01 UI` (adapt, not copy); menu patterns from [[TASK-0098-MathShow-Menu-Shell]] (Shard, Fx, Preview, TextFit gate).
- **Decisions / assumptions:** Group cap 6 (copy says UP TO 6 PLAYERS), default confirmed. Menu hides without joining only via JOIN SHOW.
- **Plan status:** proposed 2026-10-26 from the TASK-0098 follow-up list; jg asked for all follow-ups to be built (2026-10-26).

## Files expected to change
- `games/mathshow/src/{server,shared,client}`, `games/mathshow/tests`, this note, `tasks/queue.json`.

## Acceptance criteria
- [ ] AC1 Server tracks joined players per match; only joined players can submit, score and appear in standings; a new `JoinShow` remote is validated and rate limited, and the match loop still runs with zero joiners.
- [ ] AC2 A player pressing JOIN SHOW mid-match sees the WATCHING banner (`banner-violet`, HUD question layout without the answer row) until the next Intermission, then plays.
- [ ] AC3 RoundService changes keep every existing spec green; pure join rules live in `shared/` with boundary specs; Studio 1-player run shows full cycle.
- [ ] AC4 Opus audit (networking, remotes).

## Tests
- **Automated:** `scripts/check.sh` (baseline: MathShow 134 specs).
- **Studio playtest procedure:** `scripts/studio-preflight.sh --game mathshow`; fresh Play session; TextFit gate for new states; 2-client run where the task says so.

## Risks / notes
- Depends on the tasks listed above; do not start before they are done.

---
## Implementation record

## Audits

## Outcome
