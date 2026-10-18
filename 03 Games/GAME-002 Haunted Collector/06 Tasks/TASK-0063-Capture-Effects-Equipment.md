---
id: TASK-0063
title: "Capture Effects Equipment"
type: task
project: GAME-002
status: ready
priority: medium
risk: medium
owner: executor
depends_on: [TASK-0060, TASK-0061]
branch: task/TASK-0063-Capture-Effects-Equipment
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

# Capture Effects Equipment

## Goal
One equippable capture effect plays at capture without changing any capture rule. Part of the monetization baseline ([[SYS-Haunted-Monetization-UI]]). **Draft: not approved.**

## Scope
- **In:** Equip remote reusing 0062 patterns, the effect hook beside CaptureFinisher, a preview, specs. Reference: vfx_template.
- **Out (non-goals):** anything marked deferred in [[SYS-Haunted-Monetization-UI]]: premium currency, paid convenience, events, gifting, trading, bundles, fixed prices.
- **Keep unchanged:** existing gameplay, income, capacity, rarity and capture rules.

## Intake
- **Category → workflow, depth:** VFX and animation → [[VFX Workflow]], **Standard** (first audit: Sonnet).
- **References:** check `10 References/` for the matching folder at start; UI References is empty.
- **Reuse:** existing services, `Theme.luau` and the TASK-0058 spec style.
- **Decisions / assumptions / open questions:** Reuses the Finisher hooks. Effect visibility and performance limits are set in the note.
- **Measurement:** note `get_usage` context tokens at start and close; log with `record-usage`.

## Acceptance criteria
- [ ] AC1 A per-player capture effect can be equipped and removed, with a replayable preview in the item details.
- [ ] AC2 Cosmetics change nothing about timing, success, the meter or retaliation; asserted by a spec and a Studio check.
- [ ] AC3 check.sh green; one Sonnet audit; VFX rights for any plugin asset checked first (see TASK-0054).

## Tests
- **Automated:** `scripts/check.sh` plus the specs above.
- **Studio playtest procedure:** per the acceptance criteria; run `studio-preflight` first.

## Risks / notes
Persistence, trust boundary and product details are governed by the baseline note; do not invent product IDs or prices.

---
## Implementation record

## Audits

## Outcome
