---
type: workflow
---
# Development workflow

```
Idea → Research → Proposed plan → [HUMAN: approve] → Scoped implementation
     → Automated checks → Independent audit → (Revision ≤ 2) → [HUMAN: approve merge]
     → Merge → Docs & knowledge update
```

## Task states (enforced by `scripts/orchestrator.py`)

| State | Meaning | Next | Who moves it |
|---|---|---|---|
| `proposed` | Planner wrote the spec | `approved` / `cancelled` | **Human** (`approve`) |
| `approved` | Ready once its dependencies are `done` | `in_progress` | `start` |
| `in_progress` | Executor working on `task/<id>-<slug>` | `in_audit` / `revision` | `record-exec` |
| `in_audit` | Auditor reviewing | `awaiting_merge` / `revision` | `record-audit` |
| `revision` | A check or audit failed. Attempt count +1 | `in_progress` / `blocked` | `start` |
| `awaiting_merge` | Audit passed | `done` | **Human** (`approve-merge`, then merge the branch yourself) |
| `blocked` | Retry limit hit or a decision is needed | any (human decides) | **Human** (`unblock`) |
| `done` / `cancelled` | Terminal | | |

`max_revisions` (default 2) is in `workflow/budget.json`. Going past it blocks the task. Nothing retries automatically.

## Isolation
- One Git branch per task: `git switch -c task/<id>-<slug>` from an up-to-date `main`.
- Only `src/` reaches Studio, through Rojo. Playtest in a **local place file**, never in the published experience.

## Check order: cheapest first
1. `scripts/check.sh`: StyLua format, Selene lint, Rojo build, JSON and orchestrator validation, Python tests. Free and deterministic.
2. Studio playtest procedure from the spec. A human runs it, or Claude runs it through Studio MCP.
3. AI audit. Only after steps 1–2 are green.

**What the automated checks prove:** formatting, lint rules, that the project builds, and that the Python tooling is correct.
**What they don't prove:** gameplay correctness, network or replication behavior, feel, or performance under load. Those need a Studio playtest (and later, multi-client tests).

## Human gates (always)
Approving a plan · approving a merge · major design changes · DataStore schema changes · anything that touches Robux or monetization · publishing · paid API calls · changes to a live experience.

## After merge
- Update the task spec's "Outcome" section, `docs/architecture.md` if the structure changed, and add an ADR if a decision was approved.
- Add to `docs/lessons-learned.md` only if something new was learned (a recurring bug, a failed approach, a good pattern).
- Run `python3 scripts/orchestrator.py report`.
