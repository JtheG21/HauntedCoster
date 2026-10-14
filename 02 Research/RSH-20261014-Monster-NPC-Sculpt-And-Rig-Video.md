---
id: RSH-20261014-Monster-NPC-Sculpt-And-Rig-Video
title: Monster NPC Sculpt, Auto-Rig and Chase Kit (video)
type: research
project: GAME-002
status: research
sources:
  - https://youtu.be/pAPylugPf1s
confidence: medium
created: 2026-10-14
updated: 2026-10-14
tags:
  - research/3d-models
  - research/rigging
  - research/npc
---
# Monster NPC Sculpt, Auto-Rig and Chase Kit (video)

> **Draft.** A creator's quick workflow, partly an advert for his paid kit. Speaker claims are unaudited and nothing here is approved.

## Question
Using the 3D-model variant of the video prompt: what does this creator's "sculpt a scary monster, auto-rig it, animate it, drop it in a chase template" workflow show about modeling, topology (triangle budget), texturing, rigging and animation for a creature, and where does its output sit against the [[3D Model Quality Baseline]]? Modeling, topology, texturing/UVs and rigging are weighted equally. Not tied to any task.

## Sources
| Source | URL | Accessed |
|---|---|---|
| "How To Make A SCARY MONSTER NPC + Animations / Rigging in Roblox Studio (FREE KIT!)", uploader ZeDarkAlien, 16:27 | https://youtu.be/pAPylugPf1s | 2026-10-14 |

**Evidence limits.**
- Captions: English, auto-generated, provenance unknown. Readable but with mistranslations (e.g. "sculpture" for sculpt mode, "groin" for pelvis marker, "Donald's audio", "Idol"). Numbers such as the triangle target are spoken unsurely.
- Frames: 16 cue frames viewed on three contact sheets (640 px per tile) covering 1:29 to 15:39, plus 60 sweep frames (about every 16 s) viewed on four 480 px contact sheets covering the whole video. No frame was opened individually at full 1024 px, so on-screen numbers (statistics overlay, HipHeight) are mostly illegible.
- No audio was heard by us.
- **References compared:** the rubric and process text of `10 References/05 Misc/3D Model Quality Baseline.md`. Gallery images were not opened for this note (no finished model request). Nothing in `10 References/` was edited.

## Observed mechanics (verified)
Tags: (general) = game 3D work anywhere, (Roblox-specific) = Roblox Studio or its import. Timestamps *(m:ss)*.

**Modeling (general)**
- He does not model from scratch ("takes too much time"); he starts from a free 3D male base mesh (OBJ) and sculpts it into a monster. *(0:14-1:48)* (speaker claim; shown: a plain human base mesh in Blender at about 1:30)
- Sculpt tools named: draw, grab, smooth (hold Shift), snake hook for pointy shapes, symmetry on X, F to change brush size, Ctrl to push inward. *(1:48-3:48)* (shown: sculpt-mode brush list)
- Result (shown): an elongated humanoid with a spiked star-like head, very long arms and thin torso; pale grey and untextured. He says he is "not dealing with texturing" in this episode. *(1:29-1:48)*
- Opinion: he calls the result "scary" and then "horrible", and says he does not know what he made. *(3:33-3:48, 10:05)*

**Topology / budget (general)**
- Check the Statistics overlay for triangle count, then add a Decimate modifier and lower it until the count is under a limit, applying it and shading smooth. *(3:48-4:48)* The limit he states changes (15,000, 20,000, then "10K is fine, I think") and he says he does not know. (speaker claim; shown: statistics overlay and decimate panel, numbers illegible)
- He shrinks the mesh because a large one "slides when it moves", a reason he does not explain. *(4:48-5:15)*

**Rigging and animation**
- Export the mesh as FBX, selected objects only, mesh type only. *(5:15-5:47)* (general)
- Upload the FBX to Mixamo's auto-rigger, place markers on chin, wrists, elbows, knees and groin, confirm symmetry and skeleton level of detail; he says no manual rigging in Blender is needed. *(6:00-6:45)* (speaker claim; shown: marker placement and rig preview, both on an elongated body)
- Pick an in-place walk animation, 60 FPS, download "with skin" as FBX. *(6:55-7:40)* (general)
- Import the **animation** FBX (which carries the rig) into Roblox Studio with upload unchecked; the first attempt fails until he renames the asset; the imported mesh then looks "strange". *(7:40-8:30)* (Roblox-specific; shown: a pale lumpy mesh)
- Delete the animation controller; scale the imported model against another rig for size. *(8:30-9:25)* (Roblox-specific)

