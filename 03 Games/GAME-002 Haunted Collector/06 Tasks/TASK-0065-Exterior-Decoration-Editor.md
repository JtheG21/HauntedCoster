---
id: TASK-0065
title: "Exterior Decoration Editor"
type: task
project: GAME-002
status: ready
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

## Audits

## Outcome
