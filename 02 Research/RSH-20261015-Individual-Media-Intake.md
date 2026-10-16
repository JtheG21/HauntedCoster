---
id: RSH-20261015-Individual-Media-Intake
title: Individual Media Intake — Nine Attachments
type: research
status: research
confidence: medium
created: 2026-10-15
updated: 2026-10-15
tags:
  - research/index
  - reference/intake
---
# Individual Media Intake — Nine Attachments

> Draft research records. **jg's instruction, 2026-10-15: everything submitted must be individually assessed.** This index routes to nine separate assessments; it supplies no combined approval or game-design change.

## Question
What does each of the four local videos and five images demonstrate, what can we use, and what remains unproven? General research intake for the studio and possible Haunted Collector references; no implementation task assigned.

## Sources
All nine are jg's chat attachments, accessed 2026-10-15. Original platform URLs, creators' verified identities and asset licences were not supplied. Numeric prefixes below are attachment transport names; each assessment also records the filename shown by the user. Exact received files are preserved, with byte counts and SHA-256 hashes in `02 Research/assets/media-20261015/manifest.json`.

| # | Individual file | Assessment | Individual verdict |
|---|---|---|---|
| 1 | `v12044gd0000db6mtjfog65l7rpta4ug.mp4` | [[RSH-20261015-Blender-Elemental-VFX-Showcase]] | Adapt localized layering and distinct effect silhouettes; Blender pipeline not demonstrated |
| 2 | `Photo 2.jpg` | [[REF-MISC-001-Raw-Wiki-Output-Vault]] | Adapt source/curation/output traceability; no vault reorganization justified |
| 3 | `v15025gf0000db243rvog65i0oih547g.mp4` | [[RSH-20261015-Transformation-Impact-VFX]] | Adapt buildup/peak/recovery; exclude literal repeated full-screen inversion from a production brief |
| 4 | `v12044gd0000db8250vog65rdnfli080.mp4` | [[RSH-20261015-Dark-Fantasy-RNG-Exploration]] | Adapt atmosphere and landmarks; advertised RNG loop is not our approved design |
| 5 | `v15044gf0000db6mtpfog65l4b12hv60.mp4` | [[RSH-20261015-Kraken-Reveal-AI-Claim]] | Adapt staged reveal and scale cues; AI authorship/productivity unproven |
| 6 | `Photo 6.jpg` | [[REF-MISC-002-Cosmic-Rocket-Moon-Lantern]] | Adapt coherent prop-family treatment and varied silhouettes |
| 7 | `Photo 7.jpg` | [[REF-MISC-003-Cosmic-Moon-Portal-Ruins]] | Adapt open/filled silhouette contrast and focal hierarchy |
| 8 | `Photo 8.jpg` | [[REF-MISC-004-Cosmic-Planet-Comet]] | Adapt directional curves and secondary forms; animation unknown |
| 9 | `Photo 9.jpg` | [[REF-MISC-005-Cosmic-UFO-Orbital-Core]] | Adapt nested framing; beam/core function and motion unknown |

## Observed mechanics (verified)
- Nine distinct received files were independently inspected and preserved. No duplicate filename/source-ID assessment was found in the existing research/reference folders before creation.
- Four local Watch runs completed with direct visual review. All 39 selected frames were viewed through four contact sheets, with three enlarged frame checks. Another 32 cue frames, eight per video at 0:00, 0:03, 0:06, 0:09, 0:12, 0:15, 0:18 and 0:21, were viewed through four further contact sheets.
- WhisperX small reported no speech for files 1 and 3; file 4 produced English narration; file 5 produced a short, visibly misrecognized model-name phrase. No raw transcript is stored in the vault. Image originals were viewed from the attachments.

### Evidence and method
Local `watch.py --engine local --detail balanced --max-frames 10 --fps 0.35 --resolution 768`, plus an explicit cue sweep with speech disabled after the transcription run. Actual sources are 576×1024; requesting wider frames does not recover missing detail. Scene selection clusters around changes, so the uniform cue pass supplements quiet stretches. Contact sheets below include source timestamps; `evidence.json` beside them records frame names, rounded times and selection reasons. Sampling is not continuous playback or frame-accurate motion analysis.

| File | Scene/uniform selected frames | Coverage cues |
|---|---|---|
| 1 | ![[01-scenes.jpg]] | ![[01-sweep.jpg]] |
| 3 | ![[03-scenes.jpg]] | ![[03-sweep.jpg]] |
| 4 | ![[04-scenes.jpg]] | ![[04-sweep.jpg]] |
| 5 | ![[05-scenes.jpg]] | ![[05-sweep.jpg]] |

Confidence increased from low at intake to medium for visible content after the frame passes; the cue sweep added the transformation aftermath. This does not increase confidence in authorship, performance, implementation or third-party marketing claims. Images are assessed for visible qualities only, with no acceptance judgment against unseen asset internals.

## Hypotheses
Each individual note holds its own hypotheses and proposed verification. Similar-looking photographs may belong to one collection, but this is not confirmed provenance and does not merge their assessments.

## Relevance to our game
Research and visual reference capture only. Existing [[Resource Catalog]], [[Video Research Index]], [[Misc References]], [[Task Intake]] and [[Obsidian Conventions]] provide the organization; the approved game design and model baseline stay authoritative. Existing map references on hold were left alone. No Studio, Rojo, gameplay, queue status or policy change was made.

## Original implementation ideas
See each individual assessment. These are proposals, not a combined feature brief or permission to reproduce the source assets.

## Recommendations (max 3)
1. Continue one assessment per submitted file, with filename, evidence, verdict and limitations.
2. Choose a specific reference quality before turning any item into an implementation task.
3. Obtain source/provenance and inspect the relevant full asset or workflow before making claims beyond what the media shows.

## Needs human review
- Which ideas, if any, should drive a later task. No new lesson, ADR or art direction is approved by this intake.
- All nine source licences and original URLs remain unknown. No current model/version or game-release facts were externally verified because the task assessed supplied evidence.
- Merge approval is still required by [[AGENTS]]; work is isolated on `chore/individual-media-assessments` at `/private/tmp/rg1-individual-media-assessments`.

## Handoff
**Objective / receiver:** jg reviews the nine linked assessments and selects any follow-up; no implementation owner assigned.
**Inputs:** individual notes, preserved originals and timestamped sheets above; this branch carries the complete batch.
**Constraints:** retain one record per file; preserve approved design and historic records; no copying source identities/assets.
**Acceptance:** nine independent assessments, original-file traceability, timestamps for video observations, and valid vault links.
**Report:** validation and Git delivery results are recorded below; all proposals remain research pending review.

## Session record
- Created four video research notes, five image reference notes, this intake index, original-file manifest and timestamped visual evidence.
- Updated the video index, misc reference index and Resource Catalog for discoverability.
- Pending: source attribution/licences, any selected production task, and human merge approval.

**Validation (2026-10-15):** `python3 scripts/validate_vault.py` reported **0 errors, 0 warnings**; `git diff --check` passed. Nine originals matched their SHA-256 manifest; four video notes retain all research-template headings; five separate image notes exist. All 39 saved scene-frame inputs matched the directly reviewed frame inputs; 32 additional cue frames were reviewed. Commit hooks also reported 0 errors, 0 warnings, 0 parse errors and 140 Lune specs passed, 0 failed. Documentation/media-only change; the full `scripts/check.sh` suite and Studio tests were not run.
