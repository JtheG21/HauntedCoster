---
id: TASK-0068
title: "Robux Purchase Research And ADR"
type: task
project: GAME-002
status: proposed
priority: medium
risk: low
owner: executor
depends_on: []
branch: task/TASK-0068-Robux-Purchase-Research-And-ADR
related:
  - "[[Task Intake]]"
  - "[[SYS-Haunted-Monetization-UI]]"
  - "[[ADR-0011-Monetization-UI-Scope]]"
created: 2026-10-18
updated: 2026-10-18
tags:
  - workflow/task
---

# Robux Purchase Research And ADR

## Goal
jg can choose a Robux mechanism from verified evidence. Part of the monetization baseline ([[SYS-Haunted-Monetization-UI]]). **Draft: not approved.**

## Scope
- **In:** 02 Research note and an ADR draft only.
- **Out (non-goals):** anything marked deferred in [[SYS-Haunted-Monetization-UI]]: premium currency, paid convenience, events, gifting, trading, bundles, fixed prices.
- **Keep unchanged:** existing gameplay, income, capacity, rarity and capture rules.

## Intake
- **Category → workflow, depth:** Systems → [[Systems Workflow]], **Deep** (first audit: Opus).
- **References:** check `10 References/` for the matching folder at start; UI References is empty.
- **Reuse:** existing services, `Theme.luau` and the TASK-0058 spec style.
- **Decisions / assumptions / open questions:** Robux sales cannot activate until products, persistence and grants are approved and verified (SYS-Haunted-Monetization-UI).
- **Measurement:** note `get_usage` context tokens at start and close; log with `record-usage`.

## Acceptance criteria
- [ ] AC1 A research note and a draft ADR compare entitlement mechanisms (developer product vs game pass), receipt handling and grant recovery, with sources and access dates.
- [ ] AC2 The ADR stays draft; no product IDs, prices, publishing or Robux spend without jg's explicit approval.
- [ ] AC3 Open questions listed for jg; no code changes.

## Tests
- **Automated:** `scripts/check.sh` plus the specs above.
- **Studio playtest procedure:** per the acceptance criteria; run `studio-preflight` first.

## Risks / notes
Persistence, trust boundary and product details are governed by the baseline note; do not invent product IDs or prices.

---
## Implementation record

## Audits

## Outcome
