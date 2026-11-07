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
updated: 2026-11-06
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

Mockups: [[Map Mockups/README]]. Palette (A4): Night Navy #0B1433, Slate Teal #1E3D45 (terraces, ground), Basalt Blue #22303F (buildings), Plaza Stone #56626E (paths, plaza), Menu Violet #8A4DFF (competitive, rank), Holo Cyan #3FE0F0 (training, observatory), Lamp Amber #FFB547 (lamps, Blitz, Daily), Lake Ink #0F2A4A (lake). Lighting: Technology ShadowMap (decision of 2026-11-02, see Decision record below; was Future), Bloom 1.0/36/0.9, Atmosphere density 0.32, haze 1.8, ColorCorrection +0.15 sat/+0.10 contrast. Graybox built in [[TASK-0120-MathShow-Hub-Graybox]].

## Decision record: lighting and light budget (jg, 2026-11-02, TASK-0125 re-scope)
- **Lighting.Technology = ShadowMap**, the place's current setting; no place save. This replaces "Technology Future" in the Direction A line above.
- Glow comes from **Neon + Bloom** per A4 (the lamp Globe uses a Neon colour tuned for Bloom 1.0).
- **Art-1 light budget:** at most **40 PointLights** in the hub; **CastShadow false** on all props.
- **Art budget metric (jg, 2026-11-02, M6):** triangles = the deterministic geometry inventory from the committed sources (class counts x stated costs + prop manifest triangle counts). Studio rendered counts are informational. The rendered/inventory gap (4,332 in [[TASK-0126-MathShow-Hub-Art-Plaza]]) is to be explained in [[TASK-0123-MathShow-Multiplayer-Playtest]]'s real-device perf run. Stated costs per primitive (TASK-0126, measured in Play): Block 12, Wedge 10, Cylinder 96, Ball 432.
- **Running hub PointLight total: 25 of 40** (13 from [[TASK-0125-MathShow-Hub-Art-Pilot]] and Batch 1, +5 [[TASK-0127-MathShow-Hub-Art-Competitive]] arch and lamps, +2 [[TASK-0129-MathShow-Hub-Art-Training]] lamps, +3 [[TASK-0131-MathShow-Hub-Art-Observatory]]: the dome light and two Ranks-hall lamps; +2 [[TASK-0132-MathShow-Hub-Art-Lake]]: the two promenade lamps; counted from `Hub.rbxmx` at 42519a0, 25 PointLights read back in Studio; +0 [[TASK-0133-MathShow-Hub-Art-Polish]]: no light objects, 25 read back at 30dd62e). +0 [[TASK-0143-MathShow-Map-Finish-B1-Sky]]: Sky and a violet Atmosphere tint, no lights (25 unchanged). +0 [[TASK-0144-MathShow-Map-Finish-B2-Ambient-Life]]: shooting stars and ambient sounds, no lights. +0 [[TASK-0145-MathShow-Map-Finish-B3-Dressing]]: flower strips and benches, no lights (25 unchanged; triangle inventory +4,680). Update this line with each batch.
- Basis: in-Studio lighting perf on this Mac is non-gating (renderer identity unverifiable, method not reproducible); real-device perf is in [[TASK-0123-MathShow-Multiplayer-Playtest]]. Source: [[TASK-0125-MathShow-Hub-Art-Pilot]].

## Glyph rules v1

- **Purpose:** just for fun now (session counter + pickup effect); built to hook into daily quests and XP later.
- **Spawning:** per player. The server owns each player's glyph state; the client renders only its own glyphs.
- **Placement:** fixed authored `GlyphSpawn` markers. common = along paths; rare = terraces, rooftops, lake edge. All reachable with a default jump.
- **Collect:** client sends `GlyphCollect(id)`. Server validates type → known id → within `CollectRadius` of the character → not already collected → rate limit, debouncing synchronously before any yield. Server then sends `GlyphState` to that player only.
- **Respawn:** per player, on a timer (common faster than rare).
- **Visual:** collectible glyphs float at chest height, spin and sparkle. Decorative holo symbols stay high and out of reach, so the two are never confused.
- **Persistence:** in memory only until jg approves row G-DS (lifetime total, one versioned profile field).
- **Naming/IP:** called "Glyphs". Math-symbol shapes only; no star shapes, no "star bits".

Graybox status: 34 `GlyphSpawn` markers (21 common, 13 rare) with attribute `Rarity`; markers only, no Glyph system (see [[TASK-0120-MathShow-Hub-Graybox]]).

