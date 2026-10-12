---
id: TASK-0032
title: Retaliation Hardening
type: task
project: GAME-002
status: in_progress
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
*(Executor: files changed, decisions, check output)*

## Audits
*(links to AUD- notes)*

## Outcome
*(after merge: result, lessons, follow-ups)*
