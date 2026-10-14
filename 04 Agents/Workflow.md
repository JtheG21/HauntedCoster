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
| `in_progress` | Executor working on `task/TASK-####-slug` | `in_review` / `changes_requested` | `record-exec` |
| `in_review` | Auditor reviewing | `approved` / `changes_requested` | `record-audit` |
| `changes_requested` | A check or audit failed (+1 revision) | `in_progress` / `blocked` | `start` |
| `approved` | Audit passed, merge pending | `done` | **Human** (`approve-merge`, then merge) |
| `blocked` | Retry limit hit or a decision is needed | `ready` / `proposed` / `archived` | **Human** (`unblock`) |
| `done` / `archived` | Terminal | | |

`max_revisions` (default 2) is in `00 Studio/budget.json`. Going past it blocks the task. Nothing retries automatically.

## Merge procedure (human-approved merges only)
1. Merge on GitHub without a local checkout: `gh pr merge <N> --repo JtheG21/HauntedCoster --merge --subject "Merge pull request #<N> from JtheG21/<branch> (approved by <who>)"`, after CI passes.
2. Stop Rojo, then `scripts/preflight.sh --root <main checkout> --clean && git -C <main checkout> switch main && git -C <main checkout> pull --ff-only`.
3. Delete the branch locally and on the remote. Task branches run `orchestrator.py approve-merge` and the outcome notes on the branch **before** step 1, so the merge carries them.

## Isolation
- One Git branch per task, from an up-to-date `main`. Workflow and doc changes use `chore/<slug>` branches.
- Only `src/` and `tests/luau` reach Studio, through Rojo. Playtest in a **local place file**, never the published experience.

## Check order: cheapest first
1. `scripts/check.sh`: StyLua, Selene, strict types, Rojo build, JSON, queue, vault conventions, Python tests. Free and deterministic.
2. The Studio playtest procedure from the task (human, or Claude through Studio MCP) → a `TEST-` note.
3. AI audit (a fresh context) → an `AUD-` note. Only after steps 1–2 are green.

**Automated checks prove:** formatting, lint, types, that the project builds, tooling correctness, and note hygiene.
**They don't prove:** gameplay correctness, replication, feel, or performance under load. Those need a Studio playtest. Run a multi-player playtest whenever a task touches shared state, **before** asking for merge approval.

## Human gates (always)
Approving a plan · approving a merge · major design changes · DataStore schema changes · anything that touches Robux · publishing · paid API calls · changes to a live experience · deciding what happens to Inbox items · accepting an ADR.

## Finished model production
Use [[Model Approval Workflow]] and [[Asset Workflow]]. A formal audit pass requires evidence for every required criterion; unresolved required criteria keep the task in review or changes requested. Technical checks, visual review and jg acceptance are separate records. Review a stable commit with its evidence; do not review a moving checkout as a completed deliverable.
