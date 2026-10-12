---
id: TASK-0030
title: House and Train Presentation
type: task
project: GAME-002
status: in_review
priority: medium
risk: low
owner: executor
milestone: M3
depends_on:
  - TASK-0026
branch: task/TASK-0030-House-And-Train-Presentation
created: 2026-10-12
updated: 2026-10-12
tags:
  - workflow/task
  - milestone/m3
related:
  - "[[ADR-0007-World-Retrofit-Direction]]"
  - "[[SYS-Haunted-Ghost-Train]]"
---
# TASK-0030: House and Train Presentation

## Goal
Each plot reads as a small haunted theme park. The three house tiers look like clear upgrades with consistent proportions, and the ghost-train area gets a real station, themed fencing and gates, warm path lights and visible exhibits. The house, track and editor gameplay is unchanged.

## Scope
- **In:** `PlotBuilder` house tiers (better shapes, trims, roofs and porches; the shack stays recognisable), station presentation, exhibit pedestal dressing, plot fence and gate, lamp family from the TASK-0028 kit, and scenery kept clear of the track bounds.
- **Out:** track editor logic, validation, ride movement, payout, new tiers, uploaded assets.

## Acceptance criteria
- [ ] AC1: Each tier is visibly bigger and richer than the last, built from the same material palette on all six plots. Captures for jg's review.
- [ ] AC2: No new scenery inside the track bounds or the exhibit range rings, or blocking the pen, station or plot entrance. A spec checks the decoration boxes against the bounds.
- [ ] AC3: The part count per tier is recorded, and a house rebuild on upgrade stays under the agreed budget.
- [ ] AC4: FullLoop and CrossPlot pass. `scripts/check.sh` passes.

---
## Implementation record
- **References used:** map reference 6 (chunky, readable silhouettes, warm-lit windows) and the TASK-0028 lamp family. Qualities only.
- **Decisions:**
  - Every house volume per tier lives in `shared/Config/PlotDecor` (`Houses[tier]` boxes), and `PlotBuilder.buildHouse` builds from it. The `PlotDecor` spec checks the boxes (grown 1.5 studs for details), the lamps and the entrance pillars against the track bounds, the pen, the entrance, the beacon, the trophies, the spawn (5 studs) and each exhibit pedestal (6 studs, our reading of "exhibit range rings": the pedestal and room to walk round it; the scoring range of 16 studs is a gameplay radius, not a no-build zone). It also checks that each tier has a bigger footprint and is taller.
  - Tiers: the Shabby Shack keeps its crooked box and tilted roof, and gains a lean-to, a crooked chimney and a boarded window. The Restored Manor has two storeys, a gable roof with ridge and gable ends, trim bands, shuttered windows in two rows, two chimneys, a gabled wing and a columned porch. The Grand Mansion is wider and taller, with two wings, a deep porch with a balcony, and a tower with a stepped spire and the purple lantern.
  - Light budget: only 2 front windows per house cast light (plus the door-side lamps). The other lit windows glow without a light.
  - Plot dressing: stone gate pillars with lanterns and an iron spiked arch at the entrance, 5 lamps (3 between the pen and the track area, 2 by the porch), and dressed exhibit plinths with corner posts.
  - Station (TrainService): a canopy on four iron posts with two hanging lanterns and a name board. Nothing collides, so the cart, riders and the Ride prompt are unchanged.
  - No fencing around the track area. A fence there would block walking to the station and the exhibits; the plot's entrance gate and border carry the "fence and gate" look.
- **Evidence:** [[TEST-20261012-06]].

## Audits

## Outcome
