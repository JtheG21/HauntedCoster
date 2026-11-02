---
id: SYS-Plaza-Map-Brief
title: "MathShow Plaza Map Brief"
type: system
project: GAME-004
status: proposed
side: shared
source: []
related:
  - "[[REF-MAP-003-Night-festival-plaza-mood]]"
  - "[[TASK-0118-MathShow-Plaza-Map-Brief]]"
  - "[[TASK-0120-MathShow-Hub-Graybox]]"
created: 2026-11-01
updated: 2026-11-02
tags:
  - game/system
---

# MathShow Plaza Map Brief

Decision table for the hub map. Mood reference: [[REF-MAP-003-Night-festival-plaza-mood]]. Mockups: [[Map Mockups/README]].

| Topic | Decision |
|---|---|
| Role | Walkable hub; spawn in plaza; mode screens open as overlays. |
| Layout | Circular plaza ~110 studs diameter with concentric rings; 4 radial paths; zone entrances 130-190 studs from centre (8-12 s walk at 16 studs/s). |
| Zones | Competitive (Blitz, VS, Group Battle) · Training (Practice, Skill Test, rank ladder) · Leaderboard Hall · Daily Challenge. |
| Hero landmark | Observatory tower on the highest terrace, visible from everywhere; houses the Daily Challenge. |
| Water | Lake along one side of the plaza with a lakeside promenade. |
| Boundary | Terraced cliffs/hills. |
| Time | Permanent festival night, starry galaxy sky. |
| Plaza | Seating/hangout spots, rank showcase at centre, walk-on floor puzzles on the rings. |
| Mode entry | Walk-in pads; server validates position before telling the client to open the mode UI. |
| Access | All zones open; rank = visual flair only. |
| Scale | 16-20 players. |
| Platform | Balanced (desktop-designed, phone-verified). |
| Mood | Cool world / warm light sources; violet+cyan galaxy sky; bunting; bloom+haze; flower-lined paths; shooting stars (cosmetic, pcall-isolated). |
| Directions | **A Neon math city: locked (jg, 2026-11-02).** B Cozy campus park and C Rank districts are dropped. |
| IP rule | Mood only: no Nintendo characters, mushroom-cap houses, castle copies, star pickups or power-star motifs. Original motifs: math symbols, menu violet shards, rank colours. |

## Direction A (locked)

Mockups: [[Map Mockups/README]]. Palette (A4): Night Navy #0B1433, Slate Teal #1E3D45 (terraces, ground), Basalt Blue #22303F (buildings), Plaza Stone #56626E (paths, plaza), Menu Violet #8A4DFF (competitive, rank), Holo Cyan #3FE0F0 (training, observatory), Lamp Amber #FFB547 (lamps, Blitz, Daily), Lake Ink #0F2A4A (lake). Lighting: Technology Future, Bloom 1.0/36/0.9, Atmosphere density 0.32, haze 1.8, ColorCorrection +0.15 sat/+0.10 contrast. Graybox built in [[TASK-0120-MathShow-Hub-Graybox]].

## Glyph rules

Pending: jg has not yet supplied the Glyph rules table. Graybox markers only (`GlyphSpawn`, attribute `Rarity` common or rare); no Glyph system.
