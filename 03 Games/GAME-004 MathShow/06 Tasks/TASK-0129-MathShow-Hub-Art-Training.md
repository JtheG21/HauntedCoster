---
id: TASK-0129
title: "MathShow Hub Art-1 Batch 3: Training"
type: task
project: GAME-004
status: in_progress
priority: medium
risk: low
owner: claude-code
depends_on: []
branch: task/TASK-0129-art-training
related:
  - "[[TASK-0127-MathShow-Hub-Art-Competitive]]"
created: 2026-11-02
updated: 2026-11-02
tags:
  - workflow/task
---

# MathShow Hub Art-1 Batch 3: Training

## Goal
Build the Training zone (west path: Practice and Skill pads, rank ladder) to match A3 and the A4 palette, Holo Cyan accent, from generator parts only.

## Scope
- **In:** `scripts/build_hub.py` Training zone, regenerated `Hub.rbxmx`, evidence.
- **Out (non-goals):** new meshes, other zones, skybox, holo symbols, Glyph visuals, polish items, pad logic, audio, Lighting.Technology, saving the place, merging.
- **Keep unchanged:** pad parts, tags, Mode attributes, trigger volumes, walk-time limits.

## Intake
- **Category, depth:** map, standard. Reuse: TASK-0127 patterns (masses, trim, windows, signs); rank colours from `IdentityTheme.luau` `Tier.*.Rgb`.
- **Decisions:** rows T0-T6 approved by jg, 2026-11-02.

## Files expected to change
`scripts/build_hub.py`, `games/mathshow/map/Hub.rbxmx`, evidence, this note, `tasks/items/TASK-0129.json`.

## Acceptance criteria
- [ ] AC1 Hall, pad rings and signs, rank ladder, TRAINING sign built by the generator.
- [ ] AC2 Budgets met.
- [ ] AC3 Regression.
- [ ] AC4 Evidence at a clean BuildStamp.

---
## Implementation record

## Audits

## Outcome
