---
id: LES-0009
title: Rojo Partial Sync
type: lesson
status: approved
approved_by: jg
approved_on: 2026-10-18
category: bug-pattern
evidence:
  - "2026-10-18 (TASK-0060): after Rojo logged a WebSocket reset and 'Cannot rename instances yet', the published Haunted place showed the current BuildStamp (159a373) while ProfileRules still held Schema = 1, the Persistence scenario was the old version, and the two new ModuleScripts (CosmeticRules, Catalog) existed with empty Source. A plugin reconnect did not repair it. The first write run saved without cosmetics; after a hand sync (lengths checked against disk) write 9/9 and read 4/4 passed."
applies_to:
  - Studio Play tests and scenarios
  - scripts/studio-preflight.sh
created: 2026-10-18
updated: 2026-10-18
tags:
  - knowledge/lesson
---

# A matching build stamp doesn't prove Rojo synced every module

## Problem
A Studio run used a mix of new and old code. The build stamp matched the checkout, so preflight passed, but a changed module was still the old version and two new modules were empty. The test ran without failing loudly and gave a misleading result.

## Root cause
Hypothesis, not verified: after the plugin's WebSocket dropped, Rojo applied some patches (the new stamp, the new instances) and not others (Source updates). `BuildStamp` is just one more synced value, so it can be current while other modules aren't.

## Solution
- After syncing, check each module the task changed, not only the stamp: compare `#Source` in Studio with `wc -c` of the file on disk (and look for a known string in it). This takes a single `execute_luau` call.
- If anything is stale and a reconnect doesn't fix it, sync those modules by hand and record that in the task's evidence.
- Treat `WebSocket error` or `Cannot rename instances yet` in the Rojo log as a reason to re-check before any Play run.

## Validation
[[TASK-0060-Monetization-Persistence-Schema]] (implementation record, AC3). Approved by jg on 2026-10-18. A possible tooling follow-up is a per-changed-file length check in `studio-preflight`.

## Where this applies
Any Studio Play test or scenario run through Studio MCP, especially right after new files are added or when the Rojo log shows connection errors. See also [[LES-0005-Edit-Mode-Require-Cache]].
