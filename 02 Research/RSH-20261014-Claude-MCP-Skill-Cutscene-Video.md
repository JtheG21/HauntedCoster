---
id: RSH-20261014-Claude-MCP-Skill-Cutscene-Video
title: "Claude MCP + Codex Help Me Create a Roblox Skill Cutscene in Minutes (video)"
type: research
project: GAME-002
status: research
sources:
  - https://youtu.be/l9Qx5orXbs8
confidence: medium
created: 2026-10-14
updated: 2026-10-14
tags:
  - research/ai-workflow
  - research/vfx
  - research/camera
---
# Claude MCP + Codex Help Me Create a Roblox Skill Cutscene in Minutes (video)

> **Draft.** A hobbyist tutorial; speaker claims are unaudited and nothing here is approved.

## Question
AI-workflow variant: how did a creator use Claude with a Roblox Studio MCP (and Codex) to prototype a cinematic skill, and what in that workflow is trustworthy or risky for our process? General knowledge-building for GAME-002, tied to no task. Tags: (general) = applies to game work anywhere, (Roblox-specific) = Roblox Studio or its engine, (Blender) = Blender.

## Sources
| Source | URL | Accessed |
|---|---|---|
| "Claude MCP + Codex Help Me Create a Roblox Skill Cutscene in Minutes", uploader MrWonderHow, 8:08 | https://youtu.be/l9Qx5orXbs8 | 2026-10-14 |

**Evidence limits.**
- Captions: English, auto-generated, readable but with mistranslations; the speaker's English appears machine-translated in places. Scripts are described as "shown on the screen", so exact code and numeric property values are mostly not in the captions.
- Frames: 5 cue frames at 1024 px viewed on a contact sheet (640 px tiles), plus 12 sweep frames across the whole video (480 px contact sheet; not opened for every video). Fine text and numbers on screen were mostly not legible at these sizes.
- No audio was heard by us.
- **References compared:** the project's existing research notes and `10 References/` index notes were checked for overlap; nothing in `10 References/` was edited. No code from the video was copied.

## Observed mechanics (verified)
Verified means said in captions or seen in a viewed frame. Timestamps *(m:ss)*.
- Manual setup before AI: a hero and an enemy dummy, an outline using a Highlight with zero fill transparency, an anime-style skybox, colour correction, and a toolbox "charging animation" published to get its ID. *(0:01-1:42)*
- Claude (connected to Roblox Studio MCP) first explained how creators build cinematic charge scenes (blur/depth of field, atmosphere, skybox, bloom, colour correction, sun rays, aura particles, camera movement) and then built a charging-skill demo. *(2:10-3:19)* (shown: a chat and a camera/charge sequence)
- The speaker stresses screen flashes plus camera shake as key to selling impact. *(2:27-3:01)* (opinion, as relayed from Claude)
- The impact frame image was generated with an image generator, then replaced with a screenshot-based version; its asset ID was handed to Claude, which generated a ScreenGui/Frame/ImageLabel using it. *(3:35-4:38)*
- Code was split into a skill controller, a charge-skill module and a storm-skill module. *(4:38-4:55)*
- Rewrite requested: custom animation IDs and VFX triggered through animation event markers; after hitting a usage limit he moved the conversation to Codex, which reorganised animation IDs into a data structure keyed by marker names. *(4:55-6:07)*
- Hair colour changes are driven by markers on both skills (blue/yellow/purple variants, welded wigs). *(6:07-7:41)* (shown: glowing hero, "CHARGING SKILL" overlay)
- The speaker asks whether the AI workflow is good or bad for Roblox developers; no data is given. *(7:58-8:08)* (opinion)

## Visual check needed
- 3:19-4:07: the first generated cutscene in motion.
- 5:12-6:25: the prompts and the marker/data-structure result, to judge how directed the AI output was.

## Hypotheses
- **H1: AI-assisted prototyping is fast for cosmetic scenes but produces systems that still need human review** *(confidence: medium)*. Test: review one generated script for hidden assumptions.
- **H2: Passing a conversation between two assistants preserves intent only when the spec is written down** *(confidence: low-medium)*; the video shows it working once.

## Relevance to our game
- This mirrors our own Claude/Codex collaboration, where specs live in task notes and `tasks/queue.json` is authoritative; it confirms that written specs make hand-offs work.
- Any AI-generated code in our project must pass `scripts/check.sh` and be reviewed; MCP edits to Studio need an approved task.
- The hero here is a licensed anime character; see [[RSH-20261010-Anime-IP-And-Demand]].

## Original implementation ideas
- Keep our existing process; consider a short "cutscene spec" template (beats, camera, effects, markers) in a task note before generating any effect code.

## Recommendations (max 3)
1. No change to process; use the cutscene-spec idea if a task needs cinematic moments.

## Needs human review
- Unverified conclusions:
  - Claimed model names and plan details in the video (not verified).
  - Quality of AI-generated code (not shown in detail).
