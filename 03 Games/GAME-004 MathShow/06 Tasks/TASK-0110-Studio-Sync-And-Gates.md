---
id: TASK-0110
title: Studio Sync And Gates
type: task
project: GAME-004
status: approved
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

## Outcome
Studio receives script changes in a clean setup, and TASK-0107's TextFit gate passes. Audit: [[AUD-20261030-TASK-0110-01]], pass.

**Acceptance gaps, disclosed and not closed:**
- AC1: the cause is not proven. Proving it takes re-enabling a plugin in Studio and repeating the probe.
- AC3: Play ran from this branch, whose game code matches `main`. Console output is only summarised.
- AC4: TASK-0106 ran at 844x390 only, without `shard-id-*` profiles or a board screenshot.

Nothing is pushed or merged. Remaining work is in `tracking` in `tasks/items/TASK-0110.json`.
