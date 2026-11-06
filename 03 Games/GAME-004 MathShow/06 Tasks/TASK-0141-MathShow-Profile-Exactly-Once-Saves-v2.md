---
id: TASK-0141
title: "MathShow Profile Exactly-Once Saves v2"
type: task
project: GAME-004
status: in_progress
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

## Acceptance criteria
See `tasks/items/TASK-0141.json`.

## Outcome
