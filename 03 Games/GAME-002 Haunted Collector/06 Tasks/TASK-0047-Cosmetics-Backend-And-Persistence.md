---
id: TASK-0047
title: "Cosmetics Backend and Persistence"
type: task
project: GAME-002
status: in_progress
priority: high
risk: high
owner: executor
depends_on:
  - TASK-0041
branch: task/TASK-0047-Cosmetics-Backend-And-Persistence
related:
  - "[[SYS-Haunted-Art-Direction]]"
  - "[[SYS-Haunted-Monetization-UI]]"
  - "[[3D Model Quality Baseline]]"
created: 2026-10-13
updated: 2026-10-13
tags:
  - workflow/task
---

# Cosmetics Backend and Persistence

## Goal
Implement the approved cosmetic economy backend: catalog, ownership, equipment, placements, rewards and purchases, with safe persistence.

Part of the overhaul jg requested on 2026-10-13 (3D asset overhaul, full UI overhaul, approved monetization scope). jg authorized the local design and implementation work, creating scoped tasks and testing in local Studio places; publishing, spending, live products, uploads and merges stay gated.

## Scope
- **In:** Cosmetics config and rules, profile schema bump and migration, CosmeticsService, Coin purchases, ProcessReceipt grants with Studio-only fixtures, rewards, placement validation, rate limits, specs.
- **Out (non-goals):** UI (TASK-0051), assets (TASK-0050), live product configuration (jg).
- **Keep unchanged:** server authority, gameplay rules and tuning, existing interaction points and collisions, GAME-001.

## Intake
- **Category → workflow, depth:** Systems → [[Systems Workflow]], deep
- **References:** [[SYS-Haunted-Monetization-UI]], [[ADR-0011-Monetization-UI-Scope]], [[RSH-20261013-Haunted-Monetization-Discovery]], [[SYS-Haunted-Player-Data]].
- **Reuse:** existing builders keep their gameplay geometry; visuals move to the art pipeline from [[TASK-0042-Art-Pipeline-And-Direction]].
- **Branch stacking:** built on the overhaul stack (`task/TASK-0046-Mansion-Plot-And-Train-Art`, after TASK-0046's commits) so the cosmetics reach the new house and plot art; the queue dependency stays TASK-0041; the queue dependency stays TASK-0041 because unmerged stacked work cannot be `done`.

## Files expected to change
- `src/shared/Config/Cosmetics.luau`, `src/shared/Rules/{CosmeticRules,PlacementRules,ProfileRules}.luau`, `src/server/Services/{CosmeticsService,PlayerDataService}.luau`, `src/server/Remotes.luau`, tests.

## Acceptance criteria
- [ ] AC1 A cosmetic catalog (skins, auras, capture effects, mansion themes, exterior decorations) with compatibility, acquisition routes and no gameplay stats; specs prove cosmetics never change income, rarity, speed, capacity or capture.
- [ ] AC2 Profile schema bump with migration that preserves every existing field; account entitlements, per-ghost skin/aura, per-player capture effect, theme, decoration inventory and placements, and reward claims persist and survive rejoin.
- [ ] AC3 Coin purchases, equip/remove, reward claims and decoration place/move/store are server-validated, rate-limited and idempotent; Robux grants go through ProcessReceipt with duplicate-safe receipt records, and products stay disabled until configured (test fixtures only in Studio).
- [ ] AC4 Placements are validated in plot-local space against tier, footprint, paths and caps; upgrades keep compatible placements and store the rest.
- [ ] AC5 scripts/check.sh passes with new specs; Persistence scenario covers the new fields; schema change awaits jg's approval before merge.

## Tests
- **Automated:** `scripts/check.sh`.
- **Studio playtest procedure:** local place `~/Roblox-Work/haunted/Overhaul.rbxl` built from this branch; scenarios named in the criteria; captures stored with the evidence.

## Risks / notes
- Runtime meshes use EditableMesh. Live use needs either jg's batch 3D import (an upload) or jg's 13+/ID verification plus the Creator Dashboard Mesh/Image API toggle ([[SYS-Haunted-Art-Direction]]).

---
## Implementation record
- **Design (DRAFT, needs jg's approval before release):** `Config/Cosmetics.luau` lists 23 launch items across the five categories (7 skins, 3 auras, 3 capture effects, 3 mansion themes, 8 decorations) with draft Coin prices, 6 Robux items listed by product key only (every `productId` is nil, so nothing can be bought for Robux until jg configures real products), 7 collection milestones (four habitat completions, first natural variant, half and full Bestiary counting only variants that can actually spawn), and placement caps (24 per plot; per-item limits). Decorations are one unlock with reusable placements up to a per-item limit (the count policy the baseline left open). Themes cover all three tiers (tints over shared part names), so the coverage claim is true.
- **Rules (pure, specced):** `CosmeticRules` (sanitize, per-ghost skin/aura with species compatibility, capture-effect and theme selection with tier check, Coin purchase in one synchronous step, receipt application once per PurchaseId with a bounded receipt list, milestone progress from the journal only, claim once, place/move/store, tier reconcile, client snapshot) and `PlacementRules` (rotated footprint inside the plot, clear of track area, pen, entrance, exhibits, spawn, beacon, trophies, lamps, pillars, house volumes of the current tier and other decorations; grid/fine snap; 15-degree steps).
- **Schema 2 (pending jg's approval before merge):** `ProfileRules.Schema = 2` adds `cosmetics`; schema-1 profiles migrate by sanitising (every field kept, cosmetics empty); selections for released ghosts, unowned items, invalid placements and junk receipts are dropped; a schema-1 server already treats newer data as read-only.
- **Service:** `CosmeticsService` with one rate-limited remote `Cosmetic` (6/s, burst 10) for buy, buyRobux (server-side prompt only for a configured product), equip, select, claim, place, move, store; writes refused when the profile can't save (live) so nothing is falsely granted; `ProcessReceipt` applies a receipt once and returns PurchaseGranted only after `PlayerDataService.saveNow` reports the write landed (`saveNow` now returns success); unknown products stay NotProcessedYet. World: pen/exhibit models carry `Skin`/`Aura`, the house art gets theme tints, decorations are built on the plot, upgrades keep fitting placements and store the rest with a notice, secured captures fire `CosmeticFx` for the equipped capture effect.
- **Checks:** `scripts/check.sh` passes; specs 153/0 including `Cosmetics.spec` (10 tests: catalog has no gameplay fields and all five categories, no live products, income unchanged by cosmetics, Coin buy once, per-ghost compatible skins, receipts once, journal-only rewards claimed once, placement validation, upgrade reconcile, schema-1 migration and junk dropping). Studio scenario `tests/scenarios/Cosmetics.luau` written (buy, equip, incompatible refusal, theme tint on the house art, place/move, claim once, receipt with a TEST FIXTURE product id twice, unknown product unprocessed, tier-2 upgrade keeping the placement); **not yet run** (Studio stalled during this session).
- **Not done / gated:** Robux products and prices (jg configures in the Creator Dashboard); the launch assortment and Coin prices (jg); rejoin persistence on a published place (Persistence scenario needs DataStores; the local file runs memory-only).

## Audits

## Outcome
