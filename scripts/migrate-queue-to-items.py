#!/usr/bin/env python3
"""Move tasks/queue.json into one file per task at tasks/items/ (standard library only). Safe to rerun.

For open branches: merge main, then run this. It upgrades old-format entries, writes the missing task files, mirrors
renamed statuses into task notes and removes queue.json. If a task file already exists with different content it stops,
writes nothing and names the task. Rerun with --keep-existing once you've decided the existing files are right.

Usage: python3 scripts/migrate-queue-to-items.py [--root PATH] [--keep-existing]
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import migrate_queue  # noqa: E402
import task_store  # noqa: E402


def existing_task(path: Path) -> dict | None:
    """The task in an existing file, or None if it can't be read, which counts as differing."""
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return None


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--root", type=Path, default=Path(__file__).resolve().parent.parent)
    ap.add_argument("--keep-existing", action="store_true", help="where a task file differs, keep the file")
    a = ap.parse_args(argv)
    queue_path = a.root / task_store.LEGACY_QUEUE
    if not queue_path.is_file():
        print(f"no {task_store.LEGACY_QUEUE}: nothing to do")
        return 0
    try:
        queue = json.loads(queue_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        print(f"error: {task_store.LEGACY_QUEUE} is not valid JSON ({e}). Resolve any conflict markers first.", file=sys.stderr)
        return 1

    tasks = [migrate_queue.migrate_task(t) for t in queue.get("tasks", [])]
    ids = [t["id"] for t in tasks]
    duplicates = sorted({i for i in ids if ids.count(i) > 1})
    if duplicates:
        print(f"error: duplicate ids in the queue: {', '.join(duplicates)}. Nothing written.", file=sys.stderr)
        return 1

    new, same, differ = [], 0, []
    for t in tasks:
        path = task_store.items_dir(a.root) / f"{t['id']}.json"
        if not path.is_file():
            new.append(t)
        elif existing_task(path) == t:
            same += 1
        else:
            differ.append(t["id"])
    if differ and not a.keep_existing:
        print(f"error: these task files differ from the queue: {', '.join(differ)}. Nothing written. "
              "Check them, then rerun with --keep-existing to keep the files.", file=sys.stderr)
        return 1

    for t in new:
        task_store.save_task(a.root, t)
        migrate_queue.sync_note(a.root, t)
    queue_path.unlink()
    kept = f", {len(differ)} differing kept as they were ({', '.join(differ)})" if differ else ""
    print(f"{len(tasks)} tasks in the queue: {len(new)} written, {same} already present{kept}. Removed {task_store.LEGACY_QUEUE}.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
