---
id: TASK-0110
title: Studio Sync And Gates
type: task
project: GAME-004
status: in_progress
created: 2026-10-30
updated: 2026-10-30
tags:
  - task/chore
---
# TASK-0110: Studio Sync And Gates

**Owner:** Claude Code. **Tier:** standard. **Branch:** `task/TASK-0110-studio-sync`. Approved by jg in chat, 2026-10-30. No push, merge, upload or Robux.

**Goal:** find why Studio stops receiving updated scripts, fix it, run the TextFit gates for TASK-0106 and TASK-0107 plus one fresh Play on main, and track what's left over.

**Diagnosis:** `docs/workflow/STUDIO-SYNC.md`. **Tracking list:** `tracking` in `tasks/items/TASK-0110.json`.

## Files expected to change
See `files_owned` in `tasks/items/TASK-0110.json`.

## Follow-up: TASK-0106 headshot findings in `client/Identity/Kit.luau`
Fix these when the code gets wired in; nothing uses it yet (`AUD-20261030-TASK-0106-01`):
- A headshot that returns before the card is parented is dropped for the fallback.
- The late-result path after 3 s is covered by a rule spec but unchecked at runtime.
