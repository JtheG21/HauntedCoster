---
id: TASK-0066
title: "Journal Collection Rewards"
type: task
project: GAME-002
status: approved
priority: medium
risk: medium
owner: executor
depends_on: [TASK-0060, TASK-0061]
branch: task/TASK-0066-Journal-Collection-Rewards
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

# Journal Collection Rewards

## Goal
Journal milestones can be claimed exactly once and the reward appears in Owned. Part of the monetization baseline ([[SYS-Haunted-Monetization-UI]]). **Draft: not approved.**

## Scope
- **In:** Journal UI additions, a reward service and rules, specs. Milestones need jg's review.
- **Out (non-goals):** anything marked deferred in [[SYS-Haunted-Monetization-UI]]: premium currency, paid convenience, events, gifting, trading, bundles, fixed prices.
- **Keep unchanged:** existing gameplay, income, capacity, rarity and capture rules.

## Intake
- **Category → workflow, depth:** UI and graphics → [[UI Workflow]], **Standard** (first audit: Sonnet).
- **References:** check `10 References/` for the matching folder at start; UI References is empty.
- **Reuse:** existing services, `Theme.luau` and the TASK-0058 spec style.
- **Decisions / assumptions / open questions:** Decision (jg, this batch): claim button, not automatic grant.
- **Measurement:** note `get_usage` context tokens at start and close; log with `record-usage`.

## Acceptance criteria
- [ ] AC1 The Journal shows habitat completion, rare natural-variant discoveries and Bestiary milestones with Eligible and Claimed states; a Claim action grants once on the server and cannot repeat.
- [ ] AC2 Milestone definitions come from the real species and habitat roster, written into the note; a paid skin never completes a discovery.
- [ ] AC3 Specs for eligibility, single grant and replay; check.sh green; one Sonnet audit.

## Tests
- **Automated:** `scripts/check.sh` plus the specs above.
- **Studio playtest procedure:** per the acceptance criteria; run `studio-preflight` first.

## Risks / notes
Persistence, trust boundary and product details are governed by the baseline note; do not invent product IDs or prices.

---
## Implementation record
Executor: Claude (Sonnet 5.5). Context tokens at start 250,278, at close 272,555 (growth 22,277, shared with earlier session work). Weekly plan 96% at start and close.

**Milestones (DRAFT, need jg's review; defined in `Config/Milestones.luau`, rewards in `Catalog.Rewards` with the same ID):**

| ID | Earned by | Reward (sample item) |
|---|---|---|
| `bestiary_half` | caught 2 of the 4 species (Wisp, Hound, Gentleman, BellWraith) | FxSparks |
| `bestiary_all` | caught all 4 species | ThemeMoonlit |
| `hab_Cemetery` | caught every species that spawns in the Ghost Cemetery | SkinMoss |
| `hab_Woodland` | caught every species that spawns in the Cursed Woodland | AuraEmbers |
| `var_Spectral` | discovered a Spectral ghost on any species | AuraEmbers |
| `var_Ashen` | discovered an Ashen ghost (Crypt only) | SkinMoss |

SpiderWoodland and Settlement have no habitat milestone yet. The sample rewards are placeholders: duplicates simply re-grant an owned item.

**Files:** new `Config/Milestones.luau`; new `Rules/MilestoneRules.luau` (roster from the real species and habitat tables, progress, eligibility, the Locked/Eligible/Claimed status, parse and messages) and `tests/MilestoneRules.spec.luau`; `CosmeticService.claimReward` plus the `ClaimReward` remote (rate limited 4 per 8 s; eligibility re-checked server-side from the saved journal; `CosmeticRules.claimReward` is all-or-nothing and refuses a second claim; a toast points to Shop > Owned); `JournalUI` gets a "Collection rewards" section with progress, Claim and Claimed; `Catalog.Rewards` holds the six rewards; `CosmeticRules.spec` now checks rewards grant something and carry no price; `Net` registers `ClaimReward`.

**Checks:** `scripts/check.sh` ALL CHECKS PASSED; Lune specs 240 passed. A spec checks every milestone against the real species, habitat and variant tables and every reward against the catalog.

**Decisions:** eligibility reads only the journal (written by capture), so no skin or purchase can complete a discovery; a spec grants every cosmetic and asserts nothing becomes eligible. "Seen" does not count, only "caught". Claiming is a button, not automatic (jg's decision).

**Limits:** the milestone list and rewards need jg's review. The reward appears in Owned through the existing ownership list, but the Shop's "earnable" label now shows for these items. No Studio run: the Journal section layout, the Claim round trip and the toast are unverified.

| AC | State |
|---|---|
| AC1 states and a single server grant | implemented and spec-tested (Eligible, Claimed, replay refused); UI not run in Studio |
| AC2 definitions from the real roster, written here; no paid skin completes a discovery | met (table above; specs) |
| AC3 specs, check.sh, Sonnet audit | specs and check.sh done; audit see Audits |

**Studio skipped by jg, 2026-10-18.** No Play session, no Claim round trip, no screenshots. The Journal section layout, the Claim button and the toast are unverified at runtime.

## Audits
[[AUD-20261018-TASK-0066-01]]: pass (Sonnet). No blocker; the reward mapping needs jg's review and Studio is still owed.

## Outcome
