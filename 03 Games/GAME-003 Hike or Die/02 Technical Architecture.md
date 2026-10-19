---
id: GAME-003-ARCH
title: Hike or Die Technical Architecture
type: architecture
project: GAME-003
status: proposed
created: 2026-10-18
updated: 2026-10-18
tags:
  - game/architecture
---

# Technical architecture (proposed)

## Overview
New, isolated Luau project at games/hike-or-die/, built only through hike-or-die.project.json. The server owns round state, cryptid state, evidence eligibility/score, extraction and event aggregates. The client renders controls and submits shutter intent; it never submits score, rarity, distance, state, reward or target identity.

## Systems
| System | Side | Responsibility | Remotes |
|---|---|---|---|
| RoundService | S | Start/reset a solo trial, seed a known encounter variation, clean state | RoundState, Restart |
| TrailBuilder | S | Build the small handcrafted blockout and extraction landmark | — |
| CryptidService | S | Roam, observe, investigate, pursue, lose sight and return | Player stimulus intent only |
| CameraClient | C | Camera modes under test, aim/input, shutter affordance and camera state | Shutter intent |
| EvidenceService | S | Validate target/range/visibility/state/cooldown; calculate metadata grade and reasons | Shutter intent/result |
| ExtractionService | S | Validate exit reach, bank the round's evidence, produce summary | Exit prompt or intent |
| PlaytestTelemetry | S | Aggregate round events without persistent identifiers or raw images | Server-owned |

## Remotes & trust boundary
The client sends intent only. For a shutter request, the server checks request shape, round phase, alive character, request frequency, target eligibility, distance, raycast visibility and current cryptid state. Client-supplied score, subject ID, position, distance, state and reward are ignored. If a selected camera needs client-reported aim, clamp it against a server-known origin and a configured cone around the player's facing, then raycast server-side; this remains an exploit-risk boundary and requires an adversarial Studio probe.

The server creates remotes and applies per-player rate limits. No user identifiers are retained in playtest aggregates.

## Data model (DataStores)
No DataStore in Gate 1. Ephemeral round state contains captured evidence metadata, carried evidence, current creature state, round variation and aggregate event counts. Restart and player removal clear all state.

## Performance budget
One cryptid and one player; no pathfinding grid or procedural generator unless a test proves it necessary. Record frame time, instance count and any recurring server work on representative hardware before claiming a budget.

## World layout
Use a handcrafted connected blockout and controlled spawn/state variation, based on the brief's recommendation. Exit direction must be readable from a landmark; include one alternate approach and cover route. [[ADR-0014-Hike-Or-Die-Gate-1-World]] records this as a proposed, reversible experiment, not a permanent architecture decision.

## Camera
The first candidate is a real-world Scriptable camera offset front-right of the hiker, with mouse/touch drag, fixed crosshair, and server-validated aim. It is a test implementation, not a final design decision; desktop and touch tests must compare composition and controls before selecting it. CaptureService is for screenshot/gallery features, not a substitute for the server evidence contract. No permanent screenshot/gallery support is planned.

## Startup, errors, cleanup
One active solo round per server. Reset cleans camera mode, UI state, creature loops, timers and event counters. Disconnect, character death, extraction and restart must each have explicit cleanup. No persistent state survives a round.

## References and compatibility
Adapt patterns, not systems, from the code index: SODT-RC-1's separated perception/scoring and server-created remote declarations; Npc_template's bounded target selection and state cleanup. The Npc_template Theta* grid is too broad for one handcrafted trail unless path tests demonstrate a need. Sources were inspected on 2026-10-18 via the linked public repositories; exact upstream revisions were not pinned. Existing GAME-002 code is not copied.
