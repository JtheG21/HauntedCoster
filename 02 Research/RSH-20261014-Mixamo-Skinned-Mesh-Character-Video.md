---
id: RSH-20261014-Mixamo-Skinned-Mesh-Character-Video
title: Custom Skinned-Mesh Player Character (video)
type: research
project: GAME-002
status: research
sources:
  - https://youtu.be/R5KOQbz2rsI
confidence: medium
created: 2026-10-14
updated: 2026-10-14
tags:
  - research/3d-models
  - research/rigging
---
# Custom Skinned-Mesh Player Character (video)

> **Draft.** A hobbyist tutorial on the import and rig plumbing, not a professional-model quality standard. Speaker claims are unaudited and nothing here is approved.

## Question
Using the 3D-model variant of the video prompt: what does this walkthrough show, step by step, about turning a third-party rigged FBX humanoid into a Roblox player character, and what does it say or not say about the technical qualities (triangle count, scale, rig, root part, animation fit) a game-ready model must have? Modeling, topology, texturing/UVs and rigging are weighted equally. Compare with [[RSH-20261014-Mixamo-Custom-Rig-And-Camera-Video]] (same pipeline, rougher). Not tied to any task.

## Sources
| Source | URL | Accessed |
|---|---|---|
| "Roblox Studio - Custom Player Skinned Mesh Character", uploader Alcatraz, 13:31 | https://youtu.be/R5KOQbz2rsI | 2026-10-14 |

