#!/usr/bin/env python3
"""Audit-head gate for the Rg1 workflow (standard library only, Git only).

Decides whether a PR head may merge. Every input is read from immutable Git objects at decision time:

- **The verdict comes from the report**, not from the task JSON. The decisive report is the newest `06 QA/` report whose
  frontmatter names the task; its `verdict`, `reviewed_commit` and `reviewer` decide. The JSON `audits` list is an
  index only: any disagreement between it and the report refuses.
- **Reports are immutable.** Exactly one commit adds each report, and its blob at the head equals the blob at that
  commit. A changed report, or a second report with the same audit id, refuses.
- **Tier, owner, note and branch are pinned** to the task registration on the PR base (or, for a new task, the commit
  that added its JSON). Any change to them on the branch refuses.
- **Paths after the audit** are read with `git diff --raw --no-renames`, so both sides of a rename count, and only
  regular files in `06 QA/` (.md), `tasks/items/` (.json), `docs/workflow/evidence/` and the task's one linked note
  (.md) may change. Directory matching is per path component; symlinks, submodules and mode changes refuse.
- **Standard and deep are the same**: a PASS from a listed independent auditor (INDEPENDENT_AUDITORS) that is not the
  task's owner. Light tier needs no audit here; approve-merge then needs green checks.
- `status` is never read.

CI runs this file from the BASE checkout against the PR head as data (.github/workflows/audit-gate.yml):

    python3 -I scripts/audit_gate.py --root <pr data checkout> --head <sha> --branch <name> --base <base sha> [--draft]

Exit 0 = pass (or not applicable), 1 = refused, 2 = could not decide (also a refusal).
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path, PurePosixPath

HEX40 = re.compile(r"^[0-9a-f]{40}$")
TASK_ID = re.compile(r"^TASK-\d{4}$")
AUDIT_ID = re.compile(r"^[A-Za-z0-9][A-Za-z0-9_-]*$")
FRONTMATTER = re.compile(r"\A---\r?\n(.*?)\r?\n---\r?\n", re.S)
FM_LINE = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*):[ \t]*(.*?)[ \t]*$")

QA_DIR = ("06 QA",)
# Directories a PR may change after an audit, with the one extension allowed there (None = any).
RECORD_DIRS: dict[tuple[str, ...], str | None] = {
    QA_DIR: ".md",
    ("tasks", "items"): ".json",
    ("docs", "workflow", "evidence"): None,
}
# A chore branch that touches none of these needs no task or audit.
CHORE_SOURCE_DIRS = ("games", "scripts", ".github")
CHORE_SOURCE_FILES = (".gitmodules", ".gitattributes")
REGULAR, SYMLINK, GITLINK, ABSENT = "100644", "120000", "160000", "000000"
PINNED_FIELDS = ("id", "branch", "tier", "owner_agent", "note_path")
CODEX = "codex"
INDEPENDENT_AUDITORS = frozenset({CODEX})
AGENT_IDS = {"claude-code", "codex", "claude-design", "task-audit", "claude", "claude-auditor"}

Entry = tuple[str, str, str, str]  # (status, old mode, new mode, path)


class GateError(Exception):
    pass


# ---- git -----------------------------------------------------------------------------------------------------------

def _run(root: Path, args: list[str], text: bool = True) -> subprocess.CompletedProcess:
    try:
        return subprocess.run(["git", "-C", str(root), "--literal-pathspecs", *args], capture_output=True, text=text)
    except OSError as e:
        raise GateError(f"git is not available: {e}") from e


def git(root: Path, *args: str) -> subprocess.CompletedProcess:
    return _run(root, list(args))


def git_ok(root: Path, *args: str) -> str:
    out = git(root, *args)
    if out.returncode != 0:
        raise GateError(f"git {' '.join(args[:2])} failed: {out.stderr.strip()}")
    return out.stdout


def show_bytes(root: Path, rev: str, path: str) -> bytes | None:
    """A file's exact bytes at a commit, or None if it is not there."""
    out = _run(root, ["show", "--no-textconv", f"{rev}:{path}"], text=False)
    return out.stdout if out.returncode == 0 else None


