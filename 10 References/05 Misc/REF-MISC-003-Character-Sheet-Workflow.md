---
id: REF-MISC-003
title: Character Sheet to Playable Model — Process Reference
type: reference
status: proposed
area: misc
source: User-supplied video; original post URL unknown
accessed: 2026-10-16
created: 2026-10-16
updated: 2026-10-17
related:
  - "[[Misc References]]"
  - "[[3D Model Quality Baseline]]"
  - "[[REF-MISC-001-Anatomy]]"
tags:
  - reference/misc
  - reference/modeling
  - reference/animation
  - reference/needs-experimentation
---
# Character Sheet to Playable Model — Process Reference

## Identity
- **Original filename:** `v12044gd0000db8n18fog65nsq10p4mg.mp4`; attachment filename `1-v12044gd0000db8n18fog65nsq10p4mg.mp4`.
- **Local source:** `10 References/05 Misc/Media/REF-MISC-003-Character-Sheet-Workflow/1-v12044gd0000db8n18fog65nsq10p4mg.mp4`. Original video archived with this note; see the source-video embed below.
- **Source / rights:** Watermark @guineainteractive; original author, post and asset rights unverified. Reference material only.
- **Purpose:** Capture a modeling process to consider later, not a model request or workflow implementation.
- **Evaluation:** Direction supported by jg; needs experimentation. Keep as a proposed reference pending the later note-by-note review. No policy or production process changed.

## Inspection and evidence limits
Local watch analysis: 55.7 seconds, 576×1024. Eight sampled frames viewed at 00:00, 00:05, 00:20, 00:29, 00:31, 00:39, 00:47 and 00:52; full-track automatic WhisperX small transcript read. No underlying prompts, scripts, generated mesh, rig or Roblox import inspected.

The narration describes gathering references, refining a consolidated character sheet, passing the sheet and prompt to Claude connected to Blender, comparing output to the sheet, then rigging, animating and importing into Roblox. At about 00:39, a comparison slide highlights body shape, stud rows and tail thickness on a stylized mouse model. Claims of perfect matching and game-ready output remain unverified; a polished render does not establish topology, rig quality, performance or import correctness.

## Intent — interview with jg, 2026-10-16
- All areas interest jg: overall workflow, model quality, character sheets, comparison reviews, rigging and import automation.
- The finished mouse is mainly a demonstration of the process. It is not a new minimum model-quality baseline or a request to copy its design.
- Strong preference for exploring one consolidated sheet with multiple angles, colors, details and props, refined with jg before modeling.
- Comparison review should cover reference fidelity, structural coherence, visual finish, animation and Roblox suitability.
- jg supports the direction and experimentation, but explicitly wants only a note for now. Review all new notes one by one later before choosing changes or experiments.

## Interpretation and possible application (not implemented)
- **Hypothesis:** An agreed multi-view sheet could reduce ambiguity, and specific visual differences could produce more actionable revisions than broad feedback.
- **Recommendation for later review:** Compare with the existing model-design workflow, quality baseline, Blender pipeline and approval/revision rules before adding another process. A sheet must be internally consistent; apparent agreement in one view is not enough.
- Separate design approval, visual fidelity, mesh/rig checks, animation quality and in-game suitability. Do not claim one validates all the others.
- Adapt the upstream review-agent loop to project constraints if later selected. No recurring agent review, additional subagents, unlimited revisions, publishing or upload is authorized by this reference.
- Existing minimum model-quality requirements remain authoritative. This note does not require every asset to share the demonstrated mouse's style.

## Future review and evidence
During the planned note-by-note review, decide whether to experiment. If selected, record the interview, consolidated sheet and approval, exact brief, output views, concrete differences, permitted revisions, mesh/rig/animation checks, actual Roblox validation and jg's judgment. Record time, effort and failures when measured. Do not start this experiment during reference capture.

## Open questions
- Which parts improve on the existing modeling process?
- What makes a consolidated sheet sufficiently precise and consistent?
- How should comparison evidence fit the current review and revision budget?

## Traceability
- Capture only: no model built, skills modified, agents spawned, assets published or workflow changes made.
- Next action: later review this note alongside the other newly captured references, one by one with jg.

## Review decision (2026-10-17)
- **Outcome:** propose a scoped experiment
- **Decided by:** jg
- **Summary:** Review 2026-10-17 of a process reference. The archived clip (55.7 s: a 42 s five-step demo and an end card) was reopened as 40 frames over two contact sheets and its on-screen text read; no transcription tool is installed, so the narration was not heard. Steps shown: (1) collect screenshots from other Roblox games and send them to ChatGPT; (2) ChatGPT turns them into one character sheet, tweaked to a v1, with the tip 'one sheet, everything on it' and labelled panels for every angle, props and a colour palette; (3) Claude builds the model from the sheet and a prompt.txt; (4) a review agent compares the render with the reference sheet over rounds counted 1/5 to 5/5, flagging differences such as body shape, stud rows and tail thickness; (5) Claude rigs and animates it, shown as a Roblox game screenshot. The demo is a stylized grey rat with stud rows and a thick pink tail, a process demonstration and not a quality baseline; nothing about its geometry, rig quality or performance is shown. Overlap with our setup: the 3D Model Quality Baseline step 5 already requires a side-by-side comparison with the approved concept at a matched camera and a list of concrete differences on every iteration, implemented by compare.py and review.sh on the unmerged chore/art-automation branch, and the Wisp pilot used an approved concept, an explicit discrepancy list, a revision budget and jg's final review. New elements: the consolidated multi-view sheet (the Wisp concept supplied two views and its handoff calls it not a complete orthographic specification), the review agent's up-to-5-round loop (our budget is 2), and rigging a custom character (our Mixamo pipeline covers humanoids; non-humanoid rigging is untested). jg selected an experiment limited to the sheet contract and asked for a separate proposal on more review rounds, which changes nothing now.
- **Evidence inspected:** Review packet; the archived clip as two contact sheets (0.4 fps) with scene-change beats and its on-screen text; the 3D Model Quality Baseline structure; the unmerged art-automation review.sh and compare.py headers; the Wisp approved-modeling handoff note
- **Still unverified:** The narration; the author's claims of matching and game-ready output; the sheet-generation and review-agent behaviour (no prompts, scripts or mesh shown); rig quality and Roblox import; whether a consolidated sheet or more rounds improves our results; non-humanoid rigging and animation
- **Next action:** On the next character model task, refine one consolidated sheet with jg before modeling (every angle, colours, props, a scale marker, construction callouts) as the model contract, then use the existing matched-camera comparison and written difference list within the current 2-revision budget, with mesh, rig, animation and in-game checks reported separately; record the extra effort. Separately, jg asked to propose a trial with more review rounds than the 2-revision budget; that is a policy-change proposal to be approved on its own, and nothing in the budget changes now. Not started: no model built, no skill or workflow changed, no extra agents, no upload or publishing.

## Archived source video
![[1-v12044gd0000db8n18fog65nsq10p4mg.mp4]]
