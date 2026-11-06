---
id: TASK-0139
title: "MathShow Profile Save Remediation (AUD-02 F1-F3)"
type: task
project: GAME-004
status: review
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

## Revision 2 (2026-11-06, Claude): AUD-20261106-TASK-0139-02 F1 + F2
- **Approval S1 (DataStore schema):** jg, Task Audit chat, 2026-11-06 14:53 PT, typed "A" in reply to "A: schema v3 with a save log". Only `version` 2 -> 3 and the new `applied` field changed; store name, key and remotes are unchanged.
- **F1 / 3a, exactly-once:** every save is an op `{sessionId, seq, glyphsDelta}`. `ProfileRules.planSave(stored, op, now)` skips the delta when `applied[sessionId].seq >= seq`. ProfileService retries the same op after any error. The save log is pruned after 7 days and capped at 200.
- **F2 / 3b, nested settings:** known settings keys are overlaid onto a clone of the stored settings. `adopt` sanitizes, and `toPatch`/`toClient` copy only the known keys, so a stray stored key never reaches memory or the client.
- **Studio-only hook:** `MathShowForceSaveErrorAfterCommit`, a workspace attribute that only works when `IsStudio` and `IsServer` are both true.
- **Evidence:** `docs/workflow/evidence/TASK-0139/revision2.txt`, measured at source `61e1eeb`, Studio at `aa2fe41`. 376 specs passed and check.sh is green. Studio checks 1–6 passed in the private test place. API access was ON for the run, then OFF and read back OFF.
- **Not covered:** the leave-save retry loop and BindToClose were not exercised in the engine. If every leave save fails, that op is lost; this was already true before.
- F3 (UserIds/metadata) is a separate task.
