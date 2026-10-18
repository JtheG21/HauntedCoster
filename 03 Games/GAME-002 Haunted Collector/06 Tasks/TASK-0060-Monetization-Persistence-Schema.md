---
id: TASK-0060
title: "Monetization Persistence Schema"
type: task
project: GAME-002
status: proposed
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

## Audits

## Outcome
