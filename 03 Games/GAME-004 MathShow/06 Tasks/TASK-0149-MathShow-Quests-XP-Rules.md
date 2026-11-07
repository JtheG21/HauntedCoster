---
id: TASK-0149
title: "MathShow Quests XP Rules"
type: task
project: GAME-004
status: done
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

### Revision 1 (AUD-20261107-TASK-0149-01, Codex FAIL)
- F1: `boardValid` requires exactly the integer keys 1..SlotCount (counted with pairs); settlement, claim, bonus, applyProgress and copyBoard loop 1..SlotCount only. F2: slots must be one easy, one medium, one hard (categories fixed by position and checked against the catalog). F3: `xpIntoLevel` returns 0 for non-finite or negative xp (`xpForNextLevel` already used the normalised level).
- New specs `AUD-01 F1`, `AUD-01 F2` (QuestRules.spec) and `AUD-01 F3` (XpRules.spec). All three fail on 00bf9c8 (validate says ok on the extra-keyed and all-hard boards; xpIntoLevel(-5) returns -5) and pass now. `check.sh` ALL PASSED.

## Audits

## Outcome
