# Rg1: Roblox AI Studio

Roblox games built with [Rojo](https://rojo.space) 7.7.0 and an AI-assisted workflow (Claude Code) that has human approval gates. This folder is also the Obsidian vault. Start at [[Start Here]]. Agent rules are in `AGENTS.md`, note rules in [[Obsidian Conventions]].

## Install (one time)
Already on this Mac: Rokit, Rojo, StyLua, luau-lsp, Selene (Homebrew), Python 3, VS Code with the Rojo, Luau-LSP, StyLua and Selene extensions, the Rojo Studio plugin, and Obsidian.
- Tool versions are pinned in `rokit.toml`. On a new machine, run `rokit install`. Python uses only the standard library.
- In Obsidian, set Settings → Templates → *Template folder location* to `99 Templates` (core Templates plugin).

## Start a work session
```bash
cd ~/Desktop/Rg1
ps aux | grep "rojo serve"            # stop any other server first
rojo serve mathshow.project.json      # GAME-004 MathShow (active): games/mathshow → Studio (port 34872)
```
In Studio: open the **local `MathShow.rbxl`** place (first time: `rojo build mathshow.project.json -o MathShow.rbxl`) → Plugins → Rojo → **Connect**. Keep only one Rojo plugin enabled.

**Match the project to the place.** There's no default project at the repo root, so a bare `rojo serve` fails on purpose. Archived games have their own project files and places (`archive/README.md`).

```bash
scripts/check.sh                                   # the required gate for the active game
scripts/check.sh --archive                         # archived games, on demand
scripts/install-hooks.sh                           # once per clone: pre-commit StyLua+Selene, build stamp on commit/checkout
scripts/stamp.sh                                   # refresh the build stamp before a Play test
python3 scripts/orchestrator.py status             # task list
python3 scripts/orchestrator.py next               # what's ready
python3 scripts/validate_vault.py                  # note conventions + links + queue/note sync
python3 scripts/orchestrator.py report             # 08 Reviews/HLT-<date>.md
```

**Is Studio running your code?** `ReplicatedStorage.Shared.BuildStamp` must match `cat games/mathshow/src/shared/BuildStamp.txt`; if not, the sync is stale. VS Code's luau-lsp reads `sourcemap.json`, which is the active game (`.vscode/settings.json`).

## Task lifecycle (see [[Workflow]])
```bash
python3 scripts/orchestrator.py approve TASK-0002 --by jg        # HUMAN: backlog → ready
python3 scripts/orchestrator.py start TASK-0002                  # → in_progress
git switch -c task/TASK-0002-slug
python3 scripts/orchestrator.py dispatch TASK-0002 --role executor   # dry-run: writes tasks/prompts/…
python3 scripts/orchestrator.py record-exec TASK-0002 --result pass --notes "check.sh green"   # → review
python3 scripts/orchestrator.py record-audit TASK-0002 --result pass --report "06 QA/AUD-…-01.md"   # → approved
python3 scripts/orchestrator.py approve-merge TASK-0002 --by jg  # HUMAN: → done, then merge the branch
```
A failed check or audit → `changes_requested`. After 2 revisions → `blocked` (`unblock`). Each transition also updates the task note's `status` and `updated`.

## What is tested where
| Check | How | Automated? |
|---|---|---|
| Formatting / lint / types | StyLua, Selene, `scripts/typecheck.sh` (luau-lsp strict; prints `SKIP` and passes if the Roblox type definitions are missing, unless `TYPECHECK_REQUIRED=1`) | ✅ check.sh |
| Project builds | `rojo build` | ✅ check.sh |
| Tooling logic | `python3 -m unittest discover -s tests` | ✅ check.sh |
| Note conventions, links, task sync | `scripts/validate_vault.py` | ✅ check.sh |
| Active game unit specs | `lune run scripts/lune/specs` (headless, [[ADR-0008-Headless-Specs-With-Lune]]); also in Studio: `require(game.TestService.Tests.TestRunner).run()` | ✅ check.sh |
| Gameplay, replication, feel | The task's playtest procedure → a `TEST-` note | ❌ manual or Studio MCP |

GitHub Actions (`.github/workflows/check.yml`) runs `scripts/check.sh` on every PR with `TYPECHECK_REQUIRED=1`, so a skipped type check fails there. Static checks don't prove the gameplay is correct.

## Layout
- **Code and tooling:** `games/mathshow/` active game code and tests (`mathshow.project.json`) · `archive/` paused games · `tests/` · `scripts/` · `tasks/` task files, ledger, generated prompts · `project-state.json`
- **Vault:**
  - `00 Studio` config and index
  - `01 Inbox`
  - `02 Research`
  - `03 Games/GAME-004 MathShow` (active) and the archived GAME-001 to 003: overview, design, architecture, roadmap, decisions, systems, tasks, playtests, releases, retros
  - `04 Agents` roles and workflow
  - `05 Engineering`
  - `06 QA`
  - `07 Metrics`
  - `08 Reviews`
  - `09 Knowledge`
  - `10 References` reference library (UI, map, sounds, VFX, misc, code)
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
- **Validator reports a status mismatch**: the file in `tasks/items/` is authoritative. Find out why the note drifted; don't just edit the note.
- **Mac feels slow (8 GB)**: close extra Studio windows. Don't run local AI models.
