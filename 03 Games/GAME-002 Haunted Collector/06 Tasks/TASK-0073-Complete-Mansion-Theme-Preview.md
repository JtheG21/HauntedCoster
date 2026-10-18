---
id: TASK-0073
title: "Complete Mansion Theme Preview"
type: task
project: GAME-002
status: proposed
priority: medium
risk: medium
owner: executor
depends_on: ["TASK-0064"]
branch: task/TASK-0073-Complete-Mansion-Theme-Preview
related:
  - "[[Handoff to Codex 2026-10-18]]"
  - "[[AUD-20261018-TASK-0069-02]]"
  - "[[SYS-Haunted-Monetization-UI]]"
created: 2026-10-18
updated: 2026-10-18
tags:
  - workflow/task
---
# Complete Mansion Theme Preview

## Goal
Provide a complete exterior preview before theme acquisition. **Proposed; not approved or started.**

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
- `games/haunted/src/client/UI/ShopUI.luau`
- `games/haunted/src/client/Art/ArtLoader.luau`

## Acceptance criteria
- [ ] AC1 Preview shows the complete supported house exterior, all tinted regions and truthful tier coverage before purchase.
- [ ] AC2 Preview never mutates the owned house, profile, gameplay or live models; closing/cancel restores the previous screen and scroll.
- [ ] AC3 Desktop, controller and 300–520 px layouts are verified; physical-device limits remain explicit; check.sh passes.

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
