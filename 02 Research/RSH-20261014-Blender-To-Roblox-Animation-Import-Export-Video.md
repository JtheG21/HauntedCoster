---
id: RSH-20261014-Blender-To-Roblox-Animation-Import-Export-Video
title: Blender to Roblox Animation Import and Export (video)
type: research
project: GAME-002
status: research
sources:
  - https://youtu.be/NI7GXKLwk6U
confidence: medium
created: 2026-10-14
updated: 2026-10-14
tags:
  - research/3d-models
  - research/rigging
  - research/animation
---
# Blender to Roblox Animation Import and Export (video)

> **Draft.** One hobbyist-to-commission developer's workflow, with the speaker's own caveats ("I'm not a very good animator"). Settings are claims from a single practitioner, not verified by us in Studio. Nothing here is approved.

## Question
Using the 3D-model variant of the video prompt (rigging and import/export, equal weight with modeling and texturing): which Blender export settings, Roblox import steps and scale/rig pitfalls does this video show for getting a rigged, animated mesh working in Roblox, and which of them could become checks for GAME-002 asset review? Not tied to any task.

## Sources
| Source | URL | Accessed |
|---|---|---|
| "How to animate and import animations from Blender to Roblox Studio [Skinned Mesh rig]", uploader Mykaiju, 38:27 | https://youtu.be/NI7GXKLwk6U | 2026-10-14 |

**Evidence limits.**
- Captions: English, auto-generated; readable but with mishearings ("armor" for armature, "frame rate" fine, "dream marker" for a marker, "amplifier" for simplify, "stock editor of the dope sheet"). Where a Blender setting name matters I used the on-screen dialog text instead.
- Frames: 15 cue frames at 1024 px covering 1:40 to 36:30 (viewed on four contact sheets of up to four frames each) plus about 70 sweep frames (every ~35 s) that were extracted but not viewed. Text in the Blender and Studio dialogs was legible; small fields may still be misread.
- No audio was heard by us. Our own Studio or Blender runs were not done; every setting below is "shown or said in the video".
- Video is partly a follow-up to the speaker's earlier rig-import video, which we have not seen; its scale details are second-hand.
- **References compared:** the process and technical-acceptance sections of `10 References/05 Misc/3D Model Quality Baseline.md`. The gallery images were not opened for this note. Nothing under `10 References/` was edited.

## Observed mechanics (verified)
Tags: (general) = true of 3D animation pipelines broadly, (Roblox-specific) = about Roblox Studio import. All are *speaker claims or shown on screen*; timestamps *(m:ss)*.

**Rig and animation basics**
- The rig is a Blender armature with IK bones for the legs and a head/neck IK bone with a small influence value, so feet stay planted and the head can track a target. *(1:33-3:05)* (general; shown, bone list in frames)
- He says he is not a strong animator and animates simply: keyframes on a timeline, auto-keying on, a pose then a new keyframe. *(1:13-3:35, 8:06-9:16)* (opinion/self-description)
- Keep each animation based on a "base" pose action that every animation starts from. *(6:56-7:45)* (speaker claim; the action is named Base in a frame at 8:10)
- Copy the first frame to the last so a looping animation joins cleanly; "Make Cyclic" F-curve modifier helps but "doesn't always work". *(9:38-9:57, 19:12-20:22)* (general; shown)

**Frame rate and range**
- Animate at 24 fps (24-30). Higher rates (60+) make Roblox generate many in-between frames on import, which he says adds lag; about 120 frames for a short clip. *(3:50-6:56)* (Roblox-specific; speaker claim, not measured by us). He says another developer's team told everyone to use 24 to avoid lag and he believes it is the industry standard. *(6:11-6:56)* (opinion)
- Roblox does not support animated scale, so scale keyframes do not carry over. *(8:58-9:16)* (Roblox-specific; speaker claim)

**Baking and cleanup**
- If the import "looks really bad" or interpolates strangely, he bakes the action (Object > Animation > Bake Action): Bake Data = Pose, Only Selected Bones, frame start 0, end 100, step 1. *(20:36-22:11)* (shown; the dialog is visible). He admits "it's not very professional, but it works".
- Make sure Blender does not drop the action: enable the "fake user" so an unused action is kept. *(22:26-23:08)* (general; speaker claim)

**Export from Blender (FBX)**
- Select only the armature and export FBX with Object Types = Armature (no meshes). *(23:33-24:04)* (shown)
- Scale left at 1 for the standard case; he says Roblox now does the scaling and an older plugin step is no longer needed. *(24:04-24:30)* (Roblox-specific; speaker claim)
- Settings shown: Add Leaf Bones off; Animation on with Key All Bones on, NLA Strips off, All Actions off, Force Start/End Keying on, Sampling Rate 1.0, Simplify 0.0. *(24:51-27:19; shown at 25:25 and 26:15)* He turns NLA Strips and All Actions off because they export multiple layers or all actions and pick the wrong animation on import; Simplify is set to 0 because simplification makes foot IK slide, though it may reduce lag at 60 fps. *(25:05-27:19)* (speaker claim)

