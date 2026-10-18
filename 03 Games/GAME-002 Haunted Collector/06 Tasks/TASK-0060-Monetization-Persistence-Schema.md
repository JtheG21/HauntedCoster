---
id: TASK-0060
title: "Monetization Persistence Schema"
type: task
project: GAME-002
status: in_progress
priority: medium
risk: medium
owner: executor
depends_on: []
branch: task/TASK-0060-Monetization-Persistence-Schema
related:
  - "[[Task Intake]]"
  - "[[SYS-Haunted-Monetization-UI]]"
  - "[[ADR-0011-Monetization-UI-Scope]]"
created: 2026-10-18
updated: 2026-10-18
tags:
  - workflow/task
---

# Monetization Persistence Schema

## Goal
Entitlements, equipment and reward state live in the profile with one migration, before any UI or purchase can write to them. Part of the monetization baseline ([[SYS-Haunted-Monetization-UI]]). **Draft: not approved.**

## Scope
- **In:** ProfileRules.luau, a new shared Rules/CosmeticRules.luau, profile defaults, the PersistenceService round trip and specs. No UI, no remotes, no commerce.
- **Out (non-goals):** anything marked deferred in [[SYS-Haunted-Monetization-UI]]: premium currency, paid convenience, events, gifting, trading, bundles, fixed prices.
- **Keep unchanged:** existing gameplay, income, capacity, rarity and capture rules.

## Intake
- **Category → workflow, depth:** Systems → [[Systems Workflow]], **Standard** (first audit: Opus).
- **References:** check `10 References/` for the matching folder at start; UI References is empty.
- **Reuse:** existing services, `Theme.luau` and the TASK-0058 spec style.
- **Decisions / assumptions / open questions:** Catalog IDs are stable strings from a shared Catalog config; this task defines the shape and ships an empty catalog. Decoration model: reusable, capped placements (jg, this batch). Themes carry a tier list. Rewards use a Claim state.
- **Measurement:** note `get_usage` context tokens at start and close; log with `record-usage`.

## Acceptance criteria
- [ ] AC1 Profile schema gains independent entitlement inventory, per-ghost skin and aura selections (keyed by monster UID), a per-player capture effect, the mansion theme, decoration inventory and placements, and reward claim state; ProfileRules sanitizes and migrates every field, and the newer-schema read-only guard still holds.
- [ ] AC2 Lune specs cover defaults, sanitization of corrupt values, migration from the current schema, and the grant/equip/remove rules as pure functions; a negative control fails them.
- [ ] AC3 Rejoin persistence is proven in Studio (save, leave, rejoin, state intact); scripts/check.sh green; one Opus first audit (DataStore code).

## Tests
- **Automated:** `scripts/check.sh` plus the specs above.
- **Studio playtest procedure:** per the acceptance criteria; run `studio-preflight` first.

## Risks / notes
Persistence, trust boundary and product details are governed by the baseline note; do not invent product IDs or prices.

---
## Implementation record
- 2026-10-18: started (orchestrator `start`). Context at start: 86,536 tokens (`get_usage`); weekly plan 89% used, 5-hour 19%.
- Schema 2 adds `profile.cosmetics` (entitlements, `ghostLooks[uid] = {skin, aura}`, `captureEffect`, `mansionTheme`, `placements {id,x,z,r}`, `rewardsClaimed`). New `Config/Catalog.luau` (shape only, empty Items/Rewards, size bounds) and `Rules/CosmeticRules.luau` (sanitize, grant, equipLook/removeLook, setCaptureEffect, setTheme with tier check, place/removePlacement with plot bounds, right-angle rotation and per-item cap, claimReward once). Schema-1 profiles migrate by gaining empty cosmetics.
- Design choice (draft, for jg review): entitlements and selections whose ID the current catalog doesn't list are **kept**, not dropped, so a catalog config gap can't destroy owned items. Looks for a released ghost UID are dropped. Theme tier coverage is checked at equip, not at sanitize (an upgrade doesn't silently unequip).
- AC2: `tests/CosmeticRules.spec.luau` (15 tests); `lune run scripts/lune/specs` 188/188. Negative control: removing the species-compatibility check and reverting Schema to 1 failed 2 specs; restored, all pass.
- AC3: published private place (placeId 108419797534540), Studio API access on, build 159a373. Rojo plugin left ProfileRules stale and the two new modules empty; **synced by hand** (source lengths verified equal to disk: 9752/10846/1159 bytes). `Persistence` scenario (now with cosmetics in its fingerprint): write 9/9, read 4/4 ("every saved value survived leave and rejoin"); lock released after shutdown. `scripts/check.sh` green.

## Audits
- [[AUD-20261018-TASK-0060-01]]: pass (Opus), 4 minor + 2 nit findings, optional; none fixed in this task.

## Outcome
Schema 2 cosmetic persistence ships with an empty catalog; AC1-AC3 met (evidence above). Usage: context 86,536 → 182,987 tokens (+96,451), weekly plan 89% → 91%, logged with `record-usage`. Pending jg: merge, and whether to schedule the audit minors (all-or-nothing `claimReward` first).
