---
id: TASK-0052
title: "Overhaul Verification and Review Package"
type: task
project: GAME-002
status: ready
priority: high
risk: medium
owner: executor
depends_on:
  - TASK-0041
branch: task/TASK-0052-Overhaul-Verification
related:
  - "[[SYS-Haunted-Art-Direction]]"
  - "[[SYS-Haunted-Monetization-UI]]"
  - "[[3D Model Quality Baseline]]"
created: 2026-10-13
updated: 2026-10-13
tags:
  - workflow/task
---

# Overhaul Verification and Review Package

## Goal
Verify the integrated overhaul and assemble the review package.

Part of the overhaul jg requested on 2026-10-13 (3D asset overhaul, full UI overhaul, approved monetization scope). jg authorized the local design and implementation work, creating scoped tasks and testing in local Studio places; publishing, spending, live products, uploads and merges stay gated.

## Scope
- **In:** Completion matrix, performance, persistence/rejoin, 2-player appearance, before/after evidence, docs and retro.
- **Out (non-goals):** Physical devices (jg), publishing.
- **Keep unchanged:** server authority, gameplay rules and tuning, existing interaction points and collisions, GAME-001.

## Intake
- **Category → workflow, depth:** Production → [[Game Production Workflow]], standard
- **References:** All task references.
- **Reuse:** existing builders keep their gameplay geometry; visuals move to the art pipeline from [[TASK-0042-Art-Pipeline-And-Direction]].
- **Branch stacking:** stacked on `task/TASK-0051-Shop-Inventory-And-Decoration-Editor` (queue field `stacked_on`); the queue dependency stays TASK-0041 because unmerged stacked work cannot be `done`.

## Files expected to change
- Notes and evidence only, plus fixes found in verification.

## Acceptance criteria
- [ ] AC1 Completion matrix covers every asset category, screen, monetization journey and verification requirement, separating implemented, verified, blocked and pending human review.
- [ ] AC2 Performance measured (triangles, instances, EditableMesh memory, frame time) against the budgets; persistence/rejoin and 2-player appearance tests recorded.
- [ ] AC3 Review package: local playable build, before/after comparisons, evidence links, test results and the exact approvals still required.

## Tests
- **Automated:** `scripts/check.sh`.
- **Studio playtest procedure:** local place `~/Roblox-Work/haunted/Overhaul.rbxl` built from this branch; scenarios named in the criteria; captures stored with the evidence.

## Risks / notes
- Runtime meshes use EditableMesh. Live use needs either jg's batch 3D import (an upload) or jg's 13+/ID verification plus the Creator Dashboard Mesh/Image API toggle ([[SYS-Haunted-Art-Direction]]).

---
## Implementation record

## Audits

## Outcome
