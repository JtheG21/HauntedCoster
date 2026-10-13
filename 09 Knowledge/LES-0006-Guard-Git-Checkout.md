---
id: LES-0006
title: Guard Git Checkout
type: lesson
status: proposed
category: process
evidence:
  - "2026-10-10, TASK-0007 merge: the `cd` into a cleaned-up scratchpad merge worktree failed, and the chained commands ran in ~/Desktop/Rg1 on task/TASK-0007-Ring-Out-Finale. `git merge` said 'Already up to date' (it merged the branch into itself) and `orchestrator.py approve-merge` marked TASK-0007 done in that working tree. Caught from the output; the uncommitted queue, state and note changes were reverted, and the real merge was redone in a fresh worktree (567eaac)."
  - "2026-10-11: scripts/preflight.sh dry run against the real checkouts: missing worktree → exit 1; Rojo-watched checkout when main is expected → exit 1; a subfolder passed as the checkout → exit 1; the dedicated main worktree → exit 0"
applies_to:
  - Git operations by agents (merge, switch, commit, reset, clean, push)
  - scripts/preflight.sh
created: 2026-10-11
updated: 2026-10-12
tags:
  - knowledge/lesson
---

# Guard every Git operation with an explicit checkout check

## Problem
A merge meant for a dedicated `main` worktree ran in the main checkout instead, and the task tracker recorded a merge that never happened.

## Root cause
The command was `cd <worktree>; git merge ...; orchestrator approve-merge ...`. The worktree had been cleaned up, so `cd` failed; `;` doesn't stop on failure, so everything ran in the shell's current directory. Nothing checked which checkout or branch the operation was about to change.

## Solution
`scripts/preflight.sh --root <checkout> --branch <expected> [--clean]` before any state-changing Git operation, chained with `&&`, and operations addressed with `git -C <checkout>`. It fails (exit 1) when the checkout is missing, isn't a checkout top level, is on another branch, or (with `--clean`) has uncommitted changes. Rules: `AGENTS.md` "Git safety"; procedure: [[Workflow]] "Merge procedure" (since 2026-10-12, merges run on GitHub with `gh pr merge`, so no local merge worktree is needed; the guard covers the local switch, pull and branch steps).

## Validation
8 unit tests (`tests/test_preflight.py`, in `scripts/check.sh`), including the exact missing-worktree case, plus the dry run above. Not yet exercised in a real merge. Ported to `main` on 2026-10-12 (audit plan T11) from the unmerged `chore/git-safety` branch, which is kept.

## Where this applies
Every merge, branch switch, commit, reset, clean or push run by an agent, especially from scratchpad worktrees that can be cleaned up between sessions.
