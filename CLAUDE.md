# Rg1: Claude Code entry point

@AGENTS.md

## Luau conventions (summary; full version in `05 Engineering/Luau Standards.md`)
- Use `--!strict` and tabs (StyLua). Type-annotate public functions.
- Server services are `src/server/Services/<Name>Service.luau` with an idempotent `start()`. Config and pure rules go in `src/shared/`.
- Tests go in `tests/luau/<Module>.spec.luau` and return `function(t: TestRunner.T)`. Run them in a **fresh Play session (Server data model)** with `require(game.TestService.Tests.TestRunner).run()`. Edit mode caches modules (LES-0005).

## Commands
- `scripts/check.sh`: all cheap checks
- `scripts/preflight.sh --root <checkout> --branch <name> [--clean]`: run before any state-changing Git operation (AGENTS.md "Git safety")
- `python3 scripts/orchestrator.py status|next|approve|start|record-exec|record-audit|approve-merge|report ...` (`--help`)
- `python3 scripts/validate_vault.py`: note conventions, links, and queue/note sync
