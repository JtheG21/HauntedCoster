---
id: TASK-0070
title: "Decoration Load Revalidation"
type: task
project: GAME-002
status: proposed
priority: high
risk: high
owner: executor
depends_on: ["TASK-0065"]
branch: task/TASK-0070-Decoration-Load-Revalidation
related:
  - "[[Handoff to Codex 2026-10-18]]"
  - "[[AUD-20261018-TASK-0069-02]]"
  - "[[SYS-Haunted-Monetization-UI]]"
created: 2026-10-18
updated: 2026-10-18
tags:
  - workflow/task
---
# Decoration Load Revalidation

## Goal
Revalidate persisted decoration footprints at the loaded house tier before rendering. **Proposed; not approved or started.**

## Scope
- **In:** the acceptance criteria below.
- **Out (non-goals):** unrelated gameplay, Robux activation, publishing, uploads and paid APIs.
- **Keep unchanged:** gameplay, income, capacity, rarity and capture rules; server authority and atomic Coin debit/grant.

## Intake
- **Category → workflow, depth:** Systems → [[Systems Workflow]], deep.
- **References:** [[Reference_Code_Index]]; adapt the existing local rules/service and scenario patterns. No external implementation is adopted by this proposal.
- **Reuse:** [[Resource Catalog]] inspected; extend local services/rules, Theme and existing Studio scenario harness as appropriate. Production choices remain for intake after approval.
- **Decisions / assumptions / open questions:** jg requested filing this proposal on 2026-10-18, not implementation. Schema, product, balance and visual choices remain human gates. See the consolidated decision list in the handoff.

## Files expected to change
- `games/haunted/src/shared/Rules/CosmeticRules.luau`
- `games/haunted/src/shared/Rules/ProfileRules.luau`
- `games/haunted/src/shared/Rules/PlacementRules.luau`
- `games/haunted/src/server/Services/PlotService.luau`

## Acceptance criteria
- [ ] AC1 Saved placements in house, pen, exhibit, track, entrance or margin keep-outs are stored safely before rendering; entitlements remain owned.
- [ ] AC2 Valid placements survive save/load unchanged at tiers 0–2 and every plot orientation; malformed and boundary data have meaningful specs.
- [ ] AC3 Repairs are reported; check.sh and Studio rejoin evidence pass; schema changes, if needed, require jg approval.

## Tests
- **Automated:** `scripts/check.sh`; meaningful specs where the acceptance criteria require them.
- **Studio playtest procedure:** studio-preflight, verified source sync, fresh sessions, isolated data; at most two clients. Record measurements and failures in a new TEST note, including manual checks still outstanding.

## Risks / notes
Networking/persistence/economy requires the project-mandated strong independent audit after automated and Studio checks; no schema migration is approved here.

---
## Implementation record
Not started. Proposal filed by Codex from the 2026-10-18 handoff and independent source review.

## Audits
Origin: [[AUD-20261018-TASK-0069-02]]. This is evidence for the proposal, not approval of a future implementation.

## Outcome
Planned; awaiting jg approval. No runtime or visual acceptance claimed.
