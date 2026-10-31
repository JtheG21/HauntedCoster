---
id: TASK-0077
title: "Monetization Decision Packet"
type: task
project: GAME-002
status: archived
priority: medium
risk: low
owner: executor
depends_on: ["TASK-0068"]
branch: task/TASK-0077-Monetization-Decision-Packet
related:
  - "[[Handoff to Codex 2026-10-18]]"
  - "[[AUD-20261018-TASK-0069-02]]"
  - "[[SYS-Haunted-Monetization-UI]]"
created: 2026-10-18
updated: 2026-10-30
tags:
  - workflow/task
---
# Monetization Decision Packet

## Goal
Collect jg decisions without approving prices, schemas, assets or Robux implementation. **Proposed; not approved or started.**

## Scope
- **In:** the acceptance criteria below.
- **Out (non-goals):** unrelated gameplay, Robux activation, publishing, uploads and paid APIs.
- **Keep unchanged:** gameplay, income, capacity, rarity and capture rules; server authority and atomic Coin debit/grant.

## Intake
- **Category → workflow, depth:** Systems → [[Systems Workflow]], light.
- **References:** [[Reference_Code_Index]]; adapt the existing local rules/service and scenario patterns. No external implementation is adopted by this proposal.
- **Reuse:** [[Resource Catalog]] inspected; extend local services/rules, Theme and existing Studio scenario harness as appropriate. Production choices remain for intake after approval.
- **Decisions / assumptions / open questions:** jg requested filing this proposal on 2026-10-18, not implementation. Schema, product, balance and visual choices remain human gates. See the consolidated decision list in the handoff.

## Files expected to change
- `03 Games/GAME-002 Haunted Collector/06 Tasks/TASK-0077-Monetization-Decision-Packet.md`

## Acceptance criteria
- [ ] AC1 One decision packet covers measured-income Coin prices, forced save policy, milestone roster/reward mapping including SpiderWoodland/Settlement, decoration grid/fine/margin/caps, and visual approval.
- [ ] AC2 Include ADR-0013 options and all seven questions: mechanism; per-item/bundles scope; Robux/regional prices; Listed; publishing/creator; dual-currency race; receipt storage and two-server safety.
- [ ] AC3 All unanswered choices remain open; recommendations are labelled; no product IDs, paid calls, publishing, code or schema changes occur; check.sh passes.

## Tests
- **Automated:** `scripts/check.sh`; meaningful specs where the acceptance criteria require them.
- **Studio playtest procedure:** studio-preflight, verified source sync, fresh sessions, isolated data; at most two clients. No runtime change is proposed; document review is the test.

## Risks / notes
Use the depth-tier audit rules after implementation. Human merge approval remains required.

---
## Implementation record
Not started. Proposal filed by Codex from the 2026-10-18 handoff and independent source review.

## Audits
Origin: [[AUD-20261018-TASK-0069-02]]. This is evidence for the proposal, not approval of a future implementation.

## Outcome
Planned; awaiting jg approval. No runtime or visual acceptance claimed.
