---
id: RSH-20261014-Glowing-Sword-Aura-No-Script-Video
title: "How to Make a Glowing Sword Aura in Roblox Studio (No Scripts) (video)"
type: research
project: GAME-002
status: research
sources:
  - https://youtu.be/lvCpPpkCmHk
confidence: medium
created: 2026-10-14
updated: 2026-10-14
tags:
  - research/vfx
  - research/3d-models
---
# How to Make a Glowing Sword Aura in Roblox Studio (No Scripts) (video)

> **Draft.** A hobbyist tutorial; speaker claims are unaudited and nothing here is approved.

## Question
VFX variant: how is a layered weapon aura built with Beams and ParticleEmitters only, and what does the layering approach imply for our own effects and for judging "finish"? General knowledge-building for GAME-002, tied to no task. Tags: (general) = applies to game work anywhere, (Roblox-specific) = Roblox Studio or its engine, (Blender) = Blender.

## Sources
| Source | URL | Accessed |
|---|---|---|
| "How to Make a Glowing Sword Aura in Roblox Studio (No Scripts)", uploader MrWonderHow, 15:17 | https://youtu.be/lvCpPpkCmHk | 2026-10-14 |

**Evidence limits.**
- Captions: English, auto-generated, readable but with mistranslations; the speaker's English appears machine-translated in places. Scripts are described as "shown on the screen", so exact code and numeric property values are mostly not in the captions.
- Frames: 7 cue frames at 1024 px viewed on contact sheets (640 px tiles), plus 12 sweep frames across the whole video (480 px contact sheet; not all sheets were opened). Fine text and numbers on screen were mostly not legible at these sizes.
- No audio was heard by us.
- **References compared:** the project's existing research notes and `10 References/` index notes were checked for overlap; nothing in `10 References/` was edited. No code from the video was copied.

## Observed mechanics (verified)
Verified means said in captions or seen in a viewed frame. Timestamps *(m:ss)*.
- Five layers on one sword: a scrolling-lightning Beam, flickering arcs, rising energy strands, ambient sparks, and a soft glow made of beams. *(0:00-0:20)* (shown: a purple aura on a dark blade; layered stack visible in the Explorer)
- Attachments at the tip, the guard and the middle anchor everything to the blade mesh; no scripts are used. *(0:20-0:32, 14:52-15:01)* (Roblox-specific)
- Lightning is a Beam between tip and guard with a texture whose speed makes the texture appear to move along the blade. *(0:52-1:11)*
- Arcs use a sprite-sheet texture with the emitter's flipbook grid so each particle shows one arc cell; short lifetimes create the flicker. *(3:11-5:05)* (Roblox-specific)
- An invisible thin part, welded to the blade, hosts the emitters so effects follow the sword. *(3:28-3:38, 9:19-9:38)*
- Strands use a slight upward acceleration and stretch-to-velocity orientation so they read as flow. *(6:57-7:22)*
- Sparks use zero speed and a stopped flipbook so each one flashes in place. *(9:19-11:40)*
- The glow is three overlaid beams with different texture speeds instead of a particle, because particles always face the camera and do not rotate with the sword. *(11:50-13:27)* (general reasoning; Roblox-specific behaviour)
- Same set can be recoloured for fire, ice, poison; for a held weapon, weld the blade to a tool handle. *(14:52-15:17)* (speaker claim)

## Visual check needed
- 3:11-5:05: the flipbook cell grid at full size.
- 14:07-14:18: the finished aura from several camera angles.

## Hypotheses
- **H1: Layered, low-count effect stacks look richer than one heavy emitter** *(confidence: medium)*. Test: build 1, 3 and 5 layers and compare readability and cost.
- **H2: Beams are better than particles for effects that must rotate with an object** *(confidence: medium)*.

## Relevance to our game
- Could inform visual identity for ghost or capture effects; nothing is scoped.
- The baseline warns that glow can conceal weak form; any effect work should be judged on geometry first, with effects turned off ([[3D Model Quality Baseline]]).
- Performance cost is not discussed; effects here are client-visible only.

## Original implementation ideas
- A per-effect budget (beams, emitters, lifetime, rate) and a "geometry without effects" review view for our assets.

## Recommendations (max 3)
1. Use the beam-vs-particle rule and layering idea for future effects, with a budget.

## Needs human review
- Unverified conclusions:
  - Cost of five layers at many instances.
  - Texture asset licences (not shown).
