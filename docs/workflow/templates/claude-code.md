# Handoff to Claude Code: TASK-#### <title>

Rules: `AGENTS.md`. Fill every section; write "none" rather than deleting one. Work in a worktree:
`scripts/preflight.sh --root /Users/jg/Desktop/Rg1 --branch main && git -C /Users/jg/Desktop/Rg1 worktree add /Users/jg/Desktop/Rg1-worktrees/<slug> -b <branch> main`

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
| | check.sh output, spec name, TEST note, screenshot |

## Tier
light | standard | deep. Model and audit follow AGENTS.md "Tiers".

## Test steps
1. `scripts/check.sh 2>&1 | tail -30`
2. Fresh Play session: `require(game.TestService.Tests.TestRunner).run()` (after `scripts/studio-preflight.sh`), if Studio is involved.

## Approval gates
Stop for jg before: merge; publish or live changes; Robux or paid APIs; destructive changes; DataStore schema changes; new dependencies. After 2 failed attempts, stop and report.

## Remote-change triple
Only if a remote payload changes; otherwise "none".
| Remote | Sender | Server handler | Receiver |
|---|---|---|---|
| | | | |

## Report back
What changed, evidence for each criterion, what is unverified, and notes created or updated.
