---
id: RSH-20261014-Anime-Flight-System-Video
title: "How to Make a Fly System in Roblox Studio (Anime Flight R6 & R15) (video)"
type: research
project: GAME-002
status: research
sources:
  - https://youtu.be/d6D_XlNBSW4
confidence: medium
created: 2026-10-14
updated: 2026-10-14
tags:
  - research/systems
  - research/vfx
  - research/movement
---
# How to Make a Fly System in Roblox Studio (Anime Flight R6 & R15) (video)

> **Draft.** A hobbyist tutorial; speaker claims are unaudited and nothing here is approved.

## Question
Systems and VFX variant: how is a flight system built from physics-driven movement plus layered, server-replicated visual effects, and which parts are reusable ideas? General knowledge-building for GAME-002, tied to no task. Tags: (general) = applies to game work anywhere, (Roblox-specific) = Roblox Studio or its engine, (Blender) = Blender.

## Sources
| Source | URL | Accessed |
|---|---|---|
| "How to Make a Fly System in Roblox Studio (Anime Flight R6 & R15)", uploader MrWonderHow, 22:39 | https://youtu.be/d6D_XlNBSW4 | 2026-10-14 |

**Evidence limits.**
- Captions: English, auto-generated, readable but with mistranslations; the speaker's English appears machine-translated in places. Scripts are described as "shown on the screen", so exact code and numeric property values are mostly not in the captions.
- Frames: 6 cue frames at 1024 px viewed on contact sheets (640 px tiles), plus 12 sweep frames across the whole video (480 px contact sheet; not all sheets were opened). Fine text and numbers on screen were mostly not legible at these sizes.
- No audio was heard by us.
- **References compared:** the project's existing research notes and `10 References/` index notes were checked for overlap; nothing in `10 References/` was edited. No code from the video was copied.

## Observed mechanics (verified)
Verified means said in captions or seen in a viewed frame. Timestamps *(m:ss)*.
- Flight uses physics, not teleporting: a LinearVelocity pushes the character and an AlignOrientation smooths its rotation, so movement has momentum. *(4:11-4:38)* (Roblox-specific)
- Controls: double-tap Space toggles flight; W moves along the camera forward; A/D steer; Space/Ctrl up and down; hold Q to accelerate. A "moving threshold" decides when hover becomes flight. *(3:43-4:54)*
- Hover and flight each have their own animation (R15 and R6 pairs), chosen automatically by rig type. *(1:20-3:15)*
- Screen speed lines are two radial-line images on a ScreenGui that rotate in opposite directions and fade in with speed; the transparency value set is the maximum strength. *(4:55-6:19)* (shown: radial line images and the bold speed-line frame at 0:15-6:00)
- Effects are templates stored per body part in ReplicatedStorage; the server clones whole limb folders onto the character so beam/attachment/trail relationships stay intact, and toggles them by flight state (flight, high speed, hover). *(7:52-8:39, 18:28-19:48)* (Roblox-specific)
- Limb trails use two attachments for ribbon width and a stretch texture mode; sparks are particles with zero velocity locked to the limb. *(9:03-11:35)*
- Energy arcs are eight layered Beams (C-shape from equal-and-opposite curve values); high-speed beams are enabled only at speed; arc mounts tilt forward in flight via a small client script. *(12:20-16:03, 19:56-20:24)*
- Hover smoke is an unattached particle emitter so it drifts under the character. *(16:17-17:07)*
- Because effects are server-controlled, other players see them; the speaker states he tested this with a second player. *(19:40-21:24)* (speaker claim)

## Visual check needed
- 6:00-6:19: the speed-line images at full size, in motion.
- 12:20-16:03: the arc beam stack and attachments, to judge visual quality.
- 20:24-21:05: the final flight run, which stills cannot convey.

## Hypotheses
- **H1: Template-per-limb effect folders cloned by the server keep multi-part effects consistent** *(confidence: medium)*. Test: build one two-part effect and clone it to a character.
- **H2: Server-driven effects scale poorly with many players** *(confidence: low)*; the video does not address cost. Test: profile particle and beam counts at our player cap.
- **H3: Physics-constraint movement feels smoother than CFrame teleporting** *(confidence: medium)*.

## Relevance to our game
- Not scoped for GAME-002 (no flight). Effect-template cloning could inform ghost VFX that appear on other players' views.
- Server-toggled effects fit our server-authority stance; the client-side parts (speed lines, arc tilt) are cosmetic only.
- The effect count in this system is high; we would need a performance budget before using similar layers on many entities ([[SYS-Haunted-Ghost-Train]] already adds moving parts).

## Original implementation ideas
- A reusable "effect template" convention (folder per attachment point, disabled by default, server toggles) for any future ghost or capture effect.
- A performance checklist for beams and particles: count, lifetimes, rate, and visibility distance.

## Recommendations (max 3)
1. Use the effect-template idea only; skip the flight mechanic.
2. Set a VFX budget before adding layered effects to many entities.

## Needs human review
- Unverified conclusions:
  - Cost of eight beams plus particles per player.
  - Whether replicated trail/arcs look right to remote viewers (not shown beyond a claim).
