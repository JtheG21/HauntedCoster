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
- `python3 scripts/evidence.py matrix|silhouette`: the same images at real display widths on dark and light, and black/white shape sheets (`--mode alpha` for transparent PNGs); `series --max-transitions N` fails a clip with too many large luminance changes per second
- `python3 scripts/refs.py actions [--by-blocker]`: every reviewed note's outcome, next action and what it waits on (game choice, free Studio, upload question, Reallusion, jg approval)
- `python3 scripts/evidence.py frames|strip|beats|sheet|stats`: dense frames, contact sheets, scene-change beats, side-by-side, luminance/palette numbers, per-frame `series` (mono runs, flash-risk heuristic) and `audio` level envelope for reference videos and renders (ffmpeg; output outside the vault)
- `python3 scripts/skill_lint.py`: lints the project's own skills (frontmatter, trigger wording, dead paths, `.agents` copies)
- `python3 scripts/refs.py review-next|decide`: review packet for the next Index item, and `decide ... --apply` to record jg's decision (dry run by default)
- `python3 scripts/refs.py pin|drift|rights|ledger`: source commit pins, upstream drift, the licence adaptation gate (`rights --check ID --use code|asset|method`) and what tasks citing a REF cost
- `python3 scripts/refs.py list|brief|trace|lint|guard|new`: the `10 References/` library (briefs per task or category, lint, jg-approval guard, scaffold). `REFS_JG_APPROVED=1` lets a commit that jg asked for change an Intent section or approve a note. The same guard refuses (no override) any staged file byte-identical to a file in `~/Roblox-Work/resource-packs/`: the Resource Boy and ActorCore licences forbid storing pack files in a repository
- `scripts/studio-preflight.sh [--root <checkout>]`: Rojo, Studio windows, memory and build stamp before a Studio run

## Claude Code automations (`.claude/`)
- **Hooks** (`settings.json`, scripts in `hooks/`, tests in `tests/test_claude_hooks.py`). `guard.sh` blocks state-changing Git without a chained `scripts/preflight.sh`, a bare `rojo serve`, `.env`, and edits in `Agents/`, `Chats/` and `.obsidian/`. It asks jg before `gh pr merge`, `rojo upload` and edits in `10 References/`. `luau-format.sh` runs StyLua and Selene on each edited `.luau` file under `src/`, `tests/luau/` or `games/`. `ref-lint.sh` lints each edited `REF-*` note. If a block is wrong, fix the hook rather than working around it.
- **Skills:** `/reference-review [REF-ID]` (one item of the Reference Review Index with jg; only jg starts it), `reference-brief` (reference brief and interview for a Standard/Deep task), `/task-close TASK-####` (close-out; only jg starts it), `studio-preflight` (before any Studio run), `art-import <asset>` (3D Importer upload with jg's approval, ImportedArt.rbxm into the repo, round-trip check) and `codex-handoff TASK-####` (review handoff into the task note).
- **Art tools:** `games/haunted/art/tools/review.sh <asset>` (bake, comparison sheets, budget) and `tests/test_art_budgets.py` (triangle budgets from SYS-Haunted-Art-Direction), arriving with the TASK-0042/0043 art pipeline. `scripts/studio_transfer.py` moves an .rbxm between Studio and disk.
- **Agent:** `auditor`, the one audit per task. Call it with `model: sonnet` for delta re-audits.
