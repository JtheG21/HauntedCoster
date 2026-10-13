---
id: AGENT-WF-Reference-Analysis
title: Reference Analysis Workflow
type: agent
status: approved
created: 2026-10-12
updated: 2026-10-12
tags:
  - workflow/production
related:
  - "[[Task Intake]]"
  - "[[T - Reference]]"
---
# Reference analysis: images and video

Turns a screenshot, photo, sketch, map, diagram or clip into a written record that a later session can act on without the image or this conversation. The output is a reference note from [[T - Reference]]. When the reference drives work, its requirements become acceptance criteria in the TASK note, citing the reference ID.

`10 References/` changes only when a task says so ([[AGENTS]], "Reference-first development"). The existing `referenceN` map notes are on hold (jg, 2026-10-12). Leave them as they are until jg resumes them.

## Intake (every reference)
1. **Keep its identity.** Don't rename the original file; record the filename as given.
2. **Assign a stable ID:** `REF-<AREA>-NNN`, using the next free number in that area's index. Areas follow the folders: `UI`, `MAP`, `SFX`, `VFX`, `MISC`, `CODE`. Name the note `REF-MAP-001-Short-Title.md` and put it next to the asset.
3. **Record where it lives:** the repo path, a URL with its access date, or "chat attachment only, not on disk". Claude cannot save a pasted image. If it should outlive the conversation, ask jg to drop the file into the area folder.
4. **State its purpose:** what question it answers for which task.
5. **Separate what is seen from what is guessed** (sections below).
6. **Record limits:** occlusion, crop, perspective, compression, lighting, and missing scale.
7. **Note the reusable ideas** and the relationships between elements.
8. **Link it** to its tasks, decisions and requirements, and add a row to the area index (for example [[Map References]]).

## What to look at (only what the purpose needs)
- **Form:** composition, silhouette, focal points.
- **Space:** layout, routes, landmarks, entrances and exits, boundaries, sightlines.
- **Surface:** materials, textures, palette, lighting, time of day, atmosphere.
- **Content:** architecture, props, vegetation, terrain.
- **Play:** likely interactions, environmental storytelling, readability, how the player is guided.
- **Build:** a likely implementation (terrain, parts, meshes, effects), its cost, and what could be reused.
- **Scale:** give dimensions only when a known-size object is visible, and say which object. Otherwise write "scale unknown". Never invent hidden geometry, asset identities or gameplay functions.

## Video
- **Tool:** the `watch` skill (ffmpeg 9.0.2 and yt-dlp installed via Homebrew, 2026-10-12). Fallback: key frames jg exports as screenshots, with timestamps.
- **Sequential analysis** when motion, timing or continuity matters (an effect, an animation, a route walked): write a timestamped beat list.
- **Selected frames** for static detail. A few representative frames beat exhaustive extraction. Record each frame's timestamp.
- Capture what changes over time: movement paths, timing in seconds, camera moves, state changes.

## Intent: decide per element
For each element, decide one of:
- **Keep closely:** the quality matters exactly.
- **Adapt:** the idea fits, but change it for this game's style or limits.
- **Inspiration only.**
- **Exclude.**

Never reproduce logos, characters, trademarked designs or another game's recognisable layout. Translate references into original work that fits the target game's approved art direction.

## Output and handoff
- **Reference note** ([[T - Reference]]): observations, inferences and decisions kept apart. It must stand alone if the image disappears.
- **Requirements** go into the TASK note as acceptance criteria that cite `REF-…` IDs. The reference note lists those tasks back.
- **Sending to a tool that can't read local files** (Claude Design, a chat): attach the image and include the reference note's text in the handoff ([[T - Handoff]]).

## Acceptance
- Someone who has never seen the image can explain what to build from the note.
- Every dimension or material claim is labelled observed, inferred or assumed.
- Open questions are listed, not guessed.
