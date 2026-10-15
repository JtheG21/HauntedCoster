---
id: RSH-20261014-Pet-RPG-Claude-MCP-Full-Tutorial-Video
title: "I Built a Roblox Pet RPG with Claude Opus 4 MCP + Roblox Studio MCP (Full Tutorial) (video)"
type: research
project: GAME-002
status: research
sources:
  - https://youtu.be/rMcsenUyOKY
confidence: medium
created: 2026-10-14
updated: 2026-10-14
tags:
  - research/ai-workflow
  - research/3d-models
  - research/rigging
  - research/systems
---
# I Built a Roblox Pet RPG with Claude Opus 4 MCP + Roblox Studio MCP (Full Tutorial) (video)

> **Draft.** A hobbyist tutorial; speaker claims are unaudited and nothing here is approved.

## Question
3D-models + AI-workflow variant: what is the full step list from photos to rigged pets to working shop, combat and enemy systems with MCP assistants, and which lessons (budgets, rigging pitfalls, spec-driven prompting) transfer? Modeling, topology, texturing and rigging weighted equally. General knowledge-building for GAME-002, tied to no task. Tags: (general) = applies to game work anywhere, (Roblox-specific) = Roblox Studio or its engine, (Blender) = Blender.

## Sources
| Source | URL | Accessed |
|---|---|---|
| "I Built a Roblox Pet RPG with Claude Opus 4 MCP + Roblox Studio MCP (Full Tutorial)", uploader MrWonderHow, 17:35 | https://youtu.be/rMcsenUyOKY | 2026-10-14 |

**Evidence limits.**
- Captions: English, auto-generated, readable but with mistranslations; the speaker's English appears machine-translated in places. Scripts are described as "shown on the screen", so exact code and numeric property values are mostly not in the captions.
- Frames: 6 cue frames at 1024 px viewed on a contact sheet (640 px tiles), plus 12 sweep frames across the whole video (480 px contact sheet; not opened for every video). Fine text and numbers on screen were mostly not legible at these sizes.
- No audio was heard by us.
- **References compared:** the project's existing research notes and `10 References/` index notes were checked for overlap; nothing in `10 References/` was edited. No code from the video was copied.

## Observed mechanics (verified)
Verified means said in captions or seen in a viewed frame. Timestamps *(m:ss)*.
- Pet design: photos of a real dog were given to an image generator to produce a low-poly cartoon reference; the first result sat, so he asked for a standing four-legged pose with multiple views, then cropped front, side and angle views. *(0:11-1:20)* (shown: a prompt and photo grid)
- Image-to-3D: use Standard mode (not low-poly) for the first generation and enable multi-view; the first model was about 250,000 triangles; remesh adaptive/low reduced it to about 3,000 while keeping shape; quads are easier to edit later. *(1:36-2:49)* (speaker claim)
- Fixed polygon count produced a damaged texture with black patches on the parrot; fixed with the generator's texture heal brush. *(5:19-5:58)* (speaker claim)
- Rigging in Blender through an MCP assistant: skeleton, parent with automatic weights, idle and walk animations (a loop mismatch fixed by asking), IK bones for feet. *(3:08-4:47)* (speaker claim)
- The parrot's wings were drawn too close to the body, causing deformation problems; he asked the assistant to split the wings into their own mesh; result "not perfect, good enough". *(5:19-7:05)* (speaker claim; design lesson)
- Export settings: selected objects, animation, copy path mode, embed media, scale 0.01; in Studio import with rig type Custom and load animations from the FBX; root motion is not preserved, so heights/offsets are fixed by script. *(7:05-8:30)*
- Per-pet VFX folders: a "glow" copy of the mesh with neon material and a "combat" folder (attack, hit, projectile); effects partly come from free toolbox particle assets. *(9:49-10:44)*
- Systems were built with a Studio MCP assistant in a project holding the game design doc, pet data and animation IDs: shop GUI (interaction key, confirmation, success message), pet summon and follow/attack AI, enemy zones with level-scaled gold and three enemies per spawn, treasure chests, health bars, sounds. *(11:31-15:36)* (shown: a shop GUI with a confirm dialog and a project description prompt)
- He iterated by playtesting and reporting issues (shop stays open, glow fades too fast, parrot flies too high, enemy aggro range too large) and updating the project document. *(13:06-15:36)*
- Final structure: remote events, shop config (IDs, prices, stats, animation IDs), server scripts per feature, client shop and VFX scripts. *(16:10-16:56)*
- Local Roblox creator docs (`~/Code/creator-docs`, art/modeling/specifications.md) state that individual meshes cannot exceed 20,000 triangles; a 10,000-triangle figure applies per part for some avatar items. The speaker's "around 10,000 per mesh" is therefore a conservative or avatar-specific number, not the general limit. Not independently re-checked against the live site.

## Visual check needed
- 5:19-7:05: the wing deformation and the split-mesh result, at full size.
- 9:49-10:44: the glow/neon duplicate technique and its look.
- 11:31-12:30: the shop UI, for patterns only.

## Hypotheses
- **H1: Multi-view image input produces more accurate generated models than single-view** *(confidence: medium)*; stated repeatedly by the creator. Test: compare one subject both ways.
- **H2: Designing the model for rigging (limbs separated from the body, standing pose) avoids later deformation fixes** *(confidence: medium, a lesson the creator learned the hard way)*.
- **H3: A written design doc plus animation/asset IDs in the assistant's project is what makes MCP build sessions coherent** *(confidence: medium)*.

## Relevance to our game
- Strong match for how we want specs written; our task notes and Game Design note play the same role ([[RSH-20261014-AI-Incremental-Game-Pipeline-Video]] describes the same handoff idea).
- The "design for rigging" lesson is directly useful for creature briefs in our own pipeline, independent of which tool makes the mesh.
- Quality still has to meet the [[3D Model Quality Baseline]]: low triangle count and a neon duplicate are not finish; effects can hide weak form.
- Shop systems in the video are gold-based; our shop scope is in [[ADR-0011-Monetization-UI-Scope]] and [[SYS-Haunted-Monetization-UI]], which win.
- Third-party generators and paid services, and any publishing of assets, require approval.

## Original implementation ideas
- A creature brief template: pose for rigging (standing, limbs separated, wings/appendages away from the body), required views, triangle budget, texture expectations, rig class.
- A short "issues log" convention in a task note, matching the creator's playtest-and-report loop but with our own task records.

## Recommendations (max 3)
1. Add rigging-aware design points to any future creature brief.
2. Keep generator and service use behind explicit approval.

## Needs human review
- Unverified conclusions:
  - Which services are free or paid, and licence terms for their outputs.
  - Actual model and rig quality (viewed only on contact sheets).
  - Whether Roblox's limit statements match the live documentation.
