---
id: TASK-0063
title: "Capture Effects Equipment"
type: task
project: GAME-002
status: done
priority: medium
risk: medium
owner: executor
depends_on: [TASK-0060, TASK-0061, TASK-0069]
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
Executor: Claude (Sonnet 5.5). Context tokens at start 193,292, at close 208,028 (growth 14,736, shared with earlier session work). Weekly plan 95% at start and close.

**Files:** new `Rules/CaptureFxRules.luau` (request parsing, which effect plays now, payload re-check, preview cooldown) and `tests/CaptureFxRules.spec.luau`; `CosmeticService.equipCaptureEffect` plus the `EquipCaptureEffect` remote (rate limited 6 per 8 s, uses `CosmeticRules.setCaptureEffect`); `CaptureService` fires `CaptureFx` to the capturing player only, after `startCarry`, when an owned, listed effect is equipped; new `client/CaptureFx.luau` (burst on a hidden marker, ReduceEffects thins it, local preview with a 1.5 s cooldown); `ShopUI` details view gets Equip/Remove and Preview for owned effects; `Net` registers both names; `Config/CosmeticLooks` and `Config/Catalog` gain one sample, `FxSparks`.

**Checks:** `scripts/check.sh` ALL CHECKS PASSED; Lune specs 223 passed. The earlier CosmeticRules catalog spec now allows capture-effect samples.

**Decisions:** the effect plays after every capture rule has run (judge, apply, endSession, startCarry), so it cannot change timing, success, the meter, retaliation or income; a spec shows equipping changes only `captureEffect`. A stale, unowned or unlisted choice resolves to no effect, not an error. The preview is local and only emits on a hidden marker, so no live model changes. It plays for the capturer only (not other players).

**Limits:** the sample is a particle burst, not an asset, so no plugin VFX rights apply (TASK-0054 check not needed). Nobody can own `FxSparks` yet (no grant path until TASK-0066/0067). The vfx_template reference was not opened. No Studio run yet: AC1 visuals and AC2's Studio check are unverified.

| AC | State |
|---|---|
| AC1 equip/remove, replayable preview | implemented and spec-tested (rules); UI and preview not run in Studio |
| AC2 no change to capture rules | spec asserts equip touches only `captureEffect`; Studio check not run |
| AC3 check.sh, Sonnet audit, VFX rights | check.sh green; audit see Audits; no plugin asset used |

**Studio skipped by jg, 2026-10-18.** No Play session, no capture with the effect equipped, no preview run, no screenshots. The burst's look, the Equip/Preview buttons and AC2's Studio check are unverified at runtime.

## Audits
[[AUD-20261018-TASK-0063-01]]: pass (Sonnet). Nits only; Studio still owed.

## Outcome
One capture effect can be equipped and removed, with a local preview, and plays for the capturing player after every capture rule has run (merge approved by jg, 2026-10-18). Sonnet audit passed. Not verified: Studio (the burst, the Equip/Preview UI, a real capture with the effect equipped). The sample `FxSparks` is a particle burst and cannot be owned until a grant path exists (TASK-0066/0067).
