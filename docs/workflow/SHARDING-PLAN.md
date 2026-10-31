# Queue sharding plan (Phase 0 of chore/queue-sharding)

**Reserved ID:** TASK-0109. It's the next free number across `main` and every branch, whose highest is TASK-0108. **Tier:** standard.

**Status:** approved by jg with all seven decisions on 2026-10-30, and Phases 1 to 3 are done on this branch. Recon ran read-only against `main` at `7fdef5c`. Nothing is pushed. The 7 leftover files were deleted from the main checkout. The CI table below is as of recon.

## Recommendation
- One file per task at `tasks/items/TASK-####.json`.
- **Remove** `tasks/queue.json`, with no generated copy.
- Keep `project-state.json` for fixed facts only, and **calculate** counts and lists on demand.
- Mark `tasks/usage-ledger.jsonl` as union-merge, because it has the same problem.

## CI status: PRs 151 to 154

| PR | Branch tip | CI | Mergeable | Base |
|---|---|---|---|---|
| 151 | `829b67b` | **pass** (19s) | yes | `main` |
| 152 | `a655125` | **pass** (18s) | yes | `main` |
| 153 | `f215814` | **did not run** | **conflicting** | `task/TASK-0105-rules-foundation` |
| 154 | `df8ff35` | **did not run** | **conflicting** | `chore/mathshow-art-v2-shapefit` |

`gh pr checks` reports "no checks reported" for 153 and 154. The workflow runs on `pull_request`, and GitHub doesn't start that run while a PR conflicts with its base.

**Cause: the previous update.** `main` was merged into each branch separately, so child and base have different `project-state.json` timestamps, and 153 also conflicts in `tasks/queue.json`:
- 152 with 153: `project-state.json`, `tasks/queue.json`
- 151 with 154: `project-state.json`

No game code conflicts. `check.sh` passed locally on both tips before the push, and 153's last GitHub run passed on its older tip `c357098`. **Not fixed**, as this brief asks. Phase 3 fixes it by merging each base into its child.

## PR 155 decisions

| # | Decision | Verdict | Evidence | Proposal |
|---|---|---|---|---|
| a | `maps/finale_arena.json` belongs to GAME-001 | **Confirmed** | Created in `b39b5c2` (TASK-0007, ring-out finale). Only `FinaleService.luau` and `FinaleConfig.luau` in the GAME-001 archive mention it. References in `games/mathshow`: 0 | None |
| b | `test_hcm_codec.py` left the required gate | **Confirmed** | It tests the HCM1 mesh encoder for GAME-002's runtime art. A search for `hcart`, `HCM1` and `MeshCodec` in `games/mathshow`, `scripts`, `tests`, `.github` and `.claude` finds nothing | Keep it in `--archive`. Nothing active uses it |
| c | `games/haunted/` hidden by `.gitignore` | **Works, but only hides junk** | See the table below: 4 files, 0 tracked, all generated | **Delete with jg's approval**, then drop the ignore line |
| d | `98 Archive/` fits the numbering | **Partly** | Numbered prefix fits, but it's missing from the folder table in Obsidian Conventions, and `validate_vault.py` skips it because its pattern is `(0\d\|99)`. `10 References` is missing from that table too | Keep the folder; add both rows. The skip is right for retired notes, so document it |
| e | Readers of the renamed queue fields work | **Confirmed** | Ran `orchestrator.py validate`, `status`, `next` and `cycles`, `validate_queue.py`, `validate_vault.py`, `refs.py ledger` and `context_budget.py`, plus their tests: all OK. `dispatch TASK-0108` refused correctly because the task is `done`. No hook reads the queue. CI reads it only through `check.sh` | None |

Also found: two stale lines. Obsidian Conventions line 16 says "Game code stays in `src/`", and the `.gitignore` comment at line 34 says "`sourcemap.json` is GAME-002". Fix both in Phase 1.

### Decision c: every leftover

| Path in the main checkout | Size | Last changed | Tracked | Proposal |
|---|---|---|---|---|
| `games/haunted/art/hcart/__pycache__/__init__.cpython-315.pyc` | 158 B | 2026-10-18 | No | Delete (generated) |
| `games/haunted/art/hcart/__pycache__/codec.cpython-315.pyc` | 11,140 B | 2026-10-18 | No | Delete (generated) |
| `games/haunted/sourcemap.json` | 48 B | 2026-10-11 | No | Delete (generated) |
| `games/haunted/src/shared/BuildStamp.txt` | 29 B | 2026-10-26 | No | Delete (generated) |
| `game001-sourcemap.json` | 6 KB | 2026-10-30 | No | Delete (nothing writes it now) |
| `game004-sourcemap.json` | 9 KB | 2026-10-30 | No | Delete (nothing writes it now) |
| `haunted-sourcemap.json` | 8 KB | 2026-10-12 | No | Delete (nothing writes it now) |
| `sourcemap.json` | 9 KB | 2026-10-30 | No | Keep ignored: `typecheck.sh` and VS Code use it |
| `HauntedCollector.rbxl` | 245 KB | 2026-10-18 | No | **Keep:** the only local copy of that place |

