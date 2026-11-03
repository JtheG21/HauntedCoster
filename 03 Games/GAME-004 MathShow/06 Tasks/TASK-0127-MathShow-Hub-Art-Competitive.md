---
id: TASK-0127
title: "MathShow Hub Art-1 Batch 2: Competitive"
type: task
project: GAME-004
status: in_progress
priority: medium
risk: low
owner: claude-code
depends_on: []
branch: task/TASK-0127-art-competitive
related:
  - "[[TASK-0125-MathShow-Hub-Art-Pilot]]"
  - "[[TASK-0122-MathShow-Hub-Mode-Pads]]"
created: 2026-11-02
updated: 2026-11-02
tags:
  - workflow/task
---

# MathShow Hub Art-1 Batch 2: Competitive

## Goal
Build the Competitive zone (VS / Blitz / Group pads) to match `A2_competitive_entrance.png` and the A4 palette, using one generated prop, ModeArch, plus generator-built masses, signs and wall.

## Scope
- **In:** ModeArch (up to 3 candidates, scratch place), Competitive zone in `scripts/build_hub.py`, regenerated `Hub.rbxmx`, evidence.
- **Out (non-goals):** other zones, skybox, holo symbols, Glyph visuals, pad logic, audio, Lighting.Technology, saving the place, merging.
- **Keep unchanged:** pad trigger volumes and ModePad tags, walk times, Glyph behaviour.

## Intake
- **Category, depth:** map/asset, standard. Reuse: the TASK-0125 prop pipeline and LampPost.
- **Decisions:** rows C0-C6 approved by jg, 2026-11-02 (budgets: <=8 new PointLights, hub total <=40, <=600 instances, <=20k triangles).

## Files expected to change
`scripts/build_hub.py`, `games/mathshow/map/Hub.rbxmx`, `games/mathshow/map/props/{ModeArch.rbxmx,manifest.json}`, evidence logs, this note, `tasks/items/TASK-0127.json`.

## Acceptance criteria
- [ ] AC1 ModeArch candidates generated; jg picks one.
- [ ] AC2 Zone built by the generator; pad volumes and tags unchanged.
- [ ] AC3 Budgets met.
- [ ] AC4 Regression (walk times, 34 GlyphSpawn markers, pad confirm screens, blocked mid-match, HUD behind menu).
- [ ] AC5 Evidence at a clean BuildStamp.

---
## Implementation record

## Audits

## Outcome
