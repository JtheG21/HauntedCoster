---
id: SYS-Haunted-Monetization-UI
title: Monetization UI Baseline
type: system
project: GAME-002
status: approved
approved_by: jg
approved_on: 2026-10-13
version: 1.0
created: 2026-10-13
updated: 2026-10-13
tags:
  - game/design
  - game/monetization
  - game/ui
related:
  - "[[ADR-0011-Monetization-UI-Scope]]"
  - "[[RSH-20261013-Haunted-Monetization-Discovery]]"
  - "[[3D Model Quality Baseline]]"
---
# Haunted Collector — Monetization UI Baseline v1.0

This is the approved product/UI scope baseline for the next major UI update (jg, 2026-10-13, approval of the presented baseline and local merge). The category, currency and equipment choices are recorded in [[ADR-0011-Monetization-UI-Scope]]. The screen arrangement, interactions and acceptance checklist establish the intended update; they are not implemented features. Discovery's confirmed decisions are carried forward; original evidence gaps are retained rather than reconstructed. Item/backend readiness decisions remain explicit below.

## Purpose
Carry the approved monetization scope into the next major UI update.

## Responsibilities
- Catalog, previews, ownership/equipment, collection reward presentation and exterior customization.
- Clear acquisition states and authoritative persistence/commerce integration.

## Pitch (1–2 sentences)
Collect strange creatures, personalize their appearances and your haunted mansion, and earn cosmetic rewards through collection. Players can browse, preview, obtain and equip cosmetics through an optional permanent catalog without purchasing stronger ghosts.

## Target players & session length
Use [[GAME-002 Haunted Collector/01 Game Design]] for the game's audience and session goals. Shopping is player-initiated and can be exited immediately. Collection and ordinary progression remain usable without opening the Shop.

## Core loop
**Discovery:** Journal or owned ghost/mansion → inspect cosmetic → preview → optional Shop listing.

**Acquisition:** Shop → choose item → inspect compatibility and acquisition method → preview → explicit purchase or reward path → ownership confirmation → optional Equip/Place now.

**Customization:** owned inventory → select compatible ghost, mansion theme or decoration → apply/remove → authoritative confirmation → visible world result → retained after rejoin.

### Included categories and ownership
| Category | Ownership | Equipped/placed on | Product and preview requirement |
|---|---|---|---|
| Ghost skins | Account-wide compatible unlock | Each owned ghost independently, keyed by its UID | Show compatible species, selected ghost, natural variant identity and preview. The same owned skin can be used on multiple compatible ghosts without another purchase. |
| Auras | Account-wide compatible unlock | Each owned ghost independently, in its own aura slot | Preview with skin equipped; remain readable with natural variant cues. Show intensity in context, not just an isolated glow. |
| Capture effects | Account-wide unlock | Player's selected capture-effect slot | Short replayable preview. Cosmetics cannot change capture timing, success, meter visibility or retaliation. |
| Mansion themes | Account-owned theme | Player's current mansion | Complete exterior theme preview with tier compatibility. Preview before purchase and offer immediate equip after confirmation. Tier coverage remains asset-dependent; never imply all tiers if not supported. |
| Exterior decorations | Persistent account inventory | Valid plot-local placements | Catalog type/theme filters; preview scale and footprint. Each catalog entry states reusable placement versus quantity ownership and any placement limit before acquisition. Exact inventory/count policy needs approval before those items launch. |

Skin and aura slots are independent. Removing a skin restores the natural appearance; removing an aura clears that cosmetic layer. Capture effects are player-wide. No cosmetic alters income, capacity, speed, rarity, natural variant, crypt access or capture difficulty. Natural Spectral/Ashen variants remain collectible gameplay identities, not paid cosmetics.

### Screen baseline
| Surface | What the update includes |
|---|---|
| HUD / navigation | Explicit Shop access, existing Journal/Mansion access, one consistent close/back behavior. No forced shop opening after failure, upgrade or login. |
| Shop | Permanent catalog with the five categories; category, theme/type where relevant, ownership and acquisition filters; clear cards with item name, image, acquisition label and Owned state. |
| Item details / preview | Rotatable model preview where useful, replayable capture effect, compatibility, current ownership, exact price or earn condition, and explicit acquisition action. Back returns to the same catalog/filter/scroll position. |
| Owned cosmetics | Owned-only view with category filters, equipped markers, compatible targets and Equip/Remove actions. Ownership and equipment are distinct states. Accessible from Shop and Mansion customization without starting a purchase. |
| Mansion / ghost management | Keep Upgrades, Monsters and Exhibits. Add access to ghost appearance slots, mansion themes and exterior decoration inventory; ordinary Coin upgrades stay visually distinct from cosmetic purchasing. |
| Journal / collection rewards | Species/habitat progress, discovered natural variants and Bestiary milestones; clear reward eligibility and Claimed state. Unknown entries preserve discovery rather than treating paid skins as uncaught species. Optional cosmetic previews link to Shop only when the player chooses. |
| Exterior decoration editor | Owned palette with type/theme filters, grid snapping, rotation and bounded finer placement; live valid/invalid indication; Confirm, Cancel, Move, Rotate, Store and Exit. Show inventory counts/placement limits where applicable. |

