---
id: AGENT-Workflow
title: Workflow
type: agent
status: approved
created: 2026-10-10
updated: 2026-10-12
tags:
  - workflow/process
---
# Development workflow

Start every task with [[Task Intake]] (routing, depth, proceed-or-ask). This note covers task states, gates and merges.

```
Idea (01 Inbox) → Research (RSH) → Proposed task (TASK, backlog) → [HUMAN: approve → ready]
  → Implementation (in_progress) → Automated checks → Independent audit (review → AUD)
  → (changes_requested, ≤ 2 revisions) → approved → [HUMAN: approve merge] → done
  → Knowledge update (Outcome, SYS, Overview, LES, RETRO)
```

## Task states (enforced by `scripts/orchestrator.py`; vocabulary from [[Obsidian Conventions]])

| State | Meaning | Next | Who moves it |
|---|---|---|---|
| `backlog` | Planner wrote the task | `ready` / `archived` | **Human** (`approve`) |
| `ready` | Approved, waits for its dependencies | `in_progress` | `start` |
| `in_progress` | Executor working on `task/TASK-####-slug` | `review` / `changes_requested` | `record-exec` |
| `review` | Auditor reviewing | `approved` / `changes_requested` | `record-audit` |
| `changes_requested` | A check or audit failed (+1 revision) | `in_progress` / `blocked` | `start` |
| `approved` | Audit passed, merge pending | `done` | **Human** (`approve-merge`, merges on GitHub), then `mark-merged` |
| `blocked` | Retry limit hit or a decision is needed | `ready` / `backlog` / `archived` | **Human** (`unblock`) |
| `done` / `archived` | Terminal | | |

`max_revisions` (default 2) is in `00 Studio/budget.json`. Going past it blocks the task. Nothing retries automatically.

## Merge procedure (human-approved merges only)
1. The task note's Outcome is committed and pushed on the task branch first. Then `orchestrator.py approve-merge TASK-#### --by jg --pr <N> --approval-text "<jg's words>"` in the task worktree runs the CI gate on the PR head and records the approval with that head; **don't commit or push it to the PR branch** (that moves the approved head). jg merges on the GitHub UI after CI, including `audit-gate`, passes. Agents never merge, approve or mark done.
2. Afterwards, on a `chore/` branch from `main` with the task file carried over from the task worktree, `orchestrator.py mark-merged TASK-#### --pr <N>` sets `done` only if GitHub reports MERGED with exactly the approved head; commit it with the remaining outcome notes. Stop Rojo, then `scripts/preflight.sh --root <main checkout> --clean && git -C <main checkout> switch main && git -C <main checkout> pull --ff-only`.
3. Delete the branch locally and on the remote.

## Isolation
- One Git branch per task, from an up-to-date `main`. Workflow and doc changes use `chore/<slug>` branches.
- Only the active game's project file (`AGENTS.md`) reaches Studio, through Rojo. Playtest in a **local place file**, never the published experience.

## Who owns what (Claude, Codex, side sessions)
- **Before starting:** `orchestrator.py status` for `in_progress` tasks, `git worktree list`, and `orchestrator.py next --parallel-safe` for overlapping "Files expected to change". If another session's task touches the same files, stop and ask jg.
- **One owner per task, one writer per file set.** The task note's `owner:` is `executor` until jg names Claude or Codex; write the owner's name in the Implementation record when you start.
- **Each session works in its own worktree and branch.** State changes (`approve`, `start`, `record-*`) are made in that branch's worktree so they merge with the code, not left uncommitted in the main checkout.
- **Handoff between tools:** the `codex-handoff` skill writes it into the task note; the reviewer verifies, never inherits, the other's claims. A finished side session's report is a claim until the diff is checked.
- **Studio and Rojo:** one assistant at a time; say in the task note who holds them.

## Check order: cheapest first
1. `scripts/check.sh`: StyLua, Selene, strict types, Rojo build, JSON, queue, vault conventions, Python tests. Free and deterministic.
2. The Studio playtest procedure from the task (human, or Claude through Studio MCP) → a `TEST-` note.
3. AI audit (a fresh context) → an `AUD-` note. Only after steps 1–2 are green.

**Automated checks prove:** formatting, lint, types, that the project builds, tooling correctness, and note hygiene.
**They don't prove:** gameplay correctness, replication, feel, or performance under load. Those need a Studio playtest. Run a multi-player playtest whenever a task touches shared state, **before** asking for merge approval.

## Human gates (always)
Approving a plan · approving a merge · major design changes · DataStore schema changes · anything that touches Robux · publishing · paid API calls · changes to a live experience · deciding what happens to Inbox items · accepting an ADR.
Before any publish, every gate in `docs/workflow/PUBLISH-CHECKLIST.md` must hold (profile v3 cutover: TASK-0141).
