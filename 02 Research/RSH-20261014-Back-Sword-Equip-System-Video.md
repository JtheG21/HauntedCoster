---
id: RSH-20261014-Back-Sword-Equip-System-Video
title: "How to Make a Back Sword System in Roblox Studio (Equip, Animations & VFX) (video)"
type: research
project: GAME-002
status: research
sources:
  - https://youtu.be/EJFpQj6ifQQ
confidence: medium
created: 2026-10-14
updated: 2026-10-14
tags:
  - research/systems
  - research/combat
  - research/tools
---
# How to Make a Back Sword System in Roblox Studio (Equip, Animations & VFX) (video)

> **Draft.** A hobbyist tutorial; speaker claims are unaudited and nothing here is approved.

## Question
Systems variant: how does a holster-on-back / equip-in-hand weapon work with animations and a trail, and what are the replication and preload lessons? General knowledge-building for GAME-002, tied to no task. Tags: (general) = applies to game work anywhere, (Roblox-specific) = Roblox Studio or its engine, (Blender) = Blender.

## Sources
| Source | URL | Accessed |
|---|---|---|
| "How to Make a Back Sword System in Roblox Studio (Equip, Animations & VFX)", uploader MrWonderHow, 8:12 | https://youtu.be/EJFpQj6ifQQ | 2026-10-14 |

**Evidence limits.**
- Captions: English, auto-generated, readable but with mistranslations; the speaker's English appears machine-translated in places. Scripts are described as "shown on the screen", so exact code and numeric property values are mostly not in the captions.
- Frames: 5 cue frames at 1024 px viewed on a contact sheet (640 px tiles), plus 12 sweep frames across the whole video (480 px contact sheet; not opened for every video). Fine text and numbers on screen were mostly not legible at these sizes.
- No audio was heard by us.
- **References compared:** the project's existing research notes and `10 References/` index notes were checked for overlap; nothing in `10 References/` was edited. No code from the video was copied.

## Observed mechanics (verified)
Verified means said in captions or seen in a viewed frame. Timestamps *(m:ss)*.
- One blade model is duplicated: a copy welded to the torso as "back" display, and a Tool with an invisible Handle holding the real blade. *(0:30-1:32)* (shown: two blades beside an R15 rig, a tool with a welded blade)
- Grip is set with a Grip Editor plugin instead of typing CFrames. *(1:32-1:54)* (Roblox-specific)
- The character model is copied into StarterPlayer as "StarterCharacter" so every spawn uses the custom character; the tool goes in StarterPack. *(1:54-2:21)*
- Three animations: idle, walk, one-shot attack; attack has higher priority than idle/walk and is not looped. *(2:21-4:31)*
- A server script owns the tool: it adds a trail between two attachments, plays sounds, loads three animation tracks at spawn, and handles equip, attack and unequip; because it runs on the server, other players see everything. *(4:42-5:52)* (Roblox-specific, speaker claim)
- On equip the back sword hides, a draw sound plays, and idle or walk plays; on attack the trail turns on and an attack plays; pressing again during a swing waits instead of overlapping; on unequip the back sword reappears. *(5:12-7:19)*
- A client script preloads animation and sound IDs to avoid a first-use hitch where the default holding pose flashes. *(5:52-6:29)* (general)
- Sound may need to be added to the experience once via the toolbox before the ID plays. *(7:47-7:55)* (speaker claim)

## Visual check needed
- 5:52-6:29: whether the preload fully removes the first-equip flash (hard to judge in stills).

## Hypotheses
- **H1: Server-owned tool logic is simple and replicates for free, but input latency depends on the client signal path** *(confidence: medium)*.
- **H2: Preloading assets at join removes first-use hitches** *(confidence: medium)*. Test: measure first-play delay with and without.

## Relevance to our game
- No weapons are scoped for GAME-002. The preload idea is directly relevant to our client sound and effect timing (TASK-0040 uses client-only sound; preloading sounds is a known improvement to consider there).
- Server-driven tool logic matches our authority rule.

## Original implementation ideas
- A preload step for any client assets (sounds, animations) used in time-sensitive moments such as capture feedback.

## Recommendations (max 3)
1. Note the preload technique as a candidate for the audio pass; no weapon system work.

## Needs human review
- Unverified conclusions:
  - Whether replication through server-side animation playback has noticeable lag.
  - Sound permission quirk (speaker claim).
