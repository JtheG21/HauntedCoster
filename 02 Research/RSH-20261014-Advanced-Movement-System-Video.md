---
id: RSH-20261014-Advanced-Movement-System-Video
title: "How to Make an ADVANCED Movement System in Roblox Studio (R6 & R15) (video)"
type: research
project: GAME-002
status: research
sources:
  - https://youtu.be/34sKDEUkoX4
confidence: medium
created: 2026-10-14
updated: 2026-10-14
tags:
  - research/systems
  - research/movement
---
# How to Make an ADVANCED Movement System in Roblox Studio (R6 & R15) (video)

> **Draft.** A hobbyist tutorial; speaker claims are unaudited and nothing here is approved.

## Question
Systems variant: how is a multi-move locomotion system (run, slide, vault, climb, wall run, swing, dash, stamina) organised, and which design choices (config-driven, one-action-at-a-time, replicated effects, mobile parity) are worth borrowing? General knowledge-building for GAME-002, tied to no task. Tags: (general) = applies to game work anywhere, (Roblox-specific) = Roblox Studio or its engine, (Blender) = Blender.

## Sources
| Source | URL | Accessed |
|---|---|---|
| "How to Make an ADVANCED Movement System in Roblox Studio (R6 & R15)", uploader MrWonderHow, 20:39 | https://youtu.be/34sKDEUkoX4 | 2026-10-14 |

**Evidence limits.**
- Captions: English, auto-generated, readable but with mistranslations; the speaker's English appears machine-translated in places. Scripts are described as "shown on the screen", so exact code and numeric property values are mostly not in the captions.
- Frames: 6 cue frames at 1024 px viewed on a contact sheet (640 px tiles), plus 12 sweep frames across the whole video viewed on one 480 px contact sheet. Fine text and numbers on screen were mostly not legible at these sizes.
- No audio was heard by us.
- **References compared:** the project's existing research notes and `10 References/` index notes were checked for overlap; nothing in `10 References/` was edited. No code from the video was copied.

## Observed mechanics (verified)
Verified means said in captions or seen in a viewed frame. Timestamps *(m:ss)*.
- Scope: run, slide, crouch under low obstacles, vertical climb, vault, wall run, bar swing, air dash, with stamina, replicated effects, R6 and R15, PC/console/mobile. *(0:07-0:56)* (speaker claim; moves seen in demo frames)
- Only one main action may run at a time; a single shared state module is read and written by every movement module (locomotion, air, dash, slide, vault, climb, wall run, swing). *(11:46-12:09, 14:02-15:42)* (general, speaker claim)
- All tunables, animation IDs and key/gamepad bindings live in one config module; a zero animation ID falls back to a safe default animation. *(3:27-3:43, 6:08-6:27)* (general)
- Crouch and slide switch the character into a "ducking" collision group that does not collide with a "low obstacle" group, so the player passes under low beams. *(5:06-5:46)* (Roblox-specific; the Collision Groups editor with MovementDucking and MovementLowObstacle is shown at 5:30)
- Parkour moves use raycasts to measure obstacles and tag-based triggers (swing bars are found by a "swing bar" tag; walls by raycast). *(14:25-15:42)* (Roblox-specific)
- Effects are cloned templates (trail, dust, burst, sparks, shock wave); the server validates that a requested effect exists and rate-limits it, then relays it so other players see it. *(6:53-9:25)* (Roblox-specific, speaker claim)
- Three separate stamina bars (run, jump, sprint) deplete on use and refill after a short delay. *(12:20-12:44)* Three coloured bars are visible at the bottom of the demo frames.
- Mobile: round buttons (run, crouch, slide, dash) are laid out around Roblox's own jump button and only appear on touch devices; the same actions are triggered as on keyboard. *(11:00-11:23, 12:44-13:04)* (shown)
- The demo shows a controls cheat-sheet overlay, on-screen labels such as SWING and CLIMB near objects, and an anime-styled avatar. *(0:10, 16:30-19:10)* (shown)
- Troubleshooting claim: most failures are name mismatches or animations published under a different owner than the game. *(19:39-19:54)* (speaker claim)

## Visual check needed
- 5:06-5:46: collision group settings at full size, to confirm which pairs are disabled.
- 9:25-11:23: the stamina and mobile UI property sheets (values were not legible).
- 16:15-19:10: the full test run, to judge how the moves chain together and whether camera behaviour is smooth.

## Hypotheses
- **H1: Config-driven, single-state movement is easier to extend than per-move scripts** *(confidence: medium)*. Test: add a new move to an existing sample and count the files touched.
- **H2: A client-side movement system needs server validation only for cosmetics and rate limiting** *(confidence: medium)*; the video relays effects through the server but does not validate positions. Test: review what the server can verify.
- **H3: Mobile parity is cheap if input is routed to named actions** *(confidence: medium)*. Test: map our own actions to buttons and keyboard through one action table.

## Relevance to our game
- Haunted Collector's player movement is Roblox default; none of these moves are scoped. This is background only.
- The "one action at a time" shared-state idea would matter if we ever add traversal (relevant to [[SYS-Haunted-Capture-Loop]] timing, where unexpected movement could interact with capture).
- Replicating effects through the server matches our rule that the server is authoritative; but movement here is client-owned, which we would validate before trusting for anything gameplay-relevant ([[ADR-0010-Client-Reported-Gaze]] states our approach for client-reported data).
- The collision-group trick is a general Roblox technique we might reuse for ghost-passable geometry.

## Original implementation ideas
- A small "action state" module for any future player abilities: one active action, a cooldown table, and a config file for numbers.
- A collision-group audit when we add ghost-passable props, written from scratch.
- Mobile button layout rules derived from our own HUD constraints, not this video's layout.

## Recommendations (max 3)
1. Treat this as a design reference for structure only; do not import its scripts.
2. If we add traversal, define the one-action-at-a-time rule and server checks in a task note first.
3. Check collision-group usage in our own world before adding new ones.

## Needs human review
- Unverified conclusions:
  - What the full scripts do (not shown legibly), including any exploit surface.
  - Whether the climb/wall-run moves are comfortable or glitchy in practice.
  - Whether R6-vs-R15 support matters for our game (our rig choice is not part of this note).
