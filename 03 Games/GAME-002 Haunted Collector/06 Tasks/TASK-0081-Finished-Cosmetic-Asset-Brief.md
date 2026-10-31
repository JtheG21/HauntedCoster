---
id: TASK-0081
title: "Finished Cosmetic Asset Brief"
type: task
project: GAME-002
status: archived
priority: medium
risk: medium
owner: executor
depends_on: ["TASK-0069"]
branch: task/TASK-0081-Finished-Cosmetic-Asset-Brief
related:
  - "[[Handoff to Codex 2026-10-18]]"
  - "[[AUD-20261018-TASK-0069-02]]"
  - "[[SYS-Haunted-Monetization-UI]]"
created: 2026-10-18
updated: 2026-10-30
tags:
  - workflow/task
---
# Finished Cosmetic Asset Brief

## Goal
Define finished art replacements for the placeholder catalog through reference-first approval. **Proposed; not approved or started.**

## Scope
- **In:** the acceptance criteria below.
- **Out (non-goals):** unrelated gameplay, Robux activation, publishing, uploads and paid APIs.
- **Keep unchanged:** gameplay, income, capacity, rarity and capture rules; server authority and atomic Coin debit/grant.

## Intake
- **Category → workflow, depth:** 3D asset planning → [[Asset Workflow]], standard.
- **References:** [[3D Model Quality Baseline]], [[3D Model Quality Gallery]] and [[Map References]]; select and open the relevant originals before any visual change.
- **Reuse:** [[Resource Catalog]] inspected; extend local services/rules, Theme and existing Studio scenario harness as appropriate. Production choices remain for intake after approval.
- **Decisions / assumptions / open questions:** jg requested filing this proposal on 2026-10-18, not implementation. Schema, product, balance and visual choices remain human gates. See the consolidated decision list in the handoff.

## Files expected to change
- `03 Games/GAME-002 Haunted Collector/06 Tasks/TASK-0081-Finished-Cosmetic-Asset-Brief.md`

## Acceptance criteria
- [ ] AC1 Select relevant baseline/gallery originals and record positive and rejected IDs; identify target silhouette, materials, scale and in-game readability for each sample category.
- [ ] AC2 jg approves a coherent concept and production scope before modeling; placeholders are never labelled final or used as the quality floor.
- [ ] AC3 Produce scoped per-asset follow-ups with matched-view comparison criteria, neutral/game lighting and gameplay budgets; no uploads or paid generation.

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
