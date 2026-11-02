---
id: TASK-0122
title: "MathShow Hub Mode Pads"
type: task
project: GAME-004
status: in_progress
priority: medium
risk: low
owner: claude-code
depends_on: []
branch: task/TASK-0122-mode-pads
related:
  - "[[TASK-0120-MathShow-Hub-Graybox]]"
created: 2026-11-02
updated: 2026-11-02
tags:
  - workflow/task
---

# MathShow Hub Mode Pads

## Goal
Walking onto a ModePad in Workspace.Hub opens that mode's menu screen on the client, once per entry, with no retrigger while standing.

## Scope
- **In:** ModePadConfig, ModePadRules (pure), ModePadService (server poll), ModePadOpen remote, ModePadController (client), a minimal client-only `Menu.open(screen)`.
- **Out (non-goals):** art, lamps, Leaderboard hall interior, Daily Challenge feature, matchmaking changes, DataStore, publishing, merging.
- **Keep unchanged:** `shared/Glyph*`, the map (`games/mathshow/map/`).

## Intake
- **Category, depth:** systems, standard.
- **References:** none relevant in `10 References/` (server poll plus pure rules follows the repo service pattern).
- **Reuse:** adapt the existing service shape (`start()` idempotent, frozen Config, pure Rules plus spec) and the menu's `go()` screens.
- **Decision (jg, 2026-11-02):** valid modes come only from the ModePadConfig Modes map; "locked:" screens show the existing coming-soon toast.

## Files expected to change
See `files_owned` in `tasks/items/TASK-0122.json`.

## Acceptance criteria
- [x] AC1 Spec passes headless (326 passed, also in Studio Play).
- [ ] AC2 (partly proven) Studio steps 1-6 recorded in `docs/workflow/evidence/TASK-0122/mode-pads.txt`: 1-4 and 6 pass; step 5 (two players) unverified; Glyph collection not exercised (no Glyph service on this base); screenshots at 1336x669 for 2 of 6 pads, not 844x390.
- [ ] AC3 check.sh and validators green; PR open, CI green, not merged.

## Tests
- **Automated:** `scripts/check.sh`, `ModePadRules.spec`.
- **Studio:** one round, steps 1-6 from the approved rows.

## Risks / notes
Remote change rule: ModePadOpen sender ModePadService.luau, handler none (server to client), receiver ModePadController.luau.

---
## Implementation record
- Added `ModePadConfig`, `ModePadRules` (+ spec), `ModePadService` (one 0.25 s poll, pcall-wrapped, no yields in the body), the `ModePadOpen` remote (Net, Remotes), `client/Hub/ModePadController` and `Menu.open(screen)` / `Menu.isOpen()`.
- Menu change: the input binding moved into `bindInput` so `Menu.open` can rebind after `Menu.hide`; Back from a pad-opened screen closes the menu (identity check on the stack table) instead of showing the main menu.
- The Daily toast uses a small overlay View (same pattern as Watching) because the menu ScreenGui is disabled when closed.
- Remote change rule: ModePadOpen sender ModePadService, receiver ModePadController; no handler, no client to server remote.
- Revision 1 (jg, after [[AUD-20261102-TASK-0122-01]]): pad state is keyed by character, so a respawn between two polls counts as an entry. Studio recheck at 0eca0d9: Blitz regression and respawn-onto-pad both pass. The mid-match pad (second minor) is left as is: no criterion, needs jg's intent.
- Evidence: `docs/workflow/evidence/TASK-0122/mode-pads.txt`. check.sh green at bb28ee8.

## Audits

## Outcome
