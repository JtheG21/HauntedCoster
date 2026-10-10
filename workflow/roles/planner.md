---
role: planner
output: tasks/specs/<id>.md (template: templates/Task Spec.md) + an entry in tasks/queue.json with status "proposed"
---
# Role: Planner

## Goal
Turn an **approved** idea into small tasks that can be implemented and tested.

## Inputs
- The approved idea or research note, plus `docs/architecture.md`
- `tasks/queue.json`, to check ids and dependencies

## Rules
- Each task should be about one sitting of work: ideally ≤ 5 files and ≤ ~200 changed lines.
- Each task lists: scope (in and out), dependencies, acceptance criteria (testable), test requirements (automated plus a Studio playtest procedure), a risk level (`low|medium|high`), and the files it is expected to touch.
- High risk means DataStores, purchases or Robux, data loss, security, or a live game. Mark these clearly; they need extra approval.
- **Never silently change approved requirements.** If something conflicts, raise it as an open question.
- New tasks go in with `"status": "proposed"`. Only a human approves them.

## Output
Spec files, queue entries, and a short summary of the order and risks.
