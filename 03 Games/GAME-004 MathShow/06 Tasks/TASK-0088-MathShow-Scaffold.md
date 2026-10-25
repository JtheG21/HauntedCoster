---
id: TASK-0088
title: "MathShow Scaffold"
type: task
project: GAME-004
status: approved
priority: medium
risk: low
owner: executor
depends_on: []
branch: task/TASK-0088-MathShow-Scaffold
related:
  - "[[GAME-004 MathShow/00 Overview]]"
created: 2026-10-25
updated: 2026-10-25
tags:
  - workflow/task
---

# MathShow Scaffold

## Goal
Stand up the folder, bootstrap scripts and test runner for GAME-004 so later slice tasks have a working `scripts/check.sh` pass to build on.

## Scope
- **In:** `games/mathshow/src/server|shared|client` folders, bootstrap server/client scripts, a TestRunner the lune specs can require, confirming `mathshow.project.json` syncs cleanly.
- **Out (non-goals):** any gameplay module (ProblemRules, ScoringRules, RoundRules, RoundService, Hud, Scores) — those are separate tasks.
- **Keep unchanged:** `games/haunted`, `games/hike-or-die`, `src/`.

## Intake
- **Category → workflow, depth:** Systems, mechanics, pipelines → [[Systems Workflow]], light.
- **References:** none relevant in `10 References/`; see `games/hike-or-die/` as a recent same-shape precedent for an isolated game root.
- **Reuse:** `scripts/new-service.sh` scaffolds a Service/Config/Rules/spec quartet; check its spec template against how `check.sh` actually discovers lune specs before relying on it (see Risks).
- **Decisions / assumptions / open questions:** Open question — does `scripts/new-service.sh`'s generated spec path/require pattern match what `check.sh` runs? Resolve this before writing any other MathShow spec.

## Files expected to change
- `games/mathshow/src/server/Main.server.luau` (or equivalent bootstrap)
- `games/mathshow/src/shared/`, `games/mathshow/src/client/` (empty/placeholder structure)
- `games/mathshow/tests/` (TestRunner wiring)
- `scripts/new-service.sh` (only if the spec template needs fixing to match check.sh)

## Acceptance criteria
- [x] AC1 `mathshow.project.json` syncs via Rojo without errors. Evidence: `rojo build mathshow.project.json` below.
- [x] AC2 `scripts/check.sh` passes with zero MathShow specs. Evidence: `scripts/check.sh` run below.
- [x] AC3 `scripts/new-service.sh`'s spec template is confirmed to match (or fixed to match) how `check.sh` finds and runs lune specs. Evidence: see Implementation record — the template itself was fine; `scripts/lune/specs.luau` was the actual mismatch (hardcoded to GAME-002 only) and is fixed.

## Tests
- **Automated:** `scripts/check.sh`
- **Studio playtest procedure:**
  1. `rojo serve mathshow.project.json`; confirm Studio syncs the empty game tree without errors.

## Risks / notes
`scripts/new-service.sh` generates specs as `tests/<Name>Rules.spec.luau` using `require(script.Parent.TestRunner)` / `TestRunner.T`, but `check.sh` runs lune specs the way `games/hike-or-die/tests/lune/*.spec.luau` does. Compare the two directly; fix the template here if they diverge, per the Overview's "Known risk."

---
## Implementation record
**Files changed:**
- `games/mathshow/src/server/init.server.luau` — bootstrap entry (prints ready; comment marks where TASK-0092 wires RoundService).
- `games/mathshow/src/client/init.client.luau` — bootstrap entry (prints ready; comment marks where TASK-0093 wires Hud).
- `games/mathshow/tests/TestRunner.luau` — same contract as `games/haunted/tests/TestRunner.luau`.
- `scripts/lune/specs.luau` — the real fix. Generalized from a single hardcoded GAME-002 `MOUNTS` table to a `GAMES` list (`HauntedCollector`, `MathShow`), looping the DataModel build and spec discovery/run per game, skipping a game whose `shared`/`tests` dirs don't exist yet. Totals are summed and printed per-game and overall; `process.exit` now reads the summed totals.
- `scripts/check.sh` — added `mathshow.project.json` to the Rojo build and JSON-validity steps, added `games/mathshow` to StyLua/Selene, renamed the Lune step label (no longer GAME-002-only).
- `scripts/typecheck.sh` — added a GAME-004 sourcemap + luau-lsp analyze pass, mirroring the GAME-002 block.
- `.gitignore` — ignored `MathShow.rbxl(.lock)` and the new `game004-sourcemap.json`, matching the GAME-002 entries.

**Decision (assumption, reversible):** `new-service.sh`'s generated spec (`require(script.Parent.TestRunner)`) was never actually broken — `TestRunner.luau` sits beside each generated spec in the same mounted tests folder, so the headless require resolves fine once that file exists. Verified by running `scripts/new-service.sh mathshow Problem`, confirming the generated spec loads with 0 failures under the fixed harness, then deleting the probe files (ProblemRules/ProblemService/etc. are TASK-0089's job, not Scaffold's). The actual mismatch was `scripts/lune/specs.luau` itself being hardcoded to GAME-002 only, so no MathShow spec — however written — would ever run under `check.sh`. Fixed that instead of the template.

**Check output:**
```
rojo build mathshow.project.json -o /tmp/mathshow-check.rbxl
Building project 'MathShow'
Built project to mathshow-check.rbxl

lune run scripts/lune/specs
[lune specs] HauntedCollector: 265 passed, 0 failed
[lune specs] MathShow: 0 passed, 0 failed
[lune specs] 265 passed, 0 failed

scripts/check.sh: ALL CHECKS PASSED (StyLua, Selene, Lune specs, 3x Rojo build, JSON, task queue, vault, refs lint, skills, 163 Python tests)
```

## Audits
Light tier — relies on green `check.sh` (`04 Agents/Task Intake.md` depth tiers); no audit subagent.

## Outcome
Scaffold complete. GAME-004 has a working `games/mathshow/src/{server,client}` + `tests/TestRunner.luau`, and — more importantly — `scripts/lune/specs.luau` now runs any game's specs, not just GAME-002's, so TASK-0089 onward can add real `*.spec.luau` files and have `check.sh` actually run them. Studio sync (`rojo serve mathshow.project.json`) not yet verified in this session; do that before or during TASK-0089.
