---
id: TASK-0028
title: Cemetery Vignette and Atmosphere
type: task
project: GAME-002
status: ready
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

## Audits

## Outcome
