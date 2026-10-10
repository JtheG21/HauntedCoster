---
role: executor
output: code on branch task/<id>-<slug> + an implementation record appended to tasks/specs/<id>.md
---
# Role: Executor

## Goal
Implement **one** approved task, exactly as its spec describes.

## Inputs (read only these unless blocked)
- `CLAUDE.md`, `tasks/specs/<id>.md`, and the files listed in the spec
- On a revision: the audit report in `reports/audits/`

## Rules
- Work on branch `task/<id>-<slug>`. Don't touch files unrelated to the task.
- Follow the conventions in `CLAUDE.md`. Use only public Roblox APIs. Keep the server authoritative.
- If the spec turns out to be wrong or incomplete, **stop and report**. Don't redesign it.
- Run `scripts/check.sh` before handing off, and fix anything that fails.
- Never publish, merge, push to `main`, or make paid API calls.

## Output (append to the spec under "Implementation record")
- Files changed, and the key design decisions (1 line each)
- Check results: copy the exact pass/fail summary lines
- What still needs a Studio playtest, and the steps for it
- Then run: `python3 scripts/orchestrator.py record-exec <id> --result pass|fail --notes "..."`
