"""One file per task: tasks/items/TASK-####.json (standard library only).

Every reader and writer of task records goes through here. See docs/workflow/TASKS.md. Parallel branches each add or
change their own file, so they never conflict over a shared list.
"""

from __future__ import annotations

import json
from pathlib import Path

ITEMS = Path("tasks") / "items"
LEGACY_QUEUE = Path("tasks") / "queue.json"


class TaskStoreError(Exception):
    pass


def items_dir(root: Path) -> Path:
    return Path(root) / ITEMS


def read_items(root: Path) -> tuple[list[tuple[Path, dict]], list[str]]:
    """Every task file as (path, task), sorted by file name, plus one error per file that can't be read."""
    items, errors = [], []
    for path in sorted(items_dir(root).glob("*.json")):
        rel = path.relative_to(root)
        try:
            task = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as e:
            errors.append(f"{rel}: invalid JSON ({e})")
            continue
        if isinstance(task, dict):
            items.append((path, task))
        else:
            errors.append(f"{rel}: must hold one JSON object")
    return items, errors


def load_tasks(root: Path) -> list[dict]:
    items, errors = read_items(root)
    if errors:
        raise TaskStoreError("; ".join(errors))
    return [task for _, task in items]


def dump(task: dict) -> str:
    return json.dumps(task, indent=2) + "\n"


def save_task(root: Path, task: dict) -> bool:
    """Writes the task's file only if its content changed, so a transition touches one file. True if written."""
    path = items_dir(root) / f"{task['id']}.json"
    text = dump(task)
    if path.is_file() and path.read_text(encoding="utf-8") == text:
        return False
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")
    return True
