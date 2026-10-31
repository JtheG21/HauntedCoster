# Workflow hardening: final report (TASK-0108)

**Status: merged.** PR 155 merged to `main` as `b90495b` on jg's approval, after which jg had the branch `chore/workflow-hardening` and its worktree deleted. All verification below was re-run against `b90495b`. All 8 acceptance criteria pass. `scripts/check.sh --archive` still fails on GAME-003 only, which is outside the required gate.

## Verification

### `scripts/check.sh`: exit 0
```
PASS  StyLua (format, GAME-004)
PASS  Selene (lint, GAME-004)
PASS  Luau types (strict, GAME-004)
PASS  Unit specs (Lune, GAME-004)
PASS  Rojo build (mathshow.project.json)
PASS  JSON files
PASS  Queue schema (files_owned overlap)
PASS  Task queue (orchestrator)
PASS  Vault conventions
PASS  Reference notes
PASS  Project skills
PASS  Python tests
ALL CHECKS PASSED (active)
```

### `scripts/check.sh --archive`: exit 1
```
PASS  StyLua (GAME-001-rg1)
PASS  Selene (GAME-001-rg1)
PASS  Rojo build (GAME-001-rg1)
PASS  StyLua (GAME-002-haunted-collector)
PASS  Selene (GAME-002-haunted-collector)
PASS  Rojo build (GAME-002-haunted-collector)
FAIL  StyLua (GAME-003-hike-or-die)
FAIL  Selene (GAME-003-hike-or-die)
PASS  Rojo build (GAME-003-hike-or-die)
FAIL  Luau types (archive)
PASS  Unit specs (Lune, GAME-002)
PASS  Unit specs (Lune, GAME-003)
PASS  Art codec (Python, GAME-002)
CHECKS FAILED (archive)
```
The type failures are 9 errors in `archive/GAME-003-hike-or-die/tests/lune/evidence-rules.spec.luau`. GAME-003 was never in `check.sh`, and archived code is out of scope to edit.

### Archive failures are isolated from the gate
- The default gate exits 0 while GAME-003 is failing, and still exits 0 straight after an archive run.
- The active branch of `scripts/check.sh` runs no step on `archive/`. Its only mention is the note telling you the flag exists.
- CI on `main` concluded `success` for `b90495b`.

`.github/workflows/check.yml`:
```yaml
6:  pull_request:
7:  push:
9:  workflow_dispatch:
11:      archive:
12:        description: "Check archived games instead of the active game"
51:        run: scripts/check.sh ${{ inputs.archive && '--archive' || '' }}
```
`inputs.archive` exists only on a manual run with the box ticked, so PRs and pushes call the default gate. The PR and `main` runs confirm that path. **The manual archive run has never been triggered on GitHub.**

### Other checks
```
$ python3 scripts/validate_queue.py
queue: 98 tasks, 0 in_progress, 0 errors              (exit 0)

$ rojo build, each to a temp file                     (all exit 0)
mathshow.project.json: Built project
archive/GAME-001-rg1/default.project.json: Built project
archive/GAME-002-haunted-collector/haunted.project.json: Built project
archive/GAME-003-hike-or-die/hike-or-die.project.json: Built project

$ python3 -m unittest tests.test_claude_hooks
Ran 17 tests. OK

$ git status --short --branch                         (before this report was written)
## chore/workflow-hardening-report
```

## Acceptance criteria

| # | Criterion | Result | Evidence |
|---|---|---|---|
| 1 | Only MathShow is active everywhere | **PASS** | `AGENTS.md`, `CLAUDE.md`, Start Here and Studio Index mention old games only as archived |
| 2 | `check.sh` passes on the active game | **PASS** | Output above, exit 0 |
| 3 | Every archived game still builds | **PASS** | Rojo output above. This covers builds only; `--archive` lint and type failures are separate |
| 4 | Queue validates with no `files_owned` overlap | **PASS** | Validator output above |
| 5 | CI paths are correct | **PASS** | CI succeeded on the PR and on `main` at `b90495b` |
| 6 | 4 templates and `PARALLEL.md` have every section | **PASS** | `tests/test_workflow_docs.py`, part of Python tests; checklist below |
| 7 | `intake/` exists with triage table and checklist | **PASS** | `intake/README.md`, `intake/inbox/.gitkeep`; same test |
| 8 | No dependencies added, no secrets read | **PASS** | `git diff b8c4120 b90495b -- rokit.toml selene.toml stylua.toml .luaurc wally.toml wally.lock` is empty. No `.env` or key was opened. A diff can't prove what wasn't read, so that half rests on this statement |

**Section checklist:** goal, in scope, out of scope, files expected to change, owned files, acceptance criteria and evidence, tier, test steps, approval gates and remote-change triple are present in `claude-code.md`, `codex.md`, `claude-design.md` and `task-audit.md`. `claude-design.md` also covers export formats, where outputs land and the `.rbxmx` rule. `PARALLEL.md` has disjoint `files_owned`, contracts land first, and others consume without editing.

