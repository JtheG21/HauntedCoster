---
id: TASK-0067
title: "Coin Purchases"
type: task
project: GAME-002
status: done
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
Executor: Claude. jg said the session was switched to Opus, but the session still identifies as Sonnet 5.5, so usage is logged as sonnet-5.5. Context tokens at start 327,465, at close 353,493 (growth 26,028, shared with earlier session work). Weekly plan 97% at start and close.

**Prices (PLACEHOLDERS for jg to tune from measured income, in `Config/Catalog.luau`):** SkinMoss 300, AuraEmbers 250, DecoLantern 150 Coins. FxSparks and ThemeMoonlit stay reward-only. Base income is 1 to 3 Coins per second per ghost.

**Files:** new `Rules/PurchaseRules.luau` (parse, catalog-only price, quote with the exact shortfall, atomic `apply`, messages, a bounded receipt list) and `tests/PurchaseRules.spec.luau`; new `Services/PurchaseService.luau` and the `BuyItem` remote (itemId and a client request ID; rate limited 3 per 6 s; receipts remembered per player for the session, cleared on leave); `Catalog.Item.coinPrice`; `ShopRules` cards now carry `price`, `acquisition = "buyable"` and `canBuy` (true only for an unowned priced item), with the label "Costs N Coins" and the filter treating buyable-and-earnable items as earnable too; `ShopUI` details show the price, your Coins, the exact shortfall, and Buy then Confirm with a pending state; `DevProbe` and `scenarios/ExploitProbe` extended with forged `BuyItem` calls; `Net` registers `BuyItem`.

**Checks:** `scripts/check.sh` ALL CHECKS PASSED; Lune specs 264 passed (13 new for purchases, 1 for shop cards).

**Decisions:** the server reads the price only from the catalog. `apply` grants first (it can refuse a full collection) and debits second with no yield between, so it does both or neither. A repeat of the same request ID returns the first answer without touching coins; a new request for an owned item is refused as already owned, so a double submit charges once. Coins only: no Robux field exists, specs assert none and that no message mentions it. Debit and grant live in one profile table, so a crash loses both or neither; saving uses the normal autosave (no forced save).

**Limits (honest):** a lost reply after a successful purchase shows as owned on the next State update, not as the original success message. The receipt cache is per session, so across a rejoin the protection is ownership, which holds. The Buy UI, the pending state and the extended ExploitProbe were not run in Studio. Prices and whether a purchase should force a save need jg's decision.

| AC | State |
|---|---|
| AC1 authoritative debit and grant, idempotent, exact shortfall, no Robux prompt | implemented and spec-tested |
| AC2 pending, failure and rejoin states; prices from config | implemented; rejoin holds through ownership; Studio not run |
| AC3 specs, ExploitProbe extended, check.sh, Opus audit | specs and check.sh done; ExploitProbe extended but not run; Opus audit see Audits |

**Studio skipped by jg, 2026-10-18.** No Play session, no ExploitProbe run, no Buy round trip, no screenshots. The Buy UI, the pending state and the extended probe are unverified at runtime.

## Audits
[[AUD-20261018-TASK-0067-01]]: pass (Opus). Fixed after the audit: only final refusals are remembered, receipts are per item, the probe check compares against a snapshot. Studio and the ExploitProbe run still owed.

## Outcome
Sample cosmetics can be bought with Coins: the server reads the price from the catalog, debits and grants in one step, and a retry or double submit never charges twice (merge approved by jg, 2026-10-18). Opus audit passed. Needs jg: tune the placeholder prices (SkinMoss 300, AuraEmbers 250, DecoLantern 150) from measured income, and decide whether a purchase should force a save. Not verified: Studio (the Buy and Confirm round trip, the pending state) and a run of the extended ExploitProbe. Coins only; a Robux path waits on TASK-0068 and jg's approval.
