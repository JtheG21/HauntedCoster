---
id: TASK-0137
title: "MathShow Pad Prompt Dismiss On Leave"
type: task
project: GAME-004
status: done
priority: medium
risk: low
owner: claude-code
depends_on: []
branch: task/TASK-0137-pad-prompt-dismiss
related: []
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
- `ModePadRules.left`, `ModePadLeave` remote (sender `ModePadService`, `Net`/`Remotes`, receiver `ModePadController`), `Menu.closePadScreen`, `View.hideToast`; spec extended (348 specs).
- Studio: `docs/workflow/evidence/TASK-0137/pad-leave.txt` (plain path): leave closes the pad screen and the locked toast, entry opens once, a VS matchmaking screen is not closed.

## Audits
- [[AUD-20261103-TASK-0137-01]]: pass. Two narrow minor races accepted (see the note); both nits fixed after the audit.

## Outcome (2026-11-03)
- Walking off a hub mode pad now closes its menu screen or the locked:daily toast via the new `ModePadLeave` remote; entry still opens once, and a screen the player navigated into (VS matchmaking) is left alone. PR 200, merge approved by jg.
- Evidence: `docs/workflow/evidence/TASK-0137/pad-leave.txt`; audit [[AUD-20261103-TASK-0137-01]] pass; check.sh green (348 specs).
- Known, accepted: walking off in the instant between clicking START or FIND OPPONENT and the server's reply can close the screen; stepping straight onto an adjacent pad can lose its prompt (re-enter fixes it). Follow-up only if playtests show it.
