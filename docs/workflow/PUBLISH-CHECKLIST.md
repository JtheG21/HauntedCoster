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

## Gate: profile schema v4 cutover (TASK-0150)

Source: [[SYS-Quests-And-XP]] ("Migration and cutover", Codex design review 2026-11-07), [[TASK-0150-MathShow-Quests-XP-Persistence-And-Services]],
jg approval QX-T2S. Same profile store `MathShow_Profiles_v1`. A v3 build treats a v4 value as newer (`isNewerVersion`) and
refuses to write it, both at load and inside an already-running UpdateAsync, so a v3 writer cannot erase v4 xp, daily state
or receipts. A v3 server that is already running keeps its in-memory copy and may still be the last to write a v3-shaped
value only until its first save meets a v4 value: that is why the freeze and drain below are required.

> Keep the publish freeze in force. For every place and test session that can write this profile store (live experience, the private test experience, every Studio session with API access and any Rojo-connected editor), block admission and drain all v3 writers, including shutdown saves. Verify that v3 writers have stopped before enabling any v4 writer; no migration write happens until writer isolation is verified. Record the published build, the drain verification and who verified it before reopening admission. After the first v4 write, rollback requires a build that preserves and understands v4 state (xp, `dailyEpoch`, `playXpDay`, `quests`, `applied` receipts) or keeps profile writes disabled. If writer isolation or drain completion cannot be verified, keep v4 writes disabled.

Before the gate opens, also confirm: the Studio-only clock offset (`MathShowClockOffsetS`) is read only when `RunService:IsStudio()`
(inert in a published server), and no test profile outside the private test experience was written during TASK-0150 testing.

Record for this gate (fill in at release):

| Field | Value |
|---|---|
| Published build (commit, place version) | |
| Places and test sessions that can write the store | |
| Drain verification (how, when) | |
| Verified by | |
| Admission reopened (when, by) | |
| Rollback build that understands v4 | |
