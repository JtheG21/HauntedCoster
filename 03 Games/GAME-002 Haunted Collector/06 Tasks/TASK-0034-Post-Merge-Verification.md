---
id: TASK-0034
title: "Post-Merge Verification"
type: task
project: GAME-002
status: done
priority: high
risk: low
owner: executor
depends_on:
  - TASK-0033
branch: task/TASK-0034-Post-Merge-Verification
related:
  - "[[TEST-20261012-12]]"
  - "[[TEST-20261012-11]]"
created: 2026-10-12
updated: 2026-10-12
tags:
  - workflow/task
---

# Post-Merge Verification

## Goal
Run the Studio scenarios once on the merged `main` (`502a446`). Every earlier runtime result was recorded on a task-branch working tree, so the merged build of TASK-0019, 0021 and 0029–0033 had never run as a whole. This is audit finding AUDIT-001 (formal audit, 2026-10-12, chat report).

## Scope
- **In:** sync Studio to `main`; run FullLoop, ExploitProbe, CarryGuard, Retaliation, HabitatRotation, HabitatSwap, Reachability ×4 habitats; attempt CrossPlot once; record everything.
- **Out:** code changes; fixing the multiplayer harness (follow-up T2); Persistence (writes DataStores); device checks ([[TASK-0020-Physical-Device-Checks]] stays archived).

## Files expected to change
- This note, [[TEST-20261012-12]], `tasks/queue.json`. No game code.

## Acceptance criteria
- [x] AC1 Studio synced to `main@502a446` before any run (CaptureService 28503 bytes in Studio = repo). Evidence: [[TEST-20261012-12]].
- [x] AC2 The seven single-player scenarios, Reachability in all four habitats, run and recorded. Evidence: [[TEST-20261012-12]].
- [x] AC3 CrossPlot attempted once and recorded as blocked by the harness. Evidence: [[TEST-20261012-12]].
- [x] AC4 No game code changed; Persistence not run. Evidence: this branch's diff.

## Tests
- **Automated:** `scripts/check.sh` (no code changes).
- **Studio playtest procedure:** `rojo serve haunted.project.json`, connect it to `HauntedCollector.rbxl`, check source sizes, then run each scenario from Edit with `ExecutePlayModeAsync` inside `task.spawn`, as in [[TEST-20261012-12]].

## Risks / notes
- Proposed and approved in chat on 2026-10-12 as "T1" of the audit remediation plan (jg: "accept all defaults, start with T1 only").
- Retaliation step 4 now checks the pursuit at the hub edge, inside the give-up distance (`Retaliation.luau:213-229`). The audit's AUDIT-013 is superseded; this run observed it passing.

---
## Implementation record
- Synced through Rojo (jg connected the plugin). Studio's sources matched the repo before the runs.
- Results: see [[TEST-20261012-12]]. 11 single-player runs passed; CrossPlot blocked (only 1 of 2 player windows opened).
- The first three Reachability results (Woodland, Spider Woodland, Settlement) were lost when Studio's MCP connection moved to the CrossPlot client window; they were rerun after reconnecting.

## Audits
- [[AUD-20261012-TASK-0034-01]]: pass (records-only diff; minor template headings fixed)

## Outcome
- Merge approved by jg in chat on 2026-10-12 ("merge it once CI passes"); PR #35, CI passed.
- The merged `main@502a446` passes every single-player scenario. AUDIT-001 stays open only for CrossPlot (2-player harness), which is follow-up T2.
- AUDIT-013 is superseded: the Retaliation edge step tests a real boundary and passed.