Mobile: layouts fit the actual viewport, support touch previews and avoid controls hidden by scrolling or previews. Controller: focus order, visible selection, consistent back/cancel and no hover-only information. Desktop: clickable controls and keyboard actions. Physical-device verification remains required; this baseline does not claim it was done.

### Interaction/state baseline
| State | Required behavior |
|---|---|
| Loading catalog or ownership | Show a readable loading state; do not display unknown ownership as unowned or allow a duplicate buy. |
| Available / unowned | Preview and acquisition information are visible. Purchase action appears only for a configured supported purchase. |
| Owned / unequipped | Replace Buy with Equip or Place. Account unlocks do not offer another purchase; quantity decoration purchases are shown only when an approved count policy permits them. |
| Owned / equipped | Show target and equipped slot; offer Remove/default appearance. |
| Incompatible target/tier | Explain compatibility. Prevent equip, preserve ownership, and allow compatible target selection. |
| Coin purchase pending | Block duplicate submission; update ownership/balance only from authoritative confirmation. Insufficient funds shows exact requirement without automatically opening a Robux prompt. |
| Robux purchase pending | Use the supported platform purchase confirmation. Dismiss/cancel does not grant ownership or show success. Closing the UI does not lose an already completed grant. |
| Purchase confirmed but grant pending | Explain that ownership is being confirmed; refresh from authoritative state and do not encourage buying again. |
| Save/ownership unavailable | Existing owned looks remain visible where safely known; purchases, reward claims and persistent edits are unavailable with a clear retry message. No false saved/granted state. |
| Reward eligible / claimed | Show progress and eligibility; server-confirmed claim or automatic grant is reflected once, with no repeated award. Choice of claim button versus automatic reward is implementation design, not an approved mechanic. |
| Placement invalid | Indicate the blocked area and prevent confirmation. Preview does not consume inventory. Cancel restores the prior placement. |
| Mansion upgrade invalidates placement | Preserve compatible placements; return incompatible decorations to storage with a clear notice. No purchased item disappears. |

## Progression & retention
Earned Coins and collection rewards provide cosmetic routes alongside direct Robux products. Habitat completion, rare natural-variant discoveries and overall Bestiary milestones are the collection reward axes from MON-D-020. Define exact milestones and rewards against the real species/habitat roster before implementation; owning a paid skin does not complete discoveries.

The initial release uses a permanent catalog. Event cosmetics remain a future category, not a required seasonal shop at launch. Pricing uses measured discretionary income and progression rather than the idealized passive calculations in discovery. The UI must show acquisition routes per item; the baseline does not promise every premium-exclusive item can also be earned or require every earned item to be sold.

## Social features
Existing plot visits/train guests remain governed by current game scope. Gifting, trading, shared decoration editing and social customization are deferred (MON-D-022); reference screenshots mentioning gifting are not approval to implement it.

## Monetization
**Approved launch structure:** all five cosmetic categories; direct Robux purchases plus earned Coins/rewards; no premium currency in this update; paid convenience deferred until progression is measured. No income boosts, paid ghosts/variants, storage upgrades, timers/skips, random paid crates, subscription/VIP mechanics or bundles are introduced by this baseline. Bundles or other products need an explicit addition to scope.

The exact direct-purchase entitlement mechanism, product/pass choice, repeatable decoration purchases, receipt/grant recovery and catalogue configuration are backend design tasks. This document specifies required behavior without inventing product IDs or prices. A client purchase prompt/result is not proof of ownership; purchases and grants must be validated on the server, survive retries and rejoin, and avoid duplicate charges/grants.

Robux sales cannot activate until products, persistence and grant handling are approved and verified. Category screens and owned/reward interactions can be developed as scoped slices before paid sales. Do not expose fake prices, active-looking unavailable products or a Buy button with no supported grant path.

## MVP scope
Here MVP means the first monetization UI release; it does not redefine the completed original gameplay MVP.

