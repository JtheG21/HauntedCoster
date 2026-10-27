---
id: TASK-0101
title: "MathShow Practice Home, Skill Test Intro And Rank Ladder"
type: task
project: GAME-004
status: proposed
priority: medium
risk: medium
owner: executor
depends_on:
  - TASK-0099
branch: task/TASK-0101-MathShow-Practice-Home-Skill-Test-Intro-And-Rank-Ladder
related:
  - "[[GAME-004 MathShow/00 Overview]]"
  - "[[TASK-0098-MathShow-Menu-Shell]]"
created: 2026-10-26
updated: 2026-10-26
tags:
  - workflow/task
---

# MathShow Practice Home, Skill Test Intro And Rank Ladder

## Goal
Screens 11 (Practice home, cooldown, 19a rank unavailable), 12 (Skill Test intro, first time), 16 (rank ladder) and the `badgeSlam` Fx, driven by the profile.

## Scope
- **In:** see the acceptance criteria; handoff `Game_spec_UI2elements.zip` (README, RULES_SPEC, ENGINEERING_NEEDS) and `MENU_TEXT_FIT_AUDIT.md` are the spec.
- **Out (non-goals):** work belonging to the other follow-up tasks; GAME-001..003.
- **Keep unchanged:** server authority (validate type, range, ownership, rate limit); the existing match flow unless this task says so.

## Intake
- **Category → workflow, depth:** UI + server, standard tier. Standard: one Sonnet audit.
- **References:** `10 References/01 UI` (adapt, not copy); menu patterns from [[TASK-0098-MathShow-Menu-Shell]] (Shard, Fx, Preview, TextFit gate).
- **Decisions / assumptions:** Skill Test start leads to TASK-0102 (button disabled until it ships).
- **Plan status:** proposed 2026-10-26 from the TASK-0098 follow-up list; jg asked for all follow-ups to be built (2026-10-26).

## Files expected to change
- `games/mathshow/src/{server,shared,client}`, `games/mathshow/tests`, this note, `tasks/queue.json`.

## Acceptance criteria
- [ ] AC1 PRACTICE opens Practice home; TAKE TEST shows the retake countdown from `CooldownRules`; TOPIC DRILLS locked; RETRY re-requests the profile; ladder shows current/cleared/locked via `RankRules.ladderMark`.
- [ ] AC2 `Fx.badgeSlam` added (pcall-isolated, no yield, reduced-motion snap); Preview states and TextFit gate cover every new state with 0 failures.
- [ ] AC3 Specs for any new pure logic; check.sh green; screenshots compared.

## Tests
- **Automated:** `scripts/check.sh` (baseline: MathShow 134 specs).
- **Studio playtest procedure:** `scripts/studio-preflight.sh --game mathshow`; fresh Play session; TextFit gate for new states; 2-client run where the task says so.

## Risks / notes
- Depends on the tasks listed above; do not start before they are done.

---
## Implementation record

## Audits

## Outcome
