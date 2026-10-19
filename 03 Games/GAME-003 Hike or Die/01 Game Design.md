---
id: GAME-003-DESIGN
title: Hike or Die Game Design
type: design
project: GAME-003
status: proposed
version: 0.1
created: 2026-10-18
updated: 2026-10-19
tags:
  - game/design
---

# Game design

## Pitch (1–2 sentences)
Take your friends into a haunted forest, photograph the cryptids nobody believes exist, and make it out alive with the proof. Gate 1 tests whether approaching danger for stronger photographic evidence makes a clear, fair, replayable loop.

## Target players & session length
Gate 1 is a solo internal prototype with keyboard/mouse and touch camera evaluation. Session length is deliberately open and will be determined by observed play, not a fixed target. Gamepad evaluation is needed only if selected as a launch target.

## Core loop
Spawn on a compact trail → find and study one cryptid → frame and capture evidence in distinct behavior states → understand the quality feedback → evade pursuit → extract → review what was banked → restart with a controlled encounter variation.

## Progression & retention
No durable progression in Gate 1. Temporary session metadata distinguishes a basic sighting from an extracted rare-behavior achievement. Replay is measured as a voluntary choice and reason, not claimed as retention proof.

## Social features
Cooperative rescue and 1–4 player play are Gate 2. Gate 1 can use one local player and must not imply that multiplayer or rescue is implemented.

## Monetization
Excluded. No currency economy, purchases, Robux, boosts, or paid API calls.

## MVP scope
| Feature | Priority | Status |
|---|---|---|
| Small connected trail, landmarks, route/cover choice and marked extraction | Must | Generated and headlessly proved; Studio readability pending |
| One hybrid cryptid: observe, investigate, pursue, disengage | Must | Implemented in server prototype; runtime pending |
| Selfie-style camera interaction with aiming, shutter and camera state | Must | Scriptable selfie-camera candidate is present, but jg reports mouse camera controls still do not work. The existence-stage merge defers repair for higher-model review; earlier Studio probes are historical only. Touch comparison remains pending. |
| Server-validated evidence metadata and explainable grade | Must | Implemented; adversarial runtime validation pending |
| Extraction, round summary and restart | Must | Implemented; runtime validation pending |
| One controlled encounter variation and low-risk event instrumentation | Must | Partially implemented: three spawn positions, rotating roam start, and console event counts; no cohort funnel or verified analytics ingestion |
| Optional simple contract | Can | Deferred unless a test needs it |
| Persistent gallery, journal UI, evidence recovery, co-op | Out | Gate 2+ |

## Non-goals
Production lobby/matchmaking, four polished cryptids, procedural forest generation, extensive art, durable persistence, screenshot storage/sharing, economy, monetization, release, and unrelated GAME-001/GAME-002 changes.

## Open questions
- Which selfie-camera implementation works on desktop and touch while preserving useful player/creature composition?
- What server-validated signal can explain framing without accepting client-supplied scores or target identity?
- Which player-caused stimulus creates a readable investigation state?
- How much route choice and obstruction supports chase counterplay without aimless wandering?
- What sample size and qualitative threshold will be set before observed tests?
