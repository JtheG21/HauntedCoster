---
id: TASK-0062
title: "Ghost Skins And Auras Equipment"
type: task
project: GAME-002
status: approved
priority: medium
risk: medium
owner: executor
depends_on: [TASK-0060, TASK-0061, TASK-0069]
branch: task/TASK-0062-Ghost-Skins-And-Auras-Equipment
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

# Ghost Skins And Auras Equipment

## Goal
Players can equip and remove an owned skin and aura on each ghost and see it, with no gameplay effect. Part of the monetization baseline ([[SYS-Haunted-Monetization-UI]]). **Draft: not approved.**

## Scope
- **In:** A cosmetic service, the appearance applier, the Owned view's equip actions and specs. Needs at least one sample skin and aura asset that meets the 3D Model Quality Baseline.
- **Out (non-goals):** anything marked deferred in [[SYS-Haunted-Monetization-UI]]: premium currency, paid convenience, events, gifting, trading, bundles, fixed prices.
- **Keep unchanged:** existing gameplay, income, capacity, rarity and capture rules.

## Intake
- **Category → workflow, depth:** Systems → [[Systems Workflow]], **Standard** (first audit: Sonnet).
- **References:** check `10 References/` for the matching folder at start; UI References is empty.
- **Reuse:** existing services, `Theme.luau` and the TASK-0058 spec style.
- **Decisions / assumptions / open questions:** No cosmetic changes income, capacity, rarity or capture. Content is a sample item per category only; the real catalog needs jg's asset and price decisions.
- **Measurement:** note `get_usage` context tokens at start and close; log with `record-usage`.

## Acceptance criteria
- [ ] AC1 Owned skins and auras equip and remove per ghost (by UID) through a server-validated remote; compatibility is checked and explained; natural Spectral and Ashen identity is preserved.
- [ ] AC2 The appearance shows on the owner's and other players' clients, previews never alter live models, and state survives rejoin.
- [ ] AC3 Specs for equip, remove, incompatible target and invalid input; check.sh green; one Sonnet audit; Studio FullLoop still passes.

## Tests
- **Automated:** `scripts/check.sh` plus the specs above.
- **Studio playtest procedure:** per the acceptance criteria; run `studio-preflight` first.

## Risks / notes
Persistence, trust boundary and product details are governed by the baseline note; do not invent product IDs or prices.

---
## Implementation record
Executor: Claude (Sonnet 5.5). Context tokens at start 143,861, at close 181,239 (growth 37,378, shared with earlier session work). Weekly plan 94% at start, 95% at close.

**Files:** new `Rules/LookRules.luau` (request parsing, rare-variant rule, the look a ghost shows, per-item target list) and `tests/LookRules.spec.luau`; new `Services/CosmeticService.luau` (`EquipLook` remote, rate limited 6 per 8 s, ownership, species and variant checks, saves, rebuilds plot models); `Config/CosmeticLooks.luau` (sample recolour and particle looks); `Config/Catalog.luau` lists two samples (`SkinMoss`, `AuraEmbers`); `ContainmentService` sets `SkinId`/`AuraId` attributes on pen and exhibit models from `LookRules.appearance`; `client/Art/Creatures.luau` applies them; `ShopUI` details view gets Equip/Remove per owned ghost; `Net` registers `EquipLook`; `CosmeticRules.spec` updated from "catalog is empty" to "only sample looks, no products".

**Checks:** `scripts/check.sh` ALL CHECKS PASSED; Lune specs 217 passed. CI uses older pinned type definitions than the local ones; the previous task needed `any` casts for that. Nothing new here uses those APIs.

**Decisions:** a skin applies only to the natural variant (Normal); Spectral and Ashen keep their identity and get a clear refusal, while auras go on any variant. Looks are shown from the owner's saved choice, only if still owned, listed and compatible, so a catalog change falls back to the natural look. Removing never needs a compatibility check.

**Limits (honest):** the sample skin and aura are data-only recolours and particles over existing creature art, not new models, so the "3D Model Quality Baseline" asset condition is not met; real items need jg's art decisions. Nobody can own the samples yet (no grant path until TASK-0066/0067), so equip cannot be exercised in a real session without a Studio-side grant. There is no preview, so "previews never alter live models" holds trivially. Rejoin persistence rests on the TASK-0060 schema and its specs, not a rejoin test of this task.

| AC | State |
|---|---|
| AC1 equip/remove per ghost, server-validated, compatibility explained, Spectral/Ashen preserved | implemented and tested (specs); Studio not run |
| AC2 visible to other clients, survives rejoin | implemented, not tested in Studio |
| AC3 specs, check.sh, one Sonnet audit, FullLoop | specs and check.sh done; audit see Audits; FullLoop not run (Studio skipped) |

**Studio skipped by jg, 2026-10-18.** No Play session, no two-client check, no FullLoop, no screenshots. Rendering of the skin and aura and the Equip buttons are unverified at runtime.

## Audits
[[AUD-20261018-TASK-0062-01]]: pass (Sonnet). Two minor findings fixed after the audit (a result check and a nil guard in `CosmeticService`); Studio still owed.

## Outcome
