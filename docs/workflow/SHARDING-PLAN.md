# Queue sharding plan (Phase 0 of chore/queue-sharding)

**Reserved ID:** TASK-0109. It's the next free number across `main` and every branch, whose highest is TASK-0108. **Tier:** standard.

**Status:** waiting for jg's "approved". Recon ran read-only against `main` at `7fdef5c`. No task has moved and nothing is pushed.

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

## After approval
- **Phase 1:** one migration commit, then the code and docs. TASK-0109 is added as its own item file.
- **Phase 2:** two-branch merge test in a temporary clone, `check.sh`, task count (98 plus TASK-0109, so 99), hook tests, then one Sonnet audit as `AGENTS.md` requires for Standard tasks.
- **Phase 3:** written plan only. **`chore/workflow-hardening-report` needs no steps:** it merged as PR 156 and was deleted. Expected order, to be confirmed against the sharded `main`:
  1. 151 and 152: merge `main`, run the migration script, run `check.sh`.
  2. 154: merge updated 151; 153: merge updated 152. This also clears the conflict above and lets CI run.
  3. Stop. jg approves pushes per branch.

No file under `games/` changes in any phase.
