---
id: TASK-0078
title: "Art Loading Failure Recovery"
type: task
project: GAME-002
status: proposed
priority: medium
risk: medium
owner: executor
depends_on: ["TASK-0069"]
branch: task/TASK-0078-Art-Loading-Failure-Recovery
related:
  - "[[Handoff to Codex 2026-10-18]]"
  - "[[AUD-20261018-TASK-0069-02]]"
  - "[[SYS-Haunted-Monetization-UI]]"
created: 2026-10-18
updated: 2026-10-18
tags:
  - workflow/task
---
# Art Loading Failure Recovery

## Goal
Bound art startup failures and recover predictably from missing, partial and late assets. **Proposed; not approved or started.**

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
- `games/haunted/src/server/Services/ArtBakeService.luau`
- `games/haunted/src/client/Art/ArtLoader.luau`
- `games/haunted/src/client/Art/Dressing.luau`

## Acceptance criteria
- [ ] AC1 A timeout covers dispatch as well as completion even when all bake slots stall; expected parts and failure states prevent silent partial success.
- [ ] AC2 An asset becoming ready after an initial timeout can recover through a bounded path; failures use an explicit fallback and retain gameplay.
- [ ] AC3 Overlapping Dressing attaches cannot create duplicate/orphaned visuals; failed-part, delayed-bake and cancellation probes plus timing/memory evidence are recorded; check.sh passes.

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
