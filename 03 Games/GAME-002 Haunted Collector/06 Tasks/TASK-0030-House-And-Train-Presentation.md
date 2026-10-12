---
id: TASK-0030
title: House and Train Presentation
type: task
project: GAME-002
status: ready
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

## Audits

## Outcome
