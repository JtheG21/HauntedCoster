---
id: RESEARCH-Video-Index
title: Video Research Index
type: index
status: in_progress
created: 2026-10-14
updated: 2026-10-15
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
| 3D: rigging / import | [[RSH-20261014-Dynamic-Head-Neck-Joint-Fix-Video]] | medium | Missing "Neck" constraint, accessory re-attachment, ragdoll joints | Anything beyond R15 heads |
| 3D: creature pipeline | [[RSH-20261014-Monster-NPC-Sculpt-And-Rig-Video]] | medium | Creature stage order (sculpt, budget, auto-rig, animation) as a review checklist | Texturing, non-humanoid rigs |
| 3D: part-based creature | [[RSH-20261014-Hand-Built-ASYM-Monster-Video]] | medium | Motor6D part rigs, held-pose attack timing, effect templates | Meeting the model-quality baseline |
| 3D + AI pipeline | [[RSH-20261014-Procedural-Spider-Animation-MCP-Video]] | medium | Image-to-3D, remesh budget, Blender rig via MCP, procedural leg stepping | Finish quality, licences |
| 3D + AI pipeline | [[RSH-20261014-Pet-RPG-Claude-MCP-Full-Tutorial-Video]] | medium | Rig-aware creature design, export settings, spec-driven MCP building | Finish quality, licences |
| 3D + AI pipeline | [[RSH-20261014-Pet-Shop-Summon-Prototype-Video]] | medium | Shape of a summon/shop prototype and its UI patterns | Balance or monetization data |
| 3D: rigging / import | [[RSH-20261014-CSM-Custom-Rig-Import-Video]] | medium | Importing an AI-generated character onto a custom Roblox rig | Model quality, licences |
| Blender to Roblox | [[RSH-20261014-Blender-To-Roblox-Animation-Import-Export-Video]] | medium | Animation import and export settings between Blender and Roblox | Animation craft |
| Blender to Roblox | [[RSH-20261014-Blender-R6-Animation-To-Roblox-Video]] | medium | Rig prep and animation import checks (R6) | Non-R6 rigs |
| Blender to Roblox | [[RSH-20261014-Blender-Remove-Animation-Actions-Video]] | medium | Removing stale actions, resetting a posed rig | Anything beyond file cleanup |
| Systems: movement | [[RSH-20261014-Advanced-Movement-System-Video]] | medium | Config-driven single-state traversal, collision-group trick, mobile parity | Server validation of movement |
| Systems: movement | [[RSH-20261014-Parkour-Vault-System-Video]] | medium | Tag-gated, measure-then-arc interaction | Server-trusted movement |
| Systems: movement | [[RSH-20261014-Wall-Climbing-System-Video]] | medium | Raycast surface detection and state handling | Our current scope |
| Systems: combat | [[RSH-20261014-Hitscan-Gun-System-Video]] | medium | Input validation shape: client sends intent, server validates | Distance and line-of-sight checks |
| Systems: combat | [[RSH-20261014-Grab-And-Throw-Skill-Video]] | medium | Client picks, server decides; reversible ragdoll toggle | Combat as a feature |
| Systems: combat | [[RSH-20261014-Animation-Event-Ability-System-Video]] | medium | Animation-marker timing for sound, VFX and hitbox | Server validation of the release signal |
| Systems: combat | [[RSH-20261014-Fighter-Juggle-And-Air-Combo-Video]] | medium | Data-defined move tables and server state machines | PvP netcode |
| Systems: tools | [[RSH-20261014-Back-Sword-Equip-System-Video]] | medium | Holster/equip pattern, asset preloading | Weapon scope |
| VFX | [[RSH-20261014-Anime-Flight-System-Video]] | medium | Effect templates cloned and toggled by the server, layered beams | VFX budgets |
| VFX | [[RSH-20261014-Glowing-Sword-Aura-No-Script-Video]] | medium | Layering, flipbooks, beam vs particle rule | Cost at scale |
| VFX / camera | [[RSH-20261014-Impact-Frames-Video]] | medium | A rare emphasis pop; instant-in, eased-out | Photosensitivity concerns |
| VFX / cutscene | [[RSH-20261014-Claude-MCP-Skill-Cutscene-Video]] | medium | A cutscene spec idea; what AI-assisted prototyping looks like | Code quality |
| UI | [[RSH-20261014-Good-UI-Principles-Video]] | medium | HUD, Journal and shop readability principles | Final layouts |
| UI | [[RSH-20261014-Emote-Wheel-Video]] | medium | Hold-to-open radial menu, config-driven list | Touch behaviour |
| UI | [[RSH-20261014-Animated-Shine-Button-Video]] | medium | A highlight sweep for new/unlocked shop items | Constant-motion use |
| Audio | [[RSH-20261014-Material-Footsteps-Video]] | medium | Swapping the built-in Running sound by material | Mixing or ambience |
| Environment | [[RSH-20261014-Custom-Skybox-GIMP-Video]] | medium | Six-face skybox from one panorama | Seam quality, licences |
| Systems: building | [[RSH-20261014-Procedural-Building-System-MCP-Video]] | medium | Module structure of a draw-to-build tool | Persistence and validation |
| Monetization / live-ops | [[RSH-20261014-Roblox-Game-95k-Monthly-Revenue-Video]] | medium | Live-ops cadence, regional pricing and ads as questions | Revenue figures, a collector-horror audience |
| Monetization / onboarding | [[RSH-20261014-Roblox-Viral-Game-Lessons-Video]] | low | Onboarding funnel and contextual tutorial ideas | Any figures (German auto-captions) |
| Workflow (AI-built games) | [[RSH-20261014-AI-Incremental-Game-Pipeline-Video]] | low | Staged skills and handoff ideas | Incremental-genre specifics |
| Capture loop / AI build | [[RSH-20261014-Creature-Capture-AI-Build-Video]] | low | Capture-timing and label-readability lessons | Anything visual (no frames viewed) |

