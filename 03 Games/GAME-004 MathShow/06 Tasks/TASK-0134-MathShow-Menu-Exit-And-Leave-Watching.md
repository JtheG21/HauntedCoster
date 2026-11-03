---
id: TASK-0134
title: "MathShow Menu Exit And Leave Watching"
type: task
project: GAME-004
status: in_progress
priority: high
risk: low
owner: claude-code
depends_on: []
branch: task/TASK-0134-menu-exit
related: []
created: 2026-11-03
updated: 2026-11-03
tags:
  - workflow/task
---

# MathShow Menu Exit And Leave Watching

## Goal
jg's iPad playtest (TASK-0123) found a dead end: the main menu has no exit except JOIN SHOW, and a mid-match joiner is stuck on the WATCHING banner. Add a CLOSE button on the main menu and a LEAVE button on the banner.

## Scope
- **In:** Menu (CLOSE on main, Esc/B on main), Watching (LEAVE), new `LeaveShow` remote, `RoundService` handler, Hud receives the result through the existing `ShowState`.
- **Out:** new art (buttons reuse `shard-menu-secondary-silver`), a LEAVE for a player who is a participant or in Intermission, reopening the main menu from the plaza, Studio/Rojo runs (TASK-0123 playtest is using Studio).

## Intake
- **Category, depth:** UI plus a small systems change, standard. References: `10 References/01 UI` (REF-UI-001..004) were checked for exit/close affordances; the menu's own BACK shard is reused so the look stays consistent. Reuse: `backButton`, `JoinRules`, the JoinShow rate limit.
- **Decisions (assumptions, reversible):** closing the main menu is client-only (the server never learned of the player). LEAVE clears `joined` and `participant` on the server; a participant can technically send it, but only watchers get the button. Re-joining stays through the Play pad, Group Battle.

## Remote change (sender, handler, receiver)
- Sender: `Menu/init.luau` (CLOSE, LEAVE) fires `LeaveShow` with no payload.
- Handler: `RoundService.onLeave` (validated by `JoinRules.validLeave`, shares the JoinShow rate limit).
- Receiver: `Hud` already consumes `ShowState {joined=false, participant=false}` and hides the banner; the client also calls `Hud.setVisible(false)`.

## Acceptance criteria
See `tasks/items/TASK-0134.json`.

---
## Implementation record

## Audits

## Outcome
