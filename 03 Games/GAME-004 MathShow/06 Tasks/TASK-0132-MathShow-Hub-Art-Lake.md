---
id: TASK-0132
title: "MathShow Hub Art-1 Batch 5: Lake, Terraces, Holo, Glyph Visuals"
type: task
project: GAME-004
status: in_progress
priority: medium
risk: low
owner: claude-code
depends_on: []
branch: task/TASK-0132-art-lake
related: []
created: 2026-11-02
updated: 2026-11-02
tags:
  - workflow/task
---

# MathShow Hub Art-1 Batch 5: Lake, Terraces, Holo, Glyph Visuals

## Goal
Finish the hub art: the lake and promenade, the terrace walls and pine trees, decorative holo symbols, and the Glyph pickup visuals, per A1/A3 and the A4 palette.

## Scope
- **In:** PineTree prop (at most 3 `generate_mesh` calls), lake, promenade, terraces, trees in `scripts/build_hub.py`; holo symbols in `HubCosmetics.luau`; Glyph visuals in `GlyphController.luau`; regenerated `Hub.rbxmx`; brief light total; evidence.
- **Out (non-goals):** skybox, polish items (violet hue, A2 portal frame, A3 L-hall, telescope tip), audio, Lighting.Technology, saving the place, merging.
- **Keep unchanged:** Glyph collection, retry, server and remotes; the pad logic; the boundary walls' collision.

## Intake
- **Category, depth:** map + props + client cosmetics, standard. Reuse: TASK-0125 prop pipeline, TASK-0131 patterns, `HubCosmetics` controller.
- **Decisions:** rows L0-L8 approved by jg, 2026-11-02.

## Files expected to change
See `files_owned` in `tasks/items/TASK-0132.json`.

## Acceptance criteria
- [ ] AC1 PineTree generated within the call cap and picked by jg.
- [ ] AC2 Lake and promenade.
- [ ] AC3 Terraces, boundary, trees.
- [ ] AC4 Holo symbols.
- [ ] AC5 Glyph visuals.
- [ ] AC6 Budgets met.
- [ ] AC7 Regression at a clean BuildStamp.
- [ ] AC8 Evidence and brief light total.

---
## Implementation record

## Audits

## Outcome
