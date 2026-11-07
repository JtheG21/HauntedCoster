---
id: TASK-0141
title: "MathShow Profile Exactly-Once Saves v2"
type: task
project: GAME-004
status: review
priority: high
risk: high
owner: claude-code
depends_on: []
branch: task/TASK-0141-profile-exactly-once
related:
  - "[[TASK-0139-MathShow-Profile-Save-Remediation]]"
created: 2026-11-06
updated: 2026-11-06
tags:
  - workflow/task
---

# MathShow Profile Exactly-Once Saves v2

## Goal
Redo the TASK-0139 exactly-once save so over-credit is impossible by construction. TASK-0139 was parked after 2/2 failed revisions: the final Codex audit AUD-20261106-TASK-0139-03 found that receipt expiry and eviction allow a replayed op to double-credit, and that v2 writers can erase v3 receipts.

## Scope
- **In:** the design below, after it passes Codex design review.
- **Out (non-goals):** anything before the design review PASS; publishing, merging, the live experience.
- **Keep unchanged:** to be set in the plan.

## Intake
- **Category → workflow, depth:** DataStore code, deep. Registered by jg 2026-11-06 (row K2), backlog only. Branched from `c54123e` (TASK-0139 rev 2 head).
- **Decisions / open questions:** no plan approval yet. No publish checklist exists in the repo; the plan picks its location.

## Design (Codex design review 2026-11-06: changes applied verbatim)
1. Operation and invariant. Persist each glyph delta at most once. Take the delta into an immutable (sessionId, seq, glyphsDelta, createdAt) before yielding, with a unique server-generated session ID and increasing sequence. Keep one save worker per player session. Autosave, debounce, leave, and shutdown signal that worker. New increments stay pending for the next operation. Never return an abandoned or possibly committed delta to pending, and never derive a delta from the displayed total.
2. Retry and ambiguity. Use server-local monotonic elapsed time for the 900-second window. At elapsed time >= 900, start no attempt and return no new write candidate from a replayed callback. Check the deadline at dispatch and inside every UpdateAsync callback. After a call errors having returned any write candidate, mark the operation possibly committed. A later attempt may acknowledge it if the stored receipt covers its sequence. If the receipt is absent or behind, cancel the write and abandon the delta. Preserve this ambiguous state across every entry point. A failure known to have produced no write candidate may retry the unchanged operation within the window, provided no earlier attempt was ambiguous. A successful call may confirm a candidate submitted before the deadline, even if the response arrives after it.
3. Receipt retention and capacity. Check the current operation against the stored receipt before pruning. Keep entries exactly seven days old and prune older ones. At cap, evict only entries strictly older than 900 seconds plus an explicit clock-skew allowance. If space is still unavailable, return a distinct retryable capacity result without changing the stored value or log. Keep the session save-enabled and retain the unchanged operation until capacity opens or the operation expires. A newer stored schema remains a separate memory-only outcome. Receipt age and capacity affect availability. A missing receipt never authorizes an ambiguous delta to be applied again.
4. Abandonment and shutdown. After expiry, mark an active call as overdue and let it settle while the server remains running. Keep its operation and ownership until it returns. A confirmed success acknowledges it. An unresolved result abandons it without recrediting. Log the reason, sequence, delta and whether the outcome is ambiguous once per terminal operation. During shutdown, stop ordinary scheduling and let the same worker drain eligible work with bounded attempts, backoff and a shared local deadline inside Roblox's 30-second budget. At the local deadline, issue no further attempts and report unresolved work as unconfirmed. Keep any already-submitted candidate classified as potentially committed.
5. v3 cutover. Add this release gate to docs/workflow/PUBLISH-CHECKLIST.md and link it from 04 Agents/Workflow.md. "Keep the publish freeze in force. For every place and test session that can write this profile store, block admission and drain all pre-v3 writers, including shutdown saves. Verify that old writers have stopped before enabling any v3 writer. Record the published build, the drain verification and who verified it before reopening admission. After v3 writes begin, rollback requires a build that preserves v3 profiles and receipts. If writer isolation or drain completion cannot be verified, keep v3 writes disabled."
6. Verification. Test elapsed time just below, exactly at, and above 900 seconds. Exercise callback replay across the deadline, a submitted candidate whose response arrives late, ambiguous outcomes with a matching, missing or lower-sequence receipt, known no-candidate failures, receipt expiry and eviction, cap refusal and recovery, clock skew in both directions, two overlapping sessions, and leave/autosave/shutdown contention. Assert that abandoned deltas never reappear under a new sequence and that later increments remain separate. Exercise v2 migration, preservation of existing v3 receipts and refusal of newer schemas. In the private Studio run, use a server-only shortened-window hook guarded by IsStudio() and IsServer(). Record both API setting dialog readbacks and exercise the abandon and shutdown paths.

