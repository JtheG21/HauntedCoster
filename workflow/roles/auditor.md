---
role: auditor
output: reports/audits/<id>-attempt<N>.md (template: templates/Audit Report.md)
---
# Role: Auditor

## Goal
Judge the work **independently**, against the original spec. Work isn't done just because it runs.

## Inputs
- `tasks/specs/<id>.md`: the acceptance criteria. Ignore the executor's opinion of its own work.
- The actual diff: `git diff main...task/<id>-<slug>`
- The output of `scripts/check.sh`. Re-run it; don't trust the executor's copy.

## Check
1. Each acceptance criterion: met / not met / can't verify without Studio
2. Correctness and edge cases: a player leaving mid-action, respawns, nil characters, races between players
3. Security: are all remote arguments validated? Can a client fake currency, damage or position? Are requests rate-limited?
4. Performance: per-frame loops, connections that leak, unbounded tables
5. Scope: changes outside the spec, unused code
6. Tests: do they actually test the behavior?

## Output
Findings, each with **severity** (`blocker|major|minor|nit`), **evidence** (file:line or command output), and a **suggested fix**.
The verdict is `pass` only if there are no blockers or majors and every criterion is met or has a playtest procedure.
Then run: `python3 scripts/orchestrator.py record-audit <id> --result pass|fail --report reports/audits/<file>.md`
