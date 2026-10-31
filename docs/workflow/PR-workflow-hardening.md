# chore: workflow hardening (TASK-0108)

**Merged:** PR 155, `b90495b`, 2026-10-30, approved by jg. This is now the record of that PR. Full results: `docs/workflow/FINAL-REPORT-2026-10-30.md`.

Makes `AGENTS.md`, `tasks/queue.json` and `scripts/active-game.env` the single source of truth for GAME-004 MathShow, archives the paused games, and adds a queue schema, handoff templates and an intake pipeline. No gameplay, UI, remote or DataStore change: `games/mathshow/` gains only an empty `assets/`.

## What changed
- **Archive:** GAME-001, 002 and 003 moved with `git mv` to `archive/<id>-<slug>/`, each with its own project file. There's no default project at the root now, so a bare `rojo serve` fails on purpose.
- **Rulebook:** `AGENTS.md` is canonical, `CLAUDE.md` is a pointer plus Claude-only notes, and `00 Studio/Start Here.md` is the vault entry point. Two outdated handoffs moved to `98 Archive/`.
- **Queue:** schema in `docs/workflow/TASKS.md`, rerunnable `scripts/migrate_queue.py`, and `scripts/validate_queue.py` in the gate. The 17 open GAME-002 tasks are archived.
- **Gate:** `scripts/check.sh` covers the active game with one summary line per step. `--archive` runs on demand. The pre-commit hook now checks MathShow, which it didn't before.
- **Handoffs:** `docs/workflow/templates/` and `docs/workflow/PARALLEL.md`.
- **Intake:** `intake/README.md` with the triage table and checklist. The inbox is gitignored.

## Deviations from the brief
| Brief | Done | Why |
|---|---|---|
| 7 statuses | 9, keeping `approved` and `changes_requested` | jg's decision; the merge gate and revision limit need them |
| Mark paused games' tasks archived | Only the 17 open ones; done stays done | jg's decision |
| `10 References/<topic>/REFERENCE.md`; all assets in `assets/` | `REF-*` notes through `refs.py`; source art in `art/`, `.rbxmx` in `assets/` | jg's decision; lint already enforces this |
| Stop after Phase 0 | Continued | jg approved all phases |
| Sole agent | Two read-only audit subagents, one after the other | AGENTS.md requires an Opus audit on Deep tasks and ranks higher |
| One commit per phase | Also a revision commit and a close-out commit; `check.sh` and specs landed in phase 1 | Audit fixes; each commit had to stay green |
| `rokit.toml` as the single manifest | Selene stays outside it | Adding it is a dependency change, which the brief forbids |

## After merging
The `chore/workflow-hardening` branch and worktree are deleted. Item 1 is still open.

1. **Open PRs 151 to 154** add old-format queue entries and will conflict in `tasks/queue.json`. After each merge: keep every entry, run `python3 scripts/migrate_queue.py`, set `owner_agent` on TASK-0105, 0106 and 0107, run `scripts/check.sh`, and commit.
2. **Main checkout:** ignored leftovers stay under `games/haunted/` and `src/`, such as sourcemaps and the build stamp. They're harmless; clear them when convenient. `HauntedCollector.rbxl` stays at the root.
3. **Worktrees** on older branches keep their old paths until they merge `main`.

## Known and unresolved
- `scripts/check.sh --archive` exits 1: GAME-003 fails StyLua, Selene and strict types. It was never checked before, and the brief rules out editing it.
- CI passed on the PR and on `main` at `b90495b`. The manual `--archive` run hasn't been triggered on GitHub.
- `~/rokit.toml` pins Rojo 7.6.1 and `~/aftman.toml` pins 7.7.0-rc.1. They can't affect commands run inside the repo, but they can outside it. Not edited.
- Studio: jg ran the checks on this branch on 2026-10-30 and reported them good. The separate problem from the 2026-10-30 handoff, Studio not receiving updated script source, wasn't investigated here.
- PR 151 still has no task ID.

## Audit
[[AUD-20261030-TASK-0108-01]] failed with two majors, both fixed. [[AUD-20261030-TASK-0108-02]] passed.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
