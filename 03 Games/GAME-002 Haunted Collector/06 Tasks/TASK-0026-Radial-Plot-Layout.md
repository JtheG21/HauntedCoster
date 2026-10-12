---
id: TASK-0026
title: Radial Plot Layout
type: task
project: GAME-002
status: done
priority: high
risk: high
owner: executor
milestone: M3
depends_on:
  - TASK-0025
branch: task/TASK-0026-Radial-Plot-Layout
created: 2026-10-12
updated: 2026-10-12
tags:
  - workflow/task
  - milestone/m3
related:
  - "[[ADR-0007-World-Retrofit-Direction]]"
  - "[[RSH-20261012-World-Retrofit-Audit]]"
  - "[[SYS-Haunted-Ghost-Train]]"
---
# TASK-0026: Radial Plot Layout

## Goal
Six plots stand in a ring around a central hunting footprint with their entrances facing it. A persistent ring road links each plot to three hub gates, and the existing graveyard is re-laid inside the footprint as the first habitat module. Every plot-local position goes through one rotation-aware transform.

## Scope
- **In:**
  - `World` layout config: hub centre, plot ring radius and angles, ring road, hub wall and three gates. Plot centres are computed from these, not typed in.
  - `World.plotFrame / plotToWorld / worldToPlot`. Every consumer in the audit converts: plot geometry is built in local space, then transformed. That covers PlotBuilder, PlotService (spawn facing, `isInOwnPlot`), ContainmentService (residents face the plot front), `CaptureService.secure`, TrainService (positions and headings), TrackEditor (tap → local, outline, camera) and the Hud home arrow.
  - A `HabitatModule` contract (footprint disc, gate connection points, spawn zones, two landmark slots, `build`) and the cemetery as its first module. It is re-laid inside r ≤ 112, keeps all landmarks as scenery, and has winding paths linking the three gates.
  - Neutral spawn on the ring road. `ChaseRules` regions: hub disc and outer ring instead of rects.
  - CrossPlot also checks that touch-sitting a parked owner seat is refused. This is the [[AUD-20261012-TASK-0025-02]] N1 follow-up, added with jg's approval on 2026-10-12.
- **Out:** the other three habitats and swapping (TASK-0027), detail and lighting (TASK-0028), rotation (TASK-0029), new house or train visuals (TASK-0030).

## Files expected to change
`shared/Config/World.luau`, new `shared/Config/Habitats.luau`, `shared/Rules/ChaseRules.luau`, new `shared/Rules/PlotSpace.luau`, `server/World/{Build,PlotBuilder,GraveyardBuilder→HubBuilder + Habitats/Cemetery}.luau`, `server/Services/{PlotService,ContainmentService,CaptureService,TrainService,EncounterService,TutorialService}.luau`, `client/UI/{TrackEditor,Hud}.luau`, `client/LocalWorld.luau`, tests (new `PlotLayout.spec`; ChaseRules spec; FullLoop, CrossPlot, Reachability, ExploitProbe).

## Acceptance criteria
- [ ] AC1: Six plots sit 60° apart. Each plot's local -Z points at the hub, and the front gate opens onto the ring road.
- [ ] AC2: No code adds a plot-local offset to a plot centre directly (grep). All conversions use the shared transform.
- [ ] AC3: The `PlotLayout` spec proves:
  - no two plots overlap (rotated rectangles) and every plot clears the ring road;
  - track bounds and exhibit slots are inside the plot;
  - local → world → local is exact;
  - every plot is equidistant (±1 stud) to its nearest hub gate.
- [ ] AC4: Saved and starter routes build, validate, ride and pay on every plot. The editor places points where the player taps on a rotated plot (CrossPlot or FullLoop check on a non-axis-aligned plot).
- [ ] AC5: Securing works only at the player's own pen, at its new world position. Plot ownership and the cross-plot checks still hold (CrossPlot 2 players).
- [ ] AC6: The cemetery module stays inside its footprint. Reachability proves:
  - every zone centre and landmark is reachable on foot from a home plot;
  - each gate is reachable from every plot;
  - a real walk from home to the Weeping Angel succeeds.
  It also reports the longest pen walk time.
- [ ] AC7: FullLoop, ExploitProbe and the specs pass. `scripts/check.sh` passes.
- [ ] AC8: CrossPlot checks that a non-owner touching a parked owner seat is not seated (follow-up from AUD-20261012-TASK-0025-02 N1, added with jg's approval on 2026-10-12).

## Tests
- **Automated:** `scripts/check.sh`, new `PlotLayout.spec`, and the scenarios above. An optional offline `roblox-map` prove of an exported greybox spec (ring symmetry P8, overlap). Never its Studio bootstrap.
- **Studio playtest:** top-down and ground captures through Studio MCP, attached to a `TEST-` note.
- **Who settles the evidence:** scenarios (Claude). jg does a hands-on walk.

## Risks / notes
- This is the highest-risk change: ownership, secure distance and the editor all move. Prefer local-space checks (`worldToPlot`) over world-axis math.
- Return walks get shorter (about 500 → 320 studs worst case). The timers are unchanged; the measured values are reported.

---
## Implementation record
- **References used:** map references 1–7 (radial composition: plots around a central ground, entrances inward) for layout only; [[RSH-20261012-World-Retrofit-Audit]] for the coordinate audit. No reference code copied.
- **Decisions:**
  - The transforms live in `World` (`plotFrame`, `plotToWorld`, `worldToPlot`, `plotDirToWorld`) rather than a separate `PlotSpace` module: every consumer already requires `World`.
  - Plot angles are 30° + 60°k, so no plot is axis-aligned. Plot 1 (the one tests use) exercises the rotation.
  - Gates at 0°, 120° and 240° sit between plots, so every plot entrance is equally far from its nearest gate.
  - `GraveyardBuilder` is split into `HubBuilder` (wall, gates, ring road; permanent), `Props` (the shared kit) and `Habitats/Cemetery` (the first module). `Habitats.luau` holds the module contract, and `HabitatRules.validate` checks it at startup.
  - `ChaseRules` regions are a habitat disc (avoiding the crypt) and an open ring between the hub wall and the plots. Flee steps are capped at one step after the clamp.
- **AC2 grep:** no plot-local offset is added to a centre outside `World`. `PlotService.center()` only returns the centre.
- **Evidence:** [[TEST-20261012-02]].

## Audits
- [[AUD-20261012-TASK-0026-01]]: pass (4 minor, 3 nit). Findings 2, 4 and 5 are fixed in [[TASK-0027-Habitat-Modules-And-Blockouts]]; finding 1 is listed for jg's hands-on walk.

## Outcome
- **Merge** approved by jg in chat on 2026-10-12 ("anything you need my approval for you got it"). Merged through PR #20.
- **Result:** six plots in a ring around the hub, entrances facing in, one shared plot transform. The persistent hub (wall, ring road, three gates) is separate from the habitat module, and the Ghost Cemetery is the first module behind the `Habitats` contract and validator.
- **Lessons:** Vector3 is 32-bit, so geometry specs need about 1e-3 tolerance at r ≈ 126. Clamping a flee target into a ring can stretch the step, so the step is capped after the clamp.
- **Follow-ups:** return walks are at most 34 s of a 75 s timer (tuning); the editor tap on a rotated plot is part of jg's hands-on walk.

