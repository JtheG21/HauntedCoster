---
id: TASK-0088
title: "MathShow Scaffold"
type: task
project: GAME-004
status: proposed
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
- [ ] AC1 `mathshow.project.json` syncs via Rojo without errors.
- [ ] AC2 `scripts/check.sh` passes with zero MathShow specs (or the first trivial spec, if one is added here).
- [ ] AC3 `scripts/new-service.sh`'s spec template is confirmed to match (or fixed to match) how `check.sh` finds and runs lune specs.

## Tests
- **Automated:** `scripts/check.sh`
- **Studio playtest procedure:**
  1. `rojo serve mathshow.project.json`; confirm Studio syncs the empty game tree without errors.

## Risks / notes
`scripts/new-service.sh` generates specs as `tests/<Name>Rules.spec.luau` using `require(script.Parent.TestRunner)` / `TestRunner.T`, but `check.sh` runs lune specs the way `games/hike-or-die/tests/lune/*.spec.luau` does. Compare the two directly; fix the template here if they diverge, per the Overview's "Known risk."

---
## Implementation record

## Audits

## Outcome
