---
name: task-close
description: Close out a Rg1 task at the end of a work stage. After implementation it runs the checks and records the run for audit; after jg approves the merge it writes the outcome notes the merge must carry. Always ends with a handoff (when work leaves the session) and the session summary. Use when jg says a task is finished or asks to wrap up, record or hand off a task.
argument-hint: TASK-####
disable-model-invocation: true
---
# Close out $ARGUMENTS

This packages steps that already exist: AGENTS.md (knowledge protocol #9 and #17, Git safety), `04 Agents/Task Intake.md` step 10 and "Handoffs", and `04 Agents/Workflow.md`. Those notes win if they disagree with this list. Stop and report when a step fails. Never record a failed check as passed.

## 1. Locate
- `python3 scripts/orchestrator.py status`: the status of $ARGUMENTS. The task note says who owns it (Claude or Codex) and which branch. If Codex owns it, stop here: you only review.
- Confirm the checkout and branch with `git -C <checkout> status`. Preserve unrelated changes.

## 2. By status
**`in_progress` (implementation finished)**
1. `scripts/check.sh` in the task checkout. Quote its summary line.
2. Studio evidence: link the `TEST-` note, or report "needs manual Studio check". A Rojo build or headless specs are not runtime proof.
3. Fill the task note's **Implementation record**: files changed, checks and their results, and each acceptance criterion with its evidence and a reporting state (implemented and tested / implemented, not tested / planned / blocked / needs manual Studio or Blender check).
4. `python3 scripts/orchestrator.py record-exec $ARGUMENTS --result pass|fail --notes "<one line>"`. Then log the executor's cost: read `mcp__ccd_session_mgmt__get_usage` (`context.tokensUsed`) when the task starts and again here, and record the growth: `python3 scripts/orchestrator.py record-usage $ARGUMENTS --kind subscription --role executor --tokens <close minus start> --model <model> --note "context growth over the task, not cumulative billing"` (check `--help` for the flags). If the start reading is missing, skip it rather than record the close figure; never estimate one. Note the weekly plan percent from the same call in the task note.
5. On a pass, the next step is the audit: the `auditor` agent, once per task. Don't start it unless jg asked.

**`review`:** not a close-out. Run the audit, write the `AUD-` note (with the measured SHA and a verdict line), then `record-audit --verdict ... --measured-sha ... --applies-to ... --auditor ...`.

**`approved` (audit passed)**
1. Go on only after jg approves the merge in chat. On the task branch write only the task note's **Outcome** (update `updated:`), then commit and push it: after the audit, only `06 QA/`, `tasks/items/`, evidence and that note may change.
2. Then `python3 scripts/orchestrator.py approve-merge $ARGUMENTS --by jg --pr <N> --approval-text "<jg's words, verbatim>"`. It runs the CI gate on the PR head and records the approval with that head. **Don't commit or push that record to the PR branch**: it would move the head, and `mark-merged` accepts only the approved head. jg merges on GitHub; you never merge or mark done.
3. After the merge, on a `chore/` branch from `main`, carry the task file over from the task worktree (it differs from main only by `merge_approval`), run `mark-merged $ARGUMENTS --pr <N>`, and commit it with the rest of the outcome notes, updating `updated:` on each:
   - the game's `00 Overview`, the affected `SYS-` notes and the Technical Architecture note, only where a fact in them changed (link the task note's evidence; don't restate it)
   - a Resource Catalog row if something reusable came out of it; a `LES-` note only with evidence
4. Merge only through the `04 Agents/Workflow.md` merge procedure.

## 3. Validate and commit
- `python3 scripts/validate_vault.py`. Fix what this task caused; report anything else.
- Commit on the task branch, chained after the guard: `scripts/preflight.sh --root <checkout> --branch <branch> && git -C <checkout> commit ...`. Push the branch (AGENTS.md "Git safety"); open a PR only if jg asked.

## 4. Hand off and summarize
- If work leaves this session (Codex review, another tool, a fresh session), fill `99 Templates/T - Handoff.md`, sized to the task, under the task note's "Handoff" heading.
- `python3 scripts/orchestrator.py report` to refresh the health report; commit it with the task.
- Session summary: the notes created, updated and left pending, and why.
