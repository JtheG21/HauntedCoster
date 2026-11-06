#!/usr/bin/env python3
"""Audit-head binding for the Rg1 workflow (standard library only).

An audit verdict is bound to the commit it measured. A PASS counts for a PR head only when that commit is an
ancestor of the head and nothing changed since it outside non-source paths (the audit and task records, the
documented evidence directories, the task's own note). TASK-0138 was merged with source that changed after its PASS;
this is the rule that stops that.

Used by scripts/orchestrator.py (record-audit, approve-merge, mark-merged) and, on every pull request, by the
`audit-gate` job in .github/workflows/audit-gate.yml:

    python3 scripts/audit_gate.py --head <sha> --branch <name> [--base origin/main] [--draft]

Exit 0 = pass (or not applicable), 1 = the PR head is not covered by a recorded audit, 2 = could not decide.
Git only: it needs no gh, no token and no network beyond the checkout.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path

HEX40 = re.compile(r"^[0-9a-f]{40}$")
VERDICT_LINE = re.compile(r"^\s*(?:[-*>]\s*)?(?:\*\*)?verdict(?:\*\*)?\s*[:=]\s*(?:\*\*)?(pass|fail)\b", re.I | re.M)

# Paths a PR may change after an audit without the audit going stale. The task's own note is added per task.
NON_SOURCE_PREFIXES = ("06 QA/", "tasks/items/", "docs/workflow/evidence/")
# A chore branch that changes nothing under these needs no task or audit.
SOURCE_ROOTS = ("games/", "scripts/")
CODEX = "codex"
AGENT_IDS = {"claude-code", "codex", "claude-design", "task-audit", "claude", "claude-auditor"}


class GateError(Exception):
    pass


def git(root: Path, *args: str) -> subprocess.CompletedProcess:
    try:
        return subprocess.run(["git", "-C", str(root), *args], capture_output=True, text=True)
    except OSError as e:
        raise GateError(f"git is not available: {e}") from e


def show_bytes(root: Path, rev: str, path: str) -> bytes | None:
    """A file's exact bytes at a commit, or None if it is not there."""
    try:
        out = subprocess.run(["git", "-C", str(root), "show", f"{rev}:{path}"], capture_output=True)
    except OSError as e:
        raise GateError(f"git is not available: {e}") from e
    return out.stdout if out.returncode == 0 else None


def commit_exists(root: Path, sha: str) -> bool:
    return git(root, "cat-file", "-e", f"{sha}^{{commit}}").returncode == 0


def ensure_commit(root: Path, sha: str) -> bool:
    """Is the commit here, fetching it from origin once if it is not (a PR head may not be local yet)."""
    if commit_exists(root, sha):
        return True
    git(root, "fetch", "-q", "origin", sha)
    return commit_exists(root, sha)


def is_ancestor(root: Path, ancestor: str, descendant: str) -> bool:
    return git(root, "merge-base", "--is-ancestor", ancestor, descendant).returncode == 0


def changed_files(root: Path, old: str, new: str) -> list[str]:
    out = git(root, "diff", "--name-only", "-z", f"{old}..{new}")
    if out.returncode != 0:
        raise GateError(f"git diff {old[:7]}..{new[:7]} failed: {out.stderr.strip()}")
    return [p for p in out.stdout.split("\0") if p]


def source_changes(files: list[str], note_path: str | None = None) -> list[str]:
    """The files that are NOT allowed to change after an audit."""
    allowed = NON_SOURCE_PREFIXES
    return [f for f in files if not f.startswith(allowed) and f != note_path]


def normalize_identity(name: str | None) -> str:
    return (name or "").strip().lower()


def report_problems(report_text: str, measured_sha: str, verdict: str) -> list[str]:
    """What is wrong with an audit report for this claim: the exact full SHA and a verdict line that matches."""
    problems = []
    if measured_sha not in report_text:
        problems.append(f"the report does not contain the measured SHA {measured_sha}")
    verdicts = [m.group(1).lower() for m in VERDICT_LINE.finditer(report_text)]
    if not verdicts:
        problems.append("the report has no verdict line (e.g. `verdict: pass`)")
    elif any(v != verdict for v in verdicts):
        problems.append(f"the report's verdict line(s) {sorted(set(verdicts))} do not match --verdict {verdict}")
    return problems


def latest_audit(task: dict) -> dict | None:
    """The newest audit made before the merge (post-merge findings are not a verdict on a PR head)."""
    live = [a for a in (task.get("audits") or []) if not a.get("post_merge")]
    return live[-1] if live else None


