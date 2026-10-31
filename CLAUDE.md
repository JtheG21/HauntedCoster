# Rg1: Claude Code entry point

@AGENTS.md

Everything above is the rulebook. Below are notes that apply only to Claude Code.

## Automations (`.claude/`)
- **Hooks** (`settings.json`, scripts in `hooks/`, tests in `tests/test_claude_hooks.py`). `guard.sh` blocks state-changing Git without a chained `scripts/preflight.sh`, a bare `rojo serve`, `.env`, and edits in `Agents/`, `Chats/` and `.obsidian/`. It asks jg before `gh pr merge`, `rojo upload` and edits in `10 References/`. `luau-format.sh` runs StyLua and Selene on each edited `.luau` file under `games/` or `archive/`. `ref-lint.sh` lints each edited `REF-*` note. If a block is wrong, fix the hook rather than working around it.
- **Skills:** `/reference-review [REF-ID]` (one item of the Reference Review Index with jg; only jg starts it), `reference-brief` (reference brief and interview for a Standard or Deep task), `/task-close TASK-####` (close-out; only jg starts it), `studio-preflight` (before any Studio run), `art-import <asset>` (GAME-002 art, archived) and `codex-handoff TASK-####` (review handoff into the task note).
- **Agent:** `auditor`, the one audit per task. Call it with `model: sonnet` for delta re-audits.
- `scripts/studio_transfer.py` moves an .rbxm between Studio and disk.
