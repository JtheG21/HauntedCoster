---
id: TASK-0064
title: "Mansion Themes"
type: task
project: GAME-002
status: in_review
priority: medium
risk: medium
owner: executor
depends_on: [TASK-0060, TASK-0061, TASK-0069]
branch: task/TASK-0064-Mansion-Themes
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

# Mansion Themes

## Goal
One mansion theme can be previewed, equipped and survives an upgrade truthfully. Part of the monetization baseline ([[SYS-Haunted-Monetization-UI]]). **Draft: not approved.**

## Scope
- **In:** Theme config, applier on the plot house, preview, specs. One sample theme that meets the 3D Model Quality Baseline.
- **Out (non-goals):** anything marked deferred in [[SYS-Haunted-Monetization-UI]]: premium currency, paid convenience, events, gifting, trading, bundles, fixed prices.
- **Keep unchanged:** existing gameplay, income, capacity, rarity and capture rules.

## Intake
- **Category → workflow, depth:** 3D asset or prop → [[Asset Workflow]], **Standard** (first audit: Sonnet).
- **References:** check `10 References/` for the matching folder at start; UI References is empty.
- **Reuse:** existing services, `Theme.luau` and the TASK-0058 spec style.
- **Decisions / assumptions / open questions:** Decision (jg, this batch): per-theme tier list with truthful UI and fallback. Tier coverage of real themes depends on assets.
- **Measurement:** note `get_usage` context tokens at start and close; log with `record-usage`.

## Acceptance criteria
- [ ] AC1 A theme declares its supported house tiers; equipping an unsupported tier is refused with a reason, and a tier upgrade that invalidates the equipped theme falls back to the default look with a notice.
- [ ] AC2 Complete exterior preview before purchase; the theme shows consistently to all players; state survives rejoin.
- [ ] AC3 Specs for compatibility and fallback; Studio check across tiers and plot orientations; check.sh green; one Sonnet audit.

## Tests
- **Automated:** `scripts/check.sh` plus the specs above.
- **Studio playtest procedure:** per the acceptance criteria; run `studio-preflight` first.

## Risks / notes
Persistence, trust boundary and product details are governed by the baseline note; do not invent product IDs or prices.

---
## Implementation record
Executor: Claude (Sonnet 5.5). Context tokens at start 219,091, at close 238,975 (growth 19,884, shared with earlier session work). Weekly plan 95% at start and close.

**Files:** new `Rules/ThemeRules.luau` (parse, messages, tier coverage text, which theme shows at a tier, the fallback notice after an upgrade) and `tests/ThemeRules.spec.luau`; `CosmeticService.equipTheme` plus the `EquipTheme` remote (rate limited 4 per 8 s, `CosmeticRules.setTheme` checks ownership and tier inside the update, then the house is rebuilt); `PlotBuilder.buildHouse` takes a tint and sets `Tint_Walls/Trim/Roof` on the house art (the client `Dressing` already applies `Tint_` attributes, so every player sees it); `PlotService` passes the resolved tint on every house build; `EconomyService` clears an equipped theme the new tier does not cover and toasts the reason; `ShopUI` details view shows coverage, colour swatches and Equip/Remove (Equip only at a covered tier); `Config/CosmeticLooks` and `Catalog` gain one sample, `ThemeMoonlit` (tiers 1 and 2, not the Shack, so the fallback is real); `Net` registers `EquipTheme`.

**Checks:** `scripts/check.sh` ALL CHECKS PASSED; Lune specs 230 passed.

**Decisions:** the tint applies only while the house is at a covered tier (resolved when the house is built). An upgrade that leaves the theme uncovered clears the selection with a notice; the theme stays owned. A removed or unowned or unlisted theme resolves to the default look.

**Limits (honest):** the sample is a recolour of the existing house art (Walls, Trim, Roof), not a new model, so the baseline asset condition is not met; real themes need jg's art decisions. There is no full-exterior preview: the details view shows coverage and colour swatches only, so AC2's "complete exterior preview before purchase" is not met. Nobody can own `ThemeMoonlit` yet (no grant path until TASK-0066/0067). The rebuild on equip and on rejoin uses the same path as a tier upgrade, but no Studio run checked it across tiers or plot orientations.

| AC | State |
|---|---|
| AC1 tier list, refusal with reason, fallback with notice | implemented and spec-tested |
| AC2 complete exterior preview, consistent for all players, survives rejoin | NOT met: preview is swatches only; the tint replicates through house attributes and persists in `cosmetics`, untested in Studio |
| AC3 specs, Studio across tiers and orientations, check.sh, Sonnet audit | specs and check.sh done; Studio not run; audit see Audits |

**Studio skipped by jg, 2026-10-18.** No Play session, no check across tiers or plot orientations, no screenshots. The tint, the upgrade fallback and the theme UI are unverified at runtime.

## Audits

## Outcome
