---
id: RSH-20261013-Haunted-Monetization-Discovery
title: Haunted Collector Monetization Discovery
type: research
project: GAME-002
status: research
sources:
  - https://chatgpt.com/share/6ace0fc4-3a0c-83e8-9491-26608d2d0ac3
confidence: medium
created: 2026-10-13
updated: 2026-10-13
tags:
  - research/monetization
---
# Haunted Collector Monetization Discovery

## Question
**Forward scope reference (2026-10-13):** [[SYS-Haunted-Monetization-UI|Monetization UI Baseline]] and [[ADR-0011-Monetization-UI-Scope]] now carry jg's approved category, acquisition and equipment choices. This research record preserves discovery history; its previously unresolved currency and equipment choices were resolved in that ADR. Its measurements and original-source gaps remain unchanged.

Which cosmetic purchases fit Haunted Collector, and what evidence is needed before implementation? This closes the current discovery pass with a provisional recommendation; it does not authorize implementation, prices, commerce configuration, or a final Claude handoff.

## Sources
| Source | URL / location | Accessed |
|---|---|---|
| Shared discovery, visible Rounds 6–8 and submitted answers | https://chatgpt.com/share/6ace0fc4-3a0c-83e8-9491-26608d2d0ac3 | 2026-10-13 |
| Local code, base commit 345e7f1 | `games/haunted/src/shared/Config/{Economy,Monsters,Variants,World,PlotDecor,Track}.luau`; `shared/Rules/{EconomyRules,ProfileRules,TrackRules}.luau`; `server/World/{Build,PlotBuilder}.luau`; `server/Services/{EconomyService,TrainService}.luau`; `client/UI/{MansionUI,JournalUI,Theme,Hud}.luau` | 2026-10-13 |
| Local UI reference index | [[UI References]] | 2026-10-13 |

## Observed mechanics (verified)
### Recovered decision record
The visible shared conversation reports 32 decisions. The first 16 are not exposed in full; retain them as unresolved source records, never reconstruct their wording or treat absence as revocation. Earlier assistant summaries mention complete mansion skins initially, a small editor, optional player-initiated shopping, a permanent catalog first, and safe persistence; these are historical summaries, not recovered individual approvals.

| Original ID | Decision visible in shared record |
|---|---|
| MON-D-017 | Decoration areas depend on inspection of current house geometry. |
| MON-D-018 | Hybrid placement: grid snapping, rotation, limited free placement. |
| MON-D-019 | Preserve compatible decoration placements on upgrade; store incompatible ones safely. |
| MON-D-020 | Collection rewards combine habitat completion, rare variants, and Bestiary milestones. |
| MON-D-021 | Decoration catalog has type/theme filters and ownership labels. |
| MON-D-022 | Defer social customization until the core is stable. |
| MON-D-023 | Inspect ghost data before deciding cosmetic ownership. Resolved by the submitted Round 8 ownership answer below. |
| MON-D-024 | Mix earnable, directly purchased, and event cosmetics. The assistant's record says seasonal; the submitted answer says event. Do not narrow all events to seasons. |
| MON-D-025 | Preview mansion skins before buying; offer immediate equip. |
| MON-D-026 | Decide premium currency only after economy/purchase-flow analysis. Still pending. |
| MON-D-027 | Define permissible paid convenience after measuring progression. Still pending. |
| MON-D-028 | Unowned cosmetics show a preview and optional shop-listing link. |

Submitted Round 8 answers: account-wide unlocks for all compatible ghosts; separate skin, aura, and capture-effect slots; defer mansion-theme tier coverage until geometry/production review; staged economy/customization/UI audit followed by consolidated recommendations. The visible page does not show their original MON-D identifiers, so none are invented here. These choices are recovered from jg's submitted message; technical designs below remain recommendations.

### Reference preservation register
Keep original IDs and screenshot order; never replace, renumber, or claim visual inspection of unavailable originals.

| Preserved IDs | Historical description from shared conversation | Evidence availability |
|---|---|---|
| MON-REF-013, MON-REF-014, MON-REF-015, MON-REF-016 | Bestiary, discovery silhouettes, rarity, completion rewards | Images unavailable in shared page; descriptions only |
| MON-REF-017, MON-REF-018, MON-REF-019, MON-REF-020, MON-REF-021, MON-REF-022, MON-REF-023, MON-REF-024 | Illustrated journals, progression pages, seasonal rewards, navigation | Images unavailable; descriptions only |
| MON-REF-025, MON-REF-026 | Cosmetic bundles, product presentation, gifting | Images unavailable; gifting is reference material, not approval |
| MON-REF-027, MON-REF-028, MON-REF-029 | Upgrades, time-savers, convenience offers | Images unavailable; these offers remain unapproved |

