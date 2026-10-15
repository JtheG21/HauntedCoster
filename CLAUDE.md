# Rg1: Claude Code entry point

@AGENTS.md

## Luau conventions (summary; full version in `05 Engineering/Luau Standards.md`)
- Use `--!strict` and tabs (StyLua). Type-annotate public functions.
- Paths below are for the active game, GAME-002 (`games/haunted/`). GAME-001 uses the same layout under `src/` and `tests/luau/`.
- Server services are `games/haunted/src/server/Services/<Name>Service.luau` with an idempotent `start()`. Config and pure rules go in `games/haunted/src/shared/`.
- Tests go in `games/haunted/tests/<Module>.spec.luau` and return `function(t: TestRunner.T)`. They run headlessly with `lune run scripts/lune/specs` (in `check.sh`, ADR-0008), so assert properties, not exact seeded `Random` values. In Studio, use a **fresh Play session (Server data model)** with `require(game.TestService.Tests.TestRunner).run()`. Edit mode caches modules (LES-0005). Play scenarios live in `games/haunted/tests/scenarios/`.

## Commands
- `rojo serve haunted.project.json`: sync GAME-002 to the `HauntedCollector.rbxl` place (never a bare `rojo serve`, which serves GAME-001)
- `scripts/check.sh`: all cheap checks
- `scripts/preflight.sh --root <checkout> --branch <name> [--clean]`: run before any state-changing Git operation (AGENTS.md "Git safety")
- `python3 scripts/orchestrator.py status|next|approve|start|record-exec|record-audit|approve-merge|report ...` (`--help`)
- `python3 scripts/validate_vault.py`: note conventions, links, and queue/note sync
- `scripts/studio-preflight.sh [--root <checkout>]`: Rojo, Studio windows, memory and build stamp before a Studio run

## Claude Code automations (`.claude/`)
- **Hooks** (`settings.json`, scripts in `hooks/`, tests in `tests/test_claude_hooks.py`). `guard.sh` blocks state-changing Git without a chained `scripts/preflight.sh`, a bare `rojo serve`, `.env`, and edits in `Agents/`, `Chats/` and `.obsidian/`. It asks jg before `gh pr merge`, `rojo upload` and edits in `10 References/`. `luau-format.sh` runs StyLua and Selene on each edited `.luau` file under `src/`, `tests/luau/` or `games/`. If a block is wrong, fix the hook rather than working around it.
- **Skills:** `/task-close TASK-####` (close-out; only jg starts it) and `studio-preflight` (before any Studio run).
- **Agent:** `auditor`, the one audit per task. Call it with `model: sonnet` for delta re-audits.
