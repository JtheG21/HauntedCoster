---
id: AGENT-WF-Map
title: Map Workflow
type: agent
status: approved
created: 2026-10-12
updated: 2026-10-12
tags:
  - workflow/production
related:
  - "[[Task Intake]]"
  - "[[Reference Analysis Workflow]]"
---
# Environments and maps

## Gather
- References: `10 References/02 Map/`, analysed with [[Reference Analysis Workflow]].
- The game's world rules: its Technical Architecture "World layout" section and the relevant ADRs (GAME-002: [[ADR-0007-World-Retrofit-Direction]]).
- Movement numbers (walk speed, jump height) from the game's config. They decide what is reachable.

## Decide
- **Player flow:** spawn, then the first goal, the loop and the return path. Mark the landmarks a player steers by, the boundaries, entrances and exits, and the sightlines to the next goal.
- **Readability:** in dark or foggy areas, the path and goals must stay legible. Use light, contrast and silhouette, not UI.
- **Build method, per element:**
  - **Terrain** for organic ground, cliffs, water and caves.
  - **Parts** for blockouts, simple architecture and anything gameplay-critical (easier to test and change).
  - **Meshes** for custom silhouettes, repeated detailed props and reusable kits ([[Asset Workflow]]).
- **Reuse:** modular kits and existing props before new models ([[Resource Catalog]]).
- **Collision and navigation:**
  - Set `CanCollide`, `CanQuery` and `CanTouch` deliberately; decor that blocks nothing has collision off.
  - Keep pathfinding agents' routes clear, and mark no-go zones.
- **Lighting and atmosphere:** the `Lighting` settings, `Atmosphere`, local lights and fog. Lights are a performance cost; budget them.

## Build
1. **Plan and prove offline first.** Use the `roblox-map` skill: spec, plan PNG, then the prover report (reachability, stuck pockets, floating parts). Run it with `~/.venvs/roblox-skills/bin/python`. **Never run its Studio bootstrap against the Rg1 or Haunted Collector place** ([[AGENTS]]).
2. Generate the layout from code where the game already does (GAME-002 builds its world in Luau), so the layout stays testable and versioned.
3. Dress the set in Studio by hand or through Studio MCP only inside an approved task.
4. Use Blender only for custom meshes ([[Asset Workflow]]).

## Performance and mobile
- Watch these: instance and part count, unanchored parts, transparent overdraw, shadow-casting lights, and the terrain voxel area.
- Use StreamingEnabled when the map is large, and keep gameplay-critical parts streamable or persistent.
- Measure in Studio with the `Stats` service (heartbeat, physics step, memory, instance count) before and after, and record the numbers in a TEST note.

## Acceptance
- The prover report is clean for reachability and stuck pockets, or each finding is explained.
- A Studio walk-through (screenshots via Studio MCP `screen_capture`) shows the landmarks, the path to each goal, and that the dark areas stay readable.
- When the map touches shared state, run a 2-player Studio session (the current cap, see [[Multi-Client Testing]]).
- Performance numbers are recorded against the baseline.
- Anything a human must judge (looks, feel) is listed as a manual check, not claimed.
