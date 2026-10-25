---
id: GAME-004
title: MathShow Overview
type: overview
project: GAME-004
status: proposed
created: 2026-10-25
updated: 2026-10-25
tags:
  - game/overview
---
# GAME-004: MathShow

**Phase:** Intake. **This is the studio's active game** (jg, 2026-10-25); GAME-003 Hike or Die is paused, GAME-002 Haunted Collector and GAME-001 Rg1 remain source material.

**Pitch:** a timed math gameshow. Everyone answers the same question at once by typing a number; correct answers earn base points plus a speed bonus; difficulty ramps by question index. Full design: [[games/mathshow/DESIGN|MathShow Design]] (`games/mathshow/DESIGN.md`).

**Code:** `games/mathshow/src/server|shared|client` and `games/mathshow/tests`, synced by `mathshow.project.json` into `MathShow.rbxl`. Scaffolding script `scripts/new-service.sh` stamps a Service/Config/Rules/spec quartet per module.

## Project profile
- **Status and phase:** Candidate vertical slice in progress. TASK-0088–0092 are done (scaffold, ProblemRules, ScoringRules,
  RoundRules, RoundService: a full server match loop, playtested in [[TEST-20261025-01]]); next is TASK-0093 Hud.
- **Player cap:** not yet decided; the slice assumes a shared lobby of players answering simultaneously.
- **Validation:** `scripts/check.sh` (lune specs); `mathshow.project.json` currently maps `tests` → TestService, which may need to change if lune specs end up living outside the place (flagged for the Scaffold task).
- **Known risk (flagged at intake, not fixed):** `scripts/new-service.sh` generates specs as `tests/<Name>Rules.spec.luau` using `require(script.Parent.TestRunner)` / `TestRunner.T`, but `check.sh` runs lune specs the way `games/hike-or-die/tests/lune/*.spec.luau` does. Compare the two before the Scaffold task (TASK-0088) and fix the template there if they don't match.
- **Numbering fix at intake:** the MathShow setup branch was authored as GAME-003 before Hike or Die (also GAME-003, merged via PR #120) landed on `main`. Renumbered to GAME-004 throughout (`AGENTS.md`, `games/mathshow/DESIGN.md`, this note, `tasks/queue.json`) to resolve the collision.

## Tasks (queued, in dependency order)
| Task | Title | Depends on |
|---|---|---|
| [[TASK-0088-MathShow-Scaffold]] | Scaffold | — |
| [[TASK-0089-MathShow-ProblemRules]] | ProblemRules | TASK-0088 |
| [[TASK-0090-MathShow-ScoringRules]] | ScoringRules | TASK-0088 |
| [[TASK-0091-MathShow-RoundRules]] | RoundRules | TASK-0088 |
| [[TASK-0092-MathShow-RoundService]] | RoundService | TASK-0089, TASK-0090, TASK-0091 |
| [[TASK-0093-MathShow-Hud]] | Hud | TASK-0092 |
| [[TASK-0094-MathShow-Scores]] | Scores | TASK-0092 |
| [[TASK-0095-MathShow-TwoPlayer-Test]] | 2-player test | TASK-0093, TASK-0094 |

[[games/mathshow/DESIGN|MathShow Design]]
