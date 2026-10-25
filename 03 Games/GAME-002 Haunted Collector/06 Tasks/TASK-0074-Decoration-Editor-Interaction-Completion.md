---
id: TASK-0074
title: "Decoration Editor Interaction Completion"
type: task
project: GAME-002
status: proposed
priority: medium
risk: medium
owner: executor
depends_on: ["TASK-0065", "TASK-0071"]
branch: task/TASK-0074-Decoration-Editor-Interaction-Completion
related:
  - "[[Handoff to Codex 2026-10-18]]"
  - "[[AUD-20261018-TASK-0069-02]]"
  - "[[SYS-Haunted-Monetization-UI]]"
created: 2026-10-18
updated: 2026-10-18
tags:
  - workflow/task
---
# Decoration Editor Interaction Completion

## Goal
Agree and complete the direct placement interaction gap described in the handoff. **Proposed; not approved or started.**

## Scope
- **In:** the acceptance criteria below.
- **Out (non-goals):** unrelated gameplay, Robux activation, publishing, uploads and paid APIs.
- **Keep unchanged:** gameplay, income, capacity, rarity and capture rules; server authority and atomic Coin debit/grant.

## Intake
- **Category → workflow, depth:** UI → [[UI Workflow]], standard.
- **References:** [[UI References]], [[REF-UI-004-Illustrated-Halloween-Shop]] and [[SYS-Haunted-Monetization-UI]]; open originals and run reference-brief before implementation.
- **Reuse:** [[Resource Catalog]] inspected; extend local services/rules, Theme and existing Studio scenario harness as appropriate. Production choices remain for intake after approval.
- **Decisions / assumptions / open questions:** jg requested filing this proposal on 2026-10-18, not implementation. Schema, product, balance and visual choices remain human gates. See the consolidated decision list in the handoff.

## Files expected to change
- `games/haunted/src/client/UI/DecorEditor.luau`
- `games/haunted/src/client/UI/ShopUI.luau`
- `games/haunted/src/shared/Rules/PlacementRules.luau`

## Acceptance criteria
- [ ] AC1 Before implementation, compare the approved baseline with the handoff and confirm whether drag/direct placement is required; do not infer an approved control design.
- [ ] AC2 If approved, direct placement retains grid, bounded fine adjustment, rotation, valid/invalid feedback, Confirm/Cancel/Move/Store/Exit and stable target identity.
- [ ] AC3 Server validation stays authoritative; cancellation preserves previous placement; touch/controller/desktop journeys are evidenced; check.sh passes.

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
