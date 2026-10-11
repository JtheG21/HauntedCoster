---
id: REF-SODT-RC-1
title: SODT-RC-1 reference guide
type: index
status: proposed
created: 2026-10-11
updated: 2026-10-11
tags:
  - reference/code
related:
  - "[[Reference_Code_Index]]"
---
# SODT-RC-1 (Scare or Die): reference guide

Back to [[Reference_Code_Index]]. Draft for human review (see "Needs review" below).

- **Repo:** https://github.com/JtheG21/SODT-RC-1 (public, default branch `main`)
- **Verified at:** commit `86fc61d`, 2026-10-11. Every path below existed at that commit. Re-check before relying on it; the repo is still active.
- **Role:** a broad engineering reference for server-authoritative Roblox systems. **It is not a template.** Its rules, balance values, asset IDs, map and sprint state belong to Scare or Die.

## Toolchain differences from Rg1 (check these first)
| Topic | SODT-RC-1 | Rg1 / GAME-002 |
|---|---|---|
| Packages | Wally: `DataService`, `Networker`, `ProfileService`, `vide`, `ripple`, `ui-labs`, `Promise`, `TestEZ` | No Wally, no `Packages/` |
| Tests | TestEZ (`test/runner.luau`, `*.spec.luau`) | Own `TestRunner`, `function(t)` specs |
| Strictness | `--!strict` in `src/server/Services`, `shared/Balance`, `Remotes`, `Types`; **not** in `src/menu`, `PlayerData/`, `InventoryService` | `--!strict` everywhere |
| Service entry | `Service.Start()` (capital S) | `start()`, idempotent |
| Layout | `ReplicatedStorage.Shared`, menu modules mounted individually in `default.project.json` | `games/haunted/src/{server,shared,client}` via `haunted.project.json` |

Anything built on DataService, Networker or vide needs those packages **replaced, not added**. Adding Wally would be an ADR-level decision.

## Source map
| Need | File | What it shows | Reuse verdict |
|---|---|---|---|
| Agent workflow and scope discipline | [`CLAUDE.md`](https://github.com/JtheG21/SODT-RC-1/blob/main/CLAUDE.md) | Architecture invariants, conventions, testing, "what not to do" | Read for ideas. Rg1's `AGENTS.md` governs here |
| Deciding who should do a piece of work | [`docs/work-routing-protocol.md`](https://github.com/JtheG21/SODT-RC-1/blob/main/docs/work-routing-protocol.md) | Green lane (machine-verifiable), Amber lane (Claude builds an instrument, the human reads it), Red lane (human drives). Stop rule for repeated visual guessing. "Screenshots are not verification" | **High value, game-agnostic.** Sections 5–7 are Scare-or-Die specific |
| Shared sensor layer | [`src/server/Services/PerceptionService.luau`](https://github.com/JtheG21/SODT-RC-1/blob/main/src/server/Services/PerceptionService.luau) | One server module answers "seen / in view cone / hiding" for several consumers. Uses CollectionService tags | Pattern reusable (e.g. ghost detection). Tags and beast assumptions are game-specific |
| Separating calculation from mutation | [`src/server/Services/SetupService.luau`](https://github.com/JtheG21/SODT-RC-1/blob/main/src/server/Services/SetupService.luau) | `Compute()` returns a breakdown and applies nothing. Callers mutate. Easy to test | **Matches Rg1's `shared/Rules` style.** Scoring formula is game-specific |
| Central remote declaration | [`src/shared/Remotes.luau`](https://github.com/JtheG21/SODT-RC-1/blob/main/src/shared/Remotes.luau) | One `NAMES` list: the server creates the remotes, the client waits for them, and nothing else calls `Instance.new("RemoteEvent")` | Compare with GAME-002's `server/Remotes.luau` and `shared/Net.luau` before changing anything |
| Central tuning | [`src/shared/Balance.luau`](https://github.com/JtheG21/SODT-RC-1/blob/main/src/shared/Balance.luau) | All tuning numbers in one typed module | Structure only. **Never copy the values** |
| Round phases and require cycles | [`RoundService.luau`](https://github.com/JtheG21/SODT-RC-1/blob/main/src/server/Services/RoundService.luau), [`RoundState.luau`](https://github.com/JtheG21/SODT-RC-1/blob/main/src/server/Services/RoundState.luau) | Phase loop, plus a tiny leaf module holding the phase so other services avoid requiring RoundService (cycle breaker) | Leaf-state trick reusable. RoundService requires ~12 sibling services |
| Player data shape | [`PlayerData/Template.luau`](https://github.com/JtheG21/SODT-RC-1/blob/main/src/shared/PlayerData/Template.luau), [`PlayerData/Types.luau`](https://github.com/JtheG21/SODT-RC-1/blob/main/src/shared/PlayerData/Types.luau), [`PlayerDataService.luau`](https://github.com/JtheG21/SODT-RC-1/blob/main/src/server/PlayerDataService.luau) | Template plus types. The service is a thin wrapper over the Wally `DataService` | Shape ideas only. Storage is incompatible with GAME-002's own `PlayerDataService` |
| Inventory actions | [`src/server/InventoryService.luau`](https://github.com/JtheG21/SODT-RC-1/blob/main/src/server/InventoryService.luau) | LevelUp, Trash, Sell and Equip, each returning a result object, plus the config lookup | Result-object pattern reusable. Depends on DataService and Networker. Not strict |
| Menu and page UI | [`src/menu/`](https://github.com/JtheG21/SODT-RC-1/tree/main/src/menu) (`PageController`, `*PageConfig`, `*PageController`, `Button*FX`, `UI*Util`) | Config-driven pages and button hover/glow/size effects | Expects named Studio GUI children (`shopPage`, `item`, `Info`, `x`). Not strict |
| UI stories | [`src/shared/stories/`](https://github.com/JtheG21/SODT-RC-1/tree/main/src/shared/stories) | ui-labs stories per page | Needs ui-labs. Rg1 has none |
| Visual calibration instrument | [`src/client/BeastHandsCalibrationPanel.client.luau`](https://github.com/JtheG21/SODT-RC-1/blob/main/src/client/BeastHandsCalibrationPanel.client.luau) | A live dev panel: the human tunes visual offsets, and the panel prints values to paste into `Balance` (an Amber-lane instrument) | Good pattern for any "looks right?" tuning. Dev-only, never ship |

## Known pitfalls
- RoundService requires most of the other services, so any one of them pulls in the whole graph. Lift single modules, not the service set.
- `src/shared/lua.luau` is empty, and `default.project.json` is named `tutorial:importants`. Treat the repo layout as working state, not a reference layout.

## Lessons from use
*(None yet. Add an entry from the index template only after a real Rg1 implementation confirms it.)*

## Needs review
- Reuse verdicts are from reading source on 2026-10-11, not from running the code in Rg1.
