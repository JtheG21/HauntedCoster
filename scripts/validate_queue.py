#!/usr/bin/env python3
"""Validate tasks/queue.json against docs/workflow/TASKS.md (standard library only).

Checks valid JSON, required fields, unique IDs, valid statuses and enums, and no files_owned overlap among
in_progress tasks. scripts/orchestrator.py validate covers dependencies, notes and the usage ledger.

Usage: python3 scripts/validate_queue.py [--root PATH]   (exit 1 on errors)
"""

from __future__ import annotations

import argparse
import fnmatch
import json
import re
import sys
from pathlib import Path

STATUSES = {"backlog", "ready", "in_progress", "review", "changes_requested", "approved", "blocked", "done", "archived"}
FINISHED = {"done", "archived"}
TIERS = {"light", "standard", "deep"}
OWNERS = {"claude-code", "codex", "claude-design", "task-audit", "human"}
REQUIRED = ("id", "game", "title", "status", "tier", "owner_agent", "files_owned", "depends_on", "branch", "acceptance",
            "evidence", "notes")
ID_RE = re.compile(r"^TASK-\d{4}$")
GAME_RE = re.compile(r"^GAME-\d{3}$")
GLOB_RE = re.compile(r"[*?\[]")


def _fixed_prefix(pattern: str) -> str:
    """The part of a glob before its first wildcard, cut back to a whole folder."""
    m = GLOB_RE.search(pattern)
    return pattern[:m.start()].rsplit("/", 1)[0] if m and "/" in pattern[:m.start()] else ("" if m else pattern)


def _nested(a: str, b: str) -> bool:
    a, b = a.rstrip("/"), b.rstrip("/")
    return not a or not b or a == b or a.startswith(b + "/") or b.startswith(a + "/")


def overlaps(a: str, b: str) -> bool:
    a_glob, b_glob = bool(GLOB_RE.search(a)), bool(GLOB_RE.search(b))
    if a_glob and b_glob:
        return _nested(_fixed_prefix(a), _fixed_prefix(b))
    if a_glob or b_glob:
        pattern, path = (a, b) if a_glob else (b, a)
        # A plain path may be a folder holding files the glob matches, or a file the glob matches.
        return fnmatch.fnmatchcase(path.rstrip("/"), pattern) or _nested(path, _fixed_prefix(pattern)) and (
            _fixed_prefix(pattern).startswith(path.rstrip("/") + "/") or _fixed_prefix(pattern) == path.rstrip("/"))
    return _nested(a, b)


def validate(queue: dict) -> list[str]:
    errors: list[str] = []
    tasks = queue.get("tasks")
    if not isinstance(tasks, list):
        return ["'tasks' must be a list"]
    seen: set = set()
    for t in tasks:
        tid = t.get("id", "?")
        for key in REQUIRED:
            if key not in t:
                errors.append(f"{tid}: missing '{key}'")
        if not ID_RE.match(str(tid)):
            errors.append(f"{tid}: id must look like TASK-0001")
        if tid in seen:
            errors.append(f"{tid}: duplicate id")
        seen.add(tid)
        status = t.get("status")
        if status not in STATUSES:
            errors.append(f"{tid}: invalid status '{status}'")
        if "game" in t and not GAME_RE.match(str(t["game"])):
            errors.append(f"{tid}: game must look like GAME-001")
        for key, allowed in (("tier", TIERS), ("owner_agent", OWNERS)):
            value = t.get(key)
            if value is None and status not in FINISHED and key in t:
                errors.append(f"{tid}: '{key}' may be null only on done or archived tasks")
            elif value is not None and value not in allowed:
                errors.append(f"{tid}: invalid {key} '{value}'")
        for key in ("files_owned", "depends_on", "acceptance", "evidence"):
            if key in t and not isinstance(t[key], list):
                errors.append(f"{tid}: '{key}' must be a list")
        if "acceptance" in t and not t["acceptance"]:
            errors.append(f"{tid}: needs at least one acceptance criterion")
        if status == "in_progress" and not t.get("files_owned"):
            errors.append(f"{tid}: an in_progress task must list files_owned")

    active = [t for t in tasks if t.get("status") == "in_progress" and isinstance(t.get("files_owned"), list)]
    for i, a in enumerate(active):
        for b in active[i + 1:]:
            for x in a["files_owned"]:
                for y in b["files_owned"]:
                    if overlaps(x, y):
                        errors.append(f"{a.get('id')} and {b.get('id')}: files_owned overlap ('{x}' and '{y}')")
    return errors


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--root", type=Path, default=Path(__file__).resolve().parent.parent)
    a = ap.parse_args(argv)
    path = a.root / "tasks" / "queue.json"
    try:
        queue = json.loads(path.read_text())
    except (OSError, json.JSONDecodeError) as e:
        print(f"ERROR {path}: {e}")
        return 1
    errors = validate(queue)
    for e in errors:
        print("ERROR", e)
    tasks = queue.get("tasks", [])
    active = sum(1 for t in tasks if t.get("status") == "in_progress")
    print(f"queue: {len(tasks)} tasks, {active} in_progress, {len(errors)} errors")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
