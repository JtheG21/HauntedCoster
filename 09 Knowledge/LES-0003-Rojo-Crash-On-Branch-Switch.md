---
id: LES-0003
title: Rojo Crash On Branch Switch
type: lesson
status: approved
category: bug-pattern
evidence:
  - "rojo serve log 2026-10-10: 'Rojo crashed! You are running Rojo 7.7.0 … Canonicalize … NotFound … path: /Users/jg/Desktop/Rg1/src/server/Abilities' (change_processor.rs:179)"
applies_to:
  - rojo serve
  - git branch switching
created: 2026-10-10
updated: 2026-10-10
tags:
  - knowledge/lesson
---
# Switching git branches can crash `rojo serve` 7.7.0

## Problem
`rojo serve` exited with code 1 right after `git switch main` from a task branch. The Studio plugin silently stopped syncing, so new files didn't appear.

## Root cause
The task branch had added `src/server/Abilities/`. Switching branches deleted that folder while Rojo was watching it, and Rojo 7.7.0 panics when it can't canonicalize the removed path (`change_processor.rs:179`).

## Solution
- After switching branches when new folders appear or disappear, **check that `rojo serve` is still running** (`lsof -i :34872`), restart it if needed, and **reconnect the Studio plugin**.
- Prefer finishing (or pausing) Studio tests before switching branches.

## Validation
Seen once, on [[TASK-0002-Ability-Framework]] → [[TASK-0009-Multi-Client-Test-Harness]]. The restart worked. Studio needed a manual reconnect.

## Where this applies
Any workflow that switches branches while `rojo serve` runs. Candidate automation: a check in `scripts/check.sh` that warns if Rojo isn't listening.