**Game integration (Roblox-specific)**
- He drops the model into a chase "entity template" from his own kit (a system from his game "The Dark Rooms"), ungroups it, centres and scales the model, and makes template parts transparent. *(8:39-9:38)* The kit is sold through a store page. *(16:09)*
- No texture, so he recolours the mesh black; the shown result is a glossy black humanoid. *(9:53-10:05)* (shown)
- With a rig-editor plugin he sets the HumanoidRootPart, two camera parts (positions for a catch/kill cut), and a folder of "loop points" for patrol; he enables HTTP requests in game security settings and says this is needed. *(10:32-12:49)* (speaker claim; reason not stated)
- Animation: import the FBX animation in Roblox's Animation Editor, set priority movement, loop, publish, and paste the ID into an animator script; the footsteps are "not well synchronized" and the audio is unoptimized. *(13:24-14:52)* (Roblox-specific; he states the sync defect)
- HipHeight must be corrected (he arrives at 4.5) because the monster floats above the ground. *(14:52-15:56)*

## Visual check needed
- **3:48-4:48:** the Statistics overlay before and after decimation; the numbers were illegible in my views.
- **6:26-6:45:** the auto-rig marker placement and rig preview at full size; check whether limbs this long deformed cleanly.
- **8:09-8:30:** the "strange" imported mesh, at full size, to see what actually broke.
- **9:53-10:05:** the black result in close-up for surface detail.
- **14:33-15:56:** footstep sync and HipHeight fix.

## Hypotheses
- **H1: A human base mesh with auto-rig yields humanoid-proportion creatures cheaply, but not non-humanoid ones (quadrupeds, wings, many limbs).** *(confidence: medium, auto-rigger's marker set is human-shaped)* Test: try one non-humanoid sample through the same steps.
- **H2: The decimate step is a budget control, not a quality tool.** *(confidence: medium)* The speaker's own stated limit changed three times; test by comparing decimated and original silhouettes and our actual per-asset triangle budget when one is set.
- **H3: Recolouring an untextured mesh black hides form rather than finishing it.** *(confidence: medium, matches the baseline's note that glow or colour can conceal weak form)* Test: view the same mesh in neutral light, as the baseline requires.
- **H4: Skipping texturing/UVs is the main reason the result would fail a quality comparison.** *(confidence: medium)* Test: compare the shown model to baseline creature references once a finished-model task exists.

## Relevance to our game
- **Against the quality baseline:** the shown monster is a generic elongated humanoid with an untextured, recoloured surface. The baseline rejects "generic mass substituted for the defining form" and "colour alone provides all identity"; this output would be unfinished at best. The video is a pipeline demo, not a finish standard.
- **What is reusable as knowledge:** the order of stages (base mesh, sculpt, budget check, export, auto-rig, animation import, scale and hip height) is a useful checklist for technical acceptance of creature assets. These are checks, not a build method.
- **Rigging:** auto-rigging removes manual skinning effort but constrains the skeleton to a humanoid layout. Our ghosts and monsters may not be humanoid, so this must be checked per creature.
- **Texturing/UVs:** deliberately skipped, so the video gives no evidence about professional texturing.
- **Server authority:** the chase "kit" (patrol points, camera parts, HTTP request enablement) was not shown in detail. Any NPC chase logic in our game must be server-side and validated ([[ADR-0010-Client-Reported-Gaze]] illustrates what we allow clients to report). Enabling HTTP requests is not something we would do without human approval.
- **Licensing and purchasing:** the base mesh, the auto-rig site and the paid kit have unknown terms for our use. We do not buy or import paid kits without explicit human approval.
- **ADR-0011:** finished assets are required for the cosmetic categories ([[ADR-0011-Monetization-UI-Scope]]); the video does not show a path to that bar.

## Original implementation ideas
- Our own creature-asset review checklist: silhouette and form first, then triangle budget, then UV/texture state, then rig suitability (humanoid or not), then animation playback in a neutral test place, then scale and HipHeight. Written in our words and used only after a task defines it.
- A quick "rig suitability" note per creature design (humanoid, quadruped, winged, multi-limb) so we know up front whether an auto-rigger would be viable.
- Keep chase logic in our own server services, not in third-party templates.

## Recommendations (max 3)
1. Do not treat this video as a quality reference; use it only for the order of technical steps.
2. Before using any auto-rigger, record the creature's rig class (humanoid or not) in its design notes.
3. Do not adopt third-party NPC kits, enable HTTP requests, or purchase assets without explicit human approval.

## Needs human review
- Unverified conclusions:
  - Triangle counts before and after decimation (illegible), and whether the stated limits are sensible for our budgets.
  - How the auto-rig deformed on very long limbs (not checked at full size).
  - What exactly broke in the first Roblox import at 8:09-8:30.
  - What the kit's chase system does and why HTTP requests are needed (not shown).
  - Licences for the free base mesh, the rig/animation site and the paid kit.
  - Whether the pipeline is viable for our non-humanoid creatures.
