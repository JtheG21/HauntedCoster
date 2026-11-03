---
id: TASK-0129
title: "MathShow Hub Art-1 Batch 3: Training"
type: task
project: GAME-004
status: review
priority: medium
risk: low
owner: claude-code
depends_on: []
branch: task/TASK-0129-art-training
related: []
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
- **Category, depth:** map, standard. Reuse: TASK-0127 patterns (PR 186, unmerged) (masses, trim, windows, signs); rank colours from `IdentityTheme.luau` `Tier.*.Rgb`.
- **Decisions:** rows T0-T6 approved by jg, 2026-11-02.

## Files expected to change
`scripts/build_hub.py`, `games/mathshow/map/Hub.rbxmx`, evidence, this note, `tasks/items/TASK-0129.json`.

## Acceptance criteria
- [x] AC1 Hall, pad rings and signs, rank ladder, TRAINING sign built by the generator. Evidence: `docs/workflow/evidence/TASK-0129/art-training.txt`.
- [x] AC2 Budgets met: +2 lights (hub 15), +115 instances, +3240 triangles.
- [x] AC3 Regression at 7f71497: walk times 9.9-11.9 s, 34/34 glyphs, pad screens, blocked mid-match, HUD, competitive pads.
- [x] AC4 Evidence at clean BuildStamp 7f71497 (path-start and aerial screenshots, inventory, console).

---
## Implementation record
Generator-only (`build_training`, `sign_plate`, two LampPost_W lamps); no assets. Rank colours from IdentityTheme.luau. Cost: Skill +1.3 s walk (front wall). Not recorded or self-audited (row T6).

## Audits

## Outcome