def tree_entry(root: Path, rev: str, path: str) -> tuple[str, str, str] | None:
    """(mode, type, object) of one path at a commit, or None."""
    for rec in git_ok(root, "ls-tree", "-z", rev, "--", path).split("\0"):
        if "\t" in rec:
            meta, name = rec.split("\t", 1)
            if name == path:
                mode, kind, obj = meta.split()
                return mode, kind, obj
    return None


def commit_exists(root: Path, sha: str) -> bool:
    return git(root, "cat-file", "-e", f"{sha}^{{commit}}").returncode == 0


def ensure_commit(root: Path, sha: str) -> bool:
    """Is the commit here, fetching it from origin once if it is not (a PR head may not be local yet)."""
    if commit_exists(root, sha):
        return True
    git(root, "fetch", "-q", "--no-tags", "origin", sha)
    return commit_exists(root, sha)


def resolve_commit(root: Path, rev: str) -> str | None:
    out = git(root, "rev-parse", "--verify", "-q", f"{rev}^{{commit}}")
    return out.stdout.strip() if out.returncode == 0 else None


def is_ancestor(root: Path, ancestor: str, descendant: str) -> bool:
    return git(root, "merge-base", "--is-ancestor", ancestor, descendant).returncode == 0


def diff_entries(root: Path, old: str, new: str) -> list[Entry]:
    """Every change old..new. --no-renames: a rename is a delete plus an add, so both sides are judged."""
    out = git(root, "diff", "--raw", "--no-renames", "--no-abbrev", "--no-ext-diff", "-z", old, new)
    if out.returncode != 0:
        raise GateError(f"git diff {old[:12]}..{new[:12]} failed: {out.stderr.strip()}")
    toks = out.stdout.split("\0")
    entries: list[Entry] = []
    i = 0
    while i < len(toks):
        meta = toks[i]
        if not meta:
            i += 1
            continue
        if not meta.startswith(":") or i + 1 >= len(toks):
            raise GateError(f"unreadable git diff --raw output near {meta[:40]!r}")
        old_mode, new_mode, _old_obj, _new_obj, status = meta[1:].split()
        entries.append((status[0], old_mode, new_mode, toks[i + 1]))
        i += 2
    return entries


def log_paths(root: Path, rng: str, path: str, added_only: bool = False) -> list[str]:
    args = ["log", "--no-renames", "--full-history", "--format=%H"]
    if added_only:
        args.append("--diff-filter=A")
    return git_ok(root, *args, rng, "--", path).split()


