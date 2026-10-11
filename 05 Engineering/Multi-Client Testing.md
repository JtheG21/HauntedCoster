---
id: ENG-Multi-Client-Testing
title: Multi-Client Testing
type: index
status: approved
created: 2026-10-10
updated: 2026-10-10
tags:
  - engineering/testing
related:
  - "[[TASK-0009-Multi-Client-Test-Harness]]"
  - "[[LES-0004-Wait-For-Client-Physics]]"
---
# Multi-client testing (Studio, up to 8 clients)

## How it works
- `src/server/Services/StudioTestHook.luau` runs only in Studio test sessions started with test args. It requires `TestService.Tests.multiclient.<scenario>`, runs it on the server, and ends the test with the returned table.
- Scenarios live in `tests/luau/multiclient/<Name>.luau` and return `function(args) -> { ok: boolean, ... }`.

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

## Limits
- **On this 8 GB Mac, 3 clients is the practical maximum.** 4 clients didn't all join within 30 s (about 77 MB free). Give `timeout` ≥ 50 for 3 clients (they joined in about 22 s).
Everything runs on one machine, so there's no real network latency. Mobile still needs a real device. The DevForum reports `EndTest` bugs in some Studio versions. Here the sessions closed by themselves.
