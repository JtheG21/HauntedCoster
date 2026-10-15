---
id: RSH-20261014-Blender-R6-Animation-To-Roblox-Video
title: "How to Animate R6 in Blender & Import to Roblox Studio Easily (video)"
type: research
project: GAME-002
status: research
sources:
  - https://youtu.be/eo365FXAMO4
confidence: medium
created: 2026-10-14
updated: 2026-10-14
tags:
  - research/blender
  - research/animation
  - research/rigging
---
# How to Animate R6 in Blender & Import to Roblox Studio Easily (video)

> **Draft.** A hobbyist tutorial; speaker claims are unaudited and nothing here is approved.

## Question
Blender variant: what is the practical pipeline for authoring an R6 animation in Blender and importing it into Roblox Studio, and what checks does it imply for imported rigs? General knowledge-building for GAME-002, tied to no task. Tags: (general) = applies to game work anywhere, (Roblox-specific) = Roblox Studio or its engine, (Blender) = Blender.

## Sources
| Source | URL | Accessed |
|---|---|---|
| "How to Animate R6 in Blender & Import to Roblox Studio Easily", uploader MrWonderHow, 6:31 | https://youtu.be/eo365FXAMO4 | 2026-10-14 |

**Evidence limits.**
- Captions: English, auto-generated, readable but with mistranslations; the speaker's English appears machine-translated in places. Scripts are described as "shown on the screen", so exact code and numeric property values are mostly not in the captions.
- Frames: 5 cue frames at 1024 px viewed on contact sheets (640 px tiles), plus 12 sweep frames across the whole video (480 px contact sheet; not all sheets were opened). Fine text and numbers on screen were mostly not legible at these sizes.
- No audio was heard by us.
- **References compared:** the project's existing research notes and `10 References/` index notes were checked for overlap; nothing in `10 References/` was edited. No code from the video was copied.

## Observed mechanics (verified)
Verified means said in captions or seen in a viewed frame. Timestamps *(m:ss)*.
- Three resources are needed: a Blender add-on (Roblox animation importer/exporter), a Roblox Studio plugin, and a pack of R6 rigs for Blender and Roblox. *(0:00-0:34)* (links not verified)
- Install the add-on in Blender (Preferences, Extensions, Install from disk); the example uses Blender 5. *(0:34-1:04)* (Blender; version stated by speaker)
- The supplied R6 Blender rig is pre-set with IK and FK controls; animate in Pose Mode on the Dope Sheet. *(1:04-1:48)* (shown: a coloured R6 block rig with a control panel and bone counts)
- Export from the add-on's sidebar tab by baking to the clipboard or to a file; save the .blend separately to keep editing. *(2:43-3:09)* (Blender)
- In Studio, the plugin imports from clipboard or file, previews, loops, and uploads the animation to Roblox; it then loads in the Animation Editor with keyframes intact. *(3:41-5:28)* (Roblox-specific)
- The plugin warns when the rig's primary part is the head (set it to HumanoidRootPart) and when the root part is not anchored (anchor it while importing). *(5:28-6:14)*

## Visual check needed
- 3:41-4:42: the plugin's import options at full size.
- 5:28-6:14: the warnings and fixes, to confirm exact property names.

## Hypotheses
- **H1: Rig preparation (primary part, anchoring) is the common stumbling point for animation import** *(confidence: medium)*. Test: import one animation into an unprepared rig and note the warnings.

## Relevance to our game
- Background for any animation work on custom creatures. Our rig types are undecided and not covered here.
- Third-party add-on and plugin terms are unknown; adopting them needs approval.

## Original implementation ideas
- A rig-prep checklist: primary part, anchoring, naming, scale, and a one-animation smoke test.

## Recommendations (max 3)
1. Keep as a reference for rig prep; evaluate the add-on only if an animation task needs Blender authoring.

## Needs human review
- Unverified conclusions:
  - Add-on and plugin licensing and maintenance.
  - Behaviour on non-R6 rigs (not covered).