Nothing here is worth moving to `archive/`, because all of it can be regenerated.

## Who reads and writes these files

| File or area | `tasks/queue.json` | `project-state.json` | Change needed |
|---|---|---|---|
| `scripts/orchestrator.py` | Reads, writes | Reads, writes | Shared loader; write only changed task files; stop writing calculated state |
| `scripts/validate_queue.py` | Reads | | Read `tasks/items/`; check file name equals `id` |
| `scripts/validate_vault.py` | Reads | | Shared loader |
| `scripts/refs.py` | Reads | | Shared loader |
| `scripts/context_budget.py` | Reads | | Shared loader |
| `scripts/migrate_queue.py` | Reads, writes | | Keep for old-format input; the new script calls it |
| `scripts/check.sh` | JSON step | JSON step | Validate every item file |
| `tests/test_active_game.py` | | Reads | Stop checking `rojo_project` |
| `tests/test_orchestrator.py`, `test_refs.py`, `test_validate_vault.py`, `test_validate_queue.py` | Fixtures | Fixture | Update fixtures |
| `.claude/hooks/*`, git hooks | None | None | None |
| `.github/workflows/check.yml` | Through `check.sh` | Through `check.sh` | None |
| `task-close` skill (both copies) | | Mentions | Update wording |
| Docs | `AGENTS.md`, `README.md`, `TASKS.md`, `PARALLEL.md`, 4 templates, `intake/README.md`, Planner, Orchestrator, Task Intake, Obsidian Conventions, Start Here, Studio Index | `AGENTS.md`, Studio Index, Obsidian Conventions | Update wording |
| Historical notes | ADR-0004, AI Context and Usage Workflow, audits, old tasks | | Leave as written |

## Decisions for jg

| # | Decision | Recommendation | Tradeoff | Alternative |
|---|---|---|---|---|
| 1 | Task storage | `tasks/items/TASK-####.json`, same fields, one per task | 99+ small files instead of one | |
| 2 | `tasks/queue.json` | **Remove it.** `orchestrator.py status` is the list | No single file to open or grep with a simple path; use `grep -l ... tasks/items/` | Generated and gitignored: it can go stale, and tools might read it by mistake |
| 3 | `project-state.json` | **Keep fixed facts only** (`project`, `phase`, `conventions`). Calculate counts, `ready`, `needs_human` and spend on demand with a new `orchestrator.py state`. Drop `active_game`, `rojo_project` and `rojo_place` (copies of `active-game.env`), `dispatch_mode` (copy of `budget.json`) and `vault` (a machine path) | Git no longer records count history; `HLT-` reports keep dated snapshots | Fully generated: loses `phase`, which is written by hand. Per-task split: nothing left to split once counts are calculated |
| 4 | Same-ID collisions | **Add `orchestrator.py next-id`**, which checks `main` and all branches. Two branches picking one ID then gets a loud add/add conflict | Small addition beyond the brief | Skip it and pick IDs by hand, as with TASK-0105 to 0107 |
| 5 | `tasks/usage-ledger.jsonl` | **Add a `.gitattributes` line, `merge=union`.** It's append-only, so it hits the same conflict. Built into git; `orchestrator.py validate` still catches markers | Outside the brief's two named files | Leave it and resolve by hand |
| 6 | Leftovers (decision c) | **Delete the 7 files**, then drop `games/haunted/` from `.gitignore` | Permanent, but all regenerate | Keep ignored |
| 7 | Vault docs (decision d) | Add `98 Archive` and `10 References` rows; fix the 2 stale lines | None | |

**Known limit:** task notes and game overview tables stay as they are. Two branches that edit the same overview table can still conflict, but that's rare, small and outside this brief.

## Proposed format

```
tasks/
  items/
    TASK-0001.json     same fields as docs/workflow/TASKS.md
    ...
  usage-ledger.jsonl   union merge
```

- JSON with indent 2, `ensure_ascii=True` and a trailing newline. The `version` field moves to `TASKS.md`.
- **Shared loader:** new `scripts/task_store.py` with `load_tasks(root)` (sorted by ID) and `save_task(root, task)`. Writes only when the content changed, so a transition touches one task file.
- **Validator** reads `tasks/items/*.json` and still enforces unique IDs, valid statuses, required fields and no `files_owned` overlap among `in_progress` tasks. It adds: file name equals `id`, and each file parses, naming the bad file.
- **Rule for agents:** add one file; never edit another task's file.
- **Migration:** `scripts/migrate-queue-to-items.py`, committed so open branches can run it. It reads whichever `queue.json` is present, upgrades old-format entries, writes missing item files and removes `queue.json`. If an item already exists and differs, it stops and names the task instead of overwriting.

## Phase 2 results