**Import into Roblox Studio**
- Animation Editor, three-dots menu > Import > From FBX Animation. *(29:14-29:44)* (Roblox-specific; shown)
- A prompt asks whether to import based on the FBX model or the selected model; he chooses Selected and says choosing FBX "ruins the model". *(30:07-30:34)* (shown; reason unverified)
- If the foot keeps moving or the imported motion differs from Blender, he attributes it to the Simplify setting, not to Roblox. *(30:54-31:48)* (speaker claim)
- The Roblox-side animation priority and publishing are not covered in this video.

**Scale and pivots**
- A very large source model was scaled down in Roblox; he copies the Scale value from the Studio model back into Blender's export scale so animations fit. He imports the first clip at scale 1 for the big original and with the corrected number for the resized one. *(27:50-33:30)* (speaker claim; a Scale value of about 0.034 is visible in Studio properties at 28:05)
- After the corrected re-import the character floats above the ground because the root bone grew; he says the root bone cannot be shrunk in Studio, and the fix is to place the rig origin at the hip, or anywhere outside the character's bounding box. *(35:06-35:48)* (speaker claim; floating partly visible at 35:10)
- For a playable humanoid, adjust HipHeight to fit; for an AI character he moves it via an accessory-style attachment where foot position does not matter. *(35:48-36:41)* (Roblox-specific; speaker claim)

**What the visuals show about model quality**
- The example model is a red mech built from many separate cube meshes (dozens of items in the Explorer) with a flat red color and no texture; it appears the Blender model has no textures at all. *(shown 28:05-31:50)* This is a rig and animation demo, not a model-quality demo.

## Visual check needed
- **25:20-27:19**: the full Blender FBX export panel at full size (the Simplify value shows 1.00 at default in one frame and 0.00 in another; that matches him changing it, but confirm).
- **30:07-30:34**: the import prompt text; confirm which option is actually recommended by Studio and what "FBX" vs "Selected" changes.
- **35:06**: before/after of the floating root bone.
- **8:10 and 19:30**: Blender action and cyclic modifier panels, if we ever replicate them.
- **Whole video**: I did not view the sweep frames, so any slide or comparison I did not cue is unreviewed.

## Hypotheses
- **H1: Most "bad import" cases come from a few export-setting mistakes (extra layers, simplify, scale, wrong target model).** *(confidence: medium)* Test: build a tiny rig with a 2-second animation and export with the video's settings vs defaults; compare in Studio.
- **H2: Authoring at 24 fps avoids unnecessary keyframes and lag compared to 60 fps.** *(confidence: low-medium; claim, not measured)* Test: import the same clip at both rates and compare keyframe counts and Studio performance.
- **H3: The animation scale/root-pivot problem is general for any scaled rig and is better solved by authoring at the right size once.** *(confidence: medium)* Test: record the target scale in the asset spec and verify foot contact for each imported animation.

## Relevance to our game
- **Technical acceptance:** this video supports the baseline's "rig/deformation, scale, pivots" check ([[3D Model Quality Baseline]]); it adds concrete things to verify (armature-only export, no leaf bones, one action, simplify 0 for IK foot plant, scale set once, root/hip origin).
- **Not about form quality:** nothing in it helps judge silhouette, anatomy or material finish; the example is a flat-red mech.
- **Related note:** [[RSH-20261014-Mixamo-Custom-Rig-And-Camera-Video]] covers the Studio-side humanoid plumbing; this one covers the Blender-side export.
- **ADR-0011** requires finished assets in all cosmetic categories ([[ADR-0011-Monetization-UI-Scope]]); animated assets will need the technical checks above.
- **Server authority:** animation import is client/asset work and does not change authority rules.

## Original implementation ideas
- A short "rig and animation import checklist" in our own words for asset review tasks: armature-only export, no extra layers, one action per file, scale recorded in the spec, feet planted in a neutral test place, root/hip origin documented.
- A neutral "animation test place" with a ground plane and scale reference where every imported animation is played once and screenshotted before approval.
- Keep exported animation files named with the frame rate and scale used so a bad import can be diagnosed.

## Recommendations (max 3)
1. Treat this video as a source of rig and animation **technical checks**, not as a quality reference; combine with the baseline for finish.
2. Add scale, root/hip origin and foot-contact checks to any future animated-asset task acceptance criteria.
3. Verify the video's export settings and the 24 fps claim ourselves in a tiny test before relying on them.

## Needs human review
- Unverified conclusions:
  - Every export setting and the "choose Selected, not FBX" advice are one developer's practice; none was reproduced by us.
  - The 24 fps and lag claims are not measured.
  - Whether Roblox's current importer still behaves as described (the video is not dated in this note).
  - Whether "FBX" vs "Selected" truly ruins the model, and why.
  - The sweep frames were extracted but not viewed.
