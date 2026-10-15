---
id: RSH-20261014-Material-Footsteps-Video
title: "How to Add Custom Footsteps for Grass, Wood, Metal & More (video)"
type: research
project: GAME-002
status: research
sources:
  - https://youtu.be/GRJTD3SptWg
confidence: medium
created: 2026-10-14
updated: 2026-10-14
tags:
  - research/audio
  - research/systems
---
# How to Add Custom Footsteps for Grass, Wood, Metal & More (video)

> **Draft.** A hobbyist tutorial; speaker claims are unaudited and nothing here is approved.

## Question
Audio variant: how can surface-dependent footsteps be done cheaply by swapping the character's built-in running sound, and what does it imply for our audio pass? General knowledge-building for GAME-002, tied to no task. Tags: (general) = applies to game work anywhere, (Roblox-specific) = Roblox Studio or its engine, (Blender) = Blender.

## Sources
| Source | URL | Accessed |
|---|---|---|
| "How to Add Custom Footsteps for Grass, Wood, Metal & More", uploader MrWonderHow, 4:21 | https://youtu.be/GRJTD3SptWg | 2026-10-14 |

**Evidence limits.**
- Captions: English, auto-generated, readable but with mistranslations; the speaker's English appears machine-translated in places. Scripts are described as "shown on the screen", so exact code and numeric property values are mostly not in the captions.
- Frames: 3 cue frames at 1024 px viewed on contact sheets (640 px tiles), plus 12 sweep frames across the whole video (480 px contact sheet; not all sheets were opened). Fine text and numbers on screen were mostly not legible at these sizes.
- No audio was heard by us.
- **References compared:** the project's existing research notes and `10 References/` index notes were checked for overlap; nothing in `10 References/` was edited. No code from the video was copied.

## Observed mechanics (verified)
Verified means said in captions or seen in a viewed frame. Timestamps *(m:ss)*.
- Roblox already creates a looped "Running" sound in the HumanoidRootPart that plays while the character moves; the script only changes its SoundId. *(0:24-0:53, 3:41-3:50)* (Roblox-specific)
- A LocalScript in StarterCharacterScripts holds a table mapping Enum.Material to sound IDs and a base volume; changing materials swaps the ID. *(1:01-2:25)* (shown: a long Material-to-asset-ID table, volume 1.5 and a default sound)
- Unmapped materials fall back to the default sound, so steps are never silent. *(1:33-1:41, 3:07-3:16)*
- Roblox recreates the running sound on each spawn, so the script (not manual edits) must set it. *(2:07-2:16)*
- The test area is a row of labelled material slabs (Wood, Metal, Cobblestone, Brick, Sand, Concrete...). *(shown at 0:10)*
- First step may be delayed until the audio loads; preloading is suggested. *(3:25-3:41)*

## Visual check needed
- 1:33-2:25: the material table, for how many materials it covers.

## Hypotheses
- **H1: Swapping the built-in Running sound is the lowest-effort way to get surface footsteps** *(confidence: medium)*. Test: try it on one material set.
- **H2: A per-material table needs only a few distinct sounds to read as varied** *(confidence: low)*. Test: playtest with 3 vs 8 sounds.

## Relevance to our game
- Relevant to the audio pass (TASK-0040 is separate and not tied to this note): footsteps are not in the current spec, so this would be a possible extension, decided by jg.
- It is client-only and cosmetic, consistent with our "Sfx fails silent" client-side sound design.

## Original implementation ideas
- A small client "FootstepSounds" module keyed by our own world materials (mansion floor, grave dirt, grass), added only if jg wants footsteps.

## Recommendations (max 3)
1. Note as an optional audio extension; do not add scope to TASK-0040.

## Needs human review
- Unverified conclusions:
  - Which of the listed asset IDs are free and stable (not checked).
  - Whether our world uses distinct materials at all.
