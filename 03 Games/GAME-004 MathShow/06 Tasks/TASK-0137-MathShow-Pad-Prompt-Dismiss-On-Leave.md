---
id: TASK-0137
title: "MathShow Pad Prompt Dismiss On Leave"
type: task
project: GAME-004
status: in_progress
priority: medium
risk: low
owner: claude-code
depends_on: []
branch: task/TASK-0137-pad-prompt-dismiss
related:
  - "[[TASK-0122]]"
created: 2026-11-03
updated: 2026-11-03
tags:
  - workflow/task
---

# MathShow Pad Prompt Dismiss On Leave

## Goal
A mode pad fires `ModePadOpen` once on arrival, but nothing closes the screen or toast when the player walks off, so the prompt lingers. Dismiss it as soon as the player leaves the pad.

## Scope
- **In:** `ModePadRules.step` leave flag, new `ModePadLeave` remote (sender, Net/Remotes, receiver), `Menu.closePadScreen`, toast hide, spec.
- **Out (non-goals):** pad geometry (TASK-0136), publishing, merging.
- **Keep unchanged:** enter trigger and cooldown, busy suppression of opens, all other menu behaviour.

## Intake
- **Category, depth:** gameplay UI, standard. References: none relevant.
- **Decisions:** plan approved by jg, 2026-11-03.
- **Remote change rule:** sender `ModePadService`, server side `Net`/`Remotes`, receiver `ModePadController`.

## Files expected to change
See `files_owned` in `tasks/items/TASK-0137.json`.

## Acceptance criteria
See the task file; ticked in the Outcome once measured.

## Tests
- **Automated:** `scripts/check.sh`, `ModePadRules.spec`.
- **Studio:** fresh Play; walk off pad closes screen, enter opens once, VS queue not closed.

---
## Implementation record

## Audits

## Outcome
