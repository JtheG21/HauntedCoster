---
id: GAME-002-ARCH
title: Technical Architecture
type: architecture
project: GAME-002
status: proposed
created: 2026-10-11
updated: 2026-10-11
tags:
  - game/architecture
related:
  - "[[ADR-0005-Haunted-Collector-Direction]]"
  - "[[Luau Standards]]"
---
# Technical architecture (proposed)

## Overview
The server is authoritative. Code lives in `games/haunted/src/{server,shared,client}` and tests in `games/haunted/tests`. They sync to a separate place through `haunted.project.json` (ADR-0005). The project follows [[Luau Standards]]: `--!strict`, `<Name>Service.luau` files with an idempotent `start()`, and pure rules and config in `shared/` so they can be tested.

## Systems
| System | Side | Responsibility | Remotes |
|---|---|---|---|
| PlayerDataService | S | Load/save profile (UpdateAsync, session lock, retries, schema version, migration that never drops fields), in-memory fallback flagged in the UI | — |
| PlotService | S | Assign/release home plots, ownership checks, plot bounds | — |
| LandmarkService | S | Investigate prompts, record clues, unlock the gate/shortcut | `Landmark` (prompt-driven) |
| EncounterService | S | Spawn and roam monsters in zones, roll variants, inspect payload | — |
| CaptureService | S | Capture sessions, server-timed meter, carry state, return timer, escape | `Capture` (start/release) |
| ContainmentService | S | Secure at own pad, owned roster, acclimation, passive income tick | `Containment` |
| EconomyService | S | Currency changes and purchases (price, requirement and funds checks) | `Purchase` |
| TrainService | S | Validate/build routes, exhibits, server cart ride, payout and cooldown | `Track`, `Ride`, `Exhibit` |
| TutorialService | S | Step state machine, persisted | (state pushed via attributes) |
| Client UI | C | HUD, inspect card, meter, roster, journal, upgrades, editor, ride | — |
| `shared/Config/*` | Sh | MonsterDefs, VariantDefs, Economy, Track, Zones: every tunable | — |
| `shared/Rules/*` | Sh | Pure functions: payout, route validation, capture timing, income | — |

## Remotes & trust boundary
- Clients send **intents only**: start capture, release time, investigate, secure, purchase id, route control points, ride start, exhibit slot assignment.
- The server checks distance, ownership (the player's own plot), cooldown and rate limit, the payload's shape and bounds, the player's tutorial and tier requirements, and money. Rewards are computed only on the server.
- Ride completion is decided by the server-driven cart reaching the end, never by a client message.

## Data model (DataStores)
`Profile v1 = { schema, coins, speedLevel, houseTier, owned = { {uid, species, variant, acquiredAt} }, journal = { species = {}, variants = {}, clues = {} }, route = { points, pieces } | nil, exhibits = { slot -> uid }, tutorialStep, lastSeen }`. Expedition state (the carried capture) is **never saved**. Saves happen on leave, every 60 s and on BindToClose, via UpdateAsync with a session-lock field. Each save is validated against the schema and clamps values first. If DataStore access is unavailable (for example in an unpublished Studio place), the game falls back to memory only, shows a visible banner, and records that persistence is unverified.

## Performance budget
Up to 6 players. 8 roaming monsters per server at most. Monsters move by server CFrame on a 0.2 s step, with no humanoid pathfinding in the MVP. The cart is a single anchored model moved by the server along precomputed samples, with the client smoothing it. Track geometry is rebuilt only on a confirmed edit. No per-frame server loops other than the ride and roam steppers.