## Audit findings

Sources: `06 QA/AUD-20261030-TASK-0108-01.md` (Opus, fail, reviewed `ede584f`) and `-02.md` (Sonnet delta, pass, reviewed `c0eebe4`).

| Severity | File | Issue | Fixed? |
|---|---|---|---|
| major | `scripts/validate_queue.py` | Missed a folder below a glob's prefix, so an overlap could pass | Yes, `c0eebe4` |
| major | `04 Agents/Planner.md`, `99 Templates/T - Task.md`, `04 Agents/Orchestrator.md` | Old schema; following them failed `check.sh` | Yes, `c0eebe4` |
| minor | `docs/workflow/TASKS.md`, `scripts/migrate_queue.py` | Migrated open tasks need `owner_agent`; undocumented | Yes (documented), `c0eebe4` |
| minor | `docs/workflow/TASKS.md` | `risk` and `note_path` were effectively required but listed as optional | Yes, `c0eebe4` |
| minor | `scripts/typecheck.sh` | A silent luau-lsp exit counted as success (inherited from `main`) | Yes, `c0eebe4` |
| minor | `scripts/check.sh` | "ALL CHECKS PASSED" printed with a skipped step | Yes, `c0eebe4` |
| minor | `.claude/hooks/guard.sh` | Older worktrees lost folder protection | Yes, `c0eebe4` |
| minor | `04 Agents/Workflow.md`, `05 Engineering/Multi-Client Testing.md` | Stale live paths | Yes, `c0eebe4` |
| minor | `scripts/studio-preflight.sh` | Hint printed a wrong path for `--game haunted` | Yes, `c0eebe4` |
| minor | `tests/test_claude_hooks.py` | Nothing covered the `AGENTS.md` marker | Yes, `b4409a0` |
| minor | `scripts/validate_queue.py` | A folder name with a dot reads as a file | **Not fixed in code.** Rare; `TASKS.md` says to use a trailing `/` (`b4409a0`) |
| nit | `scripts/validate_queue.py` | Redundant condition | Yes (rewritten), `c0eebe4` |
| nit | `AGENTS.md` | Push rule softened without being asked | Yes, `c0eebe4` |
| nit | `scripts/migrate_queue.py` | Didn't bump `updated:` on notes | Yes, `c0eebe4` |
| nit | `docs/workflow/AUDIT-2026-10-30.md` | Listed the PR draft before it existed | Resolved when it was added, `b4409a0` |
| nit | `.gitignore` | Lists sourcemaps no longer written | **Not fixed, on purpose:** those files remain in the main checkout and would otherwise show as untracked |
| nit | `scripts/typecheck.sh` | Ignores unknown arguments | **Not fixed:** only `check.sh` and people call it, and it fails safe by checking the active game |
| nit | `scripts/validate_queue.py` | `*` crosses `/`, which over-reports | **Not fixed, on purpose:** the safe direction; documented in `TASKS.md` (`c0eebe4`) |

**The zsh word-splitting failure** came from an ad-hoc command line, not a repo file: a `$P` variable holding a whole command in the Bash tool's zsh. No script or hook was involved, so nothing changed. The chained preflight failed, and no commit ran.

## Before and after
```
BEFORE                              AFTER
src/, tests/luau/, maps/            archive/GAME-001-rg1/
default.project.json                archive/GAME-001-rg1/
games/haunted/                      archive/GAME-002-haunted-collector/
haunted.project.json                archive/GAME-002-haunted-collector/
tests/test_hcm_codec.py             archive/GAME-002-haunted-collector/art/
games/hike-or-die/                  archive/GAME-003-hike-or-die/
hike-or-die.project.json            archive/GAME-003-hike-or-die/
games/mathshow/                     games/mathshow/ (plus empty assets/)
mathshow.project.json               mathshow.project.json
                                    archive/README.md
                                    docs/workflow/ (audit, TASKS, PARALLEL, PR draft, templates/, this report)
                                    intake/ (README.md, inbox/)
                                    scripts/active-game.env, validate_queue.py, migrate_queue.py
                                    98 Archive/
                                    00 Studio/Start Here.md
```

The `git mv` commands executed were the list proposed in `AUDIT-2026-10-30.md`, section (b). `default.project.json` went to the archive with its paths unchanged, leaving no default project at the root, so a bare `rojo serve` fails on purpose.

## Files changed per commit

