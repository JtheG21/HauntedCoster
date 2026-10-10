# Rg1: project guide for Claude Code

This is a Roblox game built with Rojo. The folder is also the Obsidian vault.
Read this file first. Open other files only when the current task needs them.

## Layout
- `src/server|shared|client`: game code (Luau), synced to Studio by Rojo (`default.project.json`). **Only `src/` reaches the game.**
- `workflow/roles/*.md`: instructions for each agent role. `workflow/workflow.md` covers the process. `workflow/budget.json` holds the spending policy.
- `tasks/queue.json`: the task list, managed by `scripts/orchestrator.py`. `tasks/specs/` holds task specs.
- `docs/`: game design, architecture, roadmap, decisions (`docs/adr/`), lessons learned.
- `research/`: research notes. `reports/`: audits, bugs, weekly and health reports (`reports/prompts/` is generated and ignored by Git).
- `templates/`: Obsidian note templates. `Home.md` is the dashboard.
- `Agents/`, `Chats/`, `.obsidian/`: these belong to the Smart Second Brain plugin and Obsidian. **Do not edit.**

## Rules
- Do one scoped task at a time, on branch `task/<id>-<slug>`. Never commit straight to `main`. Never merge without human approval.
- The server is authoritative: the server validates everything that comes from the client.
- Never publish, spend money, change a live experience, or make paid API calls without explicit human approval.
- Allow at most 2 revision attempts per task (see `workflow/budget.json`). Then stop and report.
- Run the cheap checks before any AI review: `scripts/check.sh`.
- Record decisions in `docs/adr/` only after they are approved. Keep notes short and link to them, don't duplicate them.
- Never read or print `.env` or credentials.

## Luau conventions
- Use `--!strict` at the top of new modules, and tabs for indentation (StyLua). Add type annotations to public functions.
- Server services live in `src/server/Services/<Name>Service.luau`. Shared config and types live in `src/shared/`.
- Remotes are created by the server. Arguments from the client are type-checked and rate-limited.
- Keep logic pure where possible, so `tests/luau/` can test it without a playtest.

## Commands
- `scripts/check.sh`: StyLua check, Selene lint, Rojo build, orchestrator validation, Python tests
- `python3 scripts/orchestrator.py status|validate|next|report ...`: see `--help`