| Feature | Priority | Status |
|---|---|---|
| All five permanent cosmetic categories | P0 | Scope approved by jg, 2026-10-13; not implemented |
| Shop catalog, details, preview and owned inventory | P0 | Proposed interaction baseline |
| Per-ghost skin/aura equipment; per-player capture effect | P0 | Ownership/application approved; persistence schema not approved |
| Mansion themes with truthful tier coverage | P0 | Included; exact tier coverage and assets pending |
| Exterior decoration palette and bounded hybrid editor | P0 | Included; geometry/count policy pending |
| Journal collection progress and cosmetic reward states | P0 | Included from prior confirmed decisions; milestone definitions pending |
| Direct Robux and Coin/reward acquisition states | P0 | Acquisition structure approved; prices/products/backend pending |
| Touch/controller/desktop behavior and visual polish | P0 | Required verification, not yet performed |
| Events, gifting, trading, premium currency, paid convenience | Later | Deferred |

### Delivery dependencies and acceptance
1. **Design/assets:** select original UI references when recovered; until then use inspected Mansion/Journal/Theme conventions. [[UI References]] is empty and MON-REF-013–029 originals are unavailable. Their historical descriptions suggest Bestiary progress, illustrated journal hierarchy and readable product presentation; they are not inspected layouts. Every 3D asset and preview meets [[3D Model Quality Baseline]]. Approve the exact launch assortment and mansion-tier compatibility before asset production.
2. **Persistent ownership:** independent entitlement inventory, per-ghost skin/aura selections, per-player capture effect, mansion theme, decoration inventory/placements and reward grant state; scoped migration/sanitization/schema plan and rejoin tests. Existing newer-schema/read-only safeguards remain effective.
3. **World integration:** skins preserve natural variant identity; previews do not alter live models; placed decorations are server-validated in plot-local coordinates and cannot block essential gameplay. Preserve/stow behavior works across all tiers and plot orientations. Owned cosmetics appear consistently to the owner and other players.
4. **Commerce:** authoritative Coin debits/grants; verified direct-Robux entitlements; idempotent/retry-safe grant handling appropriate to the chosen mechanism; duplicate submission, cancel, delayed grant, rejoin and failure coverage. Prices come from configured real product data and approved economy tuning, not UI constants.
5. **UI verification:** all five category journeys work; owned/unowned/equipped/incompatible states are distinguishable; preview and cancel preserve the world; menus retain navigation context; no forced shopping. Validate on touch, controller and desktop, including narrow viewports and unavailable data states.
6. **Release:** run required project checks, scoped audit/playtests and explicit merge approval per task. Publishing, purchases, product configuration and paid asset generation require their own authorization. This note is a baseline, not a final Claude implementation prompt.

## Non-goals
Interior furnishing (current houses are solid), paid gameplay advantages, currency redesign, forced purchase prompts, event shop launch, gifting/trading, full UI art direction from unavailable screenshots, fixed Robux/Coin prices, exact SKU counts or a new backend framework.

## Open questions
These are item/backend readiness gates, not reasons to reopen the approved five-category scope:
- Exact launch items and prices; measured cosmetic earning targets; which items are earned, Robux-exclusive or rewarded.
- Mansion themes: all-tier versus limited-tier products and safe fallback when upgrading. Compatibility must be resolved before selling each theme.
- Decoration quantity/reuse model, inventory and placement caps, safe zones and finer-placement bounds. Do not assume infinite copies or unlimited placement.
- Natural variant visual cue when a skin/aura is applied; effect visibility/performance limits; compatible species per item.
- Collection milestone definitions and reward issuance; entitlement mechanism and schema migration design.
- Original MON-D-001–016 and MON-REF-013–029 recovery. Missing records are preserved in discovery; no new IDs are fabricated.

## Session outcome
Created this baseline and [[ADR-0011-Monetization-UI-Scope]]; linked them from Game Design, Overview and Roadmap. Discovery remains a historical research record; this note is the forward UI scope reference. No implementation task/state was invented, no game code changed, and no final Claude handoff prepared.

## Interfaces
No new API or remote names are approved here. Screen-to-service interfaces must carry stable catalog IDs, validated targets and authoritative ownership/purchase results; the exact contracts belong to scoped implementation tasks.

## Data & state
See Included categories and ownership, Interaction/state baseline, and Delivery dependencies above. Entitlements, equipped selections, placements and rewards must have an approved persistent schema before release.

## Trust boundary / security
The client previews and requests actions; the server validates ownership, compatibility, pricing, placement and grants, with input validation and rate limits. Client prompt completion never establishes entitlement.

## Tests
- Automated: implementation specs must cover purchase/grant retries, compatibility, equipment, placement and migration; current documentation checks do not prove these features.
- Playtest: all category journeys, rejoin, multiplayer appearance, house upgrades, cancellation and physical devices. No feature playtest has been run for this baseline.

## History
- 2026-10-13: baseline drafted from discovery and explicit choices in [[ADR-0011-Monetization-UI-Scope]].
- 2026-10-13: jg approved the presented baseline and its local vault merge in chat. Pricing, product configuration, schema changes, implementation and publishing remain separately gated.
