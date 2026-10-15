---
id: RSH-20261014-Pet-Shop-Summon-Prototype-Video
title: "Creating a Pet Shop Summon Game Prototype in Roblox Studio Using Claude MCP (video)"
type: research
project: GAME-002
status: research
sources:
  - https://youtu.be/_bSoffF6Emw
confidence: medium
created: 2026-10-14
updated: 2026-10-14
tags:
  - research/ai-workflow
  - research/monetization
  - research/ui
---
# Creating a Pet Shop Summon Game Prototype in Roblox Studio Using Claude MCP (video)

> **Draft.** A hobbyist tutorial; speaker claims are unaudited and nothing here is approved.

## Question
AI-workflow and game-design variant: what is the shape of a summon/pet-shop prototype built with AI tools (shop UI, pets, enemies, gold), and what relates to our own shop scope? General knowledge-building for GAME-002, tied to no task. Tags: (general) = applies to game work anywhere, (Roblox-specific) = Roblox Studio or its engine, (Blender) = Blender.

## Sources
| Source | URL | Accessed |
|---|---|---|
| "Creating a Pet Shop Summon Game Prototype in Roblox Studio Using Claude MCP", uploader MrWonderHow, 3:12 | https://youtu.be/_bSoffF6Emw | 2026-10-14 |

**Evidence limits.**
- Captions: English, auto-generated, readable but with mistranslations; the speaker's English appears machine-translated in places. Scripts are described as "shown on the screen", so exact code and numeric property values are mostly not in the captions.
- Frames: 4 cue frames at 1024 px viewed on a contact sheet (640 px tiles), plus 12 sweep frames across the whole video (480 px contact sheet; not opened for every video). Fine text and numbers on screen were mostly not legible at these sizes.
- No audio was heard by us.
- **References compared:** the project's existing research notes and `10 References/` index notes were checked for overlap; nothing in `10 References/` was edited. No code from the video was copied.

## Observed mechanics (verified)
Verified means said in captions or seen in a viewed frame. Timestamps *(m:ss)*.
- Game loop: open a pet shop, buy pets with in-game gold, use pets to fight enemies, collect treasure chests for gold. *(0:13-0:49)* (shown: a "PET SHOP" panel with a "Confirm Purchase" dialog; a gold counter; pets following the player)
- Pets: a melee dog, a ranged parrot with explosion projectiles, and a locked "coming soon" dragon; zombie NPC enemies with levels. *(0:32-0:49)*
- Pipeline: world concept via a chat assistant, environment models from an image-to-3D service, cleanup in Blender via MCP, ocean added in Studio; pets designed from concept images, modelled, and rigged with the assistant. *(1:08-2:15)* (speaker claim)
- Effects for attacks, explosions and summons were added after animations. *(2:15-2:31)*
- A separate assistant project holds the game description; shop item art/UI visuals came from an image generator. *(2:31-2:48)*

## Visual check needed
- 1:25-2:15: the environment and pet models at full size, for finish and consistency.

## Hypotheses
- **H1: A buy-with-earned-currency, confirm-before-purchase shop is the lowest-friction first monetization loop** *(confidence: medium)*, consistent with ADR-0011's earned-first approach.

## Relevance to our game
- Our approved monetization scope is cosmetics via direct Robux plus earned Coins, no premium currency or paid convenience yet ([[ADR-0011-Monetization-UI-Scope]]); this prototype is gold-only and combat-focused, so it is a different design.
- Confirm-purchase dialogs and locked "coming soon" items are UI patterns that map to the Shop in [[SYS-Haunted-Monetization-UI]], not to be copied.
- This is a prototype with unreviewed AI output; no balance or retention data.

## Original implementation ideas
- A confirmation step and clear "locked" state design for our shop, specified in our own words in the monetization UI baseline if not already present.

## Recommendations (max 3)
1. No action; compare the confirm/locked patterns against the existing baseline when that note is next reviewed.

## Needs human review
- Unverified conclusions:
  - Everything about gameplay balance and monetization is unmeasured.
  - AI-generated assets' licences.
