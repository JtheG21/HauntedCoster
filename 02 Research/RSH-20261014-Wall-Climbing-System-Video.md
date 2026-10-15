---
id: RSH-20261014-Wall-Climbing-System-Video
title: "How to Make an Advanced Wall Climbing System in Roblox Studio (R15 & R6) (video)"
type: research
project: GAME-002
status: research
sources:
  - https://youtu.be/2Pa17ztB0VI
confidence: medium
created: 2026-10-14
updated: 2026-10-14
tags:
  - research/systems
  - research/movement
---
# How to Make an Advanced Wall Climbing System in Roblox Studio (R15 & R6) (video)

> **Draft.** A hobbyist tutorial; speaker claims are unaudited and nothing here is approved.

## Question
Systems variant: how does a jump-button-driven climbing controller detect surfaces and manage climbing, ledge hanging and corners? General knowledge-building for GAME-002, tied to no task. Tags: (general) = applies to game work anywhere, (Roblox-specific) = Roblox Studio or its engine, (Blender) = Blender.

## Sources
| Source | URL | Accessed |
|---|---|---|
| "How to Make an Advanced Wall Climbing System in Roblox Studio (R15 & R6)", uploader MrWonderHow, 6:10 | https://youtu.be/2Pa17ztB0VI | 2026-10-14 |

**Evidence limits.**
- Captions: English, auto-generated, readable but with mistranslations; the speaker's English appears machine-translated in places. Scripts are described as "shown on the screen", so exact code and numeric property values are mostly not in the captions.
- Frames: 4 cue frames at 1024 px viewed on a contact sheet (640 px tiles), plus 12 sweep frames across the whole video viewed on one 480 px contact sheet. Fine text and numbers on screen were mostly not legible at these sizes.
- No audio was heard by us.
- **References compared:** the project's existing research notes and `10 References/` index notes were checked for overlap; nothing in `10 References/` was edited. No code from the video was copied.

## Observed mechanics (verified)
Verified means said in captions or seen in a viewed frame. Timestamps *(m:ss)*.
- Nine climbing animations are needed and must be published under the game's owner; looping and priority are set by the script, not at publish time. *(0:53-1:56)*
- Walls are found with short raycasts, not tags: any anchored, collidable part works. *(2:09-2:24)* (Roblox-specific; blue grid test walls shown)
- A single config module holds animation IDs for R15 and R6, plus climb speed, detection distance and offsets. *(2:24-3:09)*
- One controller (LocalScript in StarterCharacterScripts) drives the whole system; the jump button grabs, releases, or hops over an edge depending on state. *(3:09-3:34)*
- Behaviours listed: move on the wall with W/A/S/D, move around corners (inside and outside), hang from a ledge with both hands, shimmy along the ledge, jump over the edge, grab a ledge in the air, drop to a lower wall. *(3:51-4:39)* (speaker claim; a hanging character and W/A hints are shown)
- The controller is client-side because the character belongs to the player and position replicates automatically. *(1:01-1:10)* (speaker claim)
- Troubleshooting: infinite yield means a folder or module name mismatch; a default pose means wrong animation IDs or owner. *(5:06-5:35)*

## Visual check needed
- 3:51-4:39: the corner and ledge transitions in motion, which stills cannot show.

## Hypotheses
- **H1: Surface detection by raycast avoids tagging every wall** *(confidence: medium)*. Test: compare detection reliability on odd geometry.
- **H2: One controller owning all states keeps edge cases manageable** *(confidence: low-medium)*.

## Relevance to our game
- Not scoped for GAME-002. A background reference for raycast-based surface detection.

## Original implementation ideas
- If we need climbing for the mansion, design it from our own animation set and server rules.

## Recommendations (max 3)
1. Keep as background only.

## Needs human review
- Unverified conclusions:
  - Quality of corner transitions (not viewable in stills).
  - How hangs interact with collision on uneven geometry.
