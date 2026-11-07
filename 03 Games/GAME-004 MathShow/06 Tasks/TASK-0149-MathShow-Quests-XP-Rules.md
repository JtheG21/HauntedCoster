---
id: TASK-0149
title: "MathShow Quests XP Rules"
type: task
project: GAME-004
status: review
priority: medium
risk: low
owner: executor
depends_on: []
branch: task/TASK-0149-quests-xp-rules
related:
  - "[[SYS-Quests-And-XP]]"
created: 2026-11-07
updated: 2026-11-07
tags:
  - workflow/task
---

# MathShow Quests XP Rules

## Goal
Pure rules, config and specs for XP levels, the daily cap and quest selection and progress. Design: [[SYS-Quests-And-XP]].

## Scope
- **In:** as in the brief's Tasks table.
- **Out (non-goals):** anything under "Out of scope" in the brief.

## Intake
- **Decisions:** Backlog; waiting for the Codex design review of SYS-Quests-And-XP and jg's plan rows. No plan approval yet. Registered by row QX-D1 (jg, 2026-11-07).

## Acceptance criteria
- [ ] AC1 See `tasks/items/TASK-0149.json`.

## Implementation record
- Approved by row QX-T1 (jg). Pure modules `XpConfig`, `XpRules`, `LevelRewards`, `QuestConfig`, `QuestRules` plus `XpRules.spec` and `QuestRules.spec`; `check.sh` ALL PASSED, Lune specs 403 -> 432.
- Choices the brief left open (flag for review): `rollover(board, newDay, userId)` takes `userId` because the fresh board needs it; it returns `(xp, board)`. `validate(stored)` takes the whole daily state `{dailyEpoch, playXpDay, quests}` and also requires `playXpDay.amount` in 0..400. `boardFor` returns nil for an invalid input or unknown catalog. `xpIntoLevel` is 0 at level 50. Colours are plain RGB (no Color3). A claimed slot must be complete, and `bonusGranted` needs three complete slots, or `validate` says invalid.
- `owner_agent` in the task JSON still says codex; implemented by Claude on jg's instruction.

## Audits

## Outcome
