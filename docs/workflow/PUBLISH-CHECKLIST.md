# Publish checklist

Release gates that must hold before any MathShow build is published. Publishing itself always needs jg's explicit approval
(AGENTS.md "Approval gates"); this checklist does not grant it. Add a gate here when a task leaves a release condition.

## Gate: profile schema v3 cutover (TASK-0141)

Source: [[TASK-0141-MathShow-Profile-Exactly-Once-Saves-v2]], Codex design review 2026-11-06, item 5. It carries forward
the TASK-0138 release requirement (shut down old servers before the first publish) and AUD-20261106-TASK-0139-03 F2
(a pre-v3 writer can erase v3 receipts). Applies to the profile store `MathShow_Profiles_v1`.

> Keep the publish freeze in force. For every place and test session that can write this profile store, block admission and drain all pre-v3 writers, including shutdown saves. Verify that old writers have stopped before enabling any v3 writer. Record the published build, the drain verification and who verified it before reopening admission. After v3 writes begin, rollback requires a build that preserves v3 profiles and receipts. If writer isolation or drain completion cannot be verified, keep v3 writes disabled.

Record for this gate (fill in at release):

| Field | Value |
|---|---|
| Published build (commit, place version) | |
| Places and test sessions that can write the store | |
| Drain verification (how, when) | |
| Verified by | |
| Admission reopened (when, by) | |
