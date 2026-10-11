---
id: LES-0005
title: Edit Mode Require Cache
type: lesson
status: approved
category: bug-pattern
evidence:
  - "2026-10-10: after Rojo synced 3 new FactionRules specs, Edit-mode TestRunner reported 28/0 twice (stale); a fresh Play server data model reported 31/0"
  - "2026-10-10 (TASK-0007 rev 1): during a live Finale, FinaleService required through MCP execute_luau (Server data model) reported isActive=false while the game had begun the finale and eliminated the player; the in-game FinaleRingOut scenario saw the real state"
applies_to:
  - tests/luau
  - Studio MCP execute_luau
created: 2026-10-10
updated: 2026-10-10
tags:
  - knowledge/lesson
---
# Edit-mode `require` returns stale module versions

## Problem
Luau spec counts didn't change after Rojo synced new tests. They reported the old count as passing.

## Root cause
In Studio Edit mode, a ModuleScript that's already been required in the session keeps returning its first-loaded result, even after its Source changes. Running specs from the Edit data model reuses those cached modules.

## Solution
Run Luau specs in a **fresh Play (or Run) session**, in the Server data model: `require(game.TestService.Tests.TestRunner).run()`. Edit-mode results are valid only the first time a module is loaded.

## Validation
The same code reported 28/0 in Edit mode and **31/0** in a fresh Play session ([[TEST-20261010-07]]).

## Related: MCP code gets its own module instances
Even in a Play session, a module required from MCP `execute_luau` is a **separate instance** from the one the game's scripts use, so its state is empty: it read `FinaleService.isActive() == false` mid-finale ([[TEST-20261010-11]]). Pure modules (specs) are fine. To check live service state, read the attributes the services publish, or run the check inside the game as a multi-client scenario (`StudioTestHook` requires it from game context).

## Where this applies
All `tests/luau` runs, and any Edit-mode `execute_luau` that requires project modules after they changed.
