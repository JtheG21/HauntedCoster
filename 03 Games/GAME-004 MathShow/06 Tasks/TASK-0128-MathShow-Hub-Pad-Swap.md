---
id: TASK-0128
title: "MathShow Hub: swap VS and Group pad sides to match A2"
type: task
project: GAME-004
status: done
priority: low
risk: low
owner: claude-code
depends_on: []
branch: task/TASK-0128-pad-swap
related:
  - "[[TASK-0127-MathShow-Hub-Art-Competitive]]"
created: 2026-11-02
updated: 2026-11-02
tags:
  - workflow/task
---

# MathShow Hub: swap VS and Group pad sides to match A2

## Goal
From the path, VS is on the left and Group on the right, as in A2. Today it is reversed (VS at z=+26). Row requested by jg, 2026-11-02. Stacked on [[TASK-0127-MathShow-Hub-Art-Competitive]].

## Scope
- **In:** the VS and Group lateral positions in `scripts/build_hub.py` (pads, arches, signs follow), regenerated `Hub.rbxmx`, Studio checks.
- **Out (non-goals):** anything else, merging.
- **Keep unchanged:** pad sizes, tags, Mode attributes, ModePadService, walk-time limits.

## Files expected to change
`scripts/build_hub.py`, `games/mathshow/map/Hub.rbxmx`, evidence, this note, `tasks/items/TASK-0128.json`.

## Acceptance criteria
- [x] AC1 VS left, Group right from the path; Blitz unchanged. Evidence: `docs/workflow/evidence/TASK-0128/pad-swap.txt`.
- [x] AC2 Walk times 9.9-11.9 s, 34/34 glyphs, three pads open their confirm screens. Same evidence file.

---
## Implementation record
One constant changed (`ARCHES` lateral values); `Hub.rbxmx` regenerated; `scripts/check.sh` green. Not recorded or self-audited.

## Audits

## Outcome
