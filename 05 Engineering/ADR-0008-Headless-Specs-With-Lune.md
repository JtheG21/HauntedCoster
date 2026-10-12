---
id: ADR-0008
title: Headless Specs With Lune
type: adr
status: proposed
approved_by:
approved_on:
created: 2026-10-12
updated: 2026-10-12
tags:
  - workflow/decision
related:
  - "[[Luau Standards]]"
  - "[[ADR-0004-External-Skills-As-Toolbox]]"
---
# ADR-0008: Run GAME-002 unit specs headlessly with Lune, keeping instance requires

## Context
GAME-002 unit specs (`games/haunted/tests/*.spec.luau`) only ran in a Studio Play session, so CI checked format, lint, types and builds but never gameplay logic. The Rules and Config modules are pure apart from `Vector3`, `Color3` and `Random`, but they and the specs use Roblox instance requires (`require(script.Parent.Parent.Config.World)`, `game:GetService("ReplicatedStorage").Shared...`), which plain Lune can't resolve. Outside advice (2026-10-12) suggested switching every module to string requires. Reference: `dinoderek/rob` runs format, lint, analysis and tests through Lune (no licence, so studied, not copied).

## Options considered
1. **String requires everywhere.** Lune-native, but rewrites every Rules, Config and spec file and needs a Studio check that string requires resolve under Rojo.
2. **darklua build step** converting requires. Adds a transform between disk and Rojo.
3. **Runner-side tree (chosen).** `scripts/lune/specs.luau` rebuilds `ReplicatedStorage.Shared` and `TestService.Tests` from the paths in `haunted.project.json` as fake instances, and loads each module through `@lune/luau` with its own `script`, `game` and `require`. Datatypes come from `@lune/roblox`; `Random` is a seeded xorshift stand-in.

## Decision
Option 3: no source changes, and Studio keeps using `TestRunner` unchanged. Lune 0.11.0 is pinned in `rokit.toml`; `scripts/check.sh` and the pre-commit hook run `lune run scripts/lune/specs`. Studio Play remains the authority for scenarios, replication and anything touching real Instances.
*(Mark `status: approved` only after explicit human approval. Record who approved it and when.)*

## Consequences
- CI now fails on logic regressions (verified: changing `EconomyRules.fullRate` failed 3 specs).
- The stand-in `Random` gives a different sequence from Roblox's, so specs must assert properties (ranges, rates), never exact seeded values. A spec passing headlessly but failing in Studio means it relied on a seed.
- Mounted paths are duplicated from `haunted.project.json` in the runner; if the project's Shared/Tests mapping changes, update `MOUNTS`.
- A spec that needs a service, real Instance, `task` or physics fails loudly headlessly; such checks belong in `tests/scenarios/`.
- One more pinned tool (Lune), installed in CI by `setup-rokit`.
