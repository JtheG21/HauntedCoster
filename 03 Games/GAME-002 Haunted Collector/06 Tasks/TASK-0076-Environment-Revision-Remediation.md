---
id: TASK-0076
title: "Environment Revision Remediation"
type: task
project: GAME-002
status: proposed
priority: medium
risk: high
owner: executor
depends_on: ["TASK-0069"]
branch: task/TASK-0076-Environment-Revision-Remediation
related:
  - "[[Handoff to Codex 2026-10-18]]"
  - "[[AUD-20261018-TASK-0069-02]]"
  - "[[SYS-Haunted-Monetization-UI]]"
created: 2026-10-18
updated: 2026-10-18
tags:
  - workflow/task
---
# Environment Revision Remediation

## Goal
Resolve the uncompleted TASK-0044 revision against current merged code. **Proposed; not approved or started.**

## Scope
- **In:** the acceptance criteria below.
- **Out (non-goals):** unrelated gameplay, Robux activation, publishing, uploads and paid APIs.
- **Keep unchanged:** gameplay, income, capacity, rarity and capture rules; server authority and atomic Coin debit/grant.

## Intake
- **Category → workflow, depth:** Environment → [[Map Workflow]], deep.
- **References:** [[3D Model Quality Baseline]], [[3D Model Quality Gallery]] and [[Map References]]; select and open the relevant originals before any visual change.
- **Reuse:** [[Resource Catalog]] inspected; extend local services/rules, Theme and existing Studio scenario harness as appropriate. Production choices remain for intake after approval.
- **Decisions / assumptions / open questions:** jg requested filing this proposal on 2026-10-18, not implementation. Schema, product, balance and visual choices remain human gates. See the consolidated decision list in the handoff.

## Files expected to change
- `games/haunted/src/server/World/Props.luau`
- `games/haunted/src/server/World/GroundPainter.luau`
- `games/haunted/src/server/Services/HabitatService.luau`
- `games/haunted/src/server/World/Habitats/`

## Acceptance criteria
- [ ] AC1 Reproduce and disposition every finding in AUD-20261013-TASK-0044-01 on current code before fixing; do not assume old findings still reproduce.
- [ ] AC2 Verify deterministic random draw behavior, terrain cleanup/generation protection, supported paint heights and collision deviations; preserve approved walk/layout behavior.
- [ ] AC3 Provide the missing hub/habitat/tree captures and reference comparison plus fresh 2-client HauntedTrees results; check.sh passes and jg judges visuals.

## Tests
- **Automated:** `scripts/check.sh`; meaningful specs where the acceptance criteria require them.
- **Studio playtest procedure:** studio-preflight, verified source sync, fresh sessions, isolated data; at most two clients. Record measurements and failures in a new TEST note, including manual checks still outstanding.

## Source reconciliation (2026-10-18)
Commit `3ddc2e6` is already in main and contains several historical code corrections. The earlier handoff interpretation was inaccurate; reproduce current issues, do not blindly reapply that commit. Tree source/config/data match the preserved Wisp branch. See [[RSH-20261018-Delivered-Update-Reconciliation]].

## Risks / notes
Networking/persistence/economy requires the project-mandated strong independent audit after automated and Studio checks; no schema migration is approved here.

---
## Implementation record
Not started. Proposal filed by Codex from the 2026-10-18 handoff and independent source review.

## Audits
Origin: [[AUD-20261018-TASK-0069-02]]. This is evidence for the proposal, not approval of a future implementation.

## Outcome
Planned; awaiting jg approval. No runtime or visual acceptance claimed.