| Commit | Summary | Files | + / − |
|---|---|---|---|
| `b55bfed` | Phase 0: audit report | 1 | 163 / 0 |
| `a4c6218` | Phase 1: archive paused games | 364 | 396 / 171 |
| `97c9c70` | Phase 2: single rulebook | 23 | 199 / 137 |
| `b17de8f` | Phase 3: queue schema, migration, validator | 18 | 1514 / 461 |
| `3723ae3` | Phase 4: CI and active game | 3 | 41 / 4 |
| `fdfa938` | Phase 5: templates and parallel rules | 5 | 210 / 0 |
| `d49dc56` | Phase 6: intake pipeline | 4 | 84 / 0 |
| `ede584f` | Phase 7: MathShow tree | 1 | 0 / 0 |
| `c0eebe4` | Revision 1: audit fixes | 17 | 139 / 26 |
| `b4409a0` | Phase 8: close-out, audit record, PR draft | 7 | 111 / 7 |
| `403171c` | jg's Studio result | 2 | 2 / 2 |
| `6b7bd83` | TASK-0108 done | 3 | 15 / 11 |
| **`b90495b`** | **Merge to `main`** | **421** | **2831 / 776** |

Of the 421 files, 331 are renames.

## Deviations

| Brief | Done | Why |
|---|---|---|
| Stop for approval after Phase 0 | Continued | jg chose this before Phase 1 and then approved all phases |
| 7 statuses | 9, keeping `approved` and `changes_requested` | jg's decision; the merge gate and revision limit need them |
| Mark paused games' tasks archived | Only the 17 open ones | jg's decision; done stays done |
| `REFERENCE.md`; all assets in `assets/` | `REF-*` notes; source art in `art/`, `.rbxmx` in `assets/` | jg's decision; `refs.py lint` already enforces this |
| Sole agent | Two read-only audits in sequence | `AGENTS.md` requires an audit on Deep tasks and ranks higher |
| One commit per phase | Plus revision, Studio and close-out commits; `check.sh` landed in Phase 1 | Audit fixes; each commit had to stay green |
| Single tool manifest | Selene stays outside `rokit.toml` | Adding it would break the no-dependency rule |
| No push or PR until told | Pushed and merged | jg asked for each |
| Verification brief: commit message "verification + audit fixes" | "verification + final report" | This commit contains no audit fixes |

### Decisions worth a second look
None were in the brief's explicit move list:
- `maps/finale_arena.json` moved to GAME-001, because only GAME-001 uses it.
- `tests/test_hcm_codec.py` moved out of the required gate, with GAME-002's art code.
- `.gitignore` hides `games/haunted/`, so its leftovers stay out of `git status` in the main checkout.
- Two handoffs moved to the new `98 Archive/`, which sits outside the vault validator's frontmatter checks.
- Queue fields were renamed (`project` to `game`, `note` to `note_path`, `acceptance_criteria` to `acceptance`), a bigger change to the orchestrator than the statuses alone.

## Unresolved
- **PRs 151 to 154** use the old queue format and will conflict in `tasks/queue.json`. After each merge: keep every entry, run `scripts/migrate_queue.py`, set `owner_agent` on TASK-0105 to 0107, and run `scripts/check.sh`. Tested on their queue entries only, not on a real merge.
- **PR 151** has no task ID. **PR 152** waits for jg's review.
- **GAME-003** fails `--archive` (above).
- **`~/rokit.toml` pins Rojo 7.6.1**, confirmed as the version outside the repo, and `~/aftman.toml` pins 7.7.0-rc.1. Start `rojo serve` from inside the repo.
- **Studio not receiving updated scripts** (2026-10-30 handoff) was not investigated.
- **Selene** isn't managed by Rokit.
- **Leftovers:** four ignored files under `games/haunted/` and three old sourcemaps at the root of the main checkout.
- **Cleanup not done:** stale worktrees and older PRs 66, 118 and 131.

## Studio test steps
jg reported these good on 2026-10-30, without itemizing results, and the archived build output was seen directly. To repeat them from the main checkout:

1. Run `rokit install`, then `scripts/check.sh`.
2. Run `rojo serve mathshow.project.json` from inside the repo, with no other server running.
3. Open `MathShow.rbxl` and connect one Rojo plugin (7.7.1). Confirm `ReplicatedStorage.Shared`, `ServerScriptService.Server`, `StarterPlayer.StarterPlayerScripts.Client` and `StudioTests`, and `TestService.Tests`.
4. Start Play in a fresh session and confirm Output has no errors from missing modules. Check that `ReplicatedStorage.Shared.BuildStamp` matches `games/mathshow/src/shared/BuildStamp.txt`.
5. Stop the server and run `rojo build archive/GAME-002-haunted-collector/haunted.project.json -o /tmp/haunted-check.rbxl`.

## Updates after this report
This report is a record as of `b90495b`. Later on 2026-10-30:

- **Manual archive run:** triggered on GitHub as run 41150194423. It gave the same results as locally: only GAME-003's StyLua, Selene and types fail.
- **PRs 151 to 154:** updated for real, and their old-format queue conflicts are gone. TASK-0109 (PR 157) then moved all tasks to `tasks/items/` and removed `tasks/queue.json`, so this report's references to that file and to `project-state.json` describe the earlier format. See `docs/workflow/SHARDING-PLAN.md`.
- **Leftovers:** the 7 generated files in the main checkout were deleted with jg's approval, including everything under `games/haunted/`.
