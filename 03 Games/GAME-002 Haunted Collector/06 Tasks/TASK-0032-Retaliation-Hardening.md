---
id: TASK-0032
title: Retaliation Hardening
type: task
project: GAME-002
status: done
priority: medium
risk: medium
owner: executor
milestone: M3
depends_on:
  - TASK-0031
branch: task/TASK-0032-Retaliation-Hardening
created: 2026-10-12
updated: 2026-10-12
tags:
  - workflow/task
  - milestone/m3
related:
  - "[[TASK-0031-Failed-Capture-Retaliation]]"
  - "[[AUD-20261012-TASK-0031-01]]"
  - "[[SYS-Haunted-Capture-Loop]]"
  - "[[ADR-0007-World-Retrofit-Direction]]"
---
# TASK-0032: Retaliation Hardening

## Goal
Close the follow-ups from [[AUD-20261012-TASK-0031-01]]: retaliation must survive a runtime error without leaving monsters stuck in `pursuing`, a failed capture must not leave the survivor one miss from retaliating again, and the scenario must prove containment and the death ending for real.

## Scope
- **In:**
  - `RetaliationService`: run the tick under `pcall`; on error, `warn` and `finish` every pursuit (the pattern of `RotationService.swap` in TASK-0029 revision 1).
  - `CaptureService.onFled`: `pcall` each fled handler so an error still reaches the "slipped away" fallback; clear `e.progress[player]` on fled (jg's answer, 2026-10-12).
  - `EncounterService.setPursuing(nil)`: comment the assumption behind re-enabling Inspect.
  - `tests/scenarios/Retaliation.luau`: containment just outside the hub edge within the give-up distance; a death ending.
- **Out:** tuning numbers (still "needs jg" from TASK-0031), client ragdoll changes, new behaviour.

## Files expected to change
- `games/haunted/src/server/Services/RetaliationService.luau`
- `games/haunted/src/server/Services/CaptureService.luau`
- `games/haunted/src/server/Services/EncounterService.luau`
- `games/haunted/tests/scenarios/Retaliation.luau`

## Acceptance criteria
- [ ] AC1: An error inside the retaliation tick is caught and warned; every pursuit is finished (pursuers roam and can be inspected again) and the loop keeps running.
- [ ] AC2: An erroring `onFled` handler is caught and warned, and the fled monster still falls back to the slipped-away removal unless a handler took it.
- [ ] AC3: A fled capture clears that player's saved counters on the monster, so a retry on a monster that retaliated starts at 0 hits and 0 misses (jg, 2026-10-12).
- [ ] AC4: The Retaliation scenario checks containment with the player just outside the hub edge and within the give-up distance (pursuit still running, pursuers inside the habitat footprint), and a death ending (Health 0 → `pursuersOf` empty).
- [ ] AC5: The Inspect re-enable assumption in `setPursuing(nil)` is commented. Retaliation, FullLoop and ExploitProbe pass; `scripts/check.sh` passes.

## Tests
- **Automated:** `scripts/check.sh` (specs, StyLua, selene, typecheck, vault).
- **Studio playtest procedure:** fresh Play session on `HauntedCollector.rbxl` with `rojo serve haunted.project.json`; run the `Retaliation`, `FullLoop` and `ExploitProbe` scenarios (`_G.scnRun` / `_G.scnChain`). The Retaliation scenario also injects one tick error through a test hook and checks the pursuit is finished.

## Risks / notes
- References: none new; this hardens TASK-0031 code. The fix pattern is TASK-0029 revision 1 (`RotationService.swap`).
- Plan approved by jg in chat on 2026-10-12 ("Approve, start"), together with the answer "Clear on fled" to audit finding 2.

---
## Implementation record
- **References used:** none new. The recovery pattern is `RotationService.swap` (TASK-0029 revision 1).
- **Built:**
  - `RetaliationService`: the tick runs under `pcall`. On error, `abandonAll` warns, empties the pursuit table and releases every pursuer (each release under its own `pcall`), and the loop carries on. Test hooks: `failNextTickForTest`, `tickErrorCount`.
  - `CaptureService.onFled`: clears `e.progress[player]` (jg: "Clear on fled", 2026-10-12) and runs each fled handler under `pcall`. A handler that errors is warned and doesn't count as taking the monster, so the "slipped away" fallback still runs.
  - `EncounterService.setPursuing(nil)`: a comment on why re-enabling Inspect unconditionally is safe today.
  - `Retaliation` scenario: checks the cleared counters (on fled, and a retry starting at 0/0), containment on the ring road just past the wall (pursuit still running, pursuers within the 112-stud footprint), the tick-error recovery, a pursuit starting after the error, and a death ending.
- **Studio sync note:** the running Rojo server serves the main checkout, so the four changed sources were written into Studio's Edit model through MCP (byte counts checked against the worktree). Studio still holds these sources (unsaved); Rojo resyncs from disk on reconnect.
- **Checks:** `scripts/check.sh` passes (specs 96/0). Retaliation 31/31 (run 2, after seeding saved counters so the counter checks can fail), FullLoop 85/85, ExploitProbe 13/13 ([[TEST-20261012-08]]).

## Audits
- [[AUD-20261012-TASK-0032-01]]: pass (2 minor, 4 nit).

## Outcome
- **Merge** approved by jg in chat on 2026-10-12 ("merge it and do the post-merge notes"). Merged through PR #26.
- **Result:** a retaliation tick error is caught and every pursuit ends cleanly. A failing `onFled` handler still lets the monster slip away. A monster that retaliated forgets the player's counters. The scenario now proves edge containment, tick-error recovery and the death ending.
- **Follow-ups** (from [[AUD-20261012-TASK-0032-01]]):
  - `RetaliationService.begin`: a mid-loop error can leave extra pursuers flagged `pursuing` with no pursuit record. Create the record first, or release the monsters already set on error.
  - Optional: a spec or scenario with a throwing `onFled` handler.
- **Still needs jg (from TASK-0031):** the feel of the numbers (8 s, 13.5 studs/s, 1.5 s knockdown, 3 s grace).
