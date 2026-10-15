---
id: RESEARCH-Video-Index
title: Video Research Index
type: index
status: in_progress
created: 2026-10-14
updated: 2026-10-14
tags:
  - research/index
related:
  - "[[Video Research Prompt]]"
---
# Video Research Index

One row per video note. This is a lookup table, not a synthesis: each note stands alone, and nothing here is approved. Process and prompt variants: [[Video Research Prompt]]. Check this table (and `grep -rl "<video id>" "02 Research"`) before running a video.

## How the notes are used
- **Evidence first.** A fact needs a timestamp and a caption or a viewed frame. Opinions and speaker numbers are tagged as such.
- **Confidence:** `low` = captions only or few frames viewed; `medium` = captions and frames across the whole video; never `high` from one creator's video.
- **Promotion:** several notes agreeing on something concrete can become a `LES-` or `ADR-` candidate, but only with evidence and jg's approval. Nothing is promoted automatically.
- **Batching:** send several links at once; each gets its own note, and one PR carries the batch.

## Notes by topic
| Topic | Note | Confidence | Good for | Not good for |
|---|---|---|---|---|
| 3D: rigging / import | [[RSH-20261014-Mixamo-Custom-Rig-And-Camera-Video]] | medium | Order of import, root part, animation scale and HipHeight checks | Model quality, texturing |
| 3D: rigging / import | [[RSH-20261014-Mixamo-Skinned-Mesh-Character-Video]] | medium | Skinned-mesh character import checks | Form or finish quality |
| 3D: creature pipeline | [[RSH-20261014-Monster-NPC-Sculpt-And-Rig-Video]] | medium | Creature stage order (sculpt, budget, auto-rig, animation) as a review checklist | Texturing, non-humanoid rigs |
| UI | [[RSH-20261014-Good-UI-Principles-Video]] | medium | HUD, Journal and shop readability principles | Final layouts |
| Monetization / live-ops | [[RSH-20261014-Roblox-Game-95k-Monthly-Revenue-Video]] | medium | Live-ops cadence, regional pricing and ads as questions | Revenue figures, a collector-horror audience |
| Monetization / onboarding | [[RSH-20261014-Roblox-Viral-Game-Lessons-Video]] | low | Onboarding funnel and contextual tutorial ideas | Any figures (German auto-captions) |
| Workflow (AI-built games) | [[RSH-20261014-AI-Incremental-Game-Pipeline-Video]] | low | Staged skills and handoff ideas | Incremental-genre specifics |
| Capture loop / AI build | [[RSH-20261014-Creature-Capture-AI-Build-Video]] | low | Capture-timing and label-readability lessons | Anything visual (no frames viewed) |

Earlier non-video research: [[RSH-20261013-Haunted-Monetization-Discovery]], [[RSH-20261012-World-Retrofit-Audit]], [[RSH-20261010-Roblox-Platform-Economics]].

In flight on other branches (add here once merged): a Blender import-for-Roblox video note.

## Gaps (what we still don't know)
These are the subjects the next videos should cover. Remove a line when a note covers it at `medium` confidence.
- **Modeling form:** how professionals build organic creature silhouettes, anatomy and secondary forms (the main gap against the [[3D Model Quality Baseline]]).
- **Topology:** edge flow, deformation-friendly topology, and sensible triangle budgets for Roblox.
- **Texturing:** UV layout, PBR maps, and how finish is produced; the first 3D videos skipped this entirely.
- **Rig and skinning quality:** weight painting and deformation checks; non-humanoid rigs (quadrupeds, wings, many limbs).
- **Animation quality:** timing, foot sync and loops for creatures.
- **Environment art and maps:** composition and readability for horror spaces.
- **Audio:** only the audio pass notes exist; no video on mixing or ambience yet.
- **VFX:** no video notes yet.

## Rules for adding a note
1. One video, one `RSH-` note, created from the matching prompt variant.
2. Add a row here in the same PR as the note, and update the gaps.
3. Never edit `10 References/` from a video note.
