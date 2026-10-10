---
id: RETRO-M0-Workflow-Foundation
title: "M0: Workflow Foundation"
type: retro
project: GAME-001
status: done
milestone: M0
created: 2026-10-10
updated: 2026-10-10
tags:
  - workflow/retro
---
# Retrospective: M0, workflow foundation

## Goal of the milestone
A safe, low-cost AI workflow with human gates, proven by one real task.

## Outcome
| Planned | Result |
|---|---|
| Environment audit + structure | ✅ |
| Roles, workflow, budget policy | ✅ ([[Workflow]]) |
| Orchestrator (dry-run) + tests | ✅ 15 Python tests |
| Rojo ↔ Studio sync | ✅ after fixing a version mismatch ([[LES-0001-Rojo-Version-Mismatch]]) |
| One task end to end | ✅ [[TASK-0001-Collectible-Pickup]], audit pass on attempt 1 |
| Obsidian conventions | ✅ [[Obsidian Conventions]] |

## What went well
- Cheap checks (format, lint, types, build) caught type problems before any AI review.
- Studio MCP made the playtest reproducible without a human at the keyboard.
- The independent fresh-context audit found real gaps the executor missed: exploit limits, and a check that skips but still reports PASS.

## What went badly
- The merge was approved before the 2-player test ran. That gate wasn't enforced.
- The first layout had to be migrated to the numbered vault conventions (a one-time cost).

## Usage & cost
- API: $0.00. Subscription only. The audit subagent used about 75k tokens. The main session's usage wasn't measured.

## Changes to adopt
- Add the 2-player playtest to the merge checklist when a task touches shared state.
- [[LES-0002-Typed-Test-Context]]
