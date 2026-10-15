---
id: RSH-20261014-Parkour-Vault-System-Video
title: "How to Make a Parkour Vault System in Roblox Studio (R6 & R15) (video)"
type: research
project: GAME-002
status: research
sources:
  - https://youtu.be/qVOd6tRZ-V8
confidence: medium
created: 2026-10-14
updated: 2026-10-14
tags:
  - research/systems
  - research/movement
---
# How to Make a Parkour Vault System in Roblox Studio (R6 & R15) (video)

> **Draft.** A hobbyist tutorial; speaker claims are unaudited and nothing here is approved.

## Question
Systems variant: how does a one-script, tag-based vault work, and what is reusable about its measure-then-arc approach? General knowledge-building for GAME-002, tied to no task. Tags: (general) = applies to game work anywhere, (Roblox-specific) = Roblox Studio or its engine, (Blender) = Blender.

## Sources
| Source | URL | Accessed |
|---|---|---|
| "How to Make a Parkour Vault System in Roblox Studio (R6 & R15)", uploader MrWonderHow, 6:35 | https://youtu.be/qVOd6tRZ-V8 | 2026-10-14 |

**Evidence limits.**
- Captions: English, auto-generated, readable but with mistranslations; the speaker's English appears machine-translated in places. Scripts are described as "shown on the screen", so exact code and numeric property values are mostly not in the captions.
- Frames: 4 cue frames at 1024 px viewed on a contact sheet (640 px tiles), plus 12 sweep frames across the whole video viewed on one 480 px contact sheet. Fine text and numbers on screen were mostly not legible at these sizes.
- No audio was heard by us.
- **References compared:** the project's existing research notes and `10 References/` index notes were checked for overlap; nothing in `10 References/` was edited. No code from the video was copied.

## Observed mechanics (verified)
Verified means said in captions or seen in a viewed frame. Timestamps *(m:ss)*.
- A single LocalScript in StarterCharacterScripts handles the whole vault; it needs two animations (R15, R6), one sound and a trail template. *(0:05-0:44)*
- Objects are opted in by a CollectionService-style tag named "vault"; untagged parts behave as ordinary obstacles. *(0:57-1:14)* (Roblox-specific; the tag slide is shown at 1:10)
- The script measures the wall's height and thickness, computes a landing point on the far side, and moves the character along a curved arc scaled to the wall, instead of pushing it forward. *(4:01-4:18)* (general)
- Tunables at the top of the script: detection range, min/max wall height, wall thickness, landing distance, duration, cooldown, trail time and width. *(4:18-4:34)* (general)
- The trail is a disabled template that the script copies onto both arms and both legs. *(3:12-3:33)* (Roblox-specific)
- Test walls must be anchored and tagged; animations must be published by the account or group that owns the game or they will not play. *(1:35-1:47, 5:21-5:47)* (Roblox-specific, speaker claim)
- Demo frames show brick walls of different heights with the character vaulting at 4:54. *(shown)*

## Visual check needed
- 3:12-3:33: the trail template values.
- 4:54-5:11: the arc over the tallest and thickest walls, to see how it handles edge cases.

## Hypotheses
- **H1: Tag-gated, raycast-measured movement is a safe, data-driven pattern for interactions** *(confidence: medium)*. Test: build a toy interactable with the same pattern.
- **H2: Client-owned vaulting is acceptable only for non-competitive movement** *(confidence: medium)*. Test: decide per feature whether the server needs to confirm position.

## Relevance to our game
- Not scoped for GAME-002. Useful as a model for tag-gated interactions (CollectionService) and for measuring before moving.
- Because the player moves on the client, anything the server must trust would need validation; see [[ADR-0010-Client-Reported-Gaze]].

## Original implementation ideas
- A tag-based "interactable" convention for our world props, defined in our own words and implemented server-side where it matters.

## Recommendations (max 3)
1. Keep as a reference for tag-gated interactions only.

## Needs human review
- Unverified conclusions:
  - Whether the arc looks natural at all wall sizes.
  - Server-side implications (not shown).
