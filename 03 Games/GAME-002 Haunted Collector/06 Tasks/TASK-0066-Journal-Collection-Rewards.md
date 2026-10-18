---
id: TASK-0066
title: "Journal Collection Rewards"
type: task
project: GAME-002
status: proposed
priority: medium
risk: medium
owner: executor
depends_on: [TASK-0060, TASK-0061]
branch: task/TASK-0066-Journal-Collection-Rewards
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

# Journal Collection Rewards

## Goal
Journal milestones can be claimed exactly once and the reward appears in Owned. Part of the monetization baseline ([[SYS-Haunted-Monetization-UI]]). **Draft: not approved.**

## Scope
- **In:** Journal UI additions, a reward service and rules, specs. Milestones need jg's review.
- **Out (non-goals):** anything marked deferred in [[SYS-Haunted-Monetization-UI]]: premium currency, paid convenience, events, gifting, trading, bundles, fixed prices.
- **Keep unchanged:** existing gameplay, income, capacity, rarity and capture rules.

## Intake
- **Category → workflow, depth:** UI and graphics → [[UI Workflow]], **Standard** (first audit: Sonnet).
- **References:** check `10 References/` for the matching folder at start; UI References is empty.
- **Reuse:** existing services, `Theme.luau` and the TASK-0058 spec style.
- **Decisions / assumptions / open questions:** Decision (jg, this batch): claim button, not automatic grant.
- **Measurement:** note `get_usage` context tokens at start and close; log with `record-usage`.

## Acceptance criteria
- [ ] AC1 The Journal shows habitat completion, rare natural-variant discoveries and Bestiary milestones with Eligible and Claimed states; a Claim action grants once on the server and cannot repeat.
- [ ] AC2 Milestone definitions come from the real species and habitat roster, written into the note; a paid skin never completes a discovery.
- [ ] AC3 Specs for eligibility, single grant and replay; check.sh green; one Sonnet audit.

## Tests
- **Automated:** `scripts/check.sh` plus the specs above.
- **Studio playtest procedure:** per the acceptance criteria; run `studio-preflight` first.

## Risks / notes
Persistence, trust boundary and product details are governed by the baseline note; do not invent product IDs or prices.

---
## Implementation record

## Audits

## Outcome