**Decisions**
- Accepted tradeoff (jg, 2026-11-06): ambiguous + no covering receipt = abandoned delta (under-credit, warn). Key-version fence is out of scope.
- Tunables in ProfileConfig (table.freeze): RETRY_WINDOW_S = 900, CLOCK_SKEW_ALLOWANCE_S = 300 (evict only entries older than 1200 s),
  RECEIPT_TTL_S = 604800, RECEIPT_CAP = 200, SHUTDOWN_DEADLINE_S = 25.

## Implementation (claude-code, attempt 1 of 2)
- Plan approved by jg (row P1, 2026-11-06); started. Holds Studio and Rojo for the P5 pass (both released afterwards).
- Source: `c1f0498` (ProfileConfig, ProfileRules planSave + Ledger, ProfileService single worker, publish gate), `7b8e7d4` (fix found in Studio: a save is confirmed only when UpdateAsync returns the value; a transform error returns nil instead of raising). Final source head `7b8e7d4`.
- Clock: `os.clock()` (creator-docs `libraries/os.yaml`: not moved by system clock adjustments). Hook entry points and every scenario: `docs/workflow/evidence/TASK-0141/studio-pass.txt`.
- Remotes, store name, key and payloads unchanged. Persisted schema: version 3 + `applied` only.
- check.sh ALL CHECKS PASSED; Lune 388 passed. Studio pass on 7b8e7d4: S1–S7 + rejoin PASS; API access readbacks OFF → ON → OFF (images in the evidence folder).
- Draft PR #206 (not merged; no audit recorded by Claude).

## Revision 2 (claude-code, attempt 2 of 2, FINAL): AUD-20261106-TASK-0141-01
- Rows G1–G3 (jg, 2026-11-06). Started with `orchestrator.py start` (changes_requested -> in_progress), `5fb44c2`.
- Source `69004d2`: R1 acknowledging writes nothing; R2 ops carry a frozen `settingsPatch` of changed keys only; R3 the
  patch is dropped when another session's receipt has `at >= createdAtWall - 300`, except receipts this session already saw
  at load at the same or a higher seq (jg chose this load exemption, 2026-11-06: it keeps a server hop's first settings
  change); R4 the ledger records the terminal report (`reportedSeq`); R5 every callback checks the op window and, during
  shutdown, the shared deadline; R6 `ProfileRules.classifyAttempt`. An unconfirmed op's settings go out with the next op,
  dated from their first send. In memory only: `createdAtWall`, `settingsPatch`, `settingsWall`, `reportedSeq`,
  `knownReceipts`. Schema, store, key, remotes and payloads unchanged. The client sees adopted settings at its next
  MenuRequest (no push).
- Specs: the 5 existing cases that asserted an acknowledgement write or a full settings snapshot were updated to R1/R2; 9 new
  cases (R1, R3, skew boundary, load exemption, R2, settings requeue, R4, R5, R6 table). check.sh ALL CHECKS PASSED, Lune
  397 passed, 0 failed.
- Studio (G2): first attempt stopped by jg before API access ON (read back OFF, `rev2/api-access-before-off.jpg`). Second
  attempt on BuildStamp `b495b99` == HEAD (no `games/` change since `69004d2`), synced sizes == disk; API access read back ON
  (`rev2/api-access-on-readback.jpg`); jg: leave it ON from now on, so no OFF step. 11 scenarios PASS: S1 (v2->v3, R2 keeps
  another writer's sfx), S2, S3, (a1) stale-settings acknowledgement writes nothing (music 8 kept, glyph once), (a2) delayed
  retry superseded (music 8, +1 once), S4, S5, S6, rejoin, S4b, (b) shutdown failure then success with the full log through
  "shutdown drain done" (mirrored via a 1 h MemoryStore map), plus S7. Evidence: `docs/workflow/evidence/TASK-0141/rev2/studio-pass.txt`.
  Rojo stopped; place not saved; nothing published.
## Acceptance criteria
See `tasks/items/TASK-0141.json`.

## Outcome
