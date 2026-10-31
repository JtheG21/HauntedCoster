# Running agents in parallel

jg decides when agents run side by side (AGENTS.md "Tiers"). These rules keep their work from colliding.

1. **Disjoint `files_owned`.** A file may be in the `files_owned` of at most one `in_progress` task. `scripts/validate_queue.py` fails the gate on any overlap. Check first with `python3 scripts/orchestrator.py next --parallel-safe`.
2. **Shared contracts land first.** `shared/` contracts (types, `<Name>Config`, `Net`) are owned by one task, and that task merges before the others start depending on it.
3. **Others consume, they don't edit.** Other agents list those files as read-only in their handoff. A needed change goes back to the contract's owner as a new or revised task.

## Also
- One worktree per task. The main checkout stays on `main`.
- One assistant uses Studio and Rojo at a time, however disjoint the files are.
- `tasks/queue.json` is the one file everyone touches. Change only your own task's entry, and keep every entry when resolving a conflict.
- A remote payload change spans sender, handler and receiver, so one task owns all three.
- Stacked PRs: name the base in `stacked_on` and retarget to `main` when the base merges.