Run from `dc62848` in a temporary clone. Each branch added its own task file and note, appended a ledger line, then changed its own status with `orchestrator.py approve`.

```
$ git merge --no-edit b-TASK-0901
Fast-forward
unmerged files: 0
$ git merge --no-edit b-TASK-0902
Auto-merging tasks/usage-ledger.jsonl
Merge made by the 'ort' strategy.
unmerged files: 0
tasks: 101 task files, 1 in_progress, 0 errors
```

Both ledger lines survived. The same exercise on the old format:
```
CONFLICT (content): Merge conflict in tasks/queue.json
```

| Check | Result |
|---|---|
| Tasks before and after | 98 and 98, all identical in content when compared with the old queue. TASK-0109 makes 99 |
| `validate_queue.py` | `tasks: 99 task files, 1 in_progress, 0 errors` |
| `scripts/check.sh` | All 12 steps pass, exit 0 |
| Hook tests | 17 tests, OK |
| `git diff --stat main -- games/` | Empty |

## Phase 3: updating the open PRs

**Do this only after this branch has merged to `main`. jg approves each push.** `chore/workflow-hardening-report` needs no steps: it merged as PR 156 and was deleted.

Every step below was rehearsed in a temporary clone, using this branch as `main`:

| Branch | Conflicts during its update | Task files written | `check.sh` | `games/` changes |
|---|---|---|---|---|
| 151 | `project-state.json` | None (it has no task) | Pass | 0 |
| 152 | `project-state.json`, `tasks/queue.json` | TASK-0105 | Pass | 0 |
| 154 | `project-state.json`, `tasks/queue.json` | TASK-0107 | Pass | 0 |
| 153 | `project-state.json`, `tasks/queue.json` | TASK-0106 | Pass | 0 |

Afterwards, 152 with 153 and 151 with 154 had no conflicts. Merging all four onto the sharded base in order also had no conflicts: `check.sh` passed, with 102 task files and 275 specs.

### Order
1. Merge this branch to `main`.
2. Update and push **151**, then **152**, because each has `main` as its base.
3. Update and push **154**, from updated 151, and **153**, from updated 152. CI should then run on both, because the conflicts with their bases are gone.
4. Merge in any order that respects the stacks, retargeting a child to `main` when its base merges. Each merge should be clean.

### Commands
The preflight is chained because the guard hook blocks `git checkout` and `git commit` without it. Run `git status` before `git add -A`: the worktrees should hold only the merge, and anything else should be looked at first.

**151:** in `/Users/jg/Desktop/Rg1-worktrees/mathshow-art-v2`
```bash
git fetch origin
scripts/preflight.sh --root "$PWD" --branch chore/mathshow-art-v2-shapefit --clean && git merge --no-commit --no-ff origin/main
scripts/preflight.sh --root "$PWD" --branch chore/mathshow-art-v2-shapefit && git checkout origin/main -- project-state.json
python3 scripts/migrate-queue-to-items.py
git add -A
scripts/preflight.sh --root "$PWD" --branch chore/mathshow-art-v2-shapefit && git commit -m "chore: merge main and move to task files"
scripts/check.sh
```

**152:** the same in `/Users/jg/Desktop/Rg1-worktrees/task-0105`, with `task/TASK-0105-rules-foundation` as the branch in each preflight.

**154:** in `/Users/jg/Desktop/Rg1-worktrees/task-0107`, after 151 is pushed
```bash
git fetch origin
scripts/preflight.sh --root "$PWD" --branch task/TASK-0107-menu-art-v2 --clean && git merge --no-commit --no-ff origin/chore/mathshow-art-v2-shapefit
scripts/preflight.sh --root "$PWD" --branch task/TASK-0107-menu-art-v2 && git checkout origin/chore/mathshow-art-v2-shapefit -- project-state.json
python3 scripts/migrate-queue-to-items.py
git add -A
scripts/preflight.sh --root "$PWD" --branch task/TASK-0107-menu-art-v2 && git commit -m "chore: merge base and move to task files"
scripts/check.sh
```

**153:** the same as 154 in `/Users/jg/Desktop/Rg1-worktrees/task-0106`, with `task/TASK-0106-identity-ui` as the branch in each preflight and `origin/task/TASK-0105-rules-foundation` as the base.

**After each `check.sh` passes, and once jg approves that branch:**
```bash
scripts/preflight.sh --root "$PWD" --branch <branch> --clean && git push origin <branch>
```

### If something differs
- **The script says a task file differs:** the entry has changed on one side since this rehearsal, for example a status change after a merge. It writes nothing. Compare the two, then rerun with `--keep-existing` if the existing file is right. That removes `tasks/queue.json`, so the differing entry then survives only in git history.
- **Any conflict outside these two files:** stop and report it. None appeared in the rehearsal, but new commits could change that.
- **This branch's upstream:** it was created from `origin/main`, so push it with `git push -u origin chore/queue-sharding`, not a bare `git push`.
