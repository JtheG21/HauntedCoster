# Task queue schema

`tasks/queue.json` is authoritative for task status. `python3 scripts/validate_queue.py` checks this schema, and
`scripts/check.sh` runs it.

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

Fields the orchestrator also keeps: `note_path` (the task note), `risk` (`low`, `medium`, `high`), `history`, `executions`,
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

- Paths match themselves and everything below them; globs use `*`, `?` and `[]`.
- Two globs overlap if their fixed prefixes overlap. That is deliberately cautious, so narrow the globs if it complains.
- See `docs/workflow/PARALLEL.md` for how shared contracts are handled.

## Adding and migrating
- The orchestrator has no `add` command. Add entries by hand with `ensure_ascii=True` and indent 2, and create the task note.
- `scripts/migrate_queue.py` upgrades old-format entries and their notes, and it's safe to rerun. PRs opened before this schema
  add old-format entries: after merging one, run it and commit the result.