**Evidence limits.**
- Captions: English, auto-generated, provenance of the original language unknown. Readable; a few mistranslations ("block horn" is almost certainly the R6 block rig, "wait/standby/anticipation animation" is the idle animation, "RBX animation save" is the Animation Editor's saved-animation folder).
- Frames: 11 cue frames viewed on two 640 px contact sheets (0:05, 3:36, 3:50, 4:20, 5:20, 6:15, 6:50, 9:40, 10:31, 11:51, 13:10) plus 56 sweep frames (about every 15 s) on four 480 px contact sheets. UI text and numbers are mostly illegible at that size; the transcript supplies them.
- No audio heard by us; the demonstration is silent screen recording with narration.
- **References compared:** the rubric and process sections of `10 References/05 Misc/3D Model Quality Baseline.md`. Gallery images not opened (pipeline video, not a model request). Nothing in `10 References/` was edited.

## Observed mechanics (verified)
Tags: (general) = applies to game 3D work anywhere; (Roblox-specific) = about Roblox Studio or its import. Timestamps *(m:ss)*.

**Source asset (general)**
- Needs a rigged FBX character plus separate animation files; he uses a free third-party character-and-animation site (account required). *(0:09-0:26)*
- Character download: T-pose, FBX binary. *(0:34-0:43)* (shown: dark textured humanoid in T-pose)
- Animation downloads: set skin to "no skin" because the base model already has it; check "in place" for the run so the root-bone forward movement is removed. *(1:25-2:07)* (the root-motion point is why the in-place option exists)

**Import and scale (Roblox-specific)**
- Import 3D shows an orange warning triangle: speaker says the model has too many triangles for Roblox; he lets the importer reduce it instead of reducing in Blender. *(3:36-3:57)* (speaker claim; warning icon shown at 3:50; the triangle limit and the resulting count are not stated)
- The imported model is too large, so he copies the position of a standard R6 block rig and scales until the chin just touches the block rig's head. *(3:57-4:37)* (shown)
- He deletes the imported initial poses and animation controller. *(4:37-5:02)*

**Humanoid structure (Roblox-specific)**
- Add Humanoid, then an Animator under it. *(5:02-5:15)*
- Add a Part, rename exactly HumanoidRootPart; size it to sit just below the chin and just above the groin, slightly wider than the torso; collision off, transparent. *(5:15-5:57)* (shown at about 5:20: a flat box near the upper torso)
- On the mesh part: CanCollide, CanTouch and CanQuery false, Massless true. *(6:09-6:21)*
- WeldConstraint on the root part welding it to the mesh; rename the model exactly StarterCharacter and move it into StarterPlayer. *(6:21-6:36)*
- In a test, he estimates HipHeight (2.7 as a starting value) and notes that the character "slides" when it moves; he fixes the slide later. *(6:36-7:20)*

**Animation scale fix (Roblox-specific; the central point of the video)**
- A community Animation Resizer plugin is used. *(7:20-7:40)*
- Duplicate the character, open the Animation Editor, import each FBX animation, set priority (idle for idle, movement for run), save. *(7:40-9:10)*
- The sliding comes from the mesh's Scale property not being 1. He reads the Scale value (0.034 in his case), enters it in the plugin, then resets the mesh's Scale to 1 with the property's arrow button; the animations no longer fit. *(9:10-10:21)* (speaker claim; shown: character mid-run in the editor)
- Apply Scale in the plugin creates new animations with a suffix; those are the fitted ones. They are published and their IDs recorded. *(10:21-10:53)*
- He deletes the duplicate, resets the real StarterCharacter's Scale to 1, and plays: the sliding is gone. *(11:20-11:51)*
- The default Roblox Animate script is copied into the character, an erroring section removed, and the animation IDs replaced with his idle and run IDs. *(11:51-13:23)*

## Visual check needed
- **3:36-3:57**: the import preview at full size, to see what the warning actually lists and the polygon numbers if any.
- **9:30-10:21**: the plugin's input fields and the Scale property at full size.
- **11:42-11:51**: the final playtest to confirm the sliding is really gone (viewed only on a contact sheet).
- **Which mesh and texture quality the character has**: frames show a dark textured humanoid; whether textures were intact on import was not stated.

## Hypotheses
- **H1: A mesh whose Scale property is not 1 breaks animation fit (sliding or floating).** *(confidence: medium, shown plus explained twice across two videos)* Test: import any rigged mesh with non-unit Scale, play idle and run, then repeat after normalizing Scale.
- **H2: A published animation is tied to the exact rig scale it was authored for, so rescaling a character later invalidates its animations.** *(confidence: medium)* Test: change the Scale of a character that already has published animations and check feet contact.
- **H3: Triangle count is a hard import constraint, and the importer's automatic reduction is not a quality-controlled decimation.** *(confidence: low, one off-hand claim)* Test: import a high-poly model, inspect the reduced mesh against the original in neutral light.
- **H4: The pipeline only applies to humanoid-style rigs.** *(confidence: low)* Test: check GAME-002 creature rigs before reusing any step.

## Relevance to our game
- **Against the quality baseline:** this is the technical-acceptance side only (scale, pivots, collision, rig/deformation, root part, animation fit), which [[3D Model Quality Baseline]] says is necessary but separate from visual acceptance. Nothing here says what makes a model's form professional.
- **Compared with the other note** [[RSH-20261014-Mixamo-Custom-Rig-And-Camera-Video]]: this video states the cause of the sliding problem (Scale not equal to 1) and gives the CanCollide/CanTouch/CanQuery/Massless settings, which that one did not. Neither covers topology or UV quality.
- **Server authority:** these are asset and rig steps; nothing here touches remotes or trust. A character with a custom root part still needs server-side validation of any gameplay input, same as now.
- **ADR-0011** requires finished assets for the cosmetic catalog ([[ADR-0011-Monetization-UI-Scope]]); this video offers only the technical checks for that bar.
- **Licensing:** the source character and animations come from a third-party site; terms and licence are unverified, so do not use its assets without checking. (unverified)

## Original implementation ideas
- An "animation fit" test in our asset review: play idle and run on every imported rig in a neutral place and confirm feet contact and no sliding, with the mesh Scale recorded as 1.
- A short rig-sanity list written in our own words for reviewing delivered models: Scale 1, pivot/root placement, collision and query flags on visual-only meshes, massless where welded, one mesh and one texture set.
- Keep any plugins used for animation fixes outside the repo and out of the game; record only the resulting animation ids and the scale used.

## Recommendations (max 3)
1. Treat this video as a technical checklist source only; it is not a quality reference for model form.
2. Add "Scale equals 1 and animations fit" to the technical-acceptance part of future model reviews.
3. Verify the licence of any third-party character or animation site before anything from it enters the game.

## Needs human review
- Unverified conclusions:
  - The exact triangle limit and what the importer's reduction does to form (not stated).
  - Whether the character's source site licence allows use in a published game.
  - Whether our creatures use humanoid rigs (H4).
  - Fine UI values (the Scale number, flags) were read from captions, not full-size frames.
  - The claim that the final result has no sliding was seen only on a contact sheet.