Earlier non-video research: [[RSH-20261013-Haunted-Monetization-Discovery]], [[RSH-20261012-World-Retrofit-Audit]], [[RSH-20261010-Roblox-Platform-Economics]].

Workflow audits and proposals drawn from the video notes (not video notes themselves): [[RSH-20261014-Video-Production-Workflow-Audit]] (+ [[RSH-20261014-Video-Production-Workflow-Audit-Batch-02]], [[RSH-20261014-Video-Production-Workflow-Audit-Batch-03]]), [[RSH-20261014-Animation-Rigging-And-VFX-Workflow-Proposals]], [[RSH-20261014-Event-Timing-Restoration-And-Visual-Polish-Proposals]].

Wisp pilot: start at [[Wisp Pilot Start Here]], then [[RSH-20261014-Wisp-Revision-Readiness]], [[RSH-20261014-Wisp-Four-Note-Prebuild-Review]] and [[RSH-20261014-Wisp-Approved-Modeling-Handoff]].

Tool evaluation: [[RSH-20261013-Universal-Modder-Evaluation]] (its TASK-0042 trial is still on `chore/universal-modder-evaluation`).

## Gaps (what we still don't know)
These are the subjects the next videos should cover. Updated 2026-10-14 after the MrWonderHow batch (24 notes); remove a line when a note covers it at `medium` confidence.
- **Modeling form:** how professionals build organic creature silhouettes, anatomy and secondary forms. Still the main gap against the [[3D Model Quality Baseline]]; the part-based and generator workflows show process, not finish.
- **Topology:** edge flow and deformation-friendly topology. Triangle budgets are partly covered (generator remesh, the 20,000-per-mesh figure in the local docs) but not how to retopologise well.
- **Texturing:** UV layout, PBR maps and how finish is produced. Only texture stamping, neon duplicates and a texture-heal tool appear; no UV or PBR workflow yet.
- **Skinning quality:** weight painting and deformation checks; non-humanoid rigs with wings or many limbs (one video reports wing deformation problems but does not solve them well). Joint setup, auto-rigging and IK are covered at a basic level.
- **Animation quality:** timing, weight, foot sync and loop principles. Event markers, held poses and procedural stepping are covered; animation craft is not.
- **Environment art and maps:** composition, readability and lighting for horror spaces. Only a skybox workflow so far.
- **Audio:** footsteps by material is covered; mixing, ambience layering and loudness are not.
- **VFX performance:** effect techniques are well covered; budgets (counts, lifetimes, cost per player) and horror-appropriate VFX are not.
- **Security and validation depth:** gun and grab notes cover the intent/validate shape, but not line-of-sight, range inflation or rate limiting in depth.
- **Mobile and touch UI:** radial and button patterns were shown on PC only; touch behaviour is untested.
- **Licensing:** third-party assets, services and packs appear throughout; terms are unverified everywhere.

## Rules for adding a note
1. One video, one `RSH-` note, created from the matching prompt variant.
2. Add a row here in the same PR as the note, and update the gaps.
3. Never edit `10 References/` from a video note.
