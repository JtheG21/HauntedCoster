---
id: TASK-0028
title: Cemetery Vignette and Atmosphere
type: task
project: GAME-002
status: done
priority: medium
risk: low
owner: executor
milestone: M3
depends_on:
  - TASK-0027
branch: task/TASK-0028-Cemetery-Vignette-And-Atmosphere
created: 2026-10-12
updated: 2026-10-12
tags:
  - workflow/task
  - milestone/m3
related:
  - "[[ADR-0007-World-Retrofit-Direction]]"
  - "[[RSH-20261012-World-Retrofit-Audit]]"
---
# TASK-0028: Cemetery Vignette and Atmosphere

## Goal
The world's visual signature (a purple sky, green-tinted haze and warm orange path lights) is established and readable without the flashlight. The Ghost Cemetery gets one finished vignette as the quality benchmark, with an improved Weeping Angel and Bell Tower and the first shared asset kit.

## Scope
- **In:**
  - Global Lighting, Atmosphere and Sky settings: built-in only, tuned in Studio.
  - Warm lamp families placed along paths, gates and landmarks.
  - The shared kit: ground transitions, path edges, gravestones, trees and roots, fence and gate, lanterns and candles, ruined masonry.
  - Detailed Weeping Angel and Bell Tower.
  - One complete vignette: a winding path with a side route, gravestones, vegetation, a lit segment and both landmarks.
- From [[AUD-20261012-TASK-0027-01]] finding 1: `Kit.freeGround` checks only a prop's centre against gate corridors; give scenery a radius margin (long logs, cottage walls) and rerun Reachability on all four modules.
- **Out:** detail in the other three habitats, houses and trains (TASK-0030), uploaded or generated assets, flashlight changes.
- **References:** map references 3 and 7 (sky and ground glow, framed path), 5 and 6 (chunky tombstones, spiked iron, warm-lit faced trees). Qualities only ([[RSH-20261012-World-Retrofit-Audit]]).

## Acceptance criteria
- [ ] AC1: Looking up reads purple. The haze is green-tinted. Surfaces aren't globally tinted purple (no ColorCorrection tint carries the look).
- [ ] AC2: With the flashlight off, Studio captures from the ring road, a hub gate and the vignette path show the path, landmarks and a monster at 40+ studs. jg confirms readability.
- [ ] AC3: The Angel and Bell Tower have distinct, readable silhouettes from 80+ studs, and the paths stay clear for movement (Reachability passes).
- [ ] AC4: Lights are budgeted: shadows only on a few key lights, with the local light count recorded. No noticeable frame drop in a Studio play capture.
- [ ] AC5: `scripts/check.sh` and FullLoop pass.

## Tests
- **Studio:** captures before and after (same cameras), the light count and part count, and jg's visual review in a `TEST-` note.
- **Who settles the evidence:** jg (look and feel). Claude covers the captures and checks.

---
## Implementation record
- **References used** (opened the images in `10 References/02 Map`):
  - Reference 3: violet sky with stars over dark silhouettes, glowing pale-green ground, warm carved-pumpkin glows → the purple sky, the green ground mist and the pumpkins.
  - Reference 7: a winding dirt path framed by a fence, chunky stones → edge stones and the framing fences.
  - Qualities only; nothing copied.
- **Decisions:**
  - Roblox's `Atmosphere.Color` tints both the sky and the distance haze, so one colour can't make a purple sky and a green haze at once. The sky carries the purple. The green comes from low, see-through mist discs (`Kit.mist`) in every module. No ColorCorrection tint.
  - Twilight (ClockTime 19.2) with a raised OutdoorAmbient gives readable ground without the flashlight and no orange sunlight.
  - Lamp family: an iron post with an arm and a hanging orange glass lantern. Only 3 lights cast shadows (two Angel lanterns, the bell).
- **Built:**
  - `Atmosphere.Config` and `apply()` (now sets values on existing instances too).
  - Detailed Weeping Angel (plinth, robe, bowed head with hands over the face, three-layer wings) and Bell Tower (buttresses, open belfry, lit bell, stepped spire with cross).
  - Kit pieces in `Props`: lantern, pumpkin, edge stones, moss patch, cemetery gate arch, ruined wall, candles, roots on dead trees.
  - Cemetery: mossy ground, ground mist, and the vignette (`vignette()` in `Habitats/Cemetery`): the gate arch on the South Path, framing fences, edge stones on the South Path and the Old Rows loop, moss, pumpkins, candles, ruined masonry. The grave grid and trees keep clear of it.
  - `Kit.freeGround` checks a prop's reach against the gate corridors ([[AUD-20261012-TASK-0027-01]] finding 1); logs and cottages got larger clearances.
- **Evidence:** [[TEST-20261012-04]].

## Audits
- [[AUD-20261012-TASK-0028-01]]: pass (4 minor, 2 nit). TEST note wording fixed; AC1 and AC2 wait on jg.

## Outcome
- **Merge** approved by jg in chat on 2026-10-12 ("merge anything you need to to finish this up"). Merged through PR #22.
- **Result:** a twilight sky with stars, readable ground without the flashlight, the orange lamp family, a detailed Angel and Bell Tower, and the finished cemetery vignette.
- **Needs jg:** (1) the sky renders blue-indigo rather than clearly violet; (2) the green comes from ground mist, because one Atmosphere colour can't be both a purple sky and a green haze. Accept this, or ask for a retune (for example a more magenta haze colour).
- **Follow-ups:** soften the mist edges; lighten the Woodland trail; measure the frame rate on a device (TASK-0020).

