---
id: TASK-0067
title: "Coin Purchases"
type: task
project: GAME-002
status: ready
priority: medium
risk: high
owner: executor
depends_on: [TASK-0060, TASK-0061]
branch: task/TASK-0067-Coin-Purchases
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

# Coin Purchases

## Goal
Items can be bought with Coins safely, once. Part of the monetization baseline ([[SYS-Haunted-Monetization-UI]]). **Draft: not approved.**

## Scope
- **In:** A purchase service and remote, rate limits, specs. No Robux, no real prices.
- **Out (non-goals):** anything marked deferred in [[SYS-Haunted-Monetization-UI]]: premium currency, paid convenience, events, gifting, trading, bundles, fixed prices.
- **Keep unchanged:** existing gameplay, income, capacity, rarity and capture rules.

## Intake
- **Category → workflow, depth:** Systems → [[Systems Workflow]], **Standard** (first audit: Opus).
- **References:** check `10 References/` for the matching folder at start; UI References is empty.
- **Reuse:** existing services, `Theme.luau` and the TASK-0058 spec style.
- **Decisions / assumptions / open questions:** Prices need jg's tuning from measured income. Ships with sample prices flagged as placeholders in config only.
- **Measurement:** note `get_usage` context tokens at start and close; log with `record-usage`.

## Acceptance criteria
- [ ] AC1 Coin purchases of catalog items debit and grant authoritatively on the server, idempotent under retry and double submit; insufficient funds shows the exact requirement and never opens a Robux prompt.
- [ ] AC2 Pending, failure and rejoin states are covered; prices come from configured data, never UI constants.
- [ ] AC3 Specs for debit, grant, retry, insufficient funds and rapid repeats; ExploitProbe extended; check.sh green; one Opus audit (economy and persistence).

## Tests
- **Automated:** `scripts/check.sh` plus the specs above.
- **Studio playtest procedure:** per the acceptance criteria; run `studio-preflight` first.

## Risks / notes
Persistence, trust boundary and product details are governed by the baseline note; do not invent product IDs or prices.

---
## Implementation record

## Audits

## Outcome
