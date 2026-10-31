---
id: TASK-0085
title: "Narrow Viewport HUD Navigation"
type: task
project: GAME-002
status: archived
priority: medium
risk: medium
owner: executor
depends_on: ["TASK-0061"]
branch: task/TASK-0085-Narrow-Viewport-Hud-Navigation
related:
  - "[[Handoff to Codex 2026-10-18]]"
  - "[[AUD-20261018-TASK-0069-02]]"
  - "[[SYS-Haunted-Monetization-UI]]"
created: 2026-10-18
updated: 2026-10-30
tags:
  - workflow/task
---
# Narrow Viewport HUD Navigation

## Goal
Keep HUD and customization navigation inside narrow phone viewports. **Proposed; not approved or started.**

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
- `games/haunted/src/client/UI/Hud.luau`
- `games/haunted/src/client/UI/ShopUI.luau`
- `games/haunted/src/client/UI/MansionUI.luau`

## Acceptance criteria
- [ ] AC1 At actual simulated widths 300, 390 and 520 px, all HUD/navigation controls fit inside the safe area and remain readable/reachable; no left-edge clipping.
- [ ] AC2 Verify Shop/Mansion header-title spacing, filters, details, Back scroll, Buy/Confirm/pending and editor controls on touch and controller without blocking ordinary gameplay.
- [ ] AC3 Record desktop and phone screenshots plus manual-device limits; check.sh passes.

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
