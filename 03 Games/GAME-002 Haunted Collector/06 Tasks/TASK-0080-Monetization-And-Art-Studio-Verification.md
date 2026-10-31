---
id: TASK-0080
title: "Monetization And Art Studio Verification"
type: task
project: GAME-002
status: archived
priority: medium
risk: high
owner: executor
depends_on: ["TASK-0069", "TASK-0067"]
branch: task/TASK-0080-Monetization-And-Art-Studio-Verification
related:
  - "[[Handoff to Codex 2026-10-18]]"
  - "[[AUD-20261018-TASK-0069-02]]"
  - "[[SYS-Haunted-Monetization-UI]]"
created: 2026-10-18
updated: 2026-10-30
tags:
  - workflow/task
---
# Monetization And Art Studio Verification

## Goal
Complete outstanding runtime, rejoin, replication and visual evidence from the handoff. **Proposed; not approved or started.**

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
- `games/haunted/tests/scenarios/`

## Acceptance criteria
- [ ] AC1 Run every outstanding row of TEST-20261018-01 after preflight and module-content sync verification; record exact results and screenshots, never mark a source inference as runtime pass.
- [ ] AC2 Use memory-only isolated profiles for exploit/setup shortcuts; prove rejoin separately in an explicitly approved isolated persistent test namespace, without live data writes.
- [ ] AC3 FullLoop, ExploitProbe, fresh Server specs and two-client appearance/leave behavior are evidenced; phone/desktop shots, bake time and memory are recorded; real device gaps stay explicit.

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
