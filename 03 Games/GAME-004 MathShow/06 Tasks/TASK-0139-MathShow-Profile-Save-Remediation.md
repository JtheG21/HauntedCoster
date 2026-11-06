---
id: TASK-0139
title: "MathShow Profile Save Remediation (AUD-02 F1-F3)"
type: task
project: GAME-004
status: changes_requested
priority: high
risk: high
owner: claude-code
depends_on: []
branch: task/TASK-0139-profile-remediation
related:
  - "[[TASK-0138-MathShow-Lifetime-Glyph-Total]]"
  - "[[AUD-20261103-TASK-0138-02]]"
created: 2026-11-05
updated: 2026-11-06
tags:
  - workflow/task
---

# MathShow Profile Save Remediation (AUD-02 F1-F3)

## Goal
Fix the two high findings of the post-merge Codex audit [[AUD-20261103-TASK-0138-02]] on the merged TASK-0138 profile code: unknown stored fields deleted by the save transform (F1) and lifetime increments lost by max-merge across overlapping sessions (F2); and answer the evidence gap (F3).

## Scope
- **In:** `ProfileRules.merge` (preserve unknown stored fields, additive glyph delta, newer-version refusal), `ProfileService` save path (delta bookkeeping, refused write -> memory-only), `GlyphService` only if the API changes, specs, evidence.
- **Out:** schema or key changes, a session lock, other profile fields, data wipes, the live experience, publishing, merging.
- **Keep unchanged:** store name, key scheme, save cadence, retry and memory-only behaviour, no remote change.

## Intake
- **Category, depth:** DataStore code, deep. References: none relevant.
- **Decisions:** started on jg's chat instruction 2026-11-05 ("reaudit and make sure its passing if not fix it up until it passes"). No schema change is made; an operation-id field would need fresh approval.

## Acceptance criteria
See `tasks/items/TASK-0139.json`.

## Tests
- **Automated:** `scripts/check.sh`, `ProfileRules.spec` (interleaving, newer-version, unknown-field cases).
