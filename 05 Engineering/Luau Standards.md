---
id: ENG-Luau-Standards
title: Luau Standards
type: index
status: approved
created: 2026-10-10
updated: 2026-10-30
tags:
  - engineering/standards
---
# Luau standards

- `--!strict` at the top of every new module. Type-annotate public functions. `scripts/typecheck.sh` must be clean.
- StyLua formatting (tabs, 120 columns), Selene `roblox` std. Both run in `scripts/check.sh`.
- Paths are relative to the game root (`games/mathshow/` for the active game; [[AGENTS]]).
- Server services: `src/server/Services/<Name>Service.luau` with an idempotent `start()`.
- Shared config is frozen tables in `src/shared/<Name>Config.luau`. Pure logic goes in `src/shared/<Name>Rules.luau` so it can be tested.
- Remotes are created by the server. Every client argument is type-checked and range-checked, plus rate-limited.
- Debounce shared state synchronously, before any yield (pattern from [[SYS-Collectible-Service]]).
- Tests: `tests/<Module>.spec.luau` returns `function(t: TestRunner.T)` ([[LES-0002-Typed-Test-Context]]).
- Specs also run headlessly in Lune ([[ADR-0008-Headless-Specs-With-Lune]]): keep them pure (no services, real Instances or `task`), and assert properties rather than exact seeded `Random` values.
