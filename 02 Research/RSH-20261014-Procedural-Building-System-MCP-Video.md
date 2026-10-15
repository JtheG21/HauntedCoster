---
id: RSH-20261014-Procedural-Building-System-MCP-Video
title: "I Built a Procedural Roblox Building System Using Claude MCP in 1 Day (video)"
type: research
project: GAME-002
status: research
sources:
  - https://youtu.be/hWPCGAI-imI
confidence: medium
created: 2026-10-14
updated: 2026-10-14
tags:
  - research/ai-workflow
  - research/systems
  - research/ui
---
# I Built a Procedural Roblox Building System Using Claude MCP in 1 Day (video)

> **Draft.** A hobbyist tutorial; speaker claims are unaudited and nothing here is approved.

## Question
AI-workflow variant: what does a one-day AI-assisted "draw to build" system consist of, and what is credible vs unverified? General knowledge-building for GAME-002, tied to no task. Tags: (general) = applies to game work anywhere, (Roblox-specific) = Roblox Studio or its engine, (Blender) = Blender.

## Sources
| Source | URL | Accessed |
|---|---|---|
| "I Built a Procedural Roblox Building System Using Claude MCP in 1 Day", uploader MrWonderHow, 4:14 | https://youtu.be/hWPCGAI-imI | 2026-10-14 |

**Evidence limits.**
- Captions: English, auto-generated, readable but with mistranslations; the speaker's English appears machine-translated in places. Scripts are described as "shown on the screen", so exact code and numeric property values are mostly not in the captions.
- Frames: 4 cue frames at 1024 px viewed on a contact sheet (640 px tiles), plus 12 sweep frames across the whole video (480 px contact sheet; not opened for every video). Fine text and numbers on screen were mostly not legible at these sizes.
- No audio was heard by us.
- **References compared:** the project's existing research notes and `10 References/` index notes were checked for overlap; nothing in `10 References/` was edited. No code from the video was copied.

## Observed mechanics (verified)
Verified means said in captions or seen in a viewed frame. Timestamps *(m:ss)*.
- Claim: a procedural building system was created in about one day using an MCP-connected assistant. *(2:19-2:34)* (speaker claim)
- He first believed the desktop assistant was connected to Studio when it was still acting as the plain chat assistant, so it could only output code to paste manually; after several rounds the real connection worked and it could inspect, edit and test scripts. *(2:34-2:50)* (speaker claim)
- Module list: a generator (~1,000 lines) for procedural parts and structures, a manipulator for selection, handles, move/rotate/scale and curve controls, a shape detector (walls, rectangles, buildings, circles from player drawings), a smoothing module, and one main client script. *(3:07-3:40)* (shown: five modules under StarterPlayerScripts)
- The result is a client-side draw tool: frames show a path drawn on the ground turned into a curved brick wall and a house-sized building. *(shown at 1:00-3:10)*
- The module is offered for download; install by dragging into StarterPlayerScripts. *(3:40-3:55)* (not verified)

## Visual check needed
- 3:07-3:40: the code size and quality at full size; the module list is the only structural evidence.

## Hypotheses
- **H1: Client-side procedural building is fine for local placement, but anything persistent needs server validation** *(confidence: medium)*. Test: design the validation for one placed piece.

## Relevance to our game
- A possible inspiration for mansion decoration tools; the Mansion/plot features have their own approved scope and server rules ([[SYS-Haunted-Player-Data]] stores persistent state), so a client-only tool would not be enough by itself.
- Downloading and installing third-party modules is not something we do without a security review and approval.

## Original implementation ideas
- If mansion customisation grows, design server-validated placement with limits (count, bounds, cost) first.

## Recommendations (max 3)
1. Do not download or install the module; keep as an idea reference.

## Needs human review
- Unverified conclusions:
  - Module quality and safety (not inspected).
  - Whether the system persists or replicates anything (not stated).
