# Audit brief: TASK-#### <title>

One audit per task, read-only: no edits, no state-changing Git, no Studio. The main session writes the `AUD-` note from `99 Templates/T - Audit.md` and runs `record-audit`. The implementer's claims are claims to verify. Fill every section; write "none" rather than deleting one.

**Checkout:** `<path>`. **Diff:** `<base>..<head>`. **Implemented by:** `<owner_agent>`.

## Goal
What the task set out to do, in one sentence, and the question this audit answers.

## In scope
- The diff above, plus callers of what it changed

## Out of scope
- Unrelated code; style that `check.sh` already enforces

## Files expected to change
From the task. Flag any changed file not listed here.
-

## Owned files
Must match `files_owned` for this task in its `tasks/items/` file. Flag edits outside them and edits to another task's shared contracts.
-

## Acceptance criteria and evidence
Verify each one yourself, not from the implementer's report.
| Criterion | Evidence given | Verified? |
|---|---|---|
| | | |

## Focus points
3 to 4 specific risks worth the time.

## Tier
light (no audit) | standard (Sonnet) | deep, security, networking or DataStore (Opus).

## Test steps
1. `scripts/check.sh 2>&1 | tail -30` in the checkout above; report the result.
2. Note which Studio or playtest evidence exists and which is missing. Don't run Studio.

## Approval gates
Confirm the diff crosses none without recorded approval: merge; publish or live changes; Robux or paid APIs; destructive changes; DataStore schema changes; new dependencies.

## Remote-change triple
If a payload changed, verify all three moved together and that the server validates type → range → ownership → rate limit; otherwise "none".
| Remote | Sender | Server handler | Receiver |
|---|---|---|---|
| | | | |

## Report back
Verdict (pass or fail), then findings by severity with file:line, and what wasn't checked.
