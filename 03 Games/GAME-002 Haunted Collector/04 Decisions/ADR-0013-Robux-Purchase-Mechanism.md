---
id: ADR-0013
title: Robux Purchase Mechanism
type: adr
project: GAME-002
status: proposed
approved_by:
approved_on:
related:
  - "[[RSH-20261018-Robux-Purchase-Mechanisms]]"
  - "[[ADR-0011-Monetization-UI-Scope]]"
  - "[[SYS-Haunted-Monetization-UI]]"
created: 2026-10-18
updated: 2026-10-18
tags:
  - workflow/decision
  - game/monetization
---
# Robux Purchase Mechanism

**DRAFT. Not approved.** No product ID, price, publishing or Robux spend is authorised by this note.

## Context
[[ADR-0011-Monetization-UI-Scope]] approves direct Robux purchases for cosmetics, but not the mechanism, prices, product IDs or any implementation. Cosmetic ownership, equipment, Coin purchases and a single grant path (`CosmeticRules.grant`) already exist. [[RSH-20261018-Robux-Purchase-Mechanisms]] compares the two Roblox mechanisms from the creator docs.

## Options considered
1. **Developer products feeding our own entitlements.** One product per item; a server receipt handler grants through the existing path. Flexible and reuses Shop, Owned and equipment. Needs an idempotent, save-first receipt handler and a processed-receipt record; a product can be bought more than once, so the server must not prompt for an owned item.
2. **Game passes.** Roblox records one-time ownership and there is no receipt handling. But each cosmetic needs its own pass made by hand, and ownership is queried from Roblox, so it would need mirroring into our saved entitlements on join to keep one record.
3. **Hybrid.** Products for most items, passes only for a few headline permanent unlocks. More surface to keep consistent; not worth it before there are real items.

## Decision
*(Proposed, for jg.)* Recommend **option 1**: developer products that feed our own entitlements, with a receipt handler that grants by `PurchaseId` inside a profile update, saves before returning `PurchaseGranted` (or `Processed` if `BindReceiptHandler` is chosen), remembers processed IDs and treats a repeat as already granted. This is only duplicate-proof across two servers if the profile store session-locks or saves atomically, which the follow-up task must prove. Mark `status: approved` only after explicit approval by jg, and record who and when.

## Open questions for jg
1. Option 1, 2 or 3?
2. One product per item, or also bundles (ADR-0011 defers bundles)?
3. Robux prices, and whether to enable managed (regional) pricing.
4. Should products be **Listed** outside the game (this makes Roblox check the receipt handler)?
5. When may the game be published so products can be created, and who creates them?
6. Should an item ever be buyable with both Coins and Robux, and may Robux ever skip a progression gate (ADR-0011 says cosmetics only)? If so, a player could open a Robux prompt, buy the item with Coins, then finish the payment: what happens then (refund route, a substitute grant, or blocking the Coin buy while a prompt is open)?
7. Where to keep processed receipt IDs (inside the profile, bounded, which needs a schema addition) and how long, and how the two-server case is made safe (session lock or atomic save).

## Consequences
- A scoped implementation task would follow: receipt handler, schema addition for processed IDs, an ExploitProbe and a Studio test purchase plan, and an Opus audit (economy, persistence).
- Until then the Shop shows no Robux button and no fake price, as today.
- Studio's handling of test purchases and the live pass or product limits are unverified and must be confirmed before building.
