---
id: TASK-0134
title: "MathShow Menu Exit And Leave Watching"
type: task
project: GAME-004
status: approved
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
- Sender: `Menu.leaveShow` (the LEAVE button only) fires `LeaveShow` with no payload. CLOSE is client-only and sends nothing.
- Handler: `RoundService.onLeave` (validated by `JoinRules.validLeave`; synchronously debounced: a repeat leave sees both flags false and returns. It does not use the JoinShow rate limiter).
- Receiver: `Hud` already consumes `ShowState {joined=false, participant=false}` and hides the banner; the client also calls `Hud.setVisible(false)`.

## Acceptance criteria
See `tasks/items/TASK-0134.json`.

---
## Implementation record
- Client: `View.backButton` takes an optional box; CLOSE (`Layout.Close`, top right of main) and LEAVE (`Layout.WatchLeave`, under the banner since revision 1) reuse it and `handlers.back`. `Menu.back()` closes the menu on main; Esc/B now works on main. `Menu.leaveShow()` fires `LeaveShow`, hides the menu, `onLeave` hides HUD and banner. `Watching.start({onLeave})`.
- Shared/server: `Net.LeaveShow`, `Remotes.LeaveShow`, `JoinRules.validLeave/leaveChanges` (specs in `JoinRules.spec.luau`), `RoundService.onLeave`. No rate limit on purpose: a repeat leave is a no-op and a dropped leave would admit an invisible player.
- Revision 1 (audit F1 to F4): LEAVE moved to (110, 332) under the banner, out of the jump zone; `JoinRules.afterLeave` added and used by `onLeave`; TextFit ledger now 682 + 297 = 979 (`LedgerRules`, `LedgerRules.spec`); leave-rejoin specs added. Evidence: `docs/workflow/evidence/TASK-0134/gate.txt`.

## Audits

## Outcome
- [x] `scripts/check.sh` green (347 specs).
- [x] TextFit gate at c2c6f3f: 0 failures, 5 viewports, LEAVE target 112x48 clear of the jump zone (evidence file).
- [x] jg confirmed the fix on the iPad at build 81d21fc (LEAVE was beside the banner then); the moved LEAVE position is Studio-gate verified only, not seen on a device (applies_to in the evidence file).
