---
id: TASK-0064
title: "Mansion Themes"
type: task
project: GAME-002
status: proposed
priority: medium
risk: medium
owner: executor
depends_on: [TASK-0060, TASK-0061]
branch: task/TASK-0064-Mansion-Themes
related:
  - "[[Task Intake]]"
  - "[[SYS-Haunted-Monetization-UI]]"
  - "[[ADR-0011-Monetization-UI-Scope]]"
  - "[[TASK-0060-Monetization-Persistence-Schema]]"
  - "[[TASK-0061-Shop-And-Owned-Inventory-UI]]"
created: 2026-10-18
updated: 2026-10-18
tags:
  - workflow/task
---

# Mansion Themes

## Goal
One mansion theme can be previewed, equipped and survives an upgrade truthfully. Part of the monetization baseline ([[SYS-Haunted-Monetization-UI]]). **Draft: not approved.**

## Scope
- **In:** Theme config, applier on the plot house, preview, specs. One sample theme that meets the 3D Model Quality Baseline.
- **Out (non-goals):** anything marked deferred in [[SYS-Haunted-Monetization-UI]]: premium currency, paid convenience, events, gifting, trading, bundles, fixed prices.
- **Keep unchanged:** existing gameplay, income, capacity, rarity and capture rules.

## Intake
- **Category → workflow, depth:** 3D asset or prop → [[Asset Workflow]], **Standard** (first audit: Sonnet).
- **References:** check `10 References/` for the matching folder at start; UI References is empty.
- **Reuse:** existing services, `Theme.luau` and the TASK-0058 spec style.
- **Decisions / assumptions / open questions:** Decision (jg, this batch): per-theme tier list with truthful UI and fallback. Tier coverage of real themes depends on assets.
- **Measurement:** note `get_usage` context tokens at start and close; log with `record-usage`.

## Acceptance criteria
- [ ] AC1 A theme declares its supported house tiers; equipping an unsupported tier is refused with a reason, and a tier upgrade that invalidates the equipped theme falls back to the default look with a notice.
- [ ] AC2 Complete exterior preview before purchase; the theme shows consistently to all players; state survives rejoin.
- [ ] AC3 Specs for compatibility and fallback; Studio check across tiers and plot orientations; check.sh green; one Sonnet audit.

## Tests
- **Automated:** `scripts/check.sh` plus the specs above.
- **Studio playtest procedure:** per the acceptance criteria; run `studio-preflight` first.

## Risks / notes
Persistence, trust boundary and product details are governed by the baseline note; do not invent product IDs or prices.

---
## Implementation record

## Audits

## Outcome
