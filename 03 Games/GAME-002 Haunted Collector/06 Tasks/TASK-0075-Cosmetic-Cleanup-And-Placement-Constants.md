---
id: TASK-0075
title: "Cosmetic Cleanup And Placement Constants"
type: task
project: GAME-002
status: proposed
priority: medium
risk: medium
owner: executor
depends_on: ["TASK-0065", "TASK-0067"]
branch: task/TASK-0075-Cosmetic-Cleanup-And-Placement-Constants
related:
  - "[[Handoff to Codex 2026-10-18]]"
  - "[[AUD-20261018-TASK-0069-02]]"
  - "[[SYS-Haunted-Monetization-UI]]"
created: 2026-10-18
updated: 2026-10-18
tags:
  - workflow/task
---
# Cosmetic Cleanup And Placement Constants

## Goal
Reduce duplicate messages/notifications and derive placement geometry from current config. **Proposed; not approved or started.**

## Scope
- **In:** the acceptance criteria below.
- **Out (non-goals):** unrelated gameplay, Robux activation, publishing, uploads and paid APIs.
- **Keep unchanged:** gameplay, income, capacity, rarity and capture rules; server authority and atomic Coin debit/grant.

## Intake
- **Category → workflow, depth:** Systems → [[Systems Workflow]], standard.
- **References:** [[Reference_Code_Index]]; adapt the existing local rules/service and scenario patterns. No external implementation is adopted by this proposal.
- **Reuse:** [[Resource Catalog]] inspected; extend local services/rules, Theme and existing Studio scenario harness as appropriate. Production choices remain for intake after approval.
- **Decisions / assumptions / open questions:** jg requested filing this proposal on 2026-10-18, not implementation. Schema, product, balance and visual choices remain human gates. See the consolidated decision list in the handoff.

## Files expected to change
- `games/haunted/src/client/UI/ShopUI.luau`
- `games/haunted/src/server/Services/CosmeticService.luau`
- `games/haunted/src/shared/Rules/PlacementRules.luau`

## Acceptance criteria
- [ ] AC1 Consolidate duplicate banner/refusal presentation without changing user-facing refusal meanings or ownership behavior.
- [ ] AC2 Replace hard-coded entrance keep-out z extents with verified layout data and constrain firstSpot scanning to usable bounds; add boundary evidence.
- [ ] AC3 Remove only proven redundant dirty notifications; state updates, refusal snapshots and toasts remain correct; check.sh and Studio smoke checks pass.

## Tests
- **Automated:** `scripts/check.sh`; meaningful specs where the acceptance criteria require them.
- **Studio playtest procedure:** studio-preflight, verified source sync, fresh sessions, isolated data; at most two clients. Record measurements and failures in a new TEST note, including manual checks still outstanding.

## Risks / notes
Use the depth-tier audit rules after implementation. Human merge approval remains required.

---
## Implementation record
Not started. Proposal filed by Codex from the 2026-10-18 handoff and independent source review.

## Audits
Origin: [[AUD-20261018-TASK-0069-02]]. This is evidence for the proposal, not approval of a future implementation.

## Outcome
Planned; awaiting jg approval. No runtime or visual acceptance claimed.
