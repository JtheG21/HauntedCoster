---
id: TASK-0001
title: Collectible Pickup
type: task
project: GAME-001
status: done
priority: high
risk: low
owner: executor
depends_on: []
branch: task/T-001-collectibles
created: 2026-10-10
updated: 2026-10-12
tags:
  - workflow/task
  - game/collectibles
related:
  - "[[GAME-001 Rg1/00 Overview|00 Overview]]"
  - "[[SYS-Collectible-Service]]"
---
# TASK-0001: Collectible pickup + leaderstats (workflow prototype)

*Migrated from `T-001` on 2026-10-10 when the Obsidian conventions were adopted. The content below is unchanged except for links.*

## Goal
A tiny, modular, server-authoritative feature to test the full workflow (plan → approve → execute → check → audit → merge). It isn't meant to be the final game design.

## Scope
- **In:** a leaderstats `Coins` IntValue, server-spawned coin parts, touch pickup validated on the server, a respawn timer, a pure validation module with tests.
- **Out:** saving data (no DataStore), UI, sounds, client code, monetization.

## Files expected to change
- `src/shared/CollectibleConfig.luau` (new): Count, CoinValue, RespawnSeconds, MaxPickupDistance, SpawnArea
- `src/shared/CollectibleRules.luau` (new): pure `canCollect(state)` and helpers, `--!strict`
- `src/server/Services/CollectibleService.luau` (new): spawns coins, handles Touched, awards coins
- `src/server/init.server.luau`: require and start the service (keep the existing print)
- `tests/luau/CollectibleRules.spec.luau` (new)

## Acceptance criteria
- [ ] Each player gets `leaderstats.Coins = 0` on join
- [ ] The server spawns `Count` coins in `Workspace.Collectibles`
- [ ] A character touching a coin awards `CoinValue` exactly once. The coin hides and respawns after `RespawnSeconds`
- [ ] Ignored: touches from non-characters, dead humanoids, distances greater than `MaxPickupDistance`, and inactive coins
- [ ] The pure rule logic has passing tests
- [ ] `scripts/check.sh` passes

## Tests
- **Automated:** `scripts/check.sh` (format, lint, build). Run `tests/luau/CollectibleRules.spec.luau` in Studio with `require(game.TestService.Tests.TestRunner).run()` (Edit mode).
- **Studio playtest procedure:**
  1. Connect Rojo and press Play (single player).
  2. Check that `Workspace.Collectibles` has `Count` coins and that leaderstats shows Coins 0.
  3. Walk into a coin. Coins goes up by `CoinValue` once, and the coin disappears.
  4. Wait `RespawnSeconds`. The coin reappears.
  5. Check the Output window: no errors.
  6. Optional: Test → 2 players. Both touch the same coin at the same moment. Only one player gets the coin.

## Risks / notes
Low risk: no persistence and no remotes. The main thing to check is the debounce race (two touches in the same frame).

---
## Implementation record
*Executor (Claude Code), 2026-10-10, branch `task/T-001-collectibles`*

**Files changed**
- `src/shared/CollectibleConfig.luau` (new): frozen config table
- `src/shared/CollectibleRules.luau` (new): pure `canCollect`, `award`, `spawnPosition`
- `src/server/Services/CollectibleService.luau` (new): leaderstats, spawning, Touched validation, respawn
- `src/server/init.server.luau`: requires and starts the service
- `tests/luau/CollectibleRules.spec.luau` (new): 7 tests
- Tooling, outside the spec: `scripts/typecheck.sh` (new, strict luau-lsp analyze) added to `check.sh`; typed `t` in `Smoke.spec`; `pcall(fn :: any)` in `TestRunner` to satisfy strict mode

**Design decisions**
- Debounce: the coin is deactivated (`Active=false`, `CanTouch=false`) synchronously before the award, so a second Touched in the same frame is rejected.
- A spawn circle (deterministic) instead of random positions, so it's testable and reproducible.
- No remotes: pickup is detected only by server physics, so the client has nothing to spoof except its own position (limited by `MaxPickupDistance`).

**Check results**
- `scripts/check.sh`: ALL CHECKS PASSED (StyLua, Selene 0/0/0, types: no type errors, Rojo build, JSON, queue, 15 Python tests)
- Luau specs in Studio: `[TestRunner] 9 passed, 0 failed`

**Studio playtest** (automated through Studio MCP, single player, local place)
- AC1 `leaderstats.Coins=0` ✅
- AC2 10 coins in `Workspace.Collectibles` ✅
- AC3 touch → Coins=1, coin hidden; standing on it 1 s more → still 1; reappears after 5 s ✅
- AC4 unanchored non-character part falls on coin → +0, coin stays active ✅. Dead humanoid (Health=0) teleported onto coin → +0 ✅ (the character was breaking apart, so the rule-level test is the stronger evidence)
- AC4 distance > max: covered by unit tests only; you can't reproduce it physically with a touch
- Output: only the two Hello-world prints, no errors

**Not yet verified:** the 2-player simultaneous-touch case (playtest step 6). That needs Test → 2 players by hand.

## Audits
- [[AUD-20261010-TASK-0001-01]]: attempt 1, pass

## Outcome
Merged to `main` on 2026-10-10 (merge approved by jg). Audit [[AUD-20261010-TASK-0001-01]]: pass (4 minor, 3 nit).
- 2-player simultaneous-touch test: not confirmed before merge. Automated attempt blocked on 2026-10-10, then **passed** later that day through the TASK-0009 harness ([[TEST-20261010-02]]).
- Follow-ups (not done yet): pickup rate/teleport limits, tighter `MaxPickupDistance`, a portable type-check (skip should not count as PASS), `CanQuery=false` on hidden coins.
- Playtest: [[TEST-20261010-01]] · System: [[SYS-Collectible-Service]]
- Lessons: [[LES-0002-Typed-Test-Context]] · Retrospective: [[RETRO-M0-Workflow-Foundation]]
