---
id: TASK-0062
title: "Ghost Skins And Auras Equipment"
type: task
project: GAME-002
status: proposed
priority: medium
risk: medium
owner: executor
depends_on: [TASK-0060, TASK-0061]
branch: task/TASK-0062-Ghost-Skins-And-Auras-Equipment
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

# Ghost Skins And Auras Equipment

## Goal
Players can equip and remove an owned skin and aura on each ghost and see it, with no gameplay effect. Part of the monetization baseline ([[SYS-Haunted-Monetization-UI]]). **Draft: not approved.**

## Scope
- **In:** A cosmetic service, the appearance applier, the Owned view's equip actions and specs. Needs at least one sample skin and aura asset that meets the 3D Model Quality Baseline.
- **Out (non-goals):** anything marked deferred in [[SYS-Haunted-Monetization-UI]]: premium currency, paid convenience, events, gifting, trading, bundles, fixed prices.
- **Keep unchanged:** existing gameplay, income, capacity, rarity and capture rules.

## Intake
- **Category → workflow, depth:** Systems → [[Systems Workflow]], **Standard** (first audit: Sonnet).
- **References:** check `10 References/` for the matching folder at start; UI References is empty.
- **Reuse:** existing services, `Theme.luau` and the TASK-0058 spec style.
- **Decisions / assumptions / open questions:** No cosmetic changes income, capacity, rarity or capture. Content is a sample item per category only; the real catalog needs jg's asset and price decisions.
- **Measurement:** note `get_usage` context tokens at start and close; log with `record-usage`.

## Acceptance criteria
- [ ] AC1 Owned skins and auras equip and remove per ghost (by UID) through a server-validated remote; compatibility is checked and explained; natural Spectral and Ashen identity is preserved.
- [ ] AC2 The appearance shows on the owner's and other players' clients, previews never alter live models, and state survives rejoin.
- [ ] AC3 Specs for equip, remove, incompatible target and invalid input; check.sh green; one Sonnet audit; Studio FullLoop still passes.

## Tests
- **Automated:** `scripts/check.sh` plus the specs above.
- **Studio playtest procedure:** per the acceptance criteria; run `studio-preflight` first.

## Risks / notes
Persistence, trust boundary and product details are governed by the baseline note; do not invent product IDs or prices.

---
## Implementation record

## Audits

## Outcome
