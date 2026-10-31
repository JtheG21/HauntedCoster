---
id: RSH-20261018-Hike-Or-Die-Camera-Feasibility
title: Hike or Die Camera Feasibility
type: research
status: research
created: 2026-10-18
updated: 2026-10-18
tags:
  - research/roblox
  - research/camera
related:
  - "[[TASK-0087-Hike-Or-Die-Gate-1]]"
---

# Hike or Die Camera Feasibility

## Question
Which camera route is the smallest credible Gate 1 test for photographic framing, on desktop and touch, while preserving server-side evidence eligibility?

## Sources and access date
- Roblox Creator Hub, Camera API: https://create.roblox.com/docs/reference/engine/classes/Camera (accessed 2026-10-18).
- Roblox Creator Hub, CameraType enum: https://create.roblox.com/docs/reference/engine/enums/CameraType (accessed 2026-10-18).
- Roblox Creator Hub, ViewportFrame API: https://create.roblox.com/docs/reference/engine/classes/ViewportFrame (accessed 2026-10-18).
- Roblox Creator Hub, CaptureService API: https://create.roblox.com/docs/reference/engine/classes/CaptureService (accessed 2026-10-18).
- Roblox Creator Hub, Viewport frames guide: https://create.roblox.com/docs/ui/viewport-frames (accessed 2026-10-18).
- Code reference originals inspected through GitHub on 2026-10-18: JtheG21/SODT-RC-1 PerceptionService.luau, SetupService.luau, Remotes.luau; JtheG21/Npc_template CrowdController.luau, Zombie.luau, TargetService.luau, ThetaSolver.luau. The linked code index does not pin revisions; no code was copied.

## Observations
- Roblox documents CameraType.Scriptable as having no default behavior; code must update camera CFrame, and should update Focus for rendering priority.
- ViewportFrame renders objects in a 2D GUI and has material/lighting and effect limitations. A moving subject must be represented in the frame's object hierarchy; it is not a free mirror of the entire live world.
- CaptureService exposes client-side screenshot/gallery/share operations. Those are not server scoring primitives and introduce permissions/platform/storage considerations outside the metadata-first Gate 1 loop.
- SODT-RC-1 separates sensing from scoring and creates its remotes from a declaration table. Npc_template uses bounded nearest-living-player target selection, explicit NPC lifecycle states and caches routes on grid-node changes. Its Theta* grid relies on a large environment scan and appears excessive for the one-creature handcrafted blockout.
- A local Roblox/creator-docs clone is present and was also consulted for Camera and ViewportFrame class details.

## Hypotheses
- A constrained real-world camera plus a simple viewfinder likely has lower setup cost and better lighting/actor fidelity than mirroring the live creature into a ViewportFrame.
- The client cannot prove its camera view to the server. A shutter intent can be checked against a server-bounded ray origin and direction, current line of sight, range, state, phase and cooldown, but modified clients can still forge plausible aim.
- Snapshot metadata, not Roblox screenshot APIs, is sufficient to test the central loop.

## Recommendation
Prototype the constrained world-camera candidate first. Compare ViewportFrame only if a Studio test shows it cannot achieve readable selfie composition. Use server-calculated metadata and no screenshot storage. Keep the choice open until a desktop and touch evaluation.

## Open questions
- Can the avatar and cryptid both read clearly in the desired selfie-style composition?
- Does input/aim remain usable during movement on desktop and touch?
- Is a server-constrained aim ray sufficiently fair and resistant to easy reward spoofing?
