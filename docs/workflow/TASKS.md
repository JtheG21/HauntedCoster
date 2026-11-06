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

**Executor and auditor.** The executor is the task's `owner_agent`. The audit record is the **report**, not the JSON: an
`06 QA/<audit id>.md` file whose frontmatter holds `id` (equal to the file name), `task_id`, `verdict: pass|fail`,
`reviewed_commit` (the full 40-hex SHA it measured) and `reviewer` (e.g. `codex`). Each `audits` entry in the task JSON is
an **index only**: `result`, `measured_sha`, `auditor`, `report`, `report_sha256` and `applies_to`, plus `advisory: true`
for a PASS from an auditor not in the independent list, and `post_merge: true` with `remediation` for a finding on a done
task. `merge_approval` holds `{by, text, pr, head_sha, base_sha, time}` and `merged` holds
`{pr, merge_commit, merged_at, head_sha, recorded_at}` (plus `override: true` after `override-merge`). Older audit
records without these fields cannot approve a merge; such a task needs a new audit.

## Audit-head rules
Every decision (the `audit-gate` check, `approve-merge`, `mark-merged`) runs `scripts/audit_gate.py`, which reads only
committed Git objects at decision time and never reads `status`. `approved` is a prerequisite for `approve-merge` and
`mark-merged`, never sufficient.
- **The report decides.** The decisive report is the newest report whose frontmatter names the task, and it must be the
  last non-post-merge JSON entry. Its own `verdict`, `reviewed_commit` and `reviewer` are used. The gate refuses when the
  JSON disagrees with it (result, measured SHA, auditor or sha256), when a report names the task but is not indexed, or
  when the JSON order does not match the order the reports were added.
- **Reports are immutable.** Exactly one commit adds each report, and its blob at the head equals the blob at that
  commit. An edited, deleted-and-re-added or symlinked report, or a second file with the same audit id (frontmatter `id`
  or file name), refuses. A new audit is a new report with a new id.
- **Tier is pinned.** Tier, `owner_agent`, `note_path`, `branch` and `id` come from the task JSON on the PR base, or, for a
  new task, from the commit that added the JSON. Any change to them on the branch refuses, as does more than one task file
  naming the branch at the base or the head.
- **Standard is deep.** A standard or deep task needs a PASS whose reviewer is a listed independent auditor (`codex`,
  `INDEPENDENT_AUDITORS` in `audit_gate.py`) and not the pinned `owner_agent`. A light task needs no audit; `approve-merge`
  then needs every check green. An untiered task is treated as deep.
- **Paths after the audit.** The reviewed commit must be an ancestor of the head. `git diff --raw --no-renames
  <reviewed>..<head>` (a rename counts as a delete and an add, so both sides are judged) may touch only regular `100644`
  files in `06 QA/` (`.md`), `tasks/items/` (`.json`), `docs/workflow/evidence/` and the one pinned task note, which must be
  `03 Games/<game>/06 Tasks/<TASK-####>-<slug>.md`. Matching is per path component, so `06 QA-x/` is source. Symlinks,
  submodules, mode and type changes refuse even in those paths.
- **Chore branches** pass without a task only if nothing under `games/`, `scripts/` or `.github/`, no `.gitmodules` or
  `.gitattributes`, and no symlink or submodule changed (renames counted on both sides).
- **`record-audit TASK-#### --verdict pass|fail --report "06 QA/<id>.md" --measured-sha <40 hex> --applies-to <paths...> --auditor <who> [--post-merge --remediation TASK-####]`**
  indexes a report. The flags must equal the report's frontmatter, the SHA must be a commit here, the auditor must not be
  `owner_agent`, and a report or audit id already indexed refuses. Only a PASS by a listed independent auditor moves a
  standard or deep task to `approved`; any other reviewer's PASS is indexed as `advisory` and the status stays `review`. No
  other command moves a standard or deep task to `approved`. With `--post-merge` the task must be `done`: the finding is
  appended with its remediation task and the status does not change. `reopen` is unchanged.
- **`approve-merge TASK-#### --by <human> --pr N --approval-text "<verbatim>"`** needs every `gh pr view` field it uses
  (OPEN, `isDraft: false`, this task's branch, full head and base SHAs), runs the gate on that head and base, and records
  `merge_approval` with both SHAs. It never sets `done`. Do not commit the approval record to the PR branch: that moves the
  head.
- **`mark-merged TASK-#### --pr N`** needs a `merge_approval` for that PR and sets `done` only if GitHub reports MERGED with a
  full merge commit SHA and time, from this task's branch, **and the merged head equals the approved `head_sha`**. It re-runs
  the gate at that head against the approved base. Anything else refuses; a post-merge finding is the way to record it.
- **CI:** `.github/workflows/audit-gate.yml` (job `audit-gate`) runs on `pull_request_target`. It checks out the **base**
  commit into `gate/` and runs `python3 -I gate/scripts/audit_gate.py`; the PR head is checked out into `pr-data/` as data
  and passed only as `--root`: nothing from it is executed, imported or installed. Permissions are `contents: read` and
  `pull-requests: read`, `persist-credentials: false`, untrusted names reach the script through `env` only, actions are
  pinned to full SHAs, any non-zero exit fails, and a PR from another repository is refused. Requiring the check is a
  branch-protection setting, made by jg by hand.

## Known limitations
- **Identity is self-asserted.** The report's `reviewer`, the task's `owner_agent` and `--by` are text anyone with push access
  can write; the gate checks they are consistent and independent, not who wrote them. Signed audit commits (TASK-0141) close
  this.
- **The first PR that introduces or changes the gate is not gated by it.** `pull_request_target` runs the base branch's
  workflow and code, so PR #205 (which adds this version) runs the old one, or none. Its merge rests on jg's review and the
  Codex audit.
- **A new task's tier is whatever its first commit says.** jg's plan approval is the check on it; the gate only stops it
  changing afterwards.

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

**Merging over a failed audit** is jg's decision alone. After jg merges, `python3 scripts/orchestrator.py override-merge TASK-#### --by jg --reason "..." --pr N` sets `done` only if GitHub reports the PR MERGED from this task's branch and the decisive report at the merged head says fail. The verdict stays a fail, and who decided and why go on that audit record.

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
