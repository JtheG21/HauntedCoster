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
  - games/haunted/src/shared/Rules/SessionLockRules.luau
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
- DataStore `HauntedCollector_Profiles_v1`, key `p_<UserId>`, `UpdateAsync` with a session lock `{job, t}` (stale after 120 s). The record transforms (claim, save, release) are pure functions in `SessionLockRules`. A load waits up to 6 × 5 s for another server's live lock, then takes it over; a save that finds a missing or foreign lock is aborted and the session turns read-only.
- A profile saved by a newer schema loads `readonly` (`ProfileRules.persistenceFor`): the server plays with a sanitised copy, releases the lock and never writes.
- Saves on leave, every 60 s and in BindToClose; one save in flight per player, one queued.
- Modes: `saved`, `memory` (DataStores unavailable; banner), `readonly` (load failed; never writes).
- Retired but kept (ADR-0007): `journal.clues` and the flags `shortcut`, `bellHint`, `bellClue` are no longer written or read, and stay in `KNOWN_FLAGS` so older profiles keep them (schema stays 1).

## Schema-bump rule
`ProfileRules.Schema` is the guard that stops an older server from writing over data it doesn't understand. During a rolling update, old and new servers run side by side, and an old server's `sanitize` **drops** what it doesn't recognise inside known tables.
- **Bump the schema** for any change an older server would lose or misread on save:
  - a new species or variant (old servers drop unknown `owned` entries, journal keys and `Species:Variant` keys);
  - a new flag (`KNOWN_FLAGS` filters unknown flags);
  - a new field inside an existing table (`journal`, `stats`, `route`, owned or exhibit entries are rebuilt field by field);
  - a renamed or removed field, or a field whose type, range or meaning changes (for example raising a clamp such as `MaxOwned`, `MaxCoins` or house tiers).
- **No bump needed** for a new top-level field (sanitize preserves unknown top-level keys), or for a change that reads old data the same way.
- **With a bump:** migrate older profiles in `sanitize` (never drop their data), add a spec for the migration, and remember that older servers will treat these profiles as read-only until they shut down.

## Interfaces
| API / Remote | Direction | Args (validated) | Notes |
|---|---|---|---|
| `State` | S→C | snapshot table | throttled 0.25 s; providers add fields |
| `RequestState` | C→S | none | rate-limited |
| `PlayerDataService.update(player, fn)` | server | — | marks dirty |

## Trust boundary / security
The client never writes profile data. Every save re-sanitises a deep copy. Expedition state is never saved.

## Tests
- Automated: `ProfileRules.spec` (14 cases: sanitize, retired clue data, `isNewerSchema`, newer schema read-only, the repaired-field list) and `SessionLockRules.spec` (8 cases: claim, wait and take over, stale lock, save keeps or clears the lock, lost lock never writes, release only our lock).
- Playtest: memory mode seen in [[TEST-20261011-01]]. **Real persistence not yet verified.**

## History
- [[TASK-0011-Haunted-Scaffold-And-Player-Data]] to [[TASK-0018-Journal-Tutorial-And-Rare-Clue]]: built in prototype commit 17cb5ae (2026-10-11)
- [[TASK-0025-Clue-Hunting-Removal]]: clue fields retired, kept for compatibility (2026-10-12)
- [[TASK-0019-Persistence-And-Rejoin-Test]]: lock transforms made pure and spec-tested, schema-bump rule written; real rejoin test pending a private API-enabled place (2026-10-12)
