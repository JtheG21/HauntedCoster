---
id: SYS-Haunted-Player-Data
title: Haunted Player Data
type: system
project: GAME-002
status: in_progress
side: server
source:
  - games/haunted/src/server/Services/PlayerDataService.luau
  - games/haunted/src/shared/Rules/ProfileRules.luau
  - games/haunted/src/server/Services/StateService.luau
related:
  - "[[GAME-002 Haunted Collector/02 Technical Architecture]]"
created: 2026-10-11
updated: 2026-10-12
tags:
  - game/system
---
# Haunted Player Data

## Purpose
Load, validate and save each player's profile, and push a read-only snapshot to their client.

## Responsibilities
- Profile v1 schema, defaults and `sanitize` (clamp, drop unknown species, preserve unknown top-level fields).
- DataStore `HauntedCollector_Profiles_v1`, key `p_<UserId>`, `UpdateAsync` with a session lock `{job, t}` (stale after 120 s).
- Saves on leave, every 60 s and in BindToClose; one save in flight per player, one queued.
- Modes: `saved`, `memory` (DataStores unavailable; banner), `readonly` (load failed; never writes).
- Retired but kept (ADR-0007): `journal.clues` and the flags `shortcut`, `bellHint`, `bellClue` are no longer written or read, and stay in `KNOWN_FLAGS` so older profiles keep them (schema stays 1).

## Interfaces
| API / Remote | Direction | Args (validated) | Notes |
|---|---|---|---|
| `State` | S→C | snapshot table | throttled 0.25 s; providers add fields |
| `RequestState` | C→S | none | rate-limited |
| `PlayerDataService.update(player, fn)` | server | — | marks dirty |

## Trust boundary / security
The client never writes profile data. Every save re-sanitises a deep copy. Expedition state is never saved.

## Tests
- Automated: `ProfileRules.spec` (10 cases, incl. retired clue data surviving sanitize).
- Playtest: memory mode seen in [[TEST-20261011-01]]. **Real persistence not yet verified.**

## History
- [[TASK-0011-Haunted-Scaffold-And-Player-Data]] to [[TASK-0018-Journal-Tutorial-And-Rare-Clue]]: built in prototype commit 17cb5ae (2026-10-11)
- [[TASK-0025-Clue-Hunting-Removal]]: clue fields retired, kept for compatibility (2026-10-12)
