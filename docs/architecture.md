---
type: architecture
updated: 2026-10-10
tags: [architecture]
---
# Architecture

## Overview
- Rojo 7.7.0 maps `src/server` → ServerScriptService.Server, `src/shared` → ReplicatedStorage.Shared, `src/client` → StarterPlayerScripts.Client.
- Server-authoritative. Each server feature is a module in `src/server/Services/` that `init.server.luau` requires and starts.
- Shared config, types and pure logic live in `src/shared/` (and can be unit-tested).

## Services / modules
| Module | Side | Responsibility | Remotes |
|---|---|---|---|
| *(none yet; T-001 adds CollectibleService)* | | | |

## Remotes & trust boundary
Clients send requests, never results. The server validates every argument and rate-limits.

## Data model
No DataStores yet. Adding one requires an ADR and human approval.

Related: [[decisions]] · [[Home]]
