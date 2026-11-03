---
id: TASK-0132
title: "MathShow Hub Art-1 Batch 5: Lake, Terraces, Holo, Glyph Visuals"
type: task
project: GAME-004
status: review
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
- [x] AC1 PineTree generated within the cap (3 calls) and picked by jg (C2); exported from a Studio scratch place. Evidence: `docs/workflow/evidence/TASK-0132/art-lake.txt`.
- [x] AC2 Lake (Glass Part, Reflectance 0.6, lakebed, Blocker kept), railing, two lamps.
- [x] AC3 Grass tops, 47 PineTrees; boundary walls and collider guard unchanged and passing.
- [x] AC4 Ten holo symbols, bob and sway through HubCosmetics.
- [x] AC5 Glyph visuals: spinning Neon gem, symbol billboard, one sparkle emitter each, burst.
- [x] AC6 Budgets met: +2 lights (hub 25), +381 instances, +12,510 triangles, 34 emitters at Rate 5.
- [x] AC7 Regression at 42519a0: walk 10.4-11.6 s, 34/34, pads, mid-match, collect common and rare, reject-retry, respawn, HUD, lake and edges, console clean.
- [x] AC8 Evidence written; brief light total 25 of 40.

---
## Implementation record
Generator: lake, railing, grass tops, trees, holos (`add_railing`, `tree_sites`, `add_holos`); PineTree prop (C2). Client: `HubCosmetics` animates tagged holos, `GlyphController` has the new look. Lake Ink Glass reads near-black at night whatever the Reflectance. Not recorded as audited or self-audited (row L8).

## Audits

## Outcome
