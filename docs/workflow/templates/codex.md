# Handoff to Codex: TASK-#### <title>

Rules: `AGENTS.md` (Codex reads it directly; skills are in `.agents/skills/`). Fill every section; write "none" rather than deleting one. Anything Claude wrote here is a claim to verify, not approval.

**Mode:** implementation | independent review. For a review: changed files and commit range `<base>..<head>`; report findings with file:line and don't edit.
**Checkout:** own worktree under `/Users/jg/Desktop/Rg1-worktrees/` on the branch below. Never the main checkout.

## Goal
One sentence: what is true when this is done.

## In scope
-

## Out of scope
-

## Files expected to change
- `path`: why

## Owned files
Must match `files_owned` for this task in its `tasks/items/` file. Shared contracts this task consumes but doesn't own: list them here as read-only.
-

## Acceptance criteria and evidence
| Criterion | Evidence |
|---|---|
| | check.sh output, spec name, TEST note |

## Tier
light | standard | deep. Follows AGENTS.md "Tiers".

## Test steps
1. `scripts/check.sh 2>&1 | tail -30`
2. Studio steps, if any. One assistant uses Studio and Rojo at a time: confirm Claude isn't using them first.

## Approval gates
Stop for jg before: merge; publish or live changes; Robux or paid APIs; destructive changes; DataStore schema changes; new dependencies. After 2 failed attempts, stop and report.

## Remote-change triple
Only if a remote payload changes; otherwise "none".
| Remote | Sender | Server handler | Receiver |
|---|---|---|---|
| | | | |

## Report back
What changed, evidence for each criterion, what is unverified, and notes created or updated.