def check_binding(root: Path, task: dict, head: str) -> list[str]:
    """Why `head` is not covered by this task's recorded audit; an empty list means it is. Non-light tiers only."""
    problems: list[str] = []
    audit = latest_audit(task)
    if audit is None:
        return ["no audit is recorded for this task"]
    if audit.get("result") != "pass":
        return [f"the latest audit is a {audit.get('result')}, not a PASS"]
    measured = audit.get("measured_sha")
    if not measured or not HEX40.match(str(measured)):
        return ["the recorded PASS has no measured_sha (it predates head binding); re-audit and record it again"]
    if not audit.get("auditor"):
        problems.append("the recorded PASS has no auditor")
    if task.get("tier") == "deep" and normalize_identity(audit.get("auditor")) != CODEX:
        problems.append(f"a deep-tier task needs an independent Codex PASS; the auditor recorded is {audit.get('auditor')!r}")
    if not HEX40.match(head):
        return problems + [f"the PR head {head!r} is not a full commit SHA"]
    if not ensure_commit(root, head):
        return problems + [f"the PR head {head} is not in this checkout (fetch it)"]
    if not commit_exists(root, measured):
        return problems + [f"the measured commit {measured} is not in this repository"]
    if not is_ancestor(root, measured, head):
        return problems + [f"the audited commit {measured[:12]} is not an ancestor of the PR head {head[:12]}"]
    offending = source_changes(changed_files(root, measured, head), task.get("note_path"))
    if offending:
        problems.append(
            f"changed since the audited commit {measured[:12]} (audit PASS covers only it): " + ", ".join(sorted(offending))
        )
    report = audit.get("report")
    recorded = audit.get("report_sha256")
    if report and recorded:
        shown = show_bytes(root, head, report)
        if shown is None:
            problems.append(f"the audit report {report} is missing at the PR head")
        elif hashlib.sha256(shown).hexdigest() != recorded:
            problems.append(f"the audit report {report} changed after it was recorded (sha256 differs)")
    return problems


def sha256_file(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def task_for_branch(root: Path, head: str, branch: str) -> dict | None:
    """The task file, read at `head`, whose `branch` is the PR branch."""
    listing = git(root, "ls-tree", "--name-only", head, "tasks/items/")
    for name in listing.stdout.split():
        if not name.endswith(".json"):
            continue
        shown = git(root, "show", f"{head}:{name}")
        try:
            data = json.loads(shown.stdout)
        except json.JSONDecodeError:
            continue
        if data.get("branch") == branch:
            return data
    return None


def gate(root: Path, head: str, branch: str, base: str | None, draft: bool) -> tuple[int, list[str]]:
    """(exit code, message lines) for the PR check."""
    if draft:
        return 0, ["audit-gate: draft PR, not applied (a draft cannot be merged)."]
    if not ensure_commit(root, head):
        return 2, [f"audit-gate: head {head} is not in the checkout; fetch full history."]
    touched: list[str] = []
    if base:
        merge_base = git(root, "merge-base", base, head)
        if merge_base.returncode != 0:
            return 2, [f"audit-gate: no merge base between {base} and {head}; fetch full history."]
        touched = changed_files(root, merge_base.stdout.strip(), head)
    if branch.startswith("chore/") and not any(f.startswith(SOURCE_ROOTS) for f in touched):
        return 0, [f"audit-gate: chore branch {branch} changes no games/ or scripts/ source; nothing to audit."]
    task = task_for_branch(root, head, branch)
    if task is None:
        return 1, [f"audit-gate: no tasks/items/*.json names branch {branch}; a source change needs a task and an audit."]
    if task.get("tier") == "light":
        return 0, [f"audit-gate: {task['id']} is light tier (no audit); approve-merge needs a green check instead."]
    problems = check_binding(root, task, head)
    if problems:
        return 1, [f"audit-gate: {task['id']}: PR head {head[:12]} is not covered by a recorded audit PASS:"] + [
            f"  - {p}" for p in problems
        ]
    audit = latest_audit(task) or {}
    return 0, [
        f"audit-gate: {task['id']}: PASS by {audit.get('auditor')} at {str(audit.get('measured_sha'))[:12]} covers head {head[:12]}."
    ]


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--root", type=Path, default=Path(__file__).resolve().parent.parent)
    p.add_argument("--head", required=True, help="the PR head commit (github.event.pull_request.head.sha)")
    p.add_argument("--branch", required=True, help="the PR branch name (github.head_ref)")
    p.add_argument("--base", help="the base ref to compare against, e.g. origin/main")
    p.add_argument("--draft", action="store_true", help="the PR is a draft: not applied")
    a = p.parse_args(argv)
    try:
        code, lines = gate(a.root, a.head, a.branch, a.base, a.draft)
    except GateError as e:
        code, lines = 2, [f"audit-gate: {e}"]
    print("\n".join(lines))
    return code


if __name__ == "__main__":
    sys.exit(main())
