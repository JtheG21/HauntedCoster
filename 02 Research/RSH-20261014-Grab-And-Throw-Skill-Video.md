---
id: RSH-20261014-Grab-And-Throw-Skill-Video
title: "How to Make the Most Satisfying Grab Skill in Roblox (video)"
type: research
project: GAME-002
status: research
sources:
  - https://youtu.be/WKaHXyL7j-Q
confidence: medium
created: 2026-10-14
updated: 2026-10-14
tags:
  - research/systems
  - research/combat
  - research/security
---
# How to Make the Most Satisfying Grab Skill in Roblox (video)

> **Draft.** A hobbyist tutorial; speaker claims are unaudited and nothing here is approved.

## Question
Systems variant: how is a server-validated grab-and-throw skill structured (dash, grab, throw, finisher), and what does its client/server split imply for ours? General knowledge-building for GAME-002, tied to no task. Tags: (general) = applies to game work anywhere, (Roblox-specific) = Roblox Studio or its engine, (Blender) = Blender.

## Sources
| Source | URL | Accessed |
|---|---|---|
| "How to Make the Most Satisfying Grab Skill in Roblox", uploader MrWonderHow, 9:38 | https://youtu.be/WKaHXyL7j-Q | 2026-10-14 |

**Evidence limits.**
- Captions: English, auto-generated, readable but with mistranslations; the speaker's English appears machine-translated in places. Scripts are described as "shown on the screen", so exact code and numeric property values are mostly not in the captions.
- Frames: 5 cue frames at 1024 px viewed on a contact sheet (640 px tiles), plus 12 sweep frames across the whole video (480 px contact sheet; not opened for every video). Fine text and numbers on screen were mostly not legible at these sizes.
- No audio was heard by us.
- **References compared:** the project's existing research notes and `10 References/` index notes were checked for overlap; nothing in `10 References/` was edited. No code from the video was copied.

## Observed mechanics (verified)
Verified means said in captions or seen in a viewed frame. Timestamps *(m:ss)*.
- Setup: a test dummy model, one RemoteEvent ("skill remote") as the only client/server channel, attachments with particle emitters for crack and wind effects, a sounds folder (six sounds), post-processing effects (bloom, blur, colour correction) and an "aura" folder under the torso. *(0:41-2:13)*
- A ragdoll module toggles ragdoll on and off by converting joints (animation constraints on R15, Motor6D to ball-socket on R6) and records what it changed so it can be undone exactly. *(2:52-3:51)* (Roblox-specific, speaker claim)
- Server script validates the request: you have a hand, the enemy is alive and within range; the client chooses the target but the server decides whether it is allowed. *(4:39-4:56)* (security-relevant; speaker states this deters exploiters)
- The server welds the enemy's head to the player's hand with a Motor6D so the grab never depends on physics, then performs the throw and removes the weld. *(5:03-5:12)*
- A killing throw triggers a finisher: enemy pinned, animation slowed (speed 0.25), enemy slides to the floor in slow motion, and the client plays a close-up orbital camera with strong contrast. *(5:24-5:42, 9:03-9:19)* (shown: the code with a SlowMo remote and AdjustSpeed 0.25)
- Client: pressing Z finds the nearest enemy, turns toward it and dashes with a linear velocity, leaving fading ghost trails tinted by the aura; effects and screen shake are purely local and the client makes no decisions. *(6:04-7:23)*
- Two animations (grab, throw) with no event markers to add; priorities and preloading are handled by the script. *(7:23-8:41)*

## Visual check needed
- 9:03-9:19: the slow-motion finisher at full size.

## Hypotheses
- **H1: "Client picks, server decides" is the right split for any skill-targeting** *(confidence: medium)*; matches our own rule. Test: apply the same split to a hypothetical new interaction.
- **H2: A reversible ragdoll toggle that records its own changes is safer than ad-hoc property edits** *(confidence: medium)*.

## Relevance to our game
- Reinforces AGENTS.md ("the server is authoritative; every client input is validated and rate-limited") and [[ADR-0010-Client-Reported-Gaze]].
- The demo avatar in the frames is a licensed anime character; see [[RSH-20261010-Anime-IP-And-Demand]] for why we avoid that.
- Grab/throw is not in our scope; capture ([[SYS-Haunted-Capture-Loop]]) already works server-side.

## Original implementation ideas
- A "request validation" template for new skills (state, range, cooldown, target validity) with server-computed results.

## Recommendations (max 3)
1. Keep as a second example of the validation pattern; skip the combat feature.

## Needs human review
- Unverified conclusions:
  - Whether the server accounts for range inflation and latency (not shown).
  - Licensed-character usage in the demo (not ours to copy).
