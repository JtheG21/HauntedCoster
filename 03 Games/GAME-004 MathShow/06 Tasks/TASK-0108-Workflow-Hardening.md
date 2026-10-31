---
id: TASK-0108
title: Workflow Hardening
type: task
project: GAME-004
status: approved
created: 2026-10-30
updated: 2026-10-30
tags:
  - task/chore
---
# TASK-0108: Workflow Hardening

**Owner:** Claude Code. **Tier:** deep. **Branch:** `chore/workflow-hardening`. Approved by jg in chat, 2026-10-30, for all phases; pushing and merging wait for jg.

**Goal:** make the repo a single-source-of-truth workflow for GAME-004 that new material can be dropped into, and archive the paused games. No gameplay changes.

**Audit and findings:** `docs/workflow/AUDIT-2026-10-30.md`. **PR draft:** `docs/workflow/PR-workflow-hardening.md`.

## Files expected to change
See `files_owned` in `tasks/queue.json`.

## Outcome
Phases 0 to 8 are complete on `chore/workflow-hardening`, unpushed. First audit failed with two majors ([[AUD-20261030-TASK-0108-01]]); revision 1 fixed them and the delta audit passed ([[AUD-20261030-TASK-0108-02]]). jg reported the Studio checks good (2026-10-30). Waiting on jg: merge. Details: `docs/workflow/PR-workflow-hardening.md`.
