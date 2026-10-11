---
id: LES-0005
title: Edit Mode Require Cache
type: lesson
status: approved
category: bug-pattern
evidence:
  - "2026-10-10: after Rojo synced 3 new FactionRules specs, Edit-mode TestRunner reported 28/0 twice (stale); a fresh Play server data model reported 31/0"
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

## Where this applies
All `tests/luau` runs, and any Edit-mode `execute_luau` that requires project modules after they changed.