### Local code findings
- House tiers cost 0 / 250 / 1,500 Coins, with capacity 4 / 10 / 20 and exhibit slots 2 / 3 / 4. First secured ghost awards 60 Coins; acclimation is 30 seconds. `Config/Economy`.
- Normal Wisp/Hound/Gentleman/Bell Wraith earn 1 / 1.5 / 3 / 8 Coins per second. Spectral/Ashen multiply income by 1.5 / 1.75. Paid appearance must remain separate from natural gameplay variants. `Config/Monsters`, `Config/Variants`.
- Exhibited ghosts stop passive earnings. Train payout is rounded `40 × house multiplier × route quality × (1 + in-range exhibit bonus)`; quality is bounded 0.9–1.25. Paid completions have a 20-second cooldown measured from the preceding paid completion. `EconomyRules:36`, `TrackRules:258`, `TrainService:605`.
- Grand Mansion unlocks offline income: 25% of passive earnings, capped at two hours. At 10 Coins/sec the cap yields 18,000 Coins. This is arithmetic, not a playtest. `EconomyRules:47`.
- Six rotated plots are 100 × 90 studs. Placement must use plot-local coordinates and exclude track, pen, entrances, spawn, exhibits, dressing and house growth. `Config/World`, `Config/PlotDecor`.
- House bodies are solid collidable blocks, not usable rooms. Interior furnishing requires new geometry. House upgrades clear the House folder; decorations need independent storage/runtime containers. `PlotBuilder:289,421`, `Build:19`.
- Owned ghost data stores UID, species, variant and acquisition time. Sanitization rebuilds these records and would discard added nested equipment fields unless deliberately updated. Unknown top-level fields are preserved; newer-schema data is protected from older-server writes. `ProfileRules:17,146,163,202`.
- Existing Mansion tabs are Upgrades, Monsters and Exhibits. Journal has text-based unknown entries and cosmetic trophy milestones. No MarketplaceService/ProcessReceipt/purchase-prompt implementation was found by scoped source search. The local UI reference index is empty; screenshot comparison was not performed.

## Hypotheses
- Cosmetics can become a useful Coin sink after progression upgrades, but current income may make fixed cosmetic prices trivial for established players. Confidence: medium; measure post-upgrade balances and spend rates.
- Exterior mansion themes can preserve gameplay geometry while interiors substantially expand scope. Confidence: high for inspected builder; confirm in Studio and review theme assets.
- Selling storage may affect progression because capacity limits earning collections. Confidence: medium; compare acquisition, capacity pressure and upgrade times before approving convenience.

## Relevance to our game
The collectible identity and player-owned plot are strong foundations for cosmetics. Technical compatibility, collection readability, persistence and fair progression govern the product scope. Related: [[GAME-002 Haunted Collector/01 Game Design]], [[GAME-002 Haunted Collector/02 Technical Architecture]], [[SYS-Haunted-Player-Data]], [[SYS-Haunted-Ghost-Train]].

## Original implementation ideas
Draft only: maintain account cosmetic entitlements separately from equipped skin/aura/capture-effect slots; retain species/natural variant as gameplay identity. Use compatibility rules, unequip and safe visual fallback. Capture-effect ownership is confirmed account-wide where compatible, but whether equipment applies per ghost or per player still needs a decision.

Store decoration ownership independently from plot-local placements. On house rebuild, revalidate placements; preserve valid ones and return invalid ones to storage without loss. Prefer exterior decorations initially because interiors do not exist yet. Tier-spanning themes remain unapproved.

Reuse Mansion navigation for owned equipment and Journal for discovery/rewards. Catalog inspection leads to preview, explicit acquisition information, optional shop link, and equip after ownership confirmation. New preview, catalog and purchase states are required; current UI does not implement them.

## Recommendations (max 3)
1. Provisional rollout order: compatible account-wide ghost skins; mansion exterior themes after tier review; small exterior decoration assortment; auras/capture effects after clarity/performance checks. Keep the confirmed separate slots in the design even if rollout is staged. No assortment or asset creation is approved by this ranking.
2. Retain Coins as the measured baseline; defer premium currency, income boosts and paid storage. Passive-only earning times for 190 Coins are 190 / 47.5 / 31.7 seconds at 1 / 4 / 6 Coins/sec; for 1,500 Coins they are 25 / 6.25 / 4.17 minutes. These assume fixed acclimated portfolios and exclude acquisition, travel, rides and spending. Test Coin cosmetic prices as time targets using measured discretionary income rather than setting prices from these idealized rates.
3. Before implementation approval, gather fresh/typical/skilled progression samples: first secure, each house tier, capacity-full time, failures/travel, exhibit trade-offs, paid rides per minute, final balances and offline return. Review original screenshots, all tier themes, six-plot placement constraints and device previews. Then approve scope and entitlement/schema design through the existing workflow.

## Needs human review
- Original MON-D-001–016 and original Round 8 ID mappings need recovery; original MON-REF-013–029 images need filing/inspection. Current register preserves identity but cannot substitute for the assets.
- No progression playtest, visual UI audit, Studio geometry validation, receipt test or schema migration was performed in this discovery pass.
- Robux prices, premium currency, paid convenience, tier coverage, final assortment and implementation remain pending. No final Claude Code handoff prepared.
- Session outcome: created this research record and linked it from the game overview. Created [[3D Model Quality Baseline]] and [[3D Model Quality Gallery]] after inspecting the two screenshot folders, archived 87 originals, and added the mandatory baseline rule to AGENTS.md. Task queue/project state remain unchanged because this is documentation, not a completed gameplay task.
