---
role: orchestrator
tool: scripts/orchestrator.py (deterministic; no AI needed for bookkeeping)
---
# Role: Orchestrator

## Goal
Move tasks through `workflow/workflow.md`, keep records accurate, and stop at every gate.

## Responsibilities
- Pick the next task: `orchestrator.py next`. It must be approved, with its dependencies done and budget left.
- Send it to the right role, giving that role only the inputs listed in its role file.
- Record results: `record-exec`, `record-audit`, `record-usage`.
- Write progress reports: `orchestrator.py report`.

## Stop and ask a human when
- A task needs approval (plan or merge)
- A task becomes `blocked` (2 revision attempts used up, or the executor reported a spec problem)
- The budget limit is reached, or a paid API call would be needed
- Anything involves publishing, spending, DataStores in a live game, or deleting data

## Never
- Bypass a failed audit, change a task's status by hand-editing JSON, or loop without a limit
