---
id: RSH-20261014-Mixamo-Custom-Rig-And-Camera-Video
title: Custom Rig and Smooth Camera in Roblox (video)
type: research
project: GAME-002
status: research
sources:
  - https://youtu.be/V0AtCS4wmig
confidence: medium
created: 2026-10-14
updated: 2026-10-14
tags:
  - research/3d-models
  - research/rigging
---
# Custom Rig and Smooth Camera in Roblox (video)

> **Draft.** A hobbyist's walkthrough, not a professional-quality standard. Speaker claims are unaudited and nothing here is approved.

## Question
Using the 3D-model variant of the video prompt: what does this video show about the plumbing of getting a non-Roblox humanoid character into a Roblox game (source rig, single mesh, texture, humanoid root part, animations, scale) and what does it **not** show about what makes a model professional? How does that sit against the [[3D Model Quality Baseline]]? Modeling, topology, texturing/UVs and rigging are weighted equally. Not tied to any task.

## Sources
| Source | URL | Accessed |
|---|---|---|
| "How To Make ANY Roblox game look like Unreal Engine (Custom Rig + Smooth Camera) {Tutorial}", uploader DatBoiEle, 20:05 | https://youtu.be/V0AtCS4wmig | 2026-10-14 |

**Evidence limits.**
- Captions: English, auto-generated, original language. Readable; some mishearings (the speaker says "mixim"/"miimo" for the animation site, "fpx" for FBX, "Idol" for idle).
- Frames: 13 cue frames viewed on two contact sheets and one single frame, covering 0:06 to 19:34 (640 px per tile, so UI text is small), plus 60 sweep frames (about every 20 s) viewed on four 480 px contact sheets. Nothing was viewed at full 1024 px individually, so fine UI labels and numbers are partly illegible.
- No audio was heard by us. The video's own sound (footsteps, camera) is unverified.
- **References compared:** the text of `10 References/05 Misc/3D Model Quality Baseline.md` (rubric and process sections). The gallery images were not opened for this note, because it concerns pipeline steps, not a finished model request. Nothing in `10 References/` was edited.

## Observed mechanics (verified)
"Verified" means said in captions or seen in a viewed frame. Tags: (general) = applies to game 3D work anywhere, (Roblox-specific) = about Roblox Studio or its import. Timestamps *(m:ss)*.

