---
id: REF-CODE-007
title: Expert-Informed Briefs and Independent Verification
type: reference
status: proposed
area: code
source: User-supplied commentary video; original article not fully inspected
accessed: 2026-10-16
created: 2026-10-16
updated: 2026-10-17
related:
  - "[[Reference_Code_Index]]"
  - "[[REF-MISC-002-Reference-Library-Approach]]"
  - "[[REF-CODE-006-Orchestrated-Agent-Workflows]]"
tags:
  - reference/code
  - reference/workflow
  - reference/needs-experimentation
---
# Expert-Informed Briefs and Independent Verification

## Identity
- **Original filename:** `v12300gd0001db9cohnog65pc3ngsi4g.mp4`; attachment filename `1-v12300gd0001db9cohnog65pc3ngsi4g.mp4`.
- **Local source:** `10 References/06 Code/Reference_Code/Media/REF-CODE-007-Expert-Informed-Briefs/1-v12300gd0001db9cohnog65pc3ngsi4g.mp4`. Original video archived with this note; see the source-video embed below.
- **Source / rights:** Video watermark @chase_ai_; original post and rights unverified. Visible material attributes an article titled “How to be more ambitious: A tutorial for humans with models” to Felix Rieseberg. Full article and original post not independently retrieved or verified.
- **Purpose:** Capture principles for stronger interviews, briefs and evidence-based Roblox production across projects.
- **Evaluation:** Direction supported by jg; needs experimentation. Keep as a proposed reference for later note-by-note review, not a new mandatory workflow.

## Inspection and evidence limits
Local watch analysis: 76.9 seconds, 576×1024. Eight sampled frames viewed at 00:00, 00:08, 00:19, 00:26, 00:42, 00:51, 01:05 and 01:13; full-track automatic WhisperX small transcript read. This is commentary and visible article excerpts, not a full review of the underlying article or proof that the method improves results.

The visible excerpt describes ambition in four dimensions: working faster, considering the desired outcome at a broader level, investigating deeper methods/data, and drawing from other fields. The commentary suggests strengthening a brief by identifying expert practices absent from it, original source material, suitable methods/tools and evidence of correctness independent of the model/user's impressions. Visible text emphasizes outside validation. These are source recommendations, not tested effectiveness claims.

## Intent — interview with jg, 2026-10-16
- All aspects interest jg: overall approach, stronger briefs, expert methods, original sources and independent validation.
- This should inform interviews by identifying missing requirements, useful references, suitable tools and verification before producing an implementation prompt.
- Explore more ambitious approaches whenever a useful opportunity appears.
- Propose meaningful improvements, but obtain jg's agreement before expanding the objective or making consequential changes.
- Record as a supported direction needing experimentation; actual workflow changes deferred until the later note-by-note review.

## Interpretation and possible application
- **Hypothesis:** A better-informed brief can improve quality and reduce unsupported assumptions without necessarily increasing deliverable scope.
- **Recommendation for later review:** Consider what a relevant expert would inspect or ask, which original assets/data/docs are available, which methods fit this environment and what observable evidence would demonstrate success. Treat model-generated expert advice as a proposal to verify, not authority.
- Match validation to the deliverable: behavioral tests for behavior, actual reference/output comparisons for visuals and motion, and jg's judgment for preferences. Tests do not establish taste; an attractive render does not establish runtime correctness.
- Compare with existing Task Intake, reference-first development and review gates. Adapt only where this adds value rather than adding redundant checklists or expanding every task.
- Potential methods from other fields remain bounded by the game's requirements, resources and approved scope. Interest in ambition does not authorize installations, spending, publishing, extra agents or a different objective.

## Experiment and evidence to add
During the later review, decide whether to test on a real brief. Record the initial interview/brief, missing requirements found, inspected primary references, methods considered, proposed scope changes and jg's decisions, final prompt, output, actual validation and effort. Compare usefulness and quality with the existing process; retain inconclusive or negative findings.

## Open questions
- Which interview additions improve clarity without unnecessary overhead?
- What independent evidence best fits a specific visual, technical or gameplay objective?
- Does this improve results beyond the current reference-first process?

## Traceability
- Capture only: no workflow, skill or task scope changed.
- Next action: later review this note with the other new references, one by one with jg.

## Review decision (2026-10-17)
- **Outcome:** propose a scoped experiment
- **Decided by:** jg
- **Summary:** Experiment selected; status stays proposed. The source article was retrieved and matches the note: Speed, Altitude, Depth, Range, plus an 'outside judge' section whose four-part prompt asks what a top professional would do, the rawest material, the specific methods and tools, and what other than the model or user would show the result is right. Article caveats to carry into briefs: Altitude works less well for creative work; ask the model to perform what a professional does, not imitate how they write; specific hard goals beat do-your-best. The reference-brief skill already implements the four-part lens; a follow-up PR will add the two cautions.
- **Evidence inspected:** Review packet; the archived video (38 frames at 0.5 fps as two contact sheets, with the article text visible on screen; audio level only); the original article at felixrieseberg.com/how-to-be-more-ambitious-a-tutorial-for-humans-with-models/ read through the fetch tool (a summarizer, so secondary; the prompt and four types confirmed by video frames)
- **Still unverified:** Whether the method improves our briefs; the article's own claims and examples; the video commentary's accuracy; the full article text beyond the summarizer
- **Next action:** Run the reference-brief skill on the next Standard or Deep task; record additions proposed vs accepted and interview length in the task note; revisit with 'refs.py ledger' after about five tasks and keep the step only if jg accepts a meaningful share of what it adds.

## Archived source video
![[1-v12300gd0001db9cohnog65pc3ngsi4g.mp4]]
