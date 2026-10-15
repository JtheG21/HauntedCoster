---
id: RSH-20261014-Emote-Wheel-Video
title: "How to Make a Dynamic Emote Wheel in Roblox Studio (R6 & R15) (video)"
type: research
project: GAME-002
status: research
sources:
  - https://youtu.be/0cSg93Lwyvs
confidence: medium
created: 2026-10-14
updated: 2026-10-14
tags:
  - research/ui
  - research/systems
---
# How to Make a Dynamic Emote Wheel in Roblox Studio (R6 & R15) (video)

> **Draft.** A hobbyist tutorial; speaker claims are unaudited and nothing here is approved.

## Question
UI variant: how is a hold-key radial menu with a config-driven list built, and what is worth taking for HUD or shop interactions? General knowledge-building for GAME-002, tied to no task. Tags: (general) = applies to game work anywhere, (Roblox-specific) = Roblox Studio or its engine, (Blender) = Blender.

## Sources
| Source | URL | Accessed |
|---|---|---|
| "How to Make a Dynamic Emote Wheel in Roblox Studio (R6 & R15)", uploader MrWonderHow, 2:28 | https://youtu.be/0cSg93Lwyvs | 2026-10-14 |

**Evidence limits.**
- Captions: English, auto-generated, readable but with mistranslations; the speaker's English appears machine-translated in places. Scripts are described as "shown on the screen", so exact code and numeric property values are mostly not in the captions.
- Frames: 3 cue frames at 1024 px viewed on contact sheets (640 px tiles), plus 12 sweep frames across the whole video (480 px contact sheet; not all sheets were opened). Fine text and numbers on screen were mostly not legible at these sizes.
- No audio was heard by us.
- **References compared:** the project's existing research notes and `10 References/` index notes were checked for overlap; nothing in `10 References/` was edited. No code from the video was copied.

## Observed mechanics (verified)
Verified means said in captions or seen in a viewed frame. Timestamps *(m:ss)*.
- Two scripts only: a config module (one line per emote: name, R15 animation ID, R6 animation ID) and a controller. *(0:19-1:20)*
- The controller reads the config, creates a card per emote and arranges them evenly in a circle; adding or removing an emote is a list edit. *(1:20-1:29)* (general)
- Hold T to open the wheel, move the mouse to a sector (it highlights), release to play the emote. *(1:29-1:46)* (shown: eight sectors including Dance, Wave, Point, Cheer, Sit; centre label shows the highlighted action and "release to play")
- R6/R15 animation IDs are selected automatically from the config. *(1:46-2:08)*
- Names between the folder, config module and controller must match exactly or the system breaks. *(0:28-1:00)*

## Visual check needed
- 1:29-1:46: the sector highlight behaviour with the mouse (stills only show two states).

## Hypotheses
- **H1: A hold-to-open radial menu is fast to use on PC but needs a different pattern on touch** *(confidence: medium)*; the video shows PC only. Test: prototype touch selection.

## Relevance to our game
- Could inform a quick-action radial for the Journal or Mansion (for example quick equip), but nothing is scoped; the shop and monetization UI are governed by [[ADR-0011-Monetization-UI-Scope]].
- Touch behaviour is not covered; we support phone-scale UI (see HUD scaling), so a radial would need its own touch design.

## Original implementation ideas
- A data-driven radial for quick actions where the list comes from a config table; visual style from our own theme.

## Recommendations (max 3)
1. Park as a UI pattern; do not adopt without a screen that needs it.

## Needs human review
- Unverified conclusions:
  - Touch and gamepad behaviour (not shown).
  - Whether emotes fit a collector game at all.
