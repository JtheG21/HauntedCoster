#!/usr/bin/env python3
"""Upgrade tasks/queue.json to the schema in docs/workflow/TASKS.md (standard library only). Safe to rerun.

Renames project->game, note->note_path and acceptance_criteria->acceptance, renames the statuses proposed->backlog and
in_review->review (mirroring them into task notes), and adds any missing schema field. Older values it can't know
(tier, owner_agent) stay null, never guessed. history stays as written.

Usage: python3 scripts/migrate_queue.py [--root PATH]
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

RENAMES = {"project": "game", "note": "note_path", "acceptance_criteria": "acceptance"}
STATUS_RENAMES = {"proposed": "backlog", "in_review": "review"}
ORDER = ("id", "game", "title", "status", "tier", "owner_agent", "files_owned", "depends_on", "branch", "acceptance",
         "evidence", "notes", "note_path", "risk")


def migrate_task(t: dict) -> dict:
    t = {RENAMES.get(k, k): v for k, v in t.items()}
    t["status"] = STATUS_RENAMES.get(t.get("status"), t.get("status"))
    t.setdefault("tier", None)
    t.setdefault("owner_agent", None)
    t.setdefault("files_owned", [])
    t.setdefault("evidence", [a["report"] for a in t.get("audits", []) if a.get("report")])
    t.setdefault("notes", "")
    head = {k: t[k] for k in ORDER if k in t}
    return head | {k: v for k, v in t.items() if k not in head}


def sync_note(root: Path, t: dict) -> None:
    path = root / (t.get("note_path") or "")
    if not path.is_file():
        return
    text = path.read_text(encoding="utf-8")
    new = re.sub(r"^status:.*$", f"status: {t['status']}", text, count=1, flags=re.M)
    if new != text:
        path.write_text(new, encoding="utf-8")


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--root", type=Path, default=Path(__file__).resolve().parent.parent)
    a = ap.parse_args(argv)
    path = a.root / "tasks" / "queue.json"
    queue = json.loads(path.read_text())
    queue["tasks"] = [migrate_task(t) for t in queue["tasks"]]
    queue["version"] = 2
    path.write_text(json.dumps(queue, indent=2) + "\n")
    for t in queue["tasks"]:
        sync_note(a.root, t)
    print(f"{len(queue['tasks'])} tasks at schema version 2")
    return 0


if __name__ == "__main__":
    sys.exit(main())
