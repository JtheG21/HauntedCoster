#!/usr/bin/env python3
"""Validate Obsidian notes against 00 Studio/Obsidian Conventions.md (standard library only).

Checks: required frontmatter, controlled statuses and types, ISO dates, filename
patterns, folder placement, game project IDs, duplicate IDs, broken [[links]],
and task status sync with tasks/items/.

Usage: python3 scripts/validate_vault.py [--root PATH]   (exit 1 on errors)
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

import task_store

# Queue statuses (backlog, review) plus the older note vocabulary (proposed, in_review) that non-task notes keep.
STATUSES = {"backlog", "review", "inbox", "research", "proposed", "ready", "in_progress", "blocked",
            "in_review", "changes_requested", "approved", "done", "archived"}
TYPES = {"index", "overview", "design", "architecture", "roadmap", "task", "bug", "audit", "adr",
         "system", "playtest", "release", "review", "health", "lesson", "retro", "research",
         "experiment", "inbox", "agent"}
REQUIRED = ("id", "title", "type", "status", "created", "updated")
DATE_RE = re.compile(r"^\d{4}-\d{2}-\d{2}$")
SLUG = r"[A-Za-z0-9]+(?:-[A-Za-z0-9.]+)*"

# type -> (filename regex, allowed folder regex relative to root)
GAME = r"03 Games/GAME-\d{3} [^/]+"
RULES = {
    "research": (rf"RSH-\d{{8}}-{SLUG}", r"02 Research"),
    "task": (rf"TASK-\d{{4}}-{SLUG}", rf"{GAME}/06 Tasks"),
    "bug": (rf"BUG-\d{{4}}-{SLUG}", r"06 QA"),
    "audit": (r"AUD-\d{8}-TASK-\d{4}-\d{2}", r"06 QA"),
    "adr": (rf"ADR-\d{{4}}-{SLUG}", rf"(05 Engineering|{GAME}/04 Decisions)"),
    "system": (rf"SYS-{SLUG}", rf"{GAME}/05 Systems"),
    "playtest": (r"TEST-\d{8}-\d{2}", rf"{GAME}/07 Playtests"),
    "release": (r"REL-\d+\.\d+\.\d+", rf"{GAME}/08 Releases"),
    "review": (r"REV-\d{4}-W\d{2}", r"08 Reviews"),
    "health": (r"HLT-\d{8}", r"08 Reviews"),
    "lesson": (rf"LES-\d{{4}}-{SLUG}", r"09 Knowledge"),
    "retro": (rf"RETRO-{SLUG}", rf"{GAME}/09 Retrospectives"),
    "experiment": (rf"EXP-\d{{4}}-{SLUG}", r"07 Metrics"),
    "overview": (r"00 Overview", GAME),
    "design": (r"01 Game Design", GAME),
    "architecture": (r"02 Technical Architecture", GAME),
    "roadmap": (r"03 Roadmap", GAME),
    "inbox": (r".+", r"01 Inbox"),
}
# id must equal the filename up to this many hyphen-separated parts (None = whole stem)
ID_PARTS = {"task": 2, "bug": 2, "adr": 2, "lesson": 2, "experiment": 2}

NOTE_DIRS = re.compile(r"^(0\d|99) ")
SKIP_DIRS = {".git", ".obsidian", "Agents", "Chats", "src", "tests", "scripts", "tasks", "node_modules"}
LINK_RE = re.compile(r"!?\[\[([^\]]+)\]\]")


def parse_frontmatter(text: str) -> dict | None:
    if not text.startswith("---\n"):
        return None
    end = text.find("\n---", 4)
    if end == -1:
        return None
    data: dict = {}
    key = None
    for line in text[4:end].splitlines():
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        m = re.match(r"^([A-Za-z_][\w-]*):\s*(.*)$", line)
        if m:
            key, value = m.group(1), m.group(2).strip()
            data[key] = value.strip("\"'") if value else []
        elif key and re.match(r"^\s+-\s*", line):
            if not isinstance(data[key], list):
                data[key] = []
            data[key].append(re.sub(r"^\s+-\s*", "", line).strip("\"'"))
    return data


def strip_code(text: str) -> str:
    text = re.sub(r"```.*?```", "", text, flags=re.S)
    return re.sub(r"`[^`\n]*`", "", text)


class Report:
    def __init__(self):
        self.errors: list[str] = []
        self.warnings: list[str] = []

    def error(self, where: str, msg: str):
        self.errors.append(f"{where}: {msg}")

    def warn(self, where: str, msg: str):
        self.warnings.append(f"{where}: {msg}")


def vault_files(root: Path) -> list[Path]:
    out = []
    for p in root.rglob("*"):
        rel = p.relative_to(root)
        if rel.parts[0] in SKIP_DIRS or any(part.startswith(".") for part in rel.parts):
            continue
        if rel.parts[:2] == ("intake", "inbox"):  # untriaged material, not notes
            continue
        if p.is_file():
            out.append(p)
    return out


def validate(root: Path) -> Report:
    rep = Report()
    files = vault_files(root)
    md = [p for p in files if p.suffix == ".md"]
    by_name: dict[str, list[Path]] = {}
    for p in files:
        rel = p.relative_to(root)
        key = p.stem if p.suffix == ".md" else p.name
        by_name.setdefault(key.lower(), []).append(rel)

    ids: dict[str, Path] = {}
    task_notes: dict[str, tuple[Path, dict]] = {}

    for p in md:
        rel = p.relative_to(root)
        where = str(rel)
        text = p.read_text(encoding="utf-8")
        in_notes = len(rel.parts) > 1 and NOTE_DIRS.match(rel.parts[0])
        is_template = rel.parts[0] == "99 Templates"

        if in_notes:
            fm = parse_frontmatter(text)
            if fm is None:
                rep.error(where, "missing YAML frontmatter")
            elif is_template:
                if not p.name.startswith("T - "):
                    rep.error(where, "templates must be named 'T - <Name>.md'")
                for key in ("id", "type", "status"):
                    if key not in fm:
                        rep.error(where, f"template missing '{key}'")
            else:
                check_note(rep, root, rel, fm, ids, task_notes)

        if not is_template:
            check_links(rep, where, text, by_name)

    check_queue(rep, root, task_notes)
    check_overview_tables(rep, root)
    return rep


def check_note(rep, root, rel, fm, ids, task_notes):
    where = str(rel)
    for key in REQUIRED:
        if key not in fm or fm[key] in ("", []):
            rep.error(where, f"missing '{key}'")
    status, ntype, nid = fm.get("status"), fm.get("type"), fm.get("id")
    if status and status not in STATUSES:
        rep.error(where, f"invalid status '{status}'")
    if ntype and ntype not in TYPES:
        rep.error(where, f"invalid type '{ntype}'")
    for key in ("created", "updated"):
        if isinstance(fm.get(key), str) and fm[key] and not DATE_RE.match(fm[key]):
            rep.error(where, f"'{key}' must be YYYY-MM-DD")
    if nid:
        if nid in ids:
            rep.error(where, f"duplicate id '{nid}' (also in {ids[nid]})")
        ids[nid] = rel

    folder = str(rel.parent)
    game = re.match(r"03 Games/(GAME-\d{3}) ", folder)
    if game and fm.get("project") != game.group(1):
        rep.error(where, f"project must be {game.group(1)}")

    rule = RULES.get(ntype)
    if rule:
        name_re, folder_re = rule
        if not re.fullmatch(name_re, rel.stem):
            rep.error(where, f"filename doesn't match the {ntype} pattern")
        if not re.fullmatch(folder_re, folder):
            rep.error(where, f"{ntype} notes belong in {folder_re}")
        if nid and ntype not in ("overview", "design", "architecture", "roadmap", "inbox"):
            parts = ID_PARTS.get(ntype)
            expected = "-".join(rel.stem.split("-")[:parts]) if parts else rel.stem
            if nid != expected:
                rep.error(where, f"id '{nid}' should be '{expected}'")
        if ntype == "overview" and game and nid != game.group(1):
            rep.error(where, f"overview id must be {game.group(1)}")
    elif " " not in rel.stem and re.match(r"^[A-Z]+-", rel.stem):
        rep.warn(where, f"looks like a prefixed note but type is '{ntype}'")

    if ntype == "task" and nid:
        task_notes[nid] = (rel, fm)


def check_links(rep, where, text, by_name):
    for raw in LINK_RE.findall(strip_code(text)):
        target = raw.split("|")[0].split("#")[0].strip()
        if not target:
            continue
        if "/" in target:
            suffix = target.lower().removesuffix(".md")
            hits = [p for ps in by_name.values() for p in ps
                    if str(p.with_suffix("") if p.suffix == ".md" else p).lower().endswith(suffix)]
        else:
            key = target.lower().removesuffix(".md")
            hits = by_name.get(key, [])
        if not hits:
            rep.error(where, f"broken link [[{target}]]")
        elif len(hits) > 1:
            rep.warn(where, f"ambiguous link [[{target}]] -> {', '.join(map(str, hits))}")


def check_queue(rep, root, task_notes):
    if not task_store.items_dir(root).is_dir():
        return
    items, errors = task_store.read_items(root)
    for e in errors:
        rep.error("tasks/items", e)
    tasks = [task for _, task in items]
    seen = set()
    for t in tasks:
        tid = t.get("id")
        seen.add(tid)
        note = t.get("note_path")
        if not note:
            rep.error(f"tasks/items/{tid}.json", "no 'note_path'")
            continue
        if not (root / note).exists():
            rep.error(f"tasks/items/{tid}.json", f"note not found: {note}")
            continue
        if tid not in task_notes:
            rep.error(note, f"queue task {tid} has no matching 'id' in the note")
            continue
        rel, fm = task_notes[tid]
        if str(rel) != note:
            rep.error(f"tasks/items/{tid}.json", f"note path {note} but the note is at {rel}")
        if fm.get("status") != t.get("status"):
            rep.error(str(rel), f"status mismatch: note '{fm.get('status')}' vs queue '{t.get('status')}' "
                                 "(queue is authoritative; flag, don't guess)")
    for tid, (rel, _) in task_notes.items():
        if tid not in seen:
            rep.warn(str(rel), f"{tid} has no file in tasks/items/")


OVERVIEW_ROW = re.compile(r"^\|\s*\[\[(TASK-\d{4})[^\]]*\]\]\s*\|\s*([a-z_]+)")


def check_overview_tables(rep, root):
    """Warn when a game Overview's task table shows a status other than the queue's (AUDIT-005)."""
    if not task_store.items_dir(root).is_dir():
        return
    status = {t.get("id"): t.get("status") for _, t in task_store.read_items(root)[0]}  # check_queue reports bad files
    for p in sorted((root / "03 Games").glob("*/00 Overview.md")):
        where = str(p.relative_to(root))
        for line in p.read_text(encoding="utf-8").splitlines():
            m = OVERVIEW_ROW.match(line)
            if not m:
                continue
            tid, shown = m.groups()
            if tid not in status:
                rep.warn(where, f"task table lists {tid}, which has no file in tasks/items/")
            elif shown != status[tid]:
                rep.warn(where, f"task table shows {tid} as '{shown}' but the queue says '{status[tid]}'")


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--root", type=Path, default=Path(__file__).resolve().parent.parent)
    a = ap.parse_args(argv)
    rep = validate(a.root)
    for w in rep.warnings:
        print("WARN ", w)
    for e in rep.errors:
        print("ERROR", e)
    print(f"vault: {len(rep.errors)} errors, {len(rep.warnings)} warnings")
    return 1 if rep.errors else 0


if __name__ == "__main__":
    sys.exit(main())