def json_at(root: Path, rev: str, path: str) -> dict | None:
    raw = show_bytes(root, rev, path)
    if raw is None:
        return None
    try:
        data = json.loads(raw.decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as e:
        raise GateError(f"{path} at {rev[:12]} is not valid JSON ({e})") from e
    if not isinstance(data, dict):
        raise GateError(f"{path} at {rev[:12]} is not a JSON object")
    return data


def grep_paths(root: Path, rev: str, pattern: str) -> list[str]:
    """`06 QA/` paths at `rev` with a line matching the extended regex."""
    out = git(root, "grep", "-l", "-z", "-E", pattern, rev, "--", QA_DIR[0])
    if out.returncode not in (0, 1):
        raise GateError(f"git grep failed: {out.stderr.strip()}")
    prefix = f"{rev}:"
    return [r[len(prefix):] if r.startswith(prefix) else r for r in out.stdout.split("\0") if r]


# ---- paths ---------------------------------------------------------------------------------------------------------

def parts_of(path: str) -> tuple[str, ...]:
    return tuple(path.split("/"))


def under(path: str, directory: tuple[str, ...]) -> bool:
    """Directory-exact: every component of `directory` matches, and something is below it."""
    p = parts_of(path)
    return len(p) > len(directory) and p[: len(directory)] == directory


def valid_note_path(task_id: str, note: object) -> bool:
    """The one task note a task may link: 03 Games/<game>/06 Tasks/<TASK-####>-<slug>.md, nothing else."""
    if not isinstance(note, str):
        return False
    p = parts_of(note)
    return (len(p) == 4 and p[0] == "03 Games" and p[2] == "06 Tasks" and all(x and x not in (".", "..") for x in p)
            and p[3].startswith(f"{task_id}-") and p[3].endswith(".md"))


def record_dir(path: str) -> tuple[str, ...] | None:
    for d in RECORD_DIRS:
        if under(path, d):
            return d
    return None


def post_audit_problems(entries: list[Entry], task_id: str, note_path: object) -> list[str]:
    """What in a measured..head diff is not allowed after an audit. Empty = only records changed."""
    source, bad = [], []
    note = note_path if valid_note_path(task_id, note_path) else None
    for status, old_mode, new_mode, path in entries:
        d = record_dir(path)
        if d is None and path != note:
            source.append(path)
            continue
        ext = RECORD_DIRS[d] if d else ".md"
        if ext and not path.endswith(ext):
            bad.append(f"{path} (only {ext} files may change there)")
        elif {old_mode, new_mode} & {SYMLINK, GITLINK}:
            bad.append(f"{path} (a symlink or submodule)")
        elif status == "T" or (ABSENT not in (old_mode, new_mode) and old_mode != new_mode):
            bad.append(f"{path} (mode or type change {old_mode} -> {new_mode})")
        elif not {old_mode, new_mode} <= {REGULAR, ABSENT}:
            bad.append(f"{path} (not a regular 100644 file)")
    problems = []
    if source:
        problems.append("source changed after the reviewed commit (a PASS covers only that commit): "
                        + ", ".join(sorted(source)))
    if bad:
        problems.append("disallowed change in a record path: " + "; ".join(sorted(bad)))
    return problems


def is_chore_source(entry: Entry) -> bool:
    _status, old_mode, new_mode, path = entry
    return (parts_of(path)[0] in CHORE_SOURCE_DIRS or path in CHORE_SOURCE_FILES
            or bool({old_mode, new_mode} & {SYMLINK, GITLINK}))


# ---- reports -------------------------------------------------------------------------------------------------------

def normalize_identity(name: object) -> str:
    return name.strip().lower() if isinstance(name, str) else ""


def parse_frontmatter(text: str) -> tuple[dict[str, str], list[str]]:
    """Top-level `key: value` pairs of a report's frontmatter. A duplicate key is a problem, never a choice."""
    m = FRONTMATTER.match(text)
    if not m:
        return {}, ["the report has no frontmatter"]
    fields: dict[str, str] = {}
    problems = []
    for line in m.group(1).splitlines():
        lm = FM_LINE.match(line)
        if not lm:
            continue
        key, value = lm.group(1), lm.group(2)
        if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
            value = value[1:-1]
        if key in fields:
            problems.append(f"the frontmatter key {key!r} appears twice")
        fields[key] = value
    return fields, problems


def report_fields(text: str, path: str, task_id: str) -> tuple[dict[str, str], list[str]]:
    """The decisive fields of a report (id, task_id, verdict, reviewed_commit, reviewer) and what is wrong with them."""
    fm, problems = parse_frontmatter(text)
    stem = PurePosixPath(path).stem
    if fm.get("id") != stem or not AUDIT_ID.match(stem):
        problems.append(f"{path}: frontmatter id {fm.get('id')!r} must equal the file name {stem!r}")
    if fm.get("task_id") != task_id:
        problems.append(f"{path}: frontmatter task_id {fm.get('task_id')!r} is not {task_id}")
    verdict = (fm.get("verdict") or "").strip().lower()
    if verdict not in ("pass", "fail"):
        problems.append(f"{path}: frontmatter verdict must be pass or fail, got {fm.get('verdict')!r}")
    if not HEX40.match(fm.get("reviewed_commit") or ""):
        problems.append(f"{path}: frontmatter reviewed_commit must be the full 40-hex SHA, lower case")
    if not normalize_identity(fm.get("reviewer")):
        problems.append(f"{path}: frontmatter reviewer is empty")
    return {"id": fm.get("id", ""), "task_id": fm.get("task_id", ""), "verdict": verdict,
            "reviewed_commit": fm.get("reviewed_commit", ""), "reviewer": normalize_identity(fm.get("reviewer"))}, problems


def valid_report_path(path: object) -> bool:
    """A report lives directly in 06 QA/ and ends .md."""
    if not isinstance(path, str):
        return False
    p = parts_of(path)
    return len(p) == 2 and p[0] == QA_DIR[0] and p[1].endswith(".md") and AUDIT_ID.match(p[1][:-3]) is not None


def sha256_file(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def _fm_at(root: Path, rev: str, path: str) -> dict[str, str]:
    raw = show_bytes(root, rev, path)
    return parse_frontmatter(raw.decode("utf-8", "replace"))[0] if raw is not None else {}


def reports_for_task(root: Path, head: str, task_id: str) -> list[str]:
    """Every `06 QA/` file at `head` whose frontmatter task_id is this task."""
    hits = grep_paths(root, head, rf"^task_id:[[:space:]]*[\"']?{task_id}[\"']?[[:space:]]*$")
    return sorted(p for p in hits if _fm_at(root, head, p).get("task_id") == task_id)


def same_audit_id(root: Path, head: str, audit_id: str) -> list[str]:
    """Every `06 QA/` file at `head` that claims this audit id, by frontmatter id or by file name."""
    hits = grep_paths(root, head, rf"^id:[[:space:]]*[\"']?{audit_id}")
    paths = {p for p in hits if _fm_at(root, head, p).get("id") == audit_id}
    listing = git_ok(root, "ls-tree", "-r", "-z", "--name-only", head, "--", QA_DIR[0])
    paths |= {p for p in listing.split("\0") if p and PurePosixPath(p).stem == audit_id}
    return sorted(paths)


def immutability_problems(root: Path, head: str, path: str) -> tuple[str | None, list[str]]:
    """(the one commit that added the report, problems): exactly one add, same blob at head, regular file."""
    entry = tree_entry(root, head, path)
    if entry is None:
        return None, [f"the audit report {path} is missing at the PR head"]
    mode, kind, blob = entry
    if mode != REGULAR or kind != "blob":
        return None, [f"the audit report {path} is not a regular file (mode {mode})"]
    adds = log_paths(root, head, path, added_only=True)
    if len(adds) != 1:
        return None, [f"the audit report {path} was added {len(adds)} times; exactly one commit may add it"]
    added = tree_entry(root, adds[0], path)
    if added is None or added[2] != blob or added[0] != REGULAR:
        return adds[0], [f"the audit report {path} changed after it was recorded (blob differs from {adds[0][:12]})"]
    return adds[0], []


def decisive_audit(root: Path, task: dict, head: str) -> tuple[dict | None, list[str]]:
    """The decisive audit, read from its report at `head`, and every integrity problem with it or the JSON index.

    The fields returned are the report's own (verdict, reviewed_commit, reviewer, id, path). Never reads `status`."""
    task_id = str(task.get("id") or "")
    audits = task.get("audits") or []
    if not isinstance(audits, list) or not all(isinstance(a, dict) for a in audits):
        return None, ["the task JSON `audits` is not a list of objects"]
    live = [a for a in audits if not a.get("post_merge")]
    post_merge = {a.get("report") for a in audits if a.get("post_merge")}
    on_disk = [p for p in reports_for_task(root, head, task_id) if p not in post_merge]
    if not live:
        if on_disk:
            return None, ["a report names this task but the task JSON indexes none: " + ", ".join(on_disk)]
        return None, ["no audit is recorded for this task"]
    problems: list[str] = []
    indexed = [a.get("report") for a in live]
    if len(set(map(str, indexed))) != len(indexed):
        problems.append("the task JSON indexes the same report more than once")
    problems += [f"the report {p} names this task but the task JSON does not index it" for p in on_disk if p not in indexed]
    entry = live[-1]
    path = entry.get("report")
    if not valid_report_path(path):
        return None, problems + [f"the decisive report path {path!r} is not <audit id>.md directly in 06 QA/"]
    adds: dict[str, str] = {}
    for p in sorted(set(on_disk) | {path}):
        added, imm = immutability_problems(root, head, p)
        problems += imm
        if added:
            adds[p] = added
    raw = show_bytes(root, head, path)
    if raw is None:
        return None, problems
    fields, fp = report_fields(raw.decode("utf-8", "replace"), path, task_id)
    problems += fp
    if fields["id"] and AUDIT_ID.match(fields["id"]):
        claims = same_audit_id(root, head, fields["id"])
        if claims != [path]:
            problems.append(f"audit id {fields['id']} is claimed by more than one report: " + ", ".join(claims))
    if path in adds:
        for other, added in adds.items():
            if other != path and (added == adds[path] or not is_ancestor(root, added, adds[path])):
                problems.append(f"the report {other} was not added before the decisive report {path}")
    # The JSON is an index: each of its claims must equal the report's own.
    if entry.get("result") != fields["verdict"]:
        problems.append(f"the task JSON says {entry.get('result')!r} but the report {path} says {fields['verdict']!r}")
    if entry.get("measured_sha") != fields["reviewed_commit"]:
        problems.append(f"the task JSON measured_sha {entry.get('measured_sha')!r} is not the report's reviewed_commit "
                        f"{fields['reviewed_commit']!r}")
    if normalize_identity(entry.get("auditor")) != fields["reviewer"]:
        problems.append(f"the task JSON auditor {entry.get('auditor')!r} is not the report's reviewer {fields['reviewer']!r}")
    if entry.get("report_sha256") != hashlib.sha256(raw).hexdigest():
        problems.append(f"the task JSON report_sha256 does not match {path} at the PR head")
    fields["path"] = path
    return fields, problems


# ---- task registration ---------------------------------------------------------------------------------------------

def task_files_naming(root: Path, rev: str, branch: str) -> list[str]:
    listing = git_ok(root, "ls-tree", "-z", "--name-only", rev, "--", "tasks/items/")
    found = []
    for path in listing.split("\0"):
        if path.endswith(".json"):
            data = json_at(root, rev, path)
            if data and data.get("branch") == branch:
                found.append(path)
    return found


def pinned_registration(root: Path, base: str, merge_base: str, head: str,
                        branch: str) -> tuple[dict | None, str, list[str]]:
    """(registration, task file path, problems). Pinned to the PR base, or to the commit that added the task file."""
    candidates = sorted(set(task_files_naming(root, head, branch)) | set(task_files_naming(root, base, branch)))
    if not candidates:
        return None, "", [f"no tasks/items/*.json names branch {branch}; a source change needs a task and an audit"]
    if len(candidates) > 1:
        return None, "", [f"more than one task file names branch {branch} (at the base or head): " + ", ".join(candidates)]
    path = candidates[0]
    reg = json_at(root, base, path)
    origin = f"the PR base {base[:12]}"
    if reg is None:
        adds = log_paths(root, f"{merge_base}..{head}", path, added_only=True)
        if len(adds) != 1:
            return None, path, [f"{path} was added {len(adds)} times on the branch; cannot pin its registration"]
        reg = json_at(root, adds[0], path) or {}
        origin = f"its first commit {adds[0][:12]}"
    problems = []
    if not TASK_ID.match(str(reg.get("id"))) or PurePosixPath(path).stem != reg.get("id"):
        problems.append(f"{path}: id {reg.get('id')!r} does not match the file name")
    if reg.get("branch") != branch:
        problems.append(f"{path}: the registered branch at {origin} is {reg.get('branch')!r}, not {branch}")
    for rev in log_paths(root, f"{merge_base}..{head}", path) + [head]:
        now = json_at(root, rev, path)
        if now is None:
            problems.append(f"{path} is missing at {rev[:12]}")
            continue
        for field in PINNED_FIELDS:
            if now.get(field) != reg.get(field):
                problems.append(f"{path}: {field} changed on the branch at {rev[:12]} "
                                f"({reg.get(field)!r} at {origin} -> {now.get(field)!r})")
    return reg, path, sorted(set(problems))


# ---- decision ------------------------------------------------------------------------------------------------------

def binding_problems(root: Path, task_id: str, reg: dict, fields: dict, head: str) -> list[str]:
    """Is the decisive report a PASS by an independent auditor that covers `head` under the pinned registration."""
    if fields["verdict"] != "pass":
        return [f"the decisive report {fields['path']} says {fields['verdict'] or 'nothing'}, not PASS"]
    problems = []
    reviewer, owner = fields["reviewer"], normalize_identity(reg.get("owner_agent"))
    if reviewer not in INDEPENDENT_AUDITORS:
        problems.append(f"a {reg.get('tier') or 'untiered'} task needs a PASS from a listed independent auditor "
                        f"({', '.join(sorted(INDEPENDENT_AUDITORS))}); the report's reviewer is {reviewer!r}")
    if owner and reviewer == owner:
        problems.append(f"the reviewer {reviewer!r} is the task's owner_agent; an audit must be independent")
    measured = fields["reviewed_commit"]
    if not commit_exists(root, measured):
        return problems + [f"the reviewed commit {measured} is not in this repository"]
    if not is_ancestor(root, measured, head):
        return problems + [f"the reviewed commit {measured[:12]} is not an ancestor of the PR head {head[:12]}"]
    return problems + post_audit_problems(diff_entries(root, measured, head), task_id, reg.get("note_path"))


def evaluate(root: Path, head: str, branch: str, base: str) -> tuple[int, list[str], dict]:
    """(exit code, message lines, facts) for one PR head. Facts: head, branch, base, task_id, tier, report."""
    facts: dict = {"head": head, "branch": branch}
    if not HEX40.match(head or ""):
        return 2, [f"audit-gate: the head {head!r} is not a full 40-hex commit SHA."], facts
    if not branch:
        return 2, ["audit-gate: no branch name."], facts
    if not ensure_commit(root, head):
        return 2, [f"audit-gate: head {head} is not in the checkout; fetch full history."], facts
    base_sha = resolve_commit(root, base) if base else None
    if not base_sha:
        return 2, [f"audit-gate: the base {base!r} is not a commit here; fetch full history."], facts
    facts["base"] = base_sha
    mb = git(root, "merge-base", base_sha, head)
    if mb.returncode != 0:
        return 2, [f"audit-gate: no merge base between {base_sha[:12]} and {head[:12]}; fetch full history."], facts
    merge_base = mb.stdout.strip()
    if branch.startswith("chore/") and not any(is_chore_source(e) for e in diff_entries(root, merge_base, head)):
        return 0, [f"audit-gate: chore branch {branch} changes nothing under games/, scripts/ or .github/ "
                   "(and no symlink or submodule); nothing to audit."], facts
    reg, path, problems = pinned_registration(root, base_sha, merge_base, head, branch)
    if problems or reg is None:
        return 1, [f"audit-gate: {branch}: the task registration cannot be trusted:"] + [f"  - {p}" for p in problems], facts
    task_id = str(reg["id"])
    facts |= {"task_id": task_id, "tier": reg.get("tier")}
    if reg.get("tier") == "light":
        return 0, [f"audit-gate: {task_id} is light tier (pinned at registration; no audit); "
                   "approve-merge needs green checks instead."], facts
    fields, problems = decisive_audit(root, json_at(root, head, path) or {}, head)
    if fields and not problems:
        problems = binding_problems(root, task_id, reg, fields, head)
    if problems or not fields:
        return 1, [f"audit-gate: {task_id}: PR head {head[:12]} is not covered by a recorded audit PASS:"] + [
            f"  - {p}" for p in problems], facts
    facts["report"] = fields["path"]
    return 0, [f"audit-gate: {task_id}: PASS by {fields['reviewer']} at {fields['reviewed_commit'][:12]} "
               f"({fields['path']}) covers head {head[:12]}."], facts


def gate(root: Path, head: str, branch: str, base: str | None, draft: bool) -> tuple[int, list[str]]:
    if draft:
        return 0, ["audit-gate: draft PR, not applied (a draft cannot be merged)."]
    code, lines, _facts = evaluate(root, head, branch, base or "")
    return code, lines


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--root", type=Path, default=Path(__file__).resolve().parent.parent,
                   help="the repository to read as data (in CI: the PR head checkout, never executed)")
    p.add_argument("--head", required=True, help="the PR head commit (github.event.pull_request.head.sha)")
    p.add_argument("--branch", required=True, help="the PR branch name (github.event.pull_request.head.ref)")
    p.add_argument("--base", help="the PR base commit (github.event.pull_request.base.sha); required unless --draft")
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
