---
id: RSH-20261014-Custom-Skybox-GIMP-Video
title: "How to Make a Custom Skybox in Roblox Studio (Fast and Easy with GIMP) (video)"
type: research
project: GAME-002
status: research
sources:
  - https://youtu.be/pMKZrms2wyI
confidence: medium
created: 2026-10-14
updated: 2026-10-14
tags:
  - research/environment
  - research/map
---
# How to Make a Custom Skybox in Roblox Studio (Fast and Easy with GIMP) (video)

> **Draft.** A hobbyist tutorial; speaker claims are unaudited and nothing here is approved.

## Question
Maps/environment variant: how is a six-face skybox made from one panoramic image, and what does it imply for atmosphere control? General knowledge-building for GAME-002, tied to no task. Tags: (general) = applies to game work anywhere, (Roblox-specific) = Roblox Studio or its engine, (Blender) = Blender.

## Sources
| Source | URL | Accessed |
|---|---|---|
| "How to Make a Custom Skybox in Roblox Studio (Fast and Easy with GIMP)", uploader MrWonderHow, 3:04 | https://youtu.be/pMKZrms2wyI | 2026-10-14 |

**Evidence limits.**
- Captions: English, auto-generated, readable but with mistranslations; the speaker's English appears machine-translated in places. Scripts are described as "shown on the screen", so exact code and numeric property values are mostly not in the captions.
- Frames: 4 cue frames at 1024 px viewed on a contact sheet (640 px tiles), plus 12 sweep frames across the whole video (480 px contact sheet; not opened for every video). Fine text and numbers on screen were mostly not legible at these sizes.
- No audio was heard by us.
- **References compared:** the project's existing research notes and `10 References/` index notes were checked for overlap; nothing in `10 References/` was edited. No code from the video was copied.

## Observed mechanics (verified)
Verified means said in captions or seen in a viewed frame. Timestamps *(m:ss)*.
- A Roblox Sky object uses six face textures: back, down, front, left, right, up; each face is a separate image. *(0:00-0:33)* (shown: the Sky object with SkyboxBk/Dn/Ft textures listed)
- Workflow: take one panoramic or HDRI-style sky image (AI-generated or from the web), import it in GIMP, add guides for a 3x3 grid (centre becomes the front face), and use Image, Slice using Guides to create the pieces. *(0:33-1:48)* (shown: a stadium panorama split in GIMP)
- A four-vertical-section layout gives a smoother left/back/right wrap-around than the 3x3 grid. *(1:20-1:48)* (speaker claim)
- Export the slices, bulk-import them in the Asset Manager, then assign each uploaded image to the matching Sky property; Sun and Moon textures can also be changed. *(1:48-2:40)* (Roblox-specific)
- Frames show the Lighting hierarchy (Atmosphere, Sky, Bloom, DepthOfField, SunRays) alongside the sky. *(0:15, shown)*

## Visual check needed
- 1:20-1:48: the 3x3 vs 4-section layout trade-off at full size; seams are not visible in stills.

## Hypotheses
- **H1: A single image sliced into six faces can show visible seams or distortion** *(confidence: medium)*. Test: build one and inspect all views.
- **H2: Mood is mostly set by sky plus Lighting and Atmosphere, not by geometry** *(confidence: medium)*.

## Relevance to our game
- GAME-002's mood is driven by Lighting and Atmosphere (see the audio task note's reference to dark readable mood); a custom skybox is one lever but nothing here is scoped.
- Uploading images is publishing/spending-adjacent: we would not upload without human approval (AGENTS.md).

## Original implementation ideas
- A skybox checklist: source licence, seam check in-engine, brightness range, and readability at night.

## Recommendations (max 3)
1. Note as a mood lever; do not upload anything without approval.

## Needs human review
- Unverified conclusions:
  - Licence status of web or AI sky images (not discussed).
  - Resulting seam quality.
