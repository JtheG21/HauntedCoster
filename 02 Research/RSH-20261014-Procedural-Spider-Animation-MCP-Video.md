---
id: RSH-20261014-Procedural-Spider-Animation-MCP-Video
title: "Procedural Spider Animation in Roblox Studio with Claude MCP (video)"
type: research
project: GAME-002
status: research
sources:
  - https://youtu.be/j1At2JCeteo
confidence: medium
created: 2026-10-14
updated: 2026-10-14
tags:
  - research/ai-workflow
  - research/3d-models
  - research/rigging
  - research/animation
---
# Procedural Spider Animation in Roblox Studio with Claude MCP (video)

> **Draft.** A hobbyist tutorial; speaker claims are unaudited and nothing here is approved.

## Question
3D-models + AI-workflow variant: how does a creator go from concept art to an image-to-3D model, remesh, rig in Blender with an MCP assistant, and drive procedural leg stepping in Studio, and what does it imply for quality and budget? Modeling, topology, texturing and rigging weighted equally. General knowledge-building for GAME-002, tied to no task. Tags: (general) = applies to game work anywhere, (Roblox-specific) = Roblox Studio or its engine, (Blender) = Blender.

## Sources
| Source | URL | Accessed |
|---|---|---|
| "Procedural Spider Animation in Roblox Studio with Claude MCP", uploader MrWonderHow, 11:10 | https://youtu.be/j1At2JCeteo | 2026-10-14 |

**Evidence limits.**
- Captions: English, auto-generated, readable but with mistranslations; the speaker's English appears machine-translated in places. Scripts are described as "shown on the screen", so exact code and numeric property values are mostly not in the captions.
- Frames: 5 cue frames at 1024 px viewed on a contact sheet (640 px tiles), plus 12 sweep frames across the whole video (480 px contact sheet; not opened for every video). Fine text and numbers on screen were mostly not legible at these sizes.
- No audio was heard by us.
- **References compared:** the project's existing research notes and `10 References/` index notes were checked for overlap; nothing in `10 References/` was edited. No code from the video was copied.

## Observed mechanics (verified)
Verified means said in captions or seen in a viewed frame. Timestamps *(m:ss)*.
- Concept art: an image generator produced a 4-legged spider reference with multiple views (top, front, bottom, side, back, three-quarter) cropped to separate images. *(0:44-1:25)* (shown: a model/rig reference sheet)
- An image-to-3D service built the model from the multi-view images; the first result was about 270,000 triangles, then textured, then remeshed with an "adaptive, low" setting to about 5,000 triangles with a near-identical look; fixed poly count tends to create odd geometry or holes (speaker claim). *(1:25-3:04)* (shown: the generator UI with multi-view slots and a spider mesh)
- Rigging in Blender through an MCP assistant: "add bones and auto weight"; the spider is kept at origin with zero rotation for correct rig maths; legs deformed correctly in pose mode. *(4:41-5:14)* (speaker claim)
- Export both mesh and armature as FBX with selected objects, copy path mode, embedded textures and scale 0.01; import in Studio with rig type Custom and scale up about 5x. *(5:14-6:15)* (shown: the Studio importer with Rig General set to Custom)
- In Studio, an MCP-connected assistant built IK for four legs (foot targets, pull/pole objects), a spider target object that the spider chases, and server scripts split into runner, controller, leg controller and config. *(8:17-10:48)* (speaker claim; shown: the spider on terrain with target markers)
- The speaker stresses verifying the MCP connection first: sometimes the assistant only generated text because it was not actually connected; connection failed several times until a full restart. *(7:05-7:38)*
- Issues found: moving backward when the target changed and wrong body orientation on slopes; resolved over several iterations. *(8:36-9:07)* (speaker claim)
- Local Roblox creator docs (`~/Code/creator-docs`, art/modeling/specifications.md) state that individual meshes cannot exceed 20,000 triangles; a 10,000-triangle figure applies per part for some avatar items. The speaker's "around 10,000 per mesh" is therefore a conservative or avatar-specific number, not the general limit. Not independently re-checked against the live site.

## Visual check needed
- 2:06-3:04: the remesh before/after at full size, to judge detail loss (the claimed "almost identical" is not verified).
- 9:07-10:48: the stepping behaviour in motion on slopes.

## Hypotheses
- **H1: Image-to-3D plus remesh yields a usable silhouette quickly, but form quality depends on the generator and needs review against the baseline** *(confidence: medium)*. Test: run one creature through and score it with the baseline rubric.
- **H2: Auto-weights are adequate for simple leg chains but not for complex wings or fur** *(confidence: low-medium)* (a later video by the same creator reports wing problems). Test: rig one winged creature.
- **H3: Procedural IK stepping reduces the need to author walk animations for multi-legged creatures** *(confidence: medium)*.

## Relevance to our game
- Relevant to how GAME-002 might produce creature meshes, but third-party generators and paid services are not approved; spending or uploading needs jg approval.
- Generated geometry must still pass the [[3D Model Quality Baseline]] (silhouette, forms, all-view finish, no effects hiding flaws); a low triangle count is a budget fix, not quality.
- Compare with the Studio MCP use in [[RSH-20261014-AI-Incremental-Game-Pipeline-Video]] and [[RSH-20261014-Creature-Capture-AI-Build-Video]]: all depend on a live Studio connection that can silently be absent.
- Procedural movement for non-humanoid creatures is an alternative to humanoid auto-rigging noted in [[RSH-20261014-Monster-NPC-Sculpt-And-Rig-Video]].

## Original implementation ideas
- A creature asset intake checklist: source, licence, triangle count vs budget, texture state, rig class, and a baseline review.
- A "connection test first" step in any MCP-assisted session (read-only query) before asking for edits.

## Recommendations (max 3)
1. Do not adopt generators or paid services without approval; use the intake checklist idea.
2. Verify the MCP connection before relying on assistant edits.

## Needs human review
- Unverified conclusions:
  - Licence terms of the generator's output for commercial use.
  - Actual quality of the remeshed model (viewed only on small contact sheets).
  - Whether the stepping is robust on uneven terrain.
