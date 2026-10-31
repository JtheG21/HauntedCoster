---
id: TASK-0079
title: "Vacant Plot Decoration Cleanup"
type: task
project: GAME-002
status: archived
priority: medium
risk: medium
owner: executor
depends_on: ["TASK-0065"]
branch: task/TASK-0079-Vacant-Plot-Decoration-Cleanup
related:
  - "[[Handoff to Codex 2026-10-18]]"
  - "[[AUD-20261018-TASK-0069-02]]"
  - "[[SYS-Haunted-Monetization-UI]]"
created: 2026-10-18
updated: 2026-10-30
tags:
  - workflow/task
---
# Vacant Plot Decoration Cleanup

## Goal
Remove departed-owner decoration visuals when a plot becomes vacant. **Proposed; not approved or started.**

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
- `games/haunted/src/server/Services/PlotService.luau`
- `games/haunted/tests/scenarios/`

## Acceptance criteria
- [ ] AC1 Leaving clears decoration instances/lights immediately without deleting saved placements or entitlements.
- [ ] AC2 A second player assigned the same plot sees only their own decorations; the first player gets their saved placements on rejoin.
- [ ] AC3 Fresh 2-client leave/reassign evidence and check.sh pass.

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
