---
name: codex-handoff
description: Write the independent-review handoff for a Rg1 task that Claude implemented, so Codex can review it. Builds it from the task's commits, changed files, audit findings and known failures, adds it to the task note under "Handoff", and gives jg the line to paste into Codex. Use when a Claude-owned task has passed check.sh, its Studio checks and the audit, and jg wants the Codex review.
argument-hint: TASK-####
---
# Codex review handoff for $ARGUMENTS

Follows `99 Templates/T - Handoff.md` (light form) and AGENTS.md "Claude and Codex". The handoff is a prompt saved in the task note, not a new vault note.

1. **Locate.** `python3 scripts/orchestrator.py status` and the task note: owner (must be Claude; if Codex owns it, stop) and branch. Find the worktree with `git worktree list`.
2. **Gather facts; don't paste code.**
   - Commit range for this revision: `git -C <wt> log --oneline` from the first commit of the revision to HEAD. Use the revision's first commit, not `main...HEAD`: task branches stack on unmerged work and pull in unrelated commits.
   - Changed files: `git -C <wt> diff --stat <first>^..HEAD`. Pick the files where behaviour changed (code, build config, data with budgets), not notes.
   - Audit findings and how each was addressed (the task note's Audits section, or the auditor hand-back).
   - Known failures that aren't this task's, e.g. `validate_vault` mismatches on other tasks.
   - What is unverified (Studio in motion, live Rojo sync, publishing).
3. **Write the "Handoff (Codex review, <rev>, <date>)" section** above "## Audits" in the task note, in 15 lines or fewer:
   Task and objective, receiver (Codex, reviewer, no edits), workspace and branch and commit range, inputs as `[[links]]`, the review focus (3–5 bullets, each a file plus a concrete question), constraints (no uploads, publishing or Studio writes; who holds Rojo), known non-task failures, and what to report back (verdict, findings with file:line, checks run, what is unverified).
4. **Commit and push** on the task branch, with `scripts/preflight.sh` chained.
5. **Give jg the paste line**: `Review <TASK> <rev> on branch <branch> (worktree <path>). Follow the "Handoff (Codex review, <rev>)" section in the <TASK> note. Review only, no edits.`
6. When Codex reports back, record the verdict and findings under "## Audits" as a new line. Never edit earlier findings.
