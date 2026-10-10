# Rg1

A Roblox game built with [Rojo](https://rojo.space) 7.7.0 and an AI-assisted workflow (Claude Code) that has human approval gates. This folder is also the Obsidian vault. Start at [[Home]].

## Install (one time)
Already present on this Mac: Rokit, Rojo, StyLua, luau-lsp, Selene (Homebrew), Python 3, VS Code with the Rojo, Luau-LSP, StyLua and Selene extensions, the Rojo Studio plugin, and Obsidian.
- The tool versions are pinned in `rokit.toml`. On a new machine, run `rokit install`.
- Python uses only the standard library. Nothing to `pip install`.

## Start a work session
```bash
cd ~/Desktop/Rg1
rojo serve                 # sync src/ and tests/luau to Studio (port 34872, Rojo 7.7.0)
```
In Studio: open your **local** place file → Plugins → Rojo → **Connect**.

```bash
scripts/check.sh                                   # cheap checks: format, lint, build, JSON, Python tests
python3 scripts/orchestrator.py status             # task list
python3 scripts/orchestrator.py next               # what's ready to start
python3 scripts/orchestrator.py report             # write reports/health/progress-<date>.md
```

## Task lifecycle (see `workflow/workflow.md`)
```bash
python3 scripts/orchestrator.py approve T-001 --by jg          # HUMAN gate: approve the plan
python3 scripts/orchestrator.py start T-001
git switch -c task/T-001-collectibles
python3 scripts/orchestrator.py dispatch T-001 --role executor # dry-run: writes the prompt to reports/prompts/
#   → paste that prompt into Claude Code (subscription), or ask Claude to "run T-001 as executor"
python3 scripts/orchestrator.py record-exec T-001 --result pass --notes "check.sh green"
python3 scripts/orchestrator.py dispatch T-001 --role auditor  # run in a FRESH Claude session for independence
python3 scripts/orchestrator.py record-audit T-001 --result pass --report reports/audits/T-001-attempt1.md
python3 scripts/orchestrator.py approve-merge T-001 --by jg    # HUMAN gate, then merge the branch yourself
python3 scripts/orchestrator.py record-usage T-001 --kind subscription --role executor --note "1 session"
```
A failed check or audit moves the task to `revision`. After **2** revisions it becomes `blocked` and waits for you (`unblock`).

## What is tested where
| Check | How | Automated? |
|---|---|---|
| Formatting | `stylua --check` | ✅ check.sh |
| Lint | `selene` (Roblox std) | ✅ check.sh |
| Project builds | `rojo build` | ✅ check.sh |
| Orchestrator logic | `python3 -m unittest discover tests` | ✅ check.sh |
| Luau unit specs (`tests/luau/*.spec.luau`) | In Studio (Edit mode): `require(game.TestService.Tests.TestRunner).run()`. Claude can run this through Studio MCP | ⚠️ needs Studio + Rojo connected |
| Gameplay, replication, feel | The playtest procedure in each task spec | ❌ manual (or Claude-driven through Studio MCP) |

Static checks don't prove the gameplay is correct.

## Layout
`src/` game code · `tests/` Python and Luau tests · `scripts/` tooling · `tasks/` queue, specs and usage ledger · `workflow/` roles, process and budget · `docs/` design and decisions · `research/` · `reports/` · `templates/` Obsidian templates · `Agents/`, `Chats/` are Smart Second Brain plugin folders (don't edit).

## Safety
- Never publish, spend Robux or money, or touch the live experience without explicit approval.
- `workflow/budget.json` has `paid_api_enabled: false` and `dispatch_mode: dry-run`. Paid API calls stay off until you approve them.
- `.env` is ignored by Git (see `.env.example`). Obsidian workspace files, plugin data and S2B memory/chats are ignored too.

## Troubleshooting
- **`stylua`/`luau-lsp`: "Failed to find tool"**: run them from inside this folder (`rokit.toml` pins them).
- **Studio doesn't show the scripts**: make sure `rojo serve` is running and click Connect in the Rojo plugin. Port 34872 must be free (`lsof -i :34872`).
- **Rojo connect fails with `attempt to index number with 'protocolVersion'`**: the Studio plugin and `rojo serve` are on different versions. Rojo 7.7 replies in MessagePack, 7.6 in JSON. Keep the `rojo` version in `rokit.toml` the same as the Rojo plugin version in Studio (currently 7.7.0, from the Creator Store), and keep only **one** Rojo plugin enabled.
- **`orchestrator.py` says "queue invalid"**: run `python3 scripts/orchestrator.py validate` to see the errors.
- **Mac feels slow (8 GB)**: close extra Studio windows. Don't run local AI models.
