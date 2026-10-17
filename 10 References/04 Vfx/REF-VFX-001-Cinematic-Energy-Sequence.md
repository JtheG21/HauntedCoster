---
id: REF-VFX-001
title: Cinematic Energy Sequence — Quality Reference
type: reference
status: approved
area: vfx
source: User-supplied video; original post URL unknown
accessed: 2026-10-16
created: 2026-10-16
updated: 2026-10-17
related:
  - "[[VFX References]]"
  - "[[REF-CODE-001-Roqer]]"
tags:
  - reference/vfx
  - reference/animation
  - reference/cutscene
  - reference/needs-experimentation
---
# Cinematic Energy Sequence — Quality Reference

## Identity
- **Original filename:** `v15025gf0000db243rvog65i0oih547g.mp4`; attachment filename `1-v15025gf0000db243rvog65i0oih547g.mp4`.
- **Local source:** `10 References/04 Vfx/Media/REF-VFX-001-Cinematic-Energy-Sequence/1-v15025gf0000db243rvog65i0oih547g.mp4`. Original video archived with this note; see the source-video embed below.
- **Source / rights:** User-supplied clip with visible TikTok watermark `@ludc45`. Original author, post and asset rights unverified. Watermark does not establish authorship. Reference only.
- **Purpose:** Shared quality reference for animation, cutscenes and VFX across Roblox games.
- **Status distinction:** jg accepted this as inspiration and a minimum quality standard on 2026-10-16. Production techniques and ability to achieve it remain **needs experimentation**; no recreation has been implemented or tested.

## Observations and evidence limits
Local watch extraction: 25.2 seconds, 576×1024. Viewed eight sampled frames at 00:00, 00:04, 00:08, 00:10, 00:11, 00:13, 00:16 and 00:21. WhisperX detected no speech; this is not a judgment of sound design. Sparse sampling does not establish exact motion, transitions, synchronization or timing. No source project inspected.

| Approximate time | Visible sampled content |
|---|---|
| 00:04 | Character silhouette within bright golden energy, orbit-like lines, small luminous points and floating debris against dark blue/purple surroundings |
| 00:08 | Close character view with intense golden backlighting |
| 00:10 | Tall white light column, circular ground energy, debris and curved luminous accents |
| 00:11–00:13 | Bright screen-filling imagery with pale purple bands, curved light shapes and angular debris |
| 00:16 | Character surrounded by purple rings, dark circular forms with bright edges and lightning-like accents |
| 00:21 | TikTok end card |

