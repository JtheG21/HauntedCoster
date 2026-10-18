---
id: TASK-0061
title: "Shop And Owned Inventory UI"
type: task
project: GAME-002
status: proposed
priority: medium
risk: low
owner: executor
depends_on: [TASK-0060]
branch: task/TASK-0061-Shop-And-Owned-Inventory-UI
related:
  - "[[Task Intake]]"
  - "[[SYS-Haunted-Monetization-UI]]"
  - "[[ADR-0011-Monetization-UI-Scope]]"
  - "[[TASK-0060-Monetization-Persistence-Schema]]"
created: 2026-10-18
updated: 2026-10-18
tags:
  - workflow/task
---

# Shop And Owned Inventory UI

## Goal
The Shop and Owned screens exist and read real ownership state, with every item state truthful, before any category is wired. Part of the monetization baseline ([[SYS-Haunted-Monetization-UI]]). **Draft: not approved.**

## Scope
- **In:** games/haunted/src/client/UI (Theme.luau kit), a read-only service and remotes, specs and screenshots. No purchase, no equip.
- **Out (non-goals):** anything marked deferred in [[SYS-Haunted-Monetization-UI]]: premium currency, paid convenience, events, gifting, trading, bundles, fixed prices.
- **Keep unchanged:** existing gameplay, income, capacity, rarity and capture rules.

## Intake
- **Category → workflow, depth:** UI and graphics → [[UI Workflow]], **Standard** (first audit: Sonnet).
- **References:** check `10 References/` for the matching folder at start; UI References is empty.
- **Reuse:** existing services, `Theme.luau` and the TASK-0058 spec style.
- **Decisions / assumptions / open questions:** Use the existing Theme.luau kit; UI References is empty, so follow inspected Mansion and Journal conventions and say so in the note. Physical-device checks stay deferred.
- **Measurement:** note `get_usage` context tokens at start and close; log with `record-usage`.

## Acceptance criteria
- [ ] AC1 A Shop screen (five categories, ownership and acquisition filters, cards, item details) and an Owned view with equipped markers, reachable from the HUD and Mansion, with one consistent back behaviour and kept filter and scroll position.
- [ ] AC2 Loading, empty-catalog, unavailable-data and owned states are honest: no fake prices, no Buy button without a supported grant path, unknown ownership never shown as unowned.
- [ ] AC3 Server exposes read-only catalog and ownership remotes (validated, rate-limited); UI specs for state logic; Studio screenshots at desktop and phone widths; check.sh green; one Sonnet audit.

## Tests
- **Automated:** `scripts/check.sh` plus the specs above.
- **Studio playtest procedure:** per the acceptance criteria; run `studio-preflight` first.

## Risks / notes
Persistence, trust boundary and product details are governed by the baseline note; do not invent product IDs or prices.

---
## Implementation record

## Audits

## Outcome
