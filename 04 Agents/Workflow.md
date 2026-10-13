---
id: AGENT-Workflow
title: Workflow
type: agent
status: approved
created: 2026-10-10
updated: 2026-10-13
tags:
  - workflow/process
---
# Development workflow

Start every task with [[Task Intake]] (routing, depth, proceed-or-ask). This note covers task states, gates and merges.

```
Idea (01 Inbox) → Research (RSH) → Proposed task (TASK, proposed) → [HUMAN: approve → ready]
  → Implementation (in_progress) → Automated checks → Independent audit (in_review → AUD)
  → (changes_requested, ≤ 2 revisions) → approved → [HUMAN: approve merge] → done
  → Knowledge update (Outcome, SYS, Overview, LES, RETRO)
```

## Task states (enforced by `scripts/orchestrator.py`; vocabulary from [[Obsidian Conventions]])

| State | Meaning | Next | Who moves it |
|---|---|---|---|
| `proposed` | Planner wrote the task | `ready` / `archived` | **Human** (`approve`) |
| `ready` | Approved, waits for its dependencies | `in_progress` | `start` |
| `in_progress` | Executor working on its task branch | `in_review` / `changes_requested` / `paused` | `record-exec`; **human** requests `pause` |
| `paused` | Work deliberately suspended; scope, evidence and revisions retained | `in_progress` | **Human** requests `resume` |
| `in_review` | Auditor reviewing | `approved` / `changes_requested` | `record-audit` |
| `changes_requested` | A check or audit failed (+1 revision) | `in_progress` / `blocked` | `start` |
| `approved` | Audit passed, merge pending | `done` | **Human** (`approve-merge`, then merge) |
| `blocked` | Retry limit hit or a decision is needed | `ready` / `proposed` / `archived` | **Human** (`unblock`) |
| `done` / `archived` | Terminal | | |

`max_revisions` (default 2) is in `00 Studio/budget.json`. Going past it blocks the task. Nothing retries automatically.

## Claude and Codex ownership
- jg assigns one implementation owner per task and an independent reviewer. Optional queue fields `owner` and `reviewer` accept `claude` or `codex`; when both are present they must differ. Roles (executor/auditor) remain separate from assistant identity.
- `python3 scripts/orchestrator.py assign TASK-#### --owner codex --reviewer claude` records assignments and mirrors them to the note. It does not approve or start work. Omitted fields keep their existing values. Older queues without assignments remain valid; legacy note `owner: executor` is replaced only when the queue explicitly assigns an owner.
- `status` displays assignments; dry-run `dispatch` includes the assigned assistant. Dispatch stays manual and makes no AI call.
- Pause only at jg's request: `python3 scripts/orchestrator.py pause TASK-#### --by jg --reason "other work first"`. Resume only at jg's request: `python3 scripts/orchestrator.py resume TASK-#### --by jg`. Both mirror status and `updated` to the note and update project state. Resume rechecks dependencies and budget; neither transition consumes a revision. Paused tasks are excluded from `next` and cannot execute or dispatch.
- Use separate worktrees for separate work. Only one assistant controls Studio/Rojo at a time. Hand off the task, owner/reviewer, checkout/branch, scope, diff or commit, check evidence, open decisions and next action; use [[T - Handoff]]. jg keeps all approval gates below.

## Merge procedure (human-approved merges only)
1. Merge on GitHub without a local checkout: `gh pr merge <N> --repo JtheG21/HauntedCoster --merge --subject "Merge pull request #<N> from JtheG21/<branch> (approved by <who>)"`, after CI passes.
2. Stop Rojo, then `scripts/preflight.sh --root <main checkout> --clean && git -C <main checkout> switch main && git -C <main checkout> pull --ff-only`.
3. Delete the branch locally and on the remote. Task branches run `orchestrator.py approve-merge` and the outcome notes on the branch **before** step 1, so the merge carries them.

## Isolation
- One Git branch per task, from an up-to-date `main`. Workflow and doc changes use `chore/<slug>` branches.
- GAME-002 Haunted Collector uses `games/haunted/src/{server,shared,client}` and `games/haunted/tests`, synced by `haunted.project.json` to its separate place. GAME-001 uses `src/` and `tests/luau` through `default.project.json` and is paused source material. Always match the project to the place.
- Playtest in a **local place file**. Tooling/documentation chores need their applicable automated tests; Studio is needed only when their acceptance criteria require runtime evidence.

## Check order: cheapest first
1. `scripts/check.sh`: StyLua, Selene, strict types, Rojo build, JSON, queue, vault conventions, Python tests. Free and deterministic.
2. The Studio playtest procedure from the task (human, or the assigned assistant through available Studio tools) → a `TEST-` note.
3. AI audit (a fresh context) → an `AUD-` note. Only after steps 1–2 are green.

**Automated checks prove:** formatting, lint, types, that the project builds, tooling correctness, and note hygiene.
**They don't prove:** gameplay correctness, replication, feel, or performance under load. Those need a Studio playtest. Run a multi-player playtest whenever a task touches shared state, **before** asking for merge approval.

## Human gates (always)
Approving a plan · approving a merge · major design changes · DataStore schema changes · anything that touches Robux · publishing · paid API calls · changes to a live experience · deciding what happens to Inbox items · accepting an ADR.
