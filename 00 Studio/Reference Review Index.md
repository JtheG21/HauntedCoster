---
id: STUDIO-Reference-Review-Index
title: Reference Review Index
type: index
status: ready
created: 2026-10-16
updated: 2026-10-17
related:
  - "[[Resource Catalog]]"
  - "[[Studio Index]]"
tags:
  - studio/catalog
  - reference/review
---
# Reference Review Index

Start here for jg's 2026-10-16 reference collection: **19 interviewed notes, 8 archived videos and 25 saved images**. Notes stay in their subject folders; this index groups the review without merging their evidence. Dark Fantasy world and boss presentation deliberately remain separate companion notes.

## Review queue
All items await the later, deeper note-by-note review with jg. Capture/interview is complete; an unchecked item does not mean its source or tool has been tested. Check an item only after that review, and record the decision in its own note.

| Reviewed with jg | Reference | Main question / limit |
|---|---|---|
| [x] | [[REF-UI-001-Throwie]] — Throwie | Tool capabilities, text-art experiments; exports unverified |
| [x] | [[REF-UI-002-Resource-Boy]] — Resource Boy | Evaluate packs individually; formats/rights unverified |
| [x] | [[REF-MISC-001-Anatomy]] — Anatomy | Structural planning; not a proven Roblox mesh pipeline |
| [x] | [[REF-CODE-001-Roqer]] — Roqer | Animation/VFX first inspected; full implementation unreviewed |
| [x] | [[REF-CODE-002-RoPilot]] — RoPilot | Automation claims; product untested |
| [x] | [[REF-CODE-003-Shaders]] — Shaders | WebGPU looks/techniques; Roblox portability untested |
| [x] | [[REF-CODE-004-Apify]] — Apify and alternatives | Bounded research collection; comparison article inaccessible |
| [x] | [[REF-CODE-005-Expo-Skills]] — Expo Skills and PRs | Transferable methods; individual skills/PR diffs unreviewed |
| [x] | [[REF-MISC-002-Reference-Library-Approach]] — Reference library approach | Accepted organizational direction; no new RAG service |
| [x] | [[REF-VFX-001-Cinematic-Energy-Sequence]] — Cinematic energy sequence | Quality preference; motion fidelity needs denser review |
| [x] | [[REF-MAP-001-Dark-Fantasy-World]] — Dark Fantasy world | World look/feel quality floor; gameplay not requested |
| [ ] | [[REF-CODE-006-Orchestrated-Agent-Workflows]] — Orchestrated agent workflows | Investigate tools/parallelism; delegation rules unchanged |
| [ ] | [[REF-MAP-002-Stylized-Swamp-Encounter]] — Stylized swamp encounter | Whole-scene visual/gameplay/animation quality |
| [ ] | [[REF-MISC-003-Character-Sheet-Workflow]] — Character sheet to playable model | Consolidated sheet; mouse is process example, not baseline |
| [ ] | [[REF-MISC-004-Illustrated-Surreal-World]] — Illustrated surreal world | Style quality floor; explore 2D and 3D |
| [ ] | [[REF-MISC-005-Dark-Fantasy-Boss-Presentation]] — Dark Fantasy bosses and effects | Separate companion note; textures chosen case by case |
| [x] | [[REF-CODE-007-Expert-Informed-Briefs]] — Expert-informed briefs | Original sources/expert methods/independent evidence |
| [ ] | [[REF-MISC-006-ActorCore-Free-Motions]] — ActorCore | Free only; retargeting and terms unverified |
| [ ] | [[REF-CODE-008-Awesome-Learn-Gamedev]] — Awesome Learn Gamedev | Free only; discovery directory, evaluate each resource |

## How to review one item
1. Open its actual source: archived video/images or the live source link. Read its evidence limits and jg's interview answers.
2. Identify a concrete useful application and what is already solved by existing resources. Separate verified observations, preferences and proposed methods.
3. With jg, choose: keep as reference, investigate a specific gap, propose a scoped experiment, or mark unsuitable for a stated use. Do not erase historical findings.
4. Record the outcome and any task link in that note; update this queue and the resource catalog if its evidence/state changes.

## Boundaries and known gaps
- Capture does not install tools, change approved workflows or initiate experiments. Current task, delegation, revision and human-approval rules remain in force.
- Accepted visual standards describe jg's desired quality. They do not demonstrate one-prompt feasibility or production effort; those expectations require evidence from actual work.
- ActorCore and this gamedev resource directory are **free only**. Other resources retain their recorded preferences; no blanket cost policy is invented here.
- Most tools have only listing, README or selected-source inspection. Exact inspected material and unverified capabilities are listed in each note. The ScraperAPI comparison article could not be read.
- Eight original videos are archived under their note area's `Media/<reference ID>/` folder, with source-video embeds in each note. Twenty-five images are saved in subject asset folders, including the supplied library screenshot, six boss photos and extracted frames. Temporary analysis frames/transcripts are not required to locate the archived originals.
- Source media is reference evidence. Authorship, asset rights and technical claims are not established merely by retaining it. Extracted samples do not establish exact motion.

## Session handoff
**Objective:** Review this collection one item at a time with jg; no implementation yet.
**Inputs:** This index, the linked notes, their archived media and [[Resource Catalog]].
**Workspace:** `/private/tmp/rg1-reference-library`, branch `chore/reference-library`; destination vault `/Users/jg/Desktop/Rg1` on main after human-approved merge.
**Constraints:** Preserve individual notes/preferences, existing policy and unrelated edits; inspect original evidence before drawing new conclusions.
**Acceptance:** Each reviewed item has a recorded decision, evidence limits and a concrete next action only if selected by jg.
**Report:** State which item was reviewed, findings, decision and what remains unverified. Capture complete; deeper review and all experiments remain pending.

## Capture verification (2026-10-16)
- Inventory: all 19 references from this conversation have individual notes; all 33 media embeds resolve (25 images, 8 videos).
- Vault validator: 0 errors, 0 warnings. Diff whitespace check passed.
- `scripts/check.sh`: formatting, lint, type checks, 140 Luau specs, both Rojo builds, JSON, queue and vault checks passed. The sandbox blocked a Python localhost-server test; rerunning the full Python suite with localhost permission passed all 69 tests. No game code changed and no Studio test was needed for note organization.
- Published to the main vault by PR #67 (approved by jg). Reference tooling: `python3 scripts/refs.py lint|list|brief|trace` ([[RSH-20261017-Reference-Automation-Spec]]).
