---
id: TASK-0065
title: "Exterior Decoration Editor"
type: task
project: GAME-002
status: approved
priority: medium
risk: medium
owner: executor
depends_on: [TASK-0060, TASK-0061, TASK-0064]
branch: task/TASK-0065-Exterior-Decoration-Editor
related:
  - "[[Task Intake]]"
  - "[[SYS-Haunted-Monetization-UI]]"
  - "[[ADR-0011-Monetization-UI-Scope]]"
  - "[[TASK-0060-Monetization-Persistence-Schema]]"
  - "[[TASK-0061-Shop-And-Owned-Inventory-UI]]"
  - "[[TASK-0064-Mansion-Themes]]"
created: 2026-10-18
updated: 2026-10-18
tags:
  - workflow/task
---

# Exterior Decoration Editor

## Goal
A player can place, move and store a sample decoration with server-validated, persistent results. Part of the monetization baseline ([[SYS-Haunted-Monetization-UI]]). **Draft: not approved.**

## Scope
- **In:** Editor UI, placement service and rules, specs. The cap and safe zones are set in the task note and need jg's review of numbers.
- **Out (non-goals):** anything marked deferred in [[SYS-Haunted-Monetization-UI]]: premium currency, paid convenience, events, gifting, trading, bundles, fixed prices.
- **Keep unchanged:** existing gameplay, income, capacity, rarity and capture rules.

## Intake
- **Category → workflow, depth:** UI and graphics → [[UI Workflow]], **Standard** (first audit: Opus).
- **References:** check `10 References/` for the matching folder at start; UI References is empty.
- **Reuse:** existing services, `Theme.luau` and the TASK-0058 spec style.
- **Decisions / assumptions / open questions:** Interior furnishing is a non-goal. Exact cap and fine-placement bounds are an Assumption until jg reviews them.
- **Measurement:** note `get_usage` context tokens at start and close; log with `record-usage`.

## Acceptance criteria
- [ ] AC1 Owned decorations are placed in plot-local coordinates with grid snap, rotation, bounded fine placement, live valid or invalid feedback, Confirm, Cancel, Move, Rotate, Store and Exit; the server validates every placement against bounds, caps and essential gameplay areas.
- [ ] AC2 Reusable ownership with a per-plot cap (jg, this batch); a house upgrade stores incompatible placements with a notice and nothing is lost; state survives rejoin.
- [ ] AC3 Specs for placement validation, cap and storage; Studio check on all plot orientations; check.sh green; one Opus audit (server-validated persistent state).

## Tests
- **Automated:** `scripts/check.sh` plus the specs above.
- **Studio playtest procedure:** per the acceptance criteria; run `studio-preflight` first.

## Risks / notes
Persistence, trust boundary and product details are governed by the baseline note; do not invent product IDs or prices.

---
## Implementation record
Executor: Claude (Sonnet 5.5). Context tokens at start 283,615, at close 315,127 (growth 31,512, shared with earlier session work). Weekly plan 96% at start and close.

**Numbers for jg's review (DRAFT, in `Rules/PlacementRules.luau`):** coarse grid 2 studs; fine nudge at most 1 stud off the grid in 0.5 steps; server accepts positions on a 0.5-stud step; 3-stud margin inside the plot edge; per-item copies from the catalog (`placementLimit`, sample 4) and a plot cap of 60 (`Catalog.MaxPlacements`). Keep-out areas, plot-local, at the current house tier: every house box plus 2 studs, the pen plus 3, the entrance corridor, the spawn, each exhibit pedestal (6), the track editor area plus 2, the beacon, the trophies (8), each lamp and entrance pillar. Decorations may overlap each other (not refused).

**Files:** new `Rules/PlacementRules.luau` (keep-out rects, bounds, `refusal`, snap, `parseEdit`, `afterUpgrade`, messages) and `tests/PlacementRules.spec.luau`; `CosmeticService.editDecoration` plus the `EditDecoration` remote (place, move, store; rate limited 10 per 8 s; ownership, per-item limit and plot cap via `CosmeticRules.place`, geometry via `PlacementRules.refusal`, all inside one `PlayerDataService.update`); `PlotBuilder.buildDecorations` (art-only lantern post, no collision) and a `Decorations` folder; `PlotService.rebuildDecorations` and a build on plot assignment, so decorations show to every player and return on rejoin; `EconomyService` stores placements the bigger house now touches (kept owned) with a notice; new `client/UI/DecorEditor.luau` (draft, live valid or invalid answer, ghost marker) and a decoration section in the `ShopUI` details view (Place a copy, Move, Store, Confirm, Cancel); `Catalog` gains the sample `DecoLantern` and an optional `footprint`; `CosmeticLooks.Decorations`; `Net` registers `EditDecoration`; the CosmeticRules catalog spec no longer lists allowed categories.

**Checks:** `scripts/check.sh` ALL CHECKS PASSED; Lune specs 251 passed.

**Decisions:** the server never trusts a client number: `parseEdit` rejects non-numbers, NaN, infinity, off-step rotations and bad indexes before any rule runs. A refusal changes nothing. Storing keeps ownership (reusable decorations).

**Limits (honest):** the editor moves a draft with Left, Right, Fwd, Back, fine and Rotate buttons, not by dragging with the mouse or touch, so AC1's drag-style placement is not built. The sample lantern is a few Parts, not a baseline-quality model. Nobody can own `DecoLantern` yet (no grant path until TASK-0067). The ghost marker's orientation and the ShopUI layout are untested. "Sample item meets the 3D Model Quality Baseline" is not met.

| AC | State |
|---|---|
| AC1 place/move/rotate/store, live feedback, Confirm/Cancel, server validation | implemented and spec-tested (rules); button-based nudge instead of dragging; UI not run in Studio |
| AC2 reusable ownership with a cap, upgrade stores with a notice, rejoin | implemented; upgrade storing and rejoin rebuild untested in Studio |
| AC3 specs, Studio on all plot orientations, check.sh, Opus audit | specs and check.sh done; Studio not run; Opus audit see Audits |

**Studio skipped by jg, 2026-10-18.** No Play session, no check on any plot orientation, no screenshots. The decoration build, the ghost marker, the editor buttons and the upgrade storing are unverified at runtime.

## Audits
[[AUD-20261018-TASK-0065-01]]: pass (Opus). Fixed after the audit: `markDirty` when an upgrade stores decorations. Open follow-ups: re-validate placements on load, stable placement IDs. Studio still owed.

## Outcome
