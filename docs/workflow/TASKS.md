# Task files and schema (version 2)

Each task is one file, `tasks/items/TASK-####.json`, and those files are authoritative for task status. `python3 scripts/validate_queue.py` checks them, and `scripts/check.sh` runs it. It also requires the file name to equal `id`, and fails if there are no task files or a `tasks/queue.json` is still present.

`python3 scripts/orchestrator.py status` lists every task. `state` prints the counts, what is ready and what waits on jg. They are calculated, not stored: `project-state.json` holds only `project`, `phase` and `conventions`.

## Fields

| Field | Type | Meaning |
|---|---|---|
| `id` | `TASK-####` | Unique. Take the next number after the queue **and** open branches. |
| `game` | `GAME-###` | The game the task belongs to. Studio-wide chores use the active game. |
| `title` | string | Short name. |
| `status` | enum | See below. |
| `tier` | `light`, `standard`, `deep` | AGENTS.md "Tiers". `null` only on finished older tasks. |
| `owner_agent` | `claude-code`, `codex`, `claude-design`, `task-audit`, `human` | Who implements it. `null` only on finished older tasks. |
| `files_owned` | array of paths or globs | What the task may change. Required once it is `in_progress`. |
| `depends_on` | array of task IDs | Must be `done` before start. |
| `branch` | string | `task/TASK-####-slug` or `chore/<slug>`. |
| `acceptance` | array of strings | At least one criterion. |
| `evidence` | array of strings | Paths or results that prove the criteria (audit notes, test notes). |
| `notes` | string | Free text. |
| `note_path` | string | The task note. |
| `risk` | `low`, `medium`, `high` | High means DataStores, Robux, data loss, security or a live game. |

Fields the orchestrator also keeps: `history`, `executions`,
`audits`, `revisions`, `approved_by`, `merge_approved_by`, `stacked_on`, `migrated_from`.

## Statuses

| Status | Meaning | Next | Who moves it |
|---|---|---|---|
| `backlog` | Written, waiting for plan approval | `ready`, `archived` | **jg** (`approve`) |
| `ready` | Approved, dependencies may be pending | `in_progress` | `start` |
| `in_progress` | Being implemented | `review`, `changes_requested` | `record-exec` |
| `review` | Being audited | `approved`, `changes_requested` | `record-audit` |
| `changes_requested` | Needs a revision (limit 2) | `in_progress`, `blocked` | `start` |
| `approved` | Audit passed, waiting for the merge decision | `done`, `changes_requested` | **jg** (`approve-merge`) |
| `blocked` | Limit hit or a decision is needed | `ready`, `backlog`, `archived` | **jg** (`unblock`) |
| `done` | Merged | terminal | |
| `archived` | Dropped or unstarted when its game was paused | terminal | `archive` |

`approved` and `changes_requested` go beyond the seven statuses first proposed. jg chose to keep them on 2026-10-30, because the
merge gate and the revision limit depend on them. History entries keep the names they were written with, including the older
`proposed` and `in_review`.

## The `files_owned` rule
A file may be in the `files_owned` of **at most one `in_progress` task**. That is what stops parallel agents overlapping.

- Paths match themselves and everything below them; globs use `*`, `?` and `[]`, and `*` also crosses `/`.
- Give folders a trailing `/`: without one, a name with a dot (`a/v1.2`) is read as a file.
- Two globs overlap if their fixed prefixes overlap. That is deliberately cautious, so narrow the globs if it complains.
- See `docs/workflow/PARALLEL.md` for how shared contracts are handled.

## How to add a task
1. Run `python3 scripts/orchestrator.py next-id`, which checks `main` and every branch.
2. Create one file, `tasks/items/TASK-####.json`, with every field above: indent 2, ASCII only, trailing newline.
3. Create the task note and set `note_path` to it. The note's `status` must match.
4. **Never edit another task's file.** Transitions go through the orchestrator, which writes only the file that changed.

If two branches still pick one ID, git reports an add/add conflict on that file. Renumber one of them.

## Migrating a branch
A branch from before this format has a `tasks/queue.json`. Merging `main` reports a modify/delete conflict on it and usually a conflict on `project-state.json`.

```bash
git merge origin/main
git checkout origin/main -- project-state.json
python3 scripts/migrate-queue-to-items.py
git add -A
git commit
scripts/check.sh
```

The script upgrades old-format entries, writes the missing task files, mirrors renamed statuses into task notes and removes `queue.json`. If an existing task file differs, it stops, writes nothing and names the task. Check it, then rerun with `--keep-existing` if the existing file is right.
