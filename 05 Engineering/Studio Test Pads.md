---
id: ENG-Studio-Test-Pads
title: Studio Test Pads
type: index
status: proposed
created: 2026-10-17
updated: 2026-10-17
tags:
  - engineering/testing
related:
  - "[[TASK-0056-Studio-Test-Pads]]"
  - "[[RSH-20261017-Reference-Automation-Spec]]"
  - "[[Resource Catalog]]"
---
# Studio test pads

Judge a texture, icon or effect in context instead of from a preview image. Three pads, one scenario (`games/haunted/tests/scenarios/TestPads.luau`), pure rules in `shared/Rules/PadRules.luau` (Lune-tested). Numbers are aids; jg judges the look. **Uploading a texture to Roblox is always jg's per-action decision**; the pads only reference ids you pass them.

| Pad | Shows | Metrics line |
|---|---|---|
| `ui` | one image at 48, 128 and 512 px on the dark and light backgrounds `evidence.py matrix` uses | `cells`, `loaded`, frame size |
| `vfx` | an emitter with the texture, cameras at 6, 20 and 60 studs | emitters, particles per second, `withinBudget`, average frame ms |
| `surface` | the texture tiled on a 24 x 12 wall beside white, grey and black swatches, under the place's Lighting | wall size, ClockTime, Brightness, Ambient |

## Run it
Arguments: `pad` (`ui` | `vfx` | `surface` | `all`), `texture` (`rbxassetid://<digits>` or `rbxasset://textures/...`; a built-in default otherwise), `keep = true` (leave it built and print camera positions to capture from), `cleanup = true` (remove everything).
- **vfx and surface:** a fresh Play session, Server data model: `require(game.TestService.Tests.scenarios.TestPads)({ pad = "all" })`, or through `StudioTestService:ExecutePlayModeAsync({ scenario = "TestPads", pad = "vfx", texture = "rbxassetid://..." })`. It builds the pad, measures, removes it and checks the place is back to its baseline.
- **ui:** needs a client (a server has no PlayerGui, and `all` skips it there): run it in the Client data model of a Play session, `{ pad = "ui", texture = ... }`.
- **Capture:** run with `keep = true`, set `workspace.CurrentCamera.CFrame` to a printed position, then `screen_capture` with the Studio tool. **The first capture after moving the camera can be one frame stale (or time out): capture again.** Then run with `cleanup = true`.
- Edit mode caches `require` results (LES-0005): recreate the ModuleScript after changing the source, or use a fresh Play session.

## Checked
2026-10-17 in a scratch place (Place1): all three pads built, captured and removed; `vfx` and `surface` passed their baseline checks in a fresh Play session (server) and `ui` in the Client data model. Built-in textures were used for the baseline runs; a plugin texture (rights unverified) was used only for the captures.

## Limits
The UI pad was only run on a client; on a server it is skipped (`all`) or fails (`ui`). No capture images are stored in the repo (the Studio capture tool returns them to the session), so "captured and viewed" rests on the run's record in the task note. The baseline check counts the world, StarterGui and the client's PlayerGui. Pad positions (0, 40, -300) and (100, 10, -300) are assumed empty and were only checked in a scratch place. The default textures `rbxasset://textures/ui/GuiImagePlaceholder.png` and `SpawnLocation.png` loaded in Studio on 2026-10-17 but are not documented anywhere, so pass an explicit texture for anything that matters.
Not checked on a phone-size device emulation; the UI pad draws at real pixels, so judge phone size by running the client at that size. The frame time is a rough Heartbeat average, not a profile.
