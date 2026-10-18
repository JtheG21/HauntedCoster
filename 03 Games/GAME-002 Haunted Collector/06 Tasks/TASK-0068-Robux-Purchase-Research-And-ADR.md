---
id: TASK-0068
title: "Robux Purchase Research And ADR"
type: task
project: GAME-002
status: in_review
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
Executor: Claude (Sonnet 5.5). Context tokens at start 369,782, at close 391,494 (growth 21,712, shared with earlier session work). Weekly plan 97% at start and close.

**Notes written:** [[RSH-20261018-Robux-Purchase-Mechanisms]] (observations, hypotheses and recommendations kept apart, with sources and access dates) and the draft [[ADR-0013-Robux-Purchase-Mechanism]] (`status: proposed`, no approver). No code, no product IDs, no prices, no publishing, no Robux spend, no web requests: the sources are the local creator-docs clone (commit af5f853, committed 2026-10-10).

**Recommendation in the draft:** developer products feeding our own entitlements, with an idempotent, save-first receipt handler that grants by `PurchaseId` and remembers processed IDs.

**Not read or verified:** Studio test purchases, pass and product limits, tax, payout and legal pages, price optimization, and the live web docs.

| AC | State |
|---|---|
| AC1 research note and draft ADR comparing developer products and passes, receipts and grant recovery, with sources and access dates | done (receipt and recovery behaviour from the MarketplaceService reference; limits above) |
| AC2 ADR stays draft; no product IDs, prices, publishing or spend | met |
| AC3 open questions for jg; no code changes | met: seven questions in the ADR; the diff touches only notes |

## Audits

## Outcome