## Dense review (2026-10-17)
**Method and limits.** Source: 25.16 s, 30 fps (754 video frames), AAC audio 44.1 kHz stereo. Three passes with `scripts/evidence.py` (PR #69), all from the archived video:
1. Whole clip at 3 fps (75 frames) as four contact sheets, plus scene-change points (`beats --threshold 0.25`).
2. Four transition windows at 10-15 fps (00:04.8-05.7, 00:08.5-09.5, 00:10.7-11.7, 00:13.4-14.3), each frame viewed.
3. Per-frame measurements at 30 fps over 00:00-00:21 (`series`) and a loudness envelope at 0.1 s (`audio`).

Timestamps from sheets are accurate to the sample step (0.33 s, or 0.07-0.1 s in the windows); measured runs are accurate to one frame (33 ms). Descriptions are of appearance, not verified effect construction. Still not known: motion between sampled frames in the 3 fps sections, what the sound actually is (only its level over time was measured), and whether any effect is in-engine or added in editing.

Sheets read left to right, top to bottom, five columns:
- ![[Dense-3fps-sheet-1-0000-0633.jpg]] 00:00.00 to 00:06.33, step 0.33 s
- ![[Dense-3fps-sheet-2-0667-1300.jpg]] 00:06.67 to 00:13.00, step 0.33 s
- ![[Dense-3fps-sheet-3-1333-1967.jpg]] 00:13.33 to 00:19.67, step 0.33 s
- ![[Dense-3fps-sheet-4-2000-2467.jpg]] 00:20.00 to 00:24.67, step 0.33 s (end card from about 00:21)
- ![[Window-10fps-0480-0570.jpg]] 00:04.8 to 00:05.7, step 0.1 s
- ![[Window-15fps-0850-0943.jpg]] 00:08.50 to 00:09.43, step 0.067 s (3 rows of 5)
- ![[Window-15fps-1070-1163.jpg]] 00:10.70 to 00:11.63, step 0.067 s
- ![[Window-15fps-1340-1427.jpg]] 00:13.40 to 00:14.27, step 0.067 s

### Timeline (observed)
Three colour phases joined by inversion bursts and a white-out, with changing camera.

| Time (approx.) | Observed |
|---|---|
| 00:00-00:01 | Fade up from near-black; the character (fedora, sunglasses) crouches at dusk. White feather-like shards sweep across, then radiate from the character on a white beam beneath them (00:00.67). |
| 00:01-00:02 | Shards turn yellow. A yellow halo ring, then a spiky yellow-white starburst orb, encloses the character. Sparkles, a white ring swoop and blue/red arc streaks at 00:01.67-00:02. |
| 00:02-00:05.2 | Continuous pull-back over about 1.5 s to a wide space-like view: small orb at centre, concentric orbit rings, drifting debris cubes, blue planets with trails, white ring pulses (about 00:03.33), a large moon and ring arcs entering at right (about 00:03.67). The wide shot drifts slowly until 00:05.1. |
| 00:05.2 | **Hard cut** (scene change 00:05.23, confirmed in the 10 fps window) from the wide shot to a close-up of the starburst orb. A white ring swoops across 00:05.3-05.7; shards burst larger to about 00:07. |
| 00:06.67-00:08.5 | A thin vertical white beam crosses the frame (00:06.67); the orb flattens to an ellipse (00:07.0) and returns spiky. Close-up on the face (00:07.67), then the top of the hat from above (00:08.0-00:08.63) inside a yellow glow with a slow zoom. |
| 00:08.67-00:09.17 | **Inversion burst, 500 ms of near-grayscale frames** (measured, 15 frames). It cuts in on one frame and alternates three states: white silhouette on black (about 0.13 s), a tiny black figure on white (about 0.13 s), then a larger white silhouette on black growing each frame (about 0.2 s). Falling streaks and debris cubes are visible in the black frames. |
| 00:09.17-00:09.7 | Cream white-out with wide rings that **eases out** over about 0.4-0.5 s into the full scene (the in-cut is one frame; the exit is gradual). |
| 00:09.7-00:11.3 | Low-angle reveal: a tall white pillar with a bulb-like top, yellow orbit rings and lines overhead, a glowing ground ring, tiled ground, debris. Lightning bolts accumulate frame by frame. Lilac and cyan horizontal bands appear and **jump to a new position almost every frame** (a scanline or glitch overlay, 00:10.77 onward). |
| 00:11.3-00:13.0 | The frame whitens within about 0.2 s, then holds white with lilac bands for about 0.6 s (measured run 00:11.33, 18 frames). Black triangular shards on a pale sky and tiled ground at 00:12.33-00:12.67; a white swirl with a black hole at 00:13.0. |
| 00:13.4-00:14.2 | **Second inversion burst.** Alternating states every one to three frames: dark orb with purple spikes on a pale sky (00:13.40-13.47); a white-background silhouette in a disc; grey with starbursts and black circles; black background with a white character and grey radial rays; white background with a black character and green rays. The camera swings from a side view of the dark orb to a top-down A-pose of the character. Measured near-grayscale runs: 00:13.53 (233 ms), 00:13.80 (200 ms), 00:14.07 (100 ms). Settles into a purple wash with rays at about 00:14.2. |
| 00:14.3-00:16.5 | Purple phase: the character inside a spiked purple ring around a dark orb; black circles drift through the frame; the character steps out onto a blue-grey tiled ground in a tilted purple ring; the black circles gather into a sphere around the character (00:16.33). |
| 00:16.7-00:20 | A concentric purple ring target appears behind the character, which shrinks to a small figure at the bottom as the camera pulls back; purple zigzag lightning, a pale light wedge at upper left, a planet with a gold ring at right. The composition holds from about 00:18.3 to 00:20 with the ring pulsing. |
| 00:20-00:21 | Dark lava-textured planet with a gold ring (00:20), then the character on a platform inside purple orbit rings with a moon above, dimming. |
| 00:21-00:25 | TikTok end card, not part of the sequence. |

### Measured
- **Phase lengths:** gold about 00:00.7-00:09.2 (about 8.5 s); white pillar and white-out about 00:09.2-00:13.4 (about 4 s); purple about 00:14.2-00:20.7 (about 6.5 s); coda to 00:21.
- **Near-grayscale runs** (frames with saturation of about 6% or less, which includes white-outs): 00:00.00 (67 ms, fade-in), 00:08.67 (500 ms), 00:11.33 (600 ms), then 00:12.00 to 00:12.5 (several short runs), 00:13.53, 00:13.80 and 00:14.07 as above.
- **Luminance transitions of 10% or more of full scale:** 17 in 00:00-00:21; the worst one-second window starts at 00:13.53 with 8. This is a heuristic on whole-frame means at 32x32, not the area-based WCAG flash test and not a conformance result, but it flags the second inversion burst for attention before anything like it is built.
- **Audio level (RMS per 0.1 s):** a track exists and runs about -16 to -15 dBFS for the first two seconds, about -24 to -19 from 00:02 to 00:08, then **steps up about 10 dB at 00:08.7-00:08.8** (the first inversion cut at 00:08.67) to about -12 to -9, eases to about -15 from about 00:10.0, **steps up again to about -10 near 00:11.4** (the white-out at 00:11.33), stays about -13 to -10 through about 00:14.5, then **drops to about -27 by 00:15.0** (just after the second burst and purple wash), **rises sharply at 00:16.3** (the black circles gathering into a sphere, 00:16.33), then decays to about -26 by 00:20. A loud peak (-5 dBFS) at 00:21.1 and silence from 00:22.3 belong to the end card. Only three onsets pass a 6 dB-in-0.1 s test (00:00.2, 00:16.3, 00:21.1), so the level changes at 00:08.7 and 00:11.4 are steps within a continuous sound, not isolated hits. The three level changes coincide with visual changes to within one 0.1 s window; the data do not show whether that is deliberate sync.

### What this adds to the earlier eight-frame review
- Structure and timing now have evidence: three phases, two inversion bursts, one white-out, with durations in the tables above.
- Correction to the first dense pass: 00:05.2 is a hard cut, not a push-in, and the 00:08.67 silhouettes are a 500 ms alternating burst, not two held frames.
- The camera is rarely still: dusk medium, gradual pull-back, hard cut to close-up, face and hat close-ups, an inversion burst with zooming, a low-angle hero shot, a side-to-top-down swing, and a long pull-back to a small character. Earlier frames suggested mostly fixed framing.
- Layers visible together at the peaks: beam or pillar, orbit rings, debris, lightning, ground rings, jittering glitch bands and shards. No single effect carries the sequence.
- Scale: in the last third the character is small against large rings and planets; readability relies on position and a surrounding ring.
- The earlier eight-frame table rows remain consistent with this review.

### Link to the impact-frames tutorial (inference)
[[RSH-20261014-Impact-Frames-Video]] (read 2026-10-17) describes an instant switch to black-and-white (high contrast, saturation lowered) with thin radiating slash lines, instant on and eased off. The inversion bursts here are consistent with that pattern: each cuts in on a single frame, the cream white-out at 00:09.2 eases out over several frames, and the black frames carry radial grey rays. That note's own caveats apply: its claims are unaudited, photosensitivity is not addressed there, and nothing here proves this clip used that technique. In-engine versus edited remains open; the rest of the sequence (the character is a blocky avatar on tiled ground) looks like Roblox rendering, which is an appearance-based inference only.

### For a brief built from this note
Phases, durations and the two burst types are now concrete enough to interview against. Before copying the second burst's rate of flashing, include a reduce-effects option or lower the rate; the heuristic above exceeds the 6-transition-per-second marker.

## Intent — interview with jg, 2026-10-16
- jg likes the whole sequence, not only one effect.
- Learn from layering, timing, camera presentation, transformation effects and ability VFX.
- Use it as both inspiration and a minimum quality standard for animations, cutscenes, VFX and related presentation.
- He likes the brightness and spectacle shown; no exclusions selected. Further work is needed to discover context-specific preferences and limits.
- Preserve it as a visual preference while also marking implementation needs experimentation. These are compatible: the desired quality is accepted; the method is unproven.
- **User expectation:** With a sufficiently thorough interview, this level of coherent presentation should be very easily achievable from one implementation prompt. This is a target expectation, not demonstrated capability, measured ease or a delivery guarantee.

## Interpretation and application
- **Inference:** The reference combines character presentation, camera framing and multiple effect layers into a staged sequence. Denser viewing is needed before specifying exact choreography or claiming motion fidelity.
- **Recommendation:** Before implementation, interview for the subject/action, intended emotional beats, phase order and duration, camera behavior, palette, scale, player control, gameplay context and performance target. Resolve material ambiguity in the brief rather than making unsupported choices during construction.
- For a relevant task, derive explicit criteria from selected visual and motion qualities, inspect transition frames and compare the rendered sequence in motion. Functional playback alone is insufficient to meet this quality preference.
- Adapt the qualities into original game-appropriate work; no permission to copy characters, distinctive identities, copyrighted assets or another game's recognisable sequence. A quality reference does not require every ordinary effect to use this sequence's size or brightness.

## Experiment and evidence to add
Record the interview/brief and prompt, selected beats with finer source timestamps, actual implementation steps and revisions, output video, visual comparison, jg's judgment, runtime/device performance and cleanup checks. Assess the one-prompt expectation honestly from observed results. Do not describe sampled-frame inspection as a full motion review.

## Open questions
- Which details must carry into a particular game, and what can be adapted?
- What exact timing, camera path and sound treatment should a task use?
- Original video is now archived alongside this note for later review.

## Traceability
- No implementation tasks or recreated assets yet.
- 2026-10-17: dense review added (3 fps whole clip, 10-15 fps transition windows, per-frame and audio measurements; eight evidence sheets archived); Intent unchanged.
- Approved quality preference; implementation experiment remains pending; original video is now archived.

## Review decision (2026-10-17)
- **Outcome:** propose a scoped experiment
- **Decided by:** jg
- **Summary:** Review 2026-10-17 of an approved quality floor. The archived clip and the dense-review sheets were reopened and match the note's Dense review: three colour phases (gold, white pillar and white-out, purple) joined by two inversion bursts, constantly changing camera, and audio level steps coinciding with visual changes. The second inversion burst has 8 large luminance transitions in one second, above the 6-per-second marker of the flash-risk heuristic (a heuristic, not a conformance test), so any recreation keeps under that rate and offers a reduce-effects option. What now exists to attempt it: the reference-brief interview, the evidence tools, the Roqer methods restated in our own words, and the Resource Boy lightning and fog packs as candidate textures. Existing research (RSH-20261014-Claude-MCP-Skill-Cutscene-Video and RSH-20261014-Animation-Event-Ability-System-Video, both hobbyist and unaudited) describes a charging cutscene with post-processing, camera shake, screen flashes, an impact-frame ScreenGui and marker-driven effects, but nothing equivalent to a reusable sequence runner. jg selected an experiment, all four beats to carry, and building the shared sequence runner first, over my recommendation to build the first sequence directly and decide later; recorded as jg's choice. The one-prompt expectation stays a target, to be assessed from the ledger.
- **Evidence inspected:** Review packet; the archived clip's contact sheets (dense 3 fps sheet 2 and the 13.4 to 14.3 s window) reopened; the existing Dense review section and its measurements; the two existing cutscene and ability-system research notes read; the Roqer, Resource Boy and evidence-tool decisions already recorded
- **Still unverified:** Whether this look can be built in Roblox from one prompt, and at what effort or performance cost; whether a runner is justified by more than one consumer; the clip's real authorship and construction (in-engine or edited); photosensitivity beyond the heuristic; whether Resource Boy textures may be uploaded to Roblox
- **Next action:** jg chose to build a shared sequence runner first. Step 1: propose it as a Deep-tier task (a TASK plus an ADR under Task Intake and ADR-0009, jg approves the plan): data-driven timeline of camera keys, effect cues, post-processing and screen-flash cues and cleanup, with ordering and cleanup rules as pure modules tested headlessly in Lune and visuals checked in Studio; cosmetic and client-side, the server decides outcomes. Step 2: the first ability sequence of 10 to 15 s as the runner's first consumer, for a game and ability jg names, after a reference-brief interview and one implementation prompt, carrying the four selected beats (three colour phases, reduced inversion bursts under 6 large luminance changes per second with a reduce-effects option, pillar and lightning stack, camera variety). Judge with paired frame strips at the reference beats, the flash-risk check and the one-prompt ledger. Waits on the game and ability, a free Studio session and the open question on uploading Resource Boy textures to Roblox. No copying the clip's characters, layout or assets.

## Archived source video
![[1-v15025gf0000db243rvog65i0oih547g.mp4]]
