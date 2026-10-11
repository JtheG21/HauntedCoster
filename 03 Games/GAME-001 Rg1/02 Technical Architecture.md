---
id: GAME-001-ARCH
title: Technical Architecture
type: architecture
project: GAME-001
status: in_progress
created: 2026-10-10
updated: 2026-10-10
tags:
  - game/architecture
---
# Technical architecture

## Overview
- Rojo 7.7.0 maps `src/server` → ServerScriptService.Server, `src/shared` → ReplicatedStorage.Shared, `src/client` → StarterPlayerScripts.Client, and `tests/luau` → TestService.Tests.
- Server-authoritative. Each server feature is a module in `src/server/Services/` that `init.server.luau` requires and starts.
- Shared config, types and pure logic live in `src/shared/` (and can be unit-tested). Standards: [[Luau Standards]].

## Systems
| System | Side | Responsibility | Remotes |
|---|---|---|---|
| [[SYS-Collectible-Service]] | Server + Shared | Leaderstats Coins, coin spawn, validated Touched pickup, respawn | none (physics only) |
| MatchService + `MatchRules` (TASK-0006) | Server + Shared | Match state machine (only `setState` writes, via `MatchRules.transition`), match snapshot, finish order, teleports | none; publishes `MatchState`, `PhaseEndsAt`, `LastResults`, `InMatch` attributes |
| TrialService (TASK-0006) | Server | Session-only onboarding trial, first-power timing, eligibility for the first match | none; listens to `AbilityService.onActivated` |
| FinaleService + `ResultRules` + FinaleModifiers (TASK-0007) | Server + Shared | Ring-out arena, one-time eliminations, freeze at conclusion, server-simulated knockback (temporary network ownership), guards, Echo spends, Teamwork tally, category results | none new; abilities `EchoBurst`/`EchoGuard` via `AbilityRemote`; publishes `FinaleRemaining`, `FinaleAlive`, `FinaleGuard`, `Result_*` |

## Remotes & trust boundary
Clients send requests, never results. The server validates every argument and rate-limits.

## Data model
No DataStores yet. Adding one requires an ADR and human approval.

Related: [[00 Overview]]
