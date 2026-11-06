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
`audits`, `revisions`, `approved_by`, `merge_approved_by`, `merge_approval`, `merged`, `stacked_on`, `migrated_from`.

**Executor and auditor.** The executor is the task's `owner_agent`. Each audit record also holds `auditor` (who ran it,
e.g. `codex`; it must differ from `owner_agent`, compared case-insensitively), `measured_sha` (the full commit it measured),
`applies_to` (paths or globs it covers), `report` and `report_sha256`, and for a finding on a done task `post_merge: true`
and `remediation` (a task id). `merge_approval` holds `{by, text, pr, head_sha, time}` and `merged` holds
`{pr, merge_commit, merged_at, head_sha, recorded_at}`. Older audit records have no `measured_sha`; they cannot be used to
approve a merge, so such a task needs a new audit.

## Audit-head rules
- **`record-audit TASK-#### --verdict pass|fail --report "06 QA/AUD-...md" --measured-sha <40 hex> --applies-to <paths...> --auditor <who> [--post-merge --remediation TASK-####]`.**
  The report must contain that exact SHA and a `verdict:` line equal to `--verdict`; the SHA must be a commit here; the
  auditor must not be `owner_agent`. `--result` still works as an alias of `--verdict`. With `--post-merge` the task must be
  `done`: the finding is appended with its remediation task and the status does not change. `reopen` is unchanged.
- **`approve-merge TASK-#### --by <human> --pr N --approval-text "<verbatim>"`** reads `gh pr view N` and refuses a PR that is
  not OPEN, is a draft, comes from another branch, or whose head the latest audit does not cover: a PASS whose `measured_sha`
  is an ancestor of the head, and `git diff --name-only <measured>..<head>` touching only `06 QA/`, `tasks/items/`,
  `docs/workflow/evidence/` and the task's own `note_path`. The offending files are printed. A deep-tier task needs the PASS
  from `codex`. A light-tier task needs every check green instead of a PASS. It records `merge_approval` and never sets `done`.
- **`mark-merged TASK-#### --pr N`** needs a recorded `merge_approval` for that PR and sets `done` only if GitHub reports
  MERGED, with the merge commit and time; the merged head must satisfy the same audit rule, otherwise it refuses and a
  post-merge finding is the way to record it.
- **CI:** `.github/workflows/audit-gate.yml` (job `audit-gate`) runs `scripts/audit_gate.py` on each non-draft PR against
  the PR head, using git only. Chore branches that change nothing under `games/` or `scripts/` pass at once. Requiring the
  check is a branch-protection setting, made by jg by hand.

## Statuses

| Status | Meaning | Next | Who moves it |
|---|---|---|---|
| `backlog` | Written, waiting for plan approval | `ready`, `archived` | **jg** (`approve`) |
| `ready` | Approved, dependencies may be pending | `in_progress` | `start` |
| `in_progress` | Being implemented | `review`, `changes_requested` | `record-exec` |
| `review` | Being audited | `approved`, `changes_requested` | `record-audit` |
| `changes_requested` | Needs a revision (limit 2) | `in_progress`, `blocked`, `review` | `start`; **jg** (`reopen`) |
| `approved` | Audit passed, waiting for the merge | `done`, `changes_requested`, `review` | **jg** (`approve-merge` records the approval, `reopen`); `mark-merged` sets `done` after a verified merge |
| `blocked` | Limit hit or a decision is needed | `ready`, `backlog`, `archived`, `review` | **jg** (`unblock`, `reopen`) |
| `done` | Merged (GitHub reported MERGED; `merged` holds the merge commit and time) | terminal | `mark-merged`; **jg** (`override-merge`) |
| `archived` | Dropped or unstarted when its game was paused | terminal | `archive` |

**Merging over a failed audit** is jg's decision alone: `python3 scripts/orchestrator.py override-merge TASK-#### --by jg --reason "..."`. The verdict stays a fail, and who decided and why go on that audit record.

**Reopening an approved re-scope:** use `python3 scripts/orchestrator.py reopen TASK-#### --to review --reason "..." [--by jg]` instead of hand-editing status.
Only `blocked`, `changes_requested` and `approved` may reopen; only `review` is supported. The reason must be non-empty; `--by` defaults to `jg`.
The command appends `{from, to, reason, by, at}` to history, preserves earlier history/audits/revision counts, and syncs the task-note status.

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
1. Run `git fetch origin`, then `python3 scripts/orchestrator.py next-id`, which checks every local and remote branch.
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
git add -u
git add tasks/items
git commit
scripts/check.sh
```

Don't use `git add -A` here. Older checkouts can hold generated files the old `.gitignore` hid, such as `game001-sourcemap.json`, `game004-sourcemap.json` and `games/haunted/`. After the merge they show as untracked, and `-A` would commit them. Leave them out; they're harmless.

The script upgrades old-format entries, writes the missing task files, mirrors renamed statuses into task notes and removes `queue.json`. If an existing task file differs, it stops, writes nothing and names the task. Check it, then rerun with `--keep-existing` if the existing file is right. That removes `queue.json`, so the differing entry then survives only in git history.
