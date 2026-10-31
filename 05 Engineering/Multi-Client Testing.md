---
id: ENG-Multi-Client-Testing
title: Multi-Client Testing
type: index
status: approved
created: 2026-10-10
updated: 2026-10-30
tags:
  - engineering/testing
related:
  - "[[TASK-0009-Multi-Client-Test-Harness]]"
  - "[[LES-0004-Wait-For-Client-Physics]]"
---
# Multi-client testing (Studio, up to 8 clients)

## How it works
- `archive/GAME-001-rg1/src/server/Services/StudioTestHook.luau` runs only in Studio test sessions started with test args. It requires `TestService.Tests.multiclient.<scenario>`, runs it on the server, and ends the test with the returned table.
- Scenarios live in `<game tests>/multiclient/<Name>.luau` (active game: `games/mathshow/tests/multiclient/`; GAME-001: `archive/GAME-001-rg1/tests/luau/multiclient/`) and return `function(args) -> { ok: boolean, ... }`.

## Run (Claude through Studio MCP, or you from the Studio command bar in Edit mode)
```lua
local r = game:GetService("StudioTestService"):ExecuteMultiplayerTestAsync(2, { scenario = "CollectibleRace", rounds = 4 })
print(game:GetService("HttpService"):JSONEncode(r))
```
- **Runs over about 50 s: start them in the background** and poll for the result, because the MCP request times out:
```lua
-- start (returns immediately)
local SS = game:GetService("ServerStorage")
SS:SetAttribute("MC_Status", "running")
task.spawn(function()
	local ok, r = pcall(function() return game:GetService("StudioTestService"):ExecuteMultiplayerTestAsync(2, { scenario = "GateCoop", timeout = 60 }) end)
	SS:SetAttribute("MC_Result", ok and game:GetService("HttpService"):JSONEncode(r) or tostring(r))
	SS:SetAttribute("MC_Status", "done")
end)
-- later: read SS:GetAttribute("MC_Status"), SS:GetAttribute("MC_Result")
```
- Client joins are slow and occasionally fail on this Mac (2 clients took 20–45 s, and once 1 never joined within 45 s). Use `timeout` 60 and retry once before suspecting the code.
- One test per call. The Studio MCP request **times out** if a call runs two sessions back to back (seen once, then recovered after the session ended).
- Keep each scenario under about 45 s.

## Scenario rules
0. Scenarios run inside the game's server, so `require` of a service returns the **live** instance (e.g. `TrialService.complete`). That's useful for setup, but drive the behaviour under test through real inputs or signals.
1. Wait for `players` to join **and for each character to simulate** (lift it, wait for it to fall). See [[LES-0004-Wait-For-Client-Physics]].
2. Move characters with server `PivotTo`. For touch-based logic, drop them from about 4 studs above the target (physical contact).
3. Return measurements, not just pass/fail (counts, traces), so failures can be diagnosed.

## Scenarios
| Scenario | Checks | Last result |
|---|---|---|
| `CollectibleRace` | Simultaneous touch → exactly 1 reward. Legit pickups work | ✅ 2026-10-10 ([[TEST-20261010-02]]) |
| `FactionRebalance` | Leaves trigger a rebalance; every faction stays represented | ✅ 3 clients, 2026-10-10 ([[TEST-20261010-07]]) |
| `MatchJoinLeave` | Mid-match joiner waits in the lobby; the match player leaving → lobby; the joiner gets the next countdown (uses `AddPlayers`, shares module state with real services) | ✅ 2026-10-10 ([[TEST-20261010-10]]) |
| `GateCoop` | Convergence Gate: one power or stale power stays closed, both open it, 1 Echo per power per player, recloses (`checkClose`) | ✅ 2 clients, 2026-10-10 ([[TEST-20261010-08]]) |
| `FactionBalance` | Auto-balance within 1, everyone assigned (`players`, `timeout` args) | ✅ 3 clients, 2026-10-10 ([[TEST-20261010-05]]) |

## Running Luau specs
Run them in a **fresh Play session (Server data model)**, not Edit mode. Edit mode caches modules ([[LES-0005-Edit-Mode-Require-Cache]]).

## GAME-002 (Haunted Collector) runs through Studio MCP
The sections above describe the GAME-001 hook. GAME-002 scenarios live in `archive/GAME-002-haunted-collector/tests/scenarios/`. What works on this Mac (TASK-0025 to TASK-0041):
- Start runs in the Edit data model inside `task.spawn`, store a compact summary in `_G.scn[key]`, wait with a background sleep (60–240 s), then read it. Calling `ExecutePlayModeAsync` directly from `execute_luau` times out and drops the connection. Edit-mode `_G` persists across MCP calls; LogService in Edit keeps no Play logs.
- `_G.scnChain({{key, name, players, args}, ...})` runs scenarios back to back. It lives only in that Studio's Edit `_G`, so re-define it after every relaunch: loop over the entries, `pcall` `ExecutePlayModeAsync(args)` or `ExecuteMultiplayerTestAsync(players, args)`, summarise `res.checks` into `_G.scn[key]`, then wait for `RunService:IsRunning()` to go false plus 4 s.
- Args: `habitat = "<id>"` starts in a module; `rotation = {slotSeconds=30, warningSeconds=12, closingSeconds=6, startNow=true}` unpins the rotation (test runs are pinned to the Cemetery otherwise).
- Wait until Studio is back in Edit mode (and `list_roblox_studios` shows only the main window) before the next run; a run started while it's stopping returns nil.
- CrossPlot (`ExecuteMultiplayerTestAsync(2, …)`) needs `timeout = 240`. If only 1 client joined (`infra = true`), rerun once; that doesn't count as a revision. Run it once per task, at the end. It uses `CaptureService.carryForTest` instead of the timed minigame.
- `execute_luau` in the Server data model has its own module cache: requiring a service there gives a fresh, unstarted copy. Drive running services through scenario args; pure builders (e.g. `PlotBuilder.buildHouse`) work from MCP.
- `Player:LoadCharacter()` already yields until the character exists, so a following `CharacterAdded:Wait()` hangs. Poll for `Character.Head`.
- Screen captures in Play often drop the MCP connection: one capture per call, in normal Play, with `camera_position`; Studio reconnects after about a minute. To frame a shot, teleport the character from the Server data model, then set `workspace.CurrentCamera.CFrame` in the Client data model with CameraType Custom (Scriptable gets reset).
- If the Rojo plugin isn't connected, sync by writing each changed script's `Source` through `execute_luau` (a `[=====[ ]=====]` long string), check every file against disk with a length plus hash, and record in the TEST note that sync wasn't via Rojo.
- A local place rebuilt with `rojo build` runs memory-only, so the Persistence scenario can't pass there.
- Engine fact: a server `Seat:Sit()` seats a humanoid even when `Seat.Disabled` is true, and won't re-seat a just-ejected humanoid on the same seat for a while.
- Before any of this, run `scripts/studio-preflight.sh`.

## Limits
- **GAME-002: at most 2 clients in Studio** (jg, 2026-10-12: a 6-client run never started in 15 minutes). The game is still built for a full 6-player server; full-server profiling waits until jg can join from several devices.
- **On this 8 GB Mac, 3 clients is the practical maximum.** 4 clients didn't all join within 30 s (about 77 MB free). Give `timeout` ≥ 50 for 3 clients (they joined in about 22 s).
Everything runs on one machine, so there's no real network latency. Mobile still needs a real device. The DevForum reports `EndTest` bugs in some Studio versions. Here the sessions closed by themselves.
