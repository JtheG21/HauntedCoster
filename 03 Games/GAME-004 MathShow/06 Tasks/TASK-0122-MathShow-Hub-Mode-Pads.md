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
- [ ] AC1 Spec passes headless.
- [ ] AC2 Studio steps 1-6 recorded in `docs/workflow/evidence/TASK-0122/mode-pads.txt`.
- [ ] AC3 check.sh and validators green; PR open, CI green, not merged.

## Tests
- **Automated:** `scripts/check.sh`, `ModePadRules.spec`.
- **Studio:** one round, steps 1-6 from the approved rows.

## Risks / notes
Remote change rule: ModePadOpen sender ModePadService.luau, handler none (server to client), receiver ModePadController.luau.

---
## Implementation record

## Audits

## Outcome
