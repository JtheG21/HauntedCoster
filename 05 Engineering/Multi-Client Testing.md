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
- One test per call. The Studio MCP request **times out** if a call runs two sessions back to back (seen once, then recovered after the session ended).
- Keep each scenario under about 45 s.

## Scenario rules
1. Wait for `players` to join **and for each character to simulate** (lift it, wait for it to fall). See [[LES-0004-Wait-For-Client-Physics]].
2. Move characters with server `PivotTo`. For touch-based logic, drop them from about 4 studs above the target (physical contact).
3. Return measurements, not just pass/fail (counts, traces), so failures can be diagnosed.

## Scenarios
| Scenario | Checks | Last result |
|---|---|---|
| `CollectibleRace` | Simultaneous touch → exactly 1 reward. Legit pickups work | ✅ 2026-10-10 ([[TEST-20261010-02]]) |
| `FactionBalance` | Auto-balance within 1, everyone assigned (`players`, `timeout` args) | ✅ 3 clients, 2026-10-10 ([[TEST-20261010-05]]) |

## Limits
- **On this 8 GB Mac, 3 clients is the practical maximum.** 4 clients didn't all join within 30 s (about 77 MB free). Give `timeout` ≥ 50 for 3 clients (they joined in about 22 s).
Everything runs on one machine, so there's no real network latency. Mobile still needs a real device. The DevForum reports `EndTest` bugs in some Studio versions. Here the sessions closed by themselves.
