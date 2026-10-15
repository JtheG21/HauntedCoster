---
id: RSH-20261014-Dynamic-Head-Neck-Joint-Fix-Video
title: "How to Fix a Custom Dynamic Head That Won't Animate in Roblox Studio (video)"
type: research
project: GAME-002
status: research
sources:
  - https://youtu.be/zeYhb9oTmz0
confidence: medium
created: 2026-10-14
updated: 2026-10-14
tags:
  - research/rigging
  - research/3d-models
  - research/avatar
---
# How to Fix a Custom Dynamic Head That Won't Animate in Roblox Studio (video)

> **Draft.** A hobbyist tutorial; speaker claims are unaudited and nothing here is approved.

## Question
3D-models variant: why does a custom dynamic head not animate after replacing a head, and what does the fix teach about joints and accessories? Modeling, topology, texturing and rigging weighted equally; this note is rigging only. General knowledge-building for GAME-002, tied to no task. Tags: (general) = applies to game work anywhere, (Roblox-specific) = Roblox Studio or its engine, (Blender) = Blender.

## Sources
| Source | URL | Accessed |
|---|---|---|
| "How to Fix a Custom Dynamic Head That Won't Animate in Roblox Studio", uploader MrWonderHow, 9:08 | https://youtu.be/zeYhb9oTmz0 | 2026-10-14 |

**Evidence limits.**
- Captions: English, auto-generated, readable but with mistranslations; the speaker's English appears machine-translated in places. Scripts are described as "shown on the screen", so exact code and numeric property values are mostly not in the captions.
- Frames: 5 cue frames at 1024 px viewed on a contact sheet (640 px tiles), plus 12 sweep frames across the whole video (480 px contact sheet; not opened for every video). Fine text and numbers on screen were mostly not legible at these sizes.
- No audio was heard by us.
- **References compared:** the project's existing research notes and `10 References/` index notes were checked for overlap; nothing in `10 References/` was edited. No code from the video was copied.

## Observed mechanics (verified)
Verified means said in captions or seen in a viewed frame. Timestamps *(m:ss)*.
- Symptom: a custom dynamic head imported onto an R15 character shows no Head track in the Animation Editor. *(0:00-0:29)* (shown: a custom head with hair and a face)
- Cause: the Head has no "Neck" AnimationConstraint, so the animation editor has nothing to drive. A normal head has Neck and a separate NeckBallSocket (physics only). *(0:57-2:13)* (Roblox-specific)
- Fix: add an AnimationConstraint inside the Head, name it exactly "Neck", set Attachment0 to the torso's NeckRigAttachment and Attachment1 to the head's NeckRigAttachment, and enable IsKinematic. *(2:31-3:27)* (Roblox-specific)
- After the fix the Head track appears and the head rotates like any other part. *(3:27-3:46)* (shown: head animation tracks and rotate gizmo)
- Accessories: a hair accessory's AccessoryRigidConstraint still points at the old head; re-point Attachment1 to the new head's hair attachment and ensure the handle has an "accessory weld" with Part0 handle and Part1 head. *(4:23-5:21)* (Roblox-specific)
- Ragdoll is optional: add a BallSocketConstraint named neck ball socket with limits copied from a normal character, and NoCollisionConstraints to keep the head stable. *(5:46-7:32)* (speaker claim)

## Visual check needed
- 2:31-3:27: the exact properties at full size.

## Hypotheses
- **H1: Missing "Neck" naming is a common cause of non-animating custom heads** *(confidence: medium)*. Test: replicate on a sample.

## Relevance to our game
- Only relevant if we ever customise player characters. A rig-check list item: "joint names match what Roblox expects".
- Part of the rig/skeleton checks recorded in other notes; not scoped.

## Original implementation ideas
- Add "joint naming and constraint presence" to a future asset rig checklist.

## Recommendations (max 3)
1. Keep as a reference; no action.

## Needs human review
- Unverified conclusions:
  - Whether the same fix applies to non-R15 rigs.
