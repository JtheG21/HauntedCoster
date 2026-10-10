# Rg1: Roblox AI Studio

A Roblox game built with [Rojo](https://rojo.space) 7.7.0 and an AI-assisted workflow (Claude Code) that has human approval gates. This folder is also the Obsidian vault. Start at [[Studio Index]]. Agent rules are in `AGENTS.md`, note rules in [[Obsidian Conventions]].

## Install (one time)
Already on this Mac: Rokit, Rojo, StyLua, luau-lsp, Selene (Homebrew), Python 3, VS Code with the Rojo, Luau-LSP, StyLua and Selene extensions, the Rojo Studio plugin, and Obsidian.
- Tool versions are pinned in `rokit.toml`. On a new machine, run `rokit install`. Python uses only the standard library.
- In Obsidian, set Settings → Templates → *Template folder location* to `99 Templates` (core Templates plugin).

## Start a work session
```bash
cd ~/Desktop/Rg1
rojo serve                 # sync src/ and tests/luau to Studio (port 34872)
```
In Studio: open your **local** place → Plugins → Rojo → **Connect**. Keep only one Rojo plugin enabled.

```bash
scripts/check.sh                                   # format, lint, types, build, JSON, queue, vault, Python tests
python3 scripts/orchestrator.py status             # task list
python3 scripts/orchestrator.py next               # what's ready
python3 scripts/validate_vault.py                  # note conventions + links + queue/note sync
python3 scripts/orchestrator.py report             # 08 Reviews/HLT-<date>.md
```

## Task lifecycle (see [[Workflow]])
```bash
python3 scripts/orchestrator.py approve TASK-0002 --by jg        # HUMAN: proposed → ready
python3 scripts/orchestrator.py start TASK-0002                  # → in_progress
git switch -c task/TASK-0002-slug
python3 scripts/orchestrator.py dispatch TASK-0002 --role executor   # dry-run: writes tasks/prompts/…
python3 scripts/orchestrator.py record-exec TASK-0002 --result pass --notes "check.sh green"   # → in_review
python3 scripts/orchestrator.py record-audit TASK-0002 --result pass --report "06 QA/AUD-…-01.md"   # → approved
python3 scripts/orchestrator.py approve-merge TASK-0002 --by jg  # HUMAN: → done, then merge the branch
```
A failed check or audit → `changes_requested`. After 2 revisions → `blocked` (`unblock`). Each transition also updates the task note's `status` and `updated`.

## What is tested where
| Check | How | Automated? |
|---|---|---|
| Formatting / lint / types | StyLua, Selene, `scripts/typecheck.sh` (luau-lsp strict) | ✅ check.sh |
| Project builds | `rojo build` | ✅ check.sh |
| Tooling logic | `python3 -m unittest discover -s tests` | ✅ check.sh |
| Note conventions, links, task sync | `scripts/validate_vault.py` | ✅ check.sh |
| Luau unit specs | Studio Edit mode: `require(game.TestService.Tests.TestRunner).run()` (Claude can run it through Studio MCP) | ⚠️ needs Studio |
| Gameplay, replication, feel | The task's playtest procedure → a `TEST-` note | ❌ manual or Studio MCP |

Static checks don't prove the gameplay is correct.

## Layout
- **Code and tooling:** `src/` game code · `tests/` · `scripts/` · `tasks/` queue, ledger, generated prompts · `project-state.json`
- **Vault:**
  - `00 Studio` config and index
  - `01 Inbox`
  - `02 Research`
  - `03 Games/GAME-001 Rg1` overview, design, architecture, roadmap, decisions, systems, tasks, playtests, releases, retros
  - `04 Agents` roles and workflow
  - `05 Engineering`
  - `06 QA`
  - `07 Metrics`
  - `08 Reviews`
  - `09 Knowledge`
  - `99 Templates`
- **Don't edit:** `Agents/` and `Chats/` (Smart Second Brain plugin)

## Safety
- Never publish, spend Robux or money, or touch the live experience without explicit approval.
- `00 Studio/budget.json`: `paid_api_enabled: false`, `dispatch_mode: dry-run`.
- `.env` is ignored by Git (see `.env.example`). Obsidian workspace files, plugin data and S2B memory/chats are ignored too. Never put secrets in notes.

## Troubleshooting
- **`stylua`/`luau-lsp`: "Failed to find tool"**: run them from inside this folder (`rokit.toml` pins them).
- **Rojo connect fails with `attempt to index number with 'protocolVersion'`**: the plugin and server versions differ. See [[LES-0001-Rojo-Version-Mismatch]].
- **Studio doesn't show the scripts**: make sure `rojo serve` is running and click Connect. Check port 34872 (`lsof -i :34872`).
- **Validator reports a status mismatch**: `tasks/queue.json` is authoritative. Find out why the note drifted; don't just edit the note.
- **Mac feels slow (8 GB)**: close extra Studio windows. Don't run local AI models.
