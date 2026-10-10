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

## Remotes & trust boundary
Clients send requests, never results. The server validates every argument and rate-limits.

## Data model
No DataStores yet. Adding one requires an ADR and human approval.

Related: [[00 Overview]]
