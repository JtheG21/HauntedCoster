---
id: TASK-0037
title: "Plot Capacity"
type: task
project: GAME-002
status: approved
priority: medium
risk: low
owner: executor
depends_on:
  - TASK-0036
branch: task/TASK-0037-Plot-Capacity
related:
  - "[[TASK-0036-Persistence-Load-Failure]]"
  - "[[TEST-20261012-15]]"
created: 2026-10-12
updated: 2026-10-12
tags:
  - workflow/task
---

# Plot Capacity

## Goal
Make sure every player on a server can get a home plot. There are 6 plots, but the place's Max Players was recorded nowhere, and nothing tested what happens to a 7th player. Covers AUDIT-002 and AUDIT-012 (T4 of the 2026-10-12 audit plan).

## Scope
- **In:** `World.MaxPlayers`, a pure `PlotRules.firstFree`, `PlotService` uses it, a live-server warning, specs, the architecture note.
- **Out:** more plots or a queue/spectator mode (a separate design task if ever wanted); changing the "no free plot" toast.

## Files expected to change
- `games/haunted/src/shared/Config/World.luau`, `games/haunted/src/shared/Rules/PlotRules.luau` (new), `games/haunted/src/server/Services/PlotService.luau`, `games/haunted/tests/PlotRules.spec.luau` (new), `02 Technical Architecture.md`

## Acceptance criteria
- [x] AC1 `World.MaxPlayers = 6` records the cap, and a spec ties it to the plot count (cap ≤ plots).
- [x] AC2 Plot assignment uses a pure `PlotRules.firstFree`. Specs cover six occupied plots plus a 7th player (no plot, nobody's plot taken) and reuse of a freed plot. A negative control fails them.
- [x] AC3 A live server warns if the place's Max Players exceeds the plots; Studio is not checked.
- [x] AC4 jg sets Max Players to 6 in Game Settings (recorded as done or pending). FullLoop and ExploitProbe pass; `scripts/check.sh` passes.

- Evidence for AC1–AC4: [[TEST-20261012-15]]; AC3 by code review (a live server can't run in Studio). Max Players 6 set by jg in Game Settings on 2026-10-12.

## Tests
- **Automated:** `scripts/check.sh` (4 new `PlotRules` specs).
- **Studio playtest procedure:** FullLoop and ExploitProbe in the unsaved `Place1` via Rojo.

## Risks / notes
- Approved in chat on 2026-10-12: jg chose to keep 6 plots with a cap of 6 ("start T4 with 6 players").
- Max Players is a place setting that Rojo doesn't sync, so jg sets it in Studio's Game Settings; the code only records and checks it.

---
## Implementation record
- Specs first: the new spec file failed to load (no `PlotRules`). Negative control: `firstFree` ignoring occupancy failed 3 of 4 specs; the cap spec passed, as it doesn't use the function. Real rule: 121 passed, 0 failed.
- `PlotService.assign` now takes `PlotRules.firstFree(owners, #plots)` (same lowest-free order as before). `PlotService.start` warns on a live server when `Players.MaxPlayers > #plots`.

## Audits
- [[AUD-20261012-TASK-0037-01]]: pass. Minor: the live warning is reviewed, not tested; the literal 6 in the cap spec is intentional; Max Players rests on jg's report.

## Outcome
