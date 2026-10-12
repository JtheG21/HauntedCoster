---
id: GAME-002-ARCH
title: Technical Architecture
type: architecture
project: GAME-002
status: proposed
created: 2026-10-11
updated: 2026-10-12
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
| PlotService | S | Assign/release home plots, ownership checks, plot bounds (in plot-local space) | — |
| ~~LandmarkService~~ | — | Removed with clue hunting ([[TASK-0025-Clue-Hunting-Removal]], [[ADR-0007-World-Retrofit-Direction]]). Landmarks are scenery. Crypt access is the pure rule `EconomyRules.cryptOpen(houseTier)`; EconomyService adds `cryptOpen` to the snapshot and CaptureService refuses captures in gated zones below it | — |
| EncounterService | S | Spawn and roam monsters in zones, roll variants, inspect payload; startle hops and fleeing escaped captures | — |
| CaptureService | S | Capture sessions, server-timed meter, carry state, return timer, escape chase and grab | `Capture` (start/release), `Grab` prompt |
| ContainmentService | S | Secure at own pad, owned roster, acclimation, passive income tick | `Containment` |
| EconomyService | S | Currency changes and purchases (price, requirement and funds checks) | `Purchase` |
| TrainService | S | Validate/build routes, exhibits, server cart ride, payout and cooldown | `Track`, `Ride`, `Exhibit` |
| TutorialService | S | Step state machine, persisted | (state pushed via attributes) |
| Client UI | C | HUD, inspect card, meter, roster, journal, upgrades, editor, ride | — |
| `shared/Config/*` | Sh | MonsterDefs, VariantDefs, Economy, Track, Zones: every tunable | — |
| `shared/Rules/*` | Sh | Pure functions: payout, route validation, capture timing, income | — |

## World layout (M3, [[ADR-0007-World-Retrofit-Direction]])
- `shared/Config/World`: the hub (wall r 115, footprint r 112, ring road r 120–132, gates at 0°/120°/240°) and the plot ring (centres at r 185, angles 30° + 60k). Each plot has a frame, `World.plotFrame(i)`, whose -Z faces the hub. Every plot-local point or direction goes through `plotToWorld`, `worldToPlot` or `plotDirToWorld`. Plot geometry is built at local coordinates and placed with `Build.toFrame`. Saved routes and `TrackRules` stay plot-local, so they're unchanged.
- `shared/Config/Habitats`: the module contract (zones, landmarks, paths, one path per gate, plaza, crypt, starter) and the four modules in rotation order (Ghost Cemetery, Cursed Woodland, Spider Woodland, Zombie Settlement). `Habitats.active()` is the live module; the server sets it and mirrors it to the Workspace attribute `ActiveHabitat`, which the client follows.
- `shared/Rules/HabitatRules`: pure footprint, corridor and path checks, plus `validate` (species, weights, landmark zones; warnings at server start).
- `server/Services/HabitatService`: prebuilds every module into `ServerStorage.HabitatModules` and parents one under `Workspace.Habitat`. `activate` / `deactivate` hooks clear wild monsters (`EncounterService.clearWild`, fleeing escapes kept) and repopulate (`EncounterService.populate`). In Studio test runs the `habitat` argument picks the starting module.
- `shared/Config/Rotation` + `shared/Rules/RotationRules` (TASK-0029): the 15-minute, four-habitat schedule as a pure function of UTC time. `shared/HabitatState` holds the Workspace attributes (`ActiveHabitat`, `HabitatNext`, `HabitatPhase`, `HabitatSwapAt`, `HabitatFog`) the client reads.
- `server/Services/RotationService`: a 0.25 s tick on `Workspace:GetServerTimeNow()`. It publishes the phase, closes captures in the last 15 s, and swaps under a protected fog fade: cancel meter sessions, move players in the hub out to their nearest gate, activate the next module, let chases follow their players. Studio test runs are pinned unless they pass a `rotation` schedule.
- `server/Services/RetaliationService` + `shared/Rules/RetaliationRules` (TASK-0031): on a capture's final miss (`CaptureService.onFled`), the target and up to two neighbours pursue the failing player, stepped by the server inside the habitat region. A catch sets the character attribute `KnockedDownUntil`; the client ragdolls (Physics state, no damage). Ends on timeout, escape, death, leaving or a swap (`stopAll` before `clearWild`). The tick and each `onFled` handler run under `pcall`: a tick error ends every pursuit, and a failing handler falls back to "slipped away" (TASK-0032). `begin` releases every monster it had set if it errors part-way (TASK-0033).
- `server/World`: `HubBuilder` (persistent ground, ring road, hub wall and gates, spokes, lights), `Atmosphere` (lighting), `Props` (the shared prop kit), `Habitats/Kit` (shared module building steps) and one builder per module in `Habitats/`. Workspace holds `World`, `Habitat/<id>`, `Plots` and `Monsters`.

## Remotes & trust boundary
- Clients send **intents only**: start capture, release time, investigate, secure, purchase id, route control points, ride start, exhibit slot assignment.
- The server checks distance, ownership (the player's own plot), cooldown and rate limit, the payload's shape and bounds, the player's tutorial and tier requirements, and money. Rewards are computed only on the server.
- Ride completion is decided by the server-driven cart reaching the end, never by a client message.

## Data model (DataStores)
`Profile v1 = { schema, coins, speedLevel, houseTier, owned = { {uid, species, variant, acquiredAt} }, journal = { species = {}, variants = {}, clues = {} }, route = { points, pieces } | nil, exhibits = { slot -> uid }, tutorialStep, lastSeen }`. Expedition state (the carried capture) is **never saved**. Saves happen on leave, every 60 s and on BindToClose, via UpdateAsync with a session-lock field. Each save is validated against the schema and clamps values first. If DataStore access is unavailable (for example in an unpublished Studio place), the game falls back to memory only, shows a visible banner, and records that persistence is unverified.

## Performance budget
Up to 6 players. 8 roaming monsters per server at most. Monsters move by server CFrame on a 0.2 s step, with no humanoid pathfinding in the MVP. The cart is a single anchored model moved by the server along precomputed samples, with the client smoothing it. Track geometry is rebuilt only on a confirmed edit. No per-frame server loops other than the ride and roam steppers.
