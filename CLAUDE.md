# Rg1: Claude Code entry point

@AGENTS.md

## Luau conventions (summary; full version in `05 Engineering/Luau Standards.md`)
- Use `--!strict` and tabs (StyLua). Type-annotate public functions.
- Paths below are for the active game, GAME-002 (`games/haunted/`). GAME-001 uses the same layout under `src/` and `tests/luau/`.
- Server services are `games/haunted/src/server/Services/<Name>Service.luau` with an idempotent `start()`. Config and pure rules go in `games/haunted/src/shared/`.
- Tests go in `games/haunted/tests/<Module>.spec.luau` and return `function(t: TestRunner.T)`. Run them in a **fresh Play session (Server data model)** with `require(game.TestService.Tests.TestRunner).run()`. Edit mode caches modules (LES-0005). Play scenarios live in `games/haunted/tests/scenarios/`.

## Commands
- `rojo serve haunted.project.json`: sync GAME-002 to the `HauntedCollector.rbxl` place (never a bare `rojo serve`, which serves GAME-001)
- `scripts/check.sh`: all cheap checks
- `python3 scripts/orchestrator.py status|next|approve|start|record-exec|record-audit|approve-merge|report ...` (`--help`)
- `python3 scripts/validate_vault.py`: note conventions, links, and queue/note sync
