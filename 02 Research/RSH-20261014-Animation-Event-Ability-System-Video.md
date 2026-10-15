---
id: RSH-20261014-Animation-Event-Ability-System-Video
title: "Create Amazing Abilities in Roblox Studio (Animation Events + VFX + Damage System) (video)"
type: research
project: GAME-002
status: research
sources:
  - https://youtu.be/hardFeyszEE
confidence: medium
created: 2026-10-14
updated: 2026-10-14
tags:
  - research/systems
  - research/animation
  - research/vfx
---
# Create Amazing Abilities in Roblox Studio (Animation Events + VFX + Damage System) (video)

> **Draft.** A hobbyist tutorial; speaker claims are unaudited and nothing here is approved.

## Question
Systems variant: how do animation event markers drive an ability (charge, release, hitbox, damage, knockback) so timing stays synchronised, and is the pattern useful for capture feedback? General knowledge-building for GAME-002, tied to no task. Tags: (general) = applies to game work anywhere, (Roblox-specific) = Roblox Studio or its engine, (Blender) = Blender.

## Sources
| Source | URL | Accessed |
|---|---|---|
| "Create Amazing Abilities in Roblox Studio (Animation Events + VFX + Damage System)", uploader MrWonderHow, 7:02 | https://youtu.be/hardFeyszEE | 2026-10-14 |

**Evidence limits.**
- Captions: English, auto-generated, readable but with mistranslations; the speaker's English appears machine-translated in places. Scripts are described as "shown on the screen", so exact code and numeric property values are mostly not in the captions.
- Frames: 4 cue frames at 1024 px viewed on a contact sheet (640 px tiles), plus 12 sweep frames across the whole video (480 px contact sheet; not opened for every video). Fine text and numbers on screen were mostly not legible at these sizes.
- No audio was heard by us.
- **References compared:** the project's existing research notes and `10 References/` index notes were checked for overlap; nothing in `10 References/` was edited. No code from the video was copied.

## Observed mechanics (verified)
Verified means said in captions or seen in a viewed frame. Timestamps *(m:ss)*.
- Setup: an enemies folder of test dummies, a sounds folder (charge, release, character voice), a VFX folder with "charge" and "release" subfolders, a hitbox part, post-processing (bloom, blur, colour correction) at zero intensity, and a RemoteEvent. *(0:19-2:34)*
- The client LocalScript listens for the Z key, plays the skill animation, and reacts to named animation markers: "charge" attaches charge VFX to the hand and plays the charge sound; "release" removes it, plays the release sound, spawns release VFX, shakes the camera and applies post-processing. *(2:34-3:31)* (shown: an Animation Editor with event markers)
- Markers are added in the Animation Editor timeline (right-click, add animation event); their names must exactly match the names in the script. *(3:45-4:30)* (Roblox-specific)
- The server waits for the release signal, moves the hitbox in front of the player, does an overlap check, applies damage and knockback with a hit cooldown. *(5:07-5:36)* (speaker claim)
- Defeated dummies have their joints/constraints removed so they break into pieces with outward force; a clean copy respawns them after a few seconds. *(5:36-5:51)*
- The speaker adds that this extends to combos, ultimates and status effects. *(6:27-6:41)* (opinion)

## Visual check needed
- 5:07-5:36: the server hitbox/damage code and whether the client signal is validated (not legible).
- 6:03-6:27: the release moment in motion.

## Hypotheses
- **H1: Event-marker timing keeps sound, VFX and gameplay synchronised without hard-coded delays** *(confidence: medium)*. Test: build one 2-marker animation and compare with timed waits.
- **H2: A client-triggered hitbox signal needs server-side range and cooldown checks** *(confidence: medium)*; the speaker mentions only a hit cooldown.

## Relevance to our game
- Capture feedback (our meter, hit/miss) could use markers if we ever animate a capture throw; nothing is scoped.
- Server-side hitbox plus client cosmetics fits our authority rule; the client "release" signal must be treated as untrusted.

## Original implementation ideas
- A named-marker convention (event name, what it triggers) written in a small table for any future animated interaction.

## Recommendations (max 3)
1. Note the marker pattern; apply only if a task adds animations to captures.

## Needs human review
- Unverified conclusions:
  - What the server verifies about the release signal.
  - Marker names must match exactly; failure modes are silent.
