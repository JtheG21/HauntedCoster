---
id: TASK-0072
title: "Cosmetic Service Behavior Tests"
type: task
project: GAME-002
status: archived
priority: high
risk: high
owner: executor
depends_on: ["TASK-0067"]
branch: task/TASK-0072-Cosmetic-Service-Behavior-Tests
related:
  - "[[Handoff to Codex 2026-10-18]]"
  - "[[AUD-20261018-TASK-0069-02]]"
  - "[[SYS-Haunted-Monetization-UI]]"
created: 2026-10-18
updated: 2026-10-30
tags:
  - workflow/task
---
# Cosmetic Service Behavior Tests

## Goal
Prove service mutations and remote wiring rather than only pure rules. **Proposed; not approved or started.**

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
- `games/haunted/src/server/Services/CosmeticService.luau`
- `games/haunted/src/server/Services/PurchaseService.luau`
- `games/haunted/src/server/Services/EconomyService.luau`
- `games/haunted/tests/scenarios/`

## Acceptance criteria
- [ ] AC1 Exercise equipLook, equipCaptureEffect, equipTheme, claimReward, editDecoration, buy and upgrade fallback using isolated fake profiles/remotes or Studio scenarios.
- [ ] AC2 Assert unchanged state on malformed/unowned/incompatible/insufficient/full/readonly refusals; test rate wrappers, repeated and stale requests, one debit and one grant.
- [ ] AC3 Cover theme removal, decoration storing and notices during upgrades, and successful real wiring; check.sh and fresh-session results are recorded.

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
