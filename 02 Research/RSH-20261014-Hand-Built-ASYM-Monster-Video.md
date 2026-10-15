---
id: RSH-20261014-Hand-Built-ASYM-Monster-Video
title: "How to Make an ASYM Monster in Roblox Studio (Step by Step) (video)"
type: research
project: GAME-002
status: research
sources:
  - https://youtu.be/MrZdEmipp0c
confidence: medium
created: 2026-10-14
updated: 2026-10-14
tags:
  - research/3d-models
  - research/rigging
  - research/npc
---
# How to Make an ASYM Monster in Roblox Studio (Step by Step) (video)

> **Draft.** A hobbyist tutorial; speaker claims are unaudited and nothing here is approved.

## Question
3D-models variant: how is a hand-built, part-based monster made rigged and animated entirely in Studio, and how does its finish compare with our baseline? Modeling, topology, texturing and rigging are weighted equally. General knowledge-building for GAME-002, tied to no task. Tags: (general) = applies to game work anywhere, (Roblox-specific) = Roblox Studio or its engine, (Blender) = Blender.

## Sources
| Source | URL | Accessed |
|---|---|---|
| "How to Make an ASYM Monster in Roblox Studio (Step by Step)", uploader MrWonderHow, 16:05 | https://youtu.be/MrZdEmipp0c | 2026-10-14 |

**Evidence limits.**
- Captions: English, auto-generated, readable but with mistranslations; the speaker's English appears machine-translated in places. Scripts are described as "shown on the screen", so exact code and numeric property values are mostly not in the captions.
- Frames: 8 cue frames at 1024 px viewed on contact sheets (640 px tiles), plus 12 sweep frames across the whole video (480 px contact sheet; not all sheets were opened). Fine text and numbers on screen were mostly not legible at these sizes.
- No audio was heard by us.
- **References compared:** the project's existing research notes and `10 References/` index notes were checked for overlap; nothing in `10 References/` was edited. No code from the video was copied.

## Observed mechanics (verified)
Verified means said in captions or seen in a viewed frame. Timestamps *(m:ss)*.
- The monster is built from Parts named like R15 body parts, joined by Motor6D joints so animation can drive them; a Humanoid (R15, hip height 8.5) and Animator are added. *(0:41-1:00, 10:09-10:35)* (Roblox-specific; part-based block monster shown)
- Each Motor6D has Part0 (parent), Part1 (child) and C0/C1 offsets; correct offsets let limbs bend at the joint instead of drifting. *(2:56-4:26)* (Roblox-specific)
- The hammer is a model of three parts welded together and attached to the lower right hand by a Motor6D so it follows the animation; the hammer head is the ground-contact point. *(4:26-6:09)*
- Texturing: imported LEGO-style textures dragged onto parts; the frames show a brick-textured, blocky red/blue/yellow character. *(6:09-7:14, shown)* (speaker offers the textures via the description)
- VFX comes from an effects pack from the toolbox: fire on the head, black smoke on the body, lightning on hammer and body, and an impact-fire template cloned on hits. *(7:14-10:00)* (shown: fire, smoke and a Creator Store VFX search)
- Animations: idle (looped), slow heavy walk (looped), attack (not looped, with held poses at start and end for weight). *(10:44-12:09)* (shown in the Animation Editor)
- AI: a server script finds a target, computes a path, follows it and attacks about once per second; the impact point is raycast down from the hammer head. *(12:45-13:17, 15:01-15:17)* (speaker claim; code not shown)
- Client side: a camera-shake script and local impact particles; footsteps get a weaker shake. *(14:12-14:42)*
- The speaker says he does not make models from scratch in other projects; this build is "by hand". *(0:17-0:41)*

## Visual check needed
- 3:10-4:26: the joint table and a bent limb, to confirm the offsets approach.
- 12:45-15:17: the chase and attack in motion, which stills cannot show.
- 15:00: the final result at full size, for the finish comparison.

## Hypotheses
- **H1: A Motor6D part-rig is a viable path for stylised, blocky creatures with no external tooling** *(confidence: medium)*. Test: build a small creature with 6 parts and one animation.
- **H2: Baked-in brick textures give finish without UV work, but only for blocky styles** *(confidence: low-medium)*.
- **H3: Held poses at the ends of an attack animation read as weight** *(confidence: low-medium)*. Test: compare with and without.

## Relevance to our game
- **Against the 3D baseline:** the monster is a coloured, texture-stamped block assembly. The baseline accepts cubic stylisation when proportions, silhouette and secondary forms are purposeful (it cites blocky dragons and monsters as minimum examples), so a part-based creature can meet the floor, but this one is basic: sparse secondary form, generic colour blocks, and effects (fire, smoke, lightning) that the baseline warns can conceal weak form. It would be unfinished by itself.
- Rigging (Motor6D, Humanoid, hip height) is a clear, low-cost way to animate; but it constrains the model to named humanoid-style parts.
- Chase AI claims need server authority and pathfinding review before use; see [[ADR-0010-Client-Reported-Gaze]] for our stance on client-reported data.
- Some effects come from a paid or third-party pack; usage rights are unknown.

## Original implementation ideas
- A creature-rig checklist: part naming, joint offsets, root part, hip height, and a one-animation playback test.
- A held-pose rule of thumb for heavy attack animations, tested in our own creatures.

## Recommendations (max 3)
1. Use as a rigging reference only; not as a quality bar.
2. Verify any third-party pack licences before use.

## Needs human review
- Unverified conclusions:
  - Whether the chase AI is safe and efficient (not shown).
  - Texture and VFX licences.
  - How this holds up for non-humanoid creatures.
