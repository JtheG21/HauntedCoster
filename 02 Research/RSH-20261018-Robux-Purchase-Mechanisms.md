---
id: RSH-20261018-Robux-Purchase-Mechanisms
title: "Robux Purchase Mechanisms: Developer Products vs Passes"
type: research
status: research
sources:
  - "creator-docs production/monetization/developer-products.md"
  - "creator-docs production/monetization/passes.md"
  - "creator-docs reference/engine/classes/MarketplaceService.yaml"
confidence: medium
created: 2026-10-18
updated: 2026-10-18
tags:
  - research
  - game/monetization
---

# Robux Purchase Mechanisms: Developer Products vs Passes

## Question
How could Haunted Collector sell its cosmetics for Robux later, safely and once per player, on top of the Coin purchases and entitlements already built ([[TASK-0060-Monetization-Persistence-Schema]], [[TASK-0067-Coin-Purchases]])? This feeds the draft [[ADR-0013-Robux-Purchase-Mechanism]]. Nothing here is approved, and no product, price or Robux spend exists.

## Sources
| Source | URL | Accessed |
|---|---|---|
| Developer Products (local creator-docs clone, commit af5f853, committed 2026-10-10) | `~/Code/creator-docs/content/en-us/production/monetization/developer-products.md` (public: https://create.roblox.com/docs/production/monetization/developer-products) | 2026-10-18 |
| Passes (same clone) | `.../production/monetization/passes.md` | 2026-10-18 |
| MarketplaceService reference: `ProcessReceipt`, `BindReceiptHandler`, `PromptProductPurchaseFinished` (same clone) | `.../reference/engine/classes/MarketplaceService.yaml` | 2026-10-18 |
| Managed (regional) pricing and Paid random items (same clone, first lines only) | `.../production/monetization/regional-pricing.md`, `paid-random-items.md` | 2026-10-18 |

The local clone may lag the live site; the web pages were not fetched.

## Observed mechanics (verified in the docs above)
- A **developer product** can be bought more than once (currency, potions). A **pass** is a one-time purchase of a permanent privilege. *(developer-products, passes)*
- A product is created in the Creator Hub for a **published** game, with a Robux price from 1 up. *(developer-products)*
- Products are granted only through the server-side `ProcessReceipt` callback (or the newer `BindReceiptHandler`, which takes precedence and falls back to `ProcessReceipt`). The docs say not to grant on `PromptProductPurchaseFinished`, because the purchase can still fail on the backend. *(developer-products, MarketplaceService)*
- `ProcessReceipt` is set once, in one server script, and must handle every product. Its receipt carries `PurchaseId`, `PlayerId`, `ProductId`, `CurrencySpent`, `CurrencyType` and the place. Returning `PurchaseGranted` resolves it; `NotProcessedYet` leaves it unresolved. `BindReceiptHandler` uses `Enum.ReceiptDecision.Processed` and `NotProcessedYet` instead. *(MarketplaceService)*
- Unresolved purchases come back only when the player joins any server or starts another purchase: there is no time-based retry. The callback may run on two servers at once for the same purchase, runs in no fixed order, needs the player on the server, and can yield for as long as the server runs. Returning `PurchaseGranted` can still fail to record on the backend, leaving the purchase unresolved. Unresolved purchases are not refunded when escrow ends. *(MarketplaceService)*
- With no `ProcessReceipt` callback, receipts are auto-acknowledged and cannot be recovered. *(MarketplaceService)*
- **Listed** products and passes can be sold outside the game; Roblox checks the `ProcessReceipt` implementation, and a flagged product stops showing outside the game until fixed. *(developer-products)*
- Passes are checked with `UserOwnsGamePassAsync` and prompted with `PromptGamePassPurchase`; the docs sample assigns privileges from `PromptGamePassPurchaseFinished`. Passes need no receipt handling. *(passes)*
- **Managed pricing** can lower a regional price by at most 70% of the default and never raises it above the default; with price optimization the price should be fetched on the client. *(regional-pricing, developer-products)*
- **Paid random items** carry extra requirements; selling fixed, known cosmetics is not a random item. *(paid-random-items, first lines)*

## Hypotheses
- Our cosmetic entitlements (`profile.cosmetics.entitlements`) can be the single source of truth, with a Robux purchase being only another way to call `CosmeticRules.grant`. *(confidence: medium; the grant path and the Coin purchase already work this way, TASK-0067)*
- One developer product per catalog item, with processed `PurchaseId`s recorded in the profile, can prevent a double grant even when the callback runs on two servers, but only if the profile store session-locks or saves atomically; otherwise both servers could load the profile before either saves. *(confidence: low to medium; the project has `SessionLockRules`, but this was not checked against the receipt case. The v2 profile schema has no field for processed purchase IDs yet, so one must be added.)*
- Many cosmetics mean many passes, each created by hand in the Creator Hub, which scales worse than products. *(confidence: low; pass count limits were not looked up)*

## Relevance to our game
All cosmetics are permanent, account-wide and bought once, which matches a pass on paper. But ownership already lives in our own saved entitlements, every item must reach the same Shop, Owned and equipment code, and Coins can already buy the same items. A product that feeds our grant path keeps one ownership record. The cost is that a product can be bought twice, so the server must refuse to prompt for an owned item and treat a duplicate receipt as already granted.

## Original implementation ideas
- On a Robux buy, prompt only if the item is unowned and has a configured product ID; grant by `PurchaseId` inside the profile update; save before returning `PurchaseGranted`.
- Keep a bounded set of processed `PurchaseId`s in the profile so a re-delivered receipt is acknowledged without a second grant.
- Show the Robux price from the product info (not a UI constant), and nothing at all for an item whose product ID is not configured.

## Recommendations (max 3)
1. Prefer **developer products feeding our own entitlements** over passes (draft ADR-0013), because it reuses the saved ownership, the Shop and the Coin path.
2. Make the receipt handler **idempotent and save-first**: `PurchaseGranted` only after the grant is persisted, with processed `PurchaseId`s remembered.
3. Do not create products, set prices, publish or spend Robux until jg approves the ADR and a scoped implementation task.

## Needs human review
- Unverified conclusions: how Studio simulates purchases, pass or product count limits, the tax, payout and legal side (not read), price optimization behaviour (not read), and whether a duplicate purchase of an owned item can be fully prevented in the prompt flow. The local docs clone is dated 2026-10-10.
- jg decisions are listed in [[ADR-0013-Robux-Purchase-Mechanism]].
