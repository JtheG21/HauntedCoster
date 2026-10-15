---
id: RSH-20261014-Blender-Remove-Animation-Actions-Video
title: "How to Easily Remove Animations in Blender (Delete Actions) (video)"
type: research
project: GAME-002
status: research
sources:
  - https://youtu.be/2-So-uqifZY
confidence: medium
created: 2026-10-14
updated: 2026-10-14
tags:
  - research/blender
  - research/animation
---
# How to Easily Remove Animations in Blender (Delete Actions) (video)

> **Draft.** A hobbyist tutorial; speaker claims are unaudited and nothing here is approved.

## Question
Blender variant: how do you remove stale animation actions from a character file and reset a posed rig, which matters when importing rigs that carry many animations? General knowledge-building for GAME-002, tied to no task. Tags: (general) = applies to game work anywhere, (Roblox-specific) = Roblox Studio or its engine, (Blender) = Blender.

## Sources
| Source | URL | Accessed |
|---|---|---|
| "How to Easily Remove Animations in Blender (Delete Actions)", uploader MrWonderHow, 1:27 | https://youtu.be/2-So-uqifZY | 2026-10-14 |

**Evidence limits.**
- Captions: English, auto-generated, readable but with mistranslations; the speaker's English appears machine-translated in places. Scripts are described as "shown on the screen", so exact code and numeric property values are mostly not in the captions.
- Frames: 3 cue frames at 1024 px viewed on a contact sheet (640 px tiles), plus 12 sweep frames across the whole video viewed on one 480 px contact sheet. Fine text and numbers on screen were mostly not legible at these sizes.
- No audio was heard by us.
- **References compared:** the project's existing research notes and `10 References/` index notes were checked for overlap; nothing in `10 References/` was edited. No code from the video was copied.

## Observed mechanics (verified)
Verified means said in captions or seen in a viewed frame. Timestamps *(m:ss)*.
- Unwanted actions cannot be deleted from the Action Editor; switch the Outliner display mode from View Layer to Blender File, expand Actions, select and delete. *(0:10-0:46)* (Blender)
- After deletion the Action Editor shows them gone; "New Action" creates a clean action. *(0:34-0:56)* (Blender)
- To reset a character stuck in a pose: select the armature, enter Pose Mode, press A, then Alt+G (location), Alt+R (rotation), Alt+S (scale). *(0:56-1:19)* (Blender)
- The frames show a colour-coded R6 rig with a Roblox-account panel and an animation-importer tab open in Blender. *(0:20-1:10, shown)*

## Visual check needed
- 0:10-0:46: the Outliner steps at full size.

## Hypotheses
- **H1: Cleaning actions before export reduces junk animations on import** *(confidence: medium)*. Test: export before/after and compare imported animation lists.

## Relevance to our game
- Background for any Blender asset prep we do; ties to the Blender-to-Roblox pipeline notes. No GAME-002 task depends on it.

## Original implementation ideas
- A short Blender cleanup checklist (actions, pose reset, naming) for imported rigs, in our own words.

## Recommendations (max 3)
1. Fold into any future asset-prep checklist.

## Needs human review
- Unverified conclusions:
  - Blender version differences (the video does not state one).