**Framing**
- The speaker says he did not make the rig or camera himself: he compiled free scripts and assets from the toolbox and outside Roblox and tweaked them, and says he cannot code. *(0:20-1:08)* (speaker claim)
- The title promises an "Unreal Engine" look; the final frames show an untextured grey mannequin on a default baseplate with motion blur and black bars. *(19:34 and sweep frames)* (shown on screen; my observation, not the speaker's claim). He himself says a good build and lighting are still needed. *(19:46-19:57)*

**Source character and animations (general)**
- The character is a free humanoid from a third-party rigged-character and animation site; he downloads it as FBX with no texture applied, so it is plain white. *(1:15-1:49)* An account sign-in is required to download. *(1:35-1:44)* (speaker claim; shown: grey and teal T-pose mannequin)
- Animations (idle, an in-place run, jump) are downloaded separately from the same site "without skin". *(1:49-3:10)*

**Single mesh and texture (general)**
- Import into Roblox Studio shows the character as two separate meshes, flagged with warning icons in the import preview. *(3:11-3:33)* (shown at 3:27: two items named like "Alpha_Surface" and "Alpha_Joints")
- Fix: import the FBX into Blender, select both parts and join them (Ctrl+J), then re-export FBX over the original. *(3:36-4:52)* (shown)
- Joining breaks the texture; the correct fix is to "bake" textures into one set, but he skips it as "too complicated" and keeps the model white. *(4:13-4:45)* (speaker claim, explicitly skipped)

**Roblox setup (Roblox-specific)**
- After re-import he scales the mesh to a standard Roblox character as a size reference, then deletes the imported initial poses and animation controller. *(5:08-5:33)*
- He adds a Humanoid with an Animator, then a Part named exactly HumanoidRootPart: can-collide off, fully transparent, positioned at the torso by copying the mesh position, and attached with a WeldConstraint (Part0 = root part, Part1 = the character mesh). *(5:36-7:48)* (shown at 6:45: a box at the torso)
- The Animation Editor reports the imported character as already rigged; he says the source site supplied the rig. *(7:48-8:10)* (speaker claim; the Blender view at about 3:50 shows an armature)
- He imports each downloaded animation FBX in the Animation Editor, sets animation priority (idle for idle, movement for run), and saves. *(8:13-9:01)*
- The animations do not fit the character's scale, so he uses an "animation resizer" plugin: copy the character's Scale value, paste it, and apply to each animation; the fixed copies have numbers in their names. *(9:01-10:30)* The "broken" jump shown at 10:43 has the character floating above the ground. *(shown)*
- He publishes the fixed animations to Roblox and records their IDs. *(10:56-11:49)*
- He copies Roblox's default Animate script from a playtest character into the model, pastes his IDs, names the model StarterCharacter and puts it in StarterPlayer. *(11:49-13:43)*
- HipHeight on the Humanoid must be raised (he found 3) until the feet sit on the ground, and set again on the StarterCharacter because playtest changes do not persist. *(13:43-14:28)* There is no fall animation. *(14:40)*

**Camera and polish (Roblox-specific, mostly unrelated to model quality)**
- Camera offset, FOV about 45-50, a dot cursor, smooth camera, motion blur, footstep sounds and black bars all come from toolbox scripts, put into player or character scripts, with values tweaked after reading them. *(14:52-19:34)* He picks one script because it "doesn't have a rating" over one with a bad rating. *(16:40-16:51)* (opinion/practice)

## Visual check needed
- **3:27**: the import preview warnings next to the two meshes. The speaker does not say what they mean; check at full size.
- **4:20-4:45**: what the "broken texture" after joining actually looks like (the frame shows the model without textures either way).
- **9:30-10:56**: the animation resizer plugin's UI and the before/after of the jump, at full size.
- **13:58-14:28**: HipHeight before/after.
- **19:34**: final result at full resolution against any claim of an "Unreal" look.

## Hypotheses
- **H1: Retargeting animation to a different-scaled rig is a common failure and shows up as floating or sinking.** *(confidence: medium, shown at 10:43)* Test: before accepting any imported character, play its idle and run in Studio and check feet against the ground.
- **H2: A model is not "finished" until it is one mesh with a single working texture set.** *(confidence: low-medium, speaker's own skipped step suggests the failure mode)* Test: join and bake on a small sample in Blender, compare in Studio under default lighting.
- **H3: Toolbox scripts used as-is are a risk worth treating as untrusted code.** *(confidence: medium, general knowledge plus the "unrated is better than a bad rating" practice)* Test: read every script before use; none should touch the server or remotes.
- **H4: The video's character plumbing applies to humanoid rigs; our monsters may not be humanoids.** *(confidence: low)* Test: check the rig type of GAME-002's creatures before adopting any step.

## Relevance to our game
- **Against the quality baseline:** this video teaches import and rig mechanics, not form quality. It would not meet the baseline rubric by itself; its shown character is an untextured generic mannequin, which is the "generic mass, no finish" pattern the baseline rejects. Use it only for the technical-acceptance side (scale, pivots, rig/deformation, collision) described in [[3D Model Quality Baseline]].
- **Technical acceptance checklist hints** worth adding to our own review: one mesh, textures intact, HumanoidRootPart and welds correct, animation scale checked, HipHeight, priorities. These are checks, not a build method.
- **Licensing:** the third-party character and animations come from a site whose terms and licence we have not read. Do not use its assets without verifying terms. (unverified)
- **Server authority:** camera, cursor and sound scripts are client cosmetic and would not need server authority, but any toolbox script must not add remotes or trust the client ([[ADR-0010-Client-Reported-Gaze]] shows our rule for client-reported cosmetic data).
- **ADR-0011:** finished assets for all five cosmetic categories are required ([[ADR-0011-Monetization-UI-Scope]]); this video does not help with that bar beyond the technical checks above.

## Original implementation ideas
- A short "import acceptance" checklist for our own reviews (scale reference, one mesh, textures, root part, rig check, animation foot contact), written in our own words as part of an asset-review step, not copying the video's procedure.
- A rule that any imported animation set is played in a neutral test place and recorded with a single screenshot before use.
- Treat all third-party scripts as untrusted until read, and keep camera or polish effects in our own client module rather than toolbox scripts.

## Recommendations (max 3)
1. Do not use this video as a quality reference; use it for the technical import/rig checks only.
2. Add the one-mesh, intact-texture, correct-scale and feet-on-ground checks to our asset review when a task defines it.
3. Keep third-party assets and toolbox scripts out of the game until their licence and code are reviewed.

## Needs human review
- Unverified conclusions:
  - Whether the imported mesh warnings at 3:27 matter (cause not stated).
  - Whether the character's source site licence allows use in a published game.
  - Whether our creatures are humanoid rigs at all (H4).
  - Any claim that the result looks "like Unreal Engine": not supported by the frames I viewed, but judged from small contact sheets.
  - Frame review used contact sheets; fine UI text and numbers were not checked at full size.
