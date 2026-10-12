---
id: ENG-Luau-Standards
title: Luau Standards
type: index
status: approved
created: 2026-10-10
updated: 2026-10-12
tags:
  - engineering/standards
---
# Luau standards

- `--!strict` at the top of every new module. Type-annotate public functions. `scripts/typecheck.sh` must be clean.
- StyLua formatting (tabs, 120 columns), Selene `roblox` std. Both run in `scripts/check.sh`.
- Server services: `src/server/Services/<Name>Service.luau` with an idempotent `start()`.
- Shared config is frozen tables in `src/shared/<Name>Config.luau`. Pure logic goes in `src/shared/<Name>Rules.luau` so it can be tested.
- Remotes are created by the server. Every client argument is type-checked and range-checked, plus rate-limited.
- Debounce shared state synchronously, before any yield (pattern from [[SYS-Collectible-Service]]).
- Tests: `tests/luau/<Module>.spec.luau` returns `function(t: TestRunner.T)` ([[LES-0002-Typed-Test-Context]]).
- GAME-002 specs (`games/haunted/tests/`) also run headlessly in Lune ([[ADR-0008-Headless-Specs-With-Lune]]): keep them pure (no services, real Instances or `task`), and assert properties rather than exact seeded `Random` values.
