#!/usr/bin/env python3
"""Lint the project's own skills in .claude/skills/ (standard library only).

Checks, for every skill except the third-party ones listed in .claude/skills/PROVENANCE.md:
  - SKILL.md has frontmatter; `name` equals the folder; `description` is present, at most 1024 characters
    and says when to use it ("Use when ...");
  - the file is not oversized (warning above 150 lines, error above 400: move detail into the vault);
  - every repo path named in backticks exists; a missing file under games/, tasks/ or src/ is a warning (a skill may create it);
  - .agents/skills/<name>/SKILL.md exists and is identical (Codex reads that copy).

  python3 scripts/skill_lint.py [--root PATH]     exit 1 on errors
Origin: REF-CODE-005 (how a mature skills collection stays tidy), spec item EX-1.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from validate_vault import parse_frontmatter  # noqa: E402

PATH_RE = re.compile(r"`((?:scripts|tests|\.claude|\.agents|games|tasks|src|\d\d [A-Za-z][A-Za-z ]*)/[^`\s<>*$]+)`")
WARN_LINES, MAX_LINES, MAX_DESC = 150, 400, 1024
OUTPUT_ROOTS = {"games", "tasks", "src"}  # where a skill may name a file it creates


def third_party(root: Path) -> set[str]:
    f = root / ".claude" / "skills" / "PROVENANCE.md"
    return set(re.findall(r"^\|\s*`([\w-]+)`", f.read_text(encoding="utf-8"), re.M)) if f.exists() else set()


def lint(root: Path) -> tuple[list[str], list[str]]:
    errors: list[str] = []
    warnings: list[str] = []
    skills = root / ".claude" / "skills"
    skip = third_party(root)
    for d in sorted(p for p in skills.iterdir() if p.is_dir()) if skills.is_dir() else []:
        f = d / "SKILL.md"
        where = f"{d.name}"
        if d.name in skip:
            continue
        if not f.exists():
            errors.append(f"{where}: no SKILL.md")
            continue
        text = f.read_text(encoding="utf-8")
        fm = parse_frontmatter(text)
        if fm is None:
            errors.append(f"{where}: missing frontmatter")
            continue
        if fm.get("name") != d.name:
            errors.append(f"{where}: name '{fm.get('name')}' does not match the folder")
        desc = fm.get("description")
        if not isinstance(desc, str) or not desc.strip():
            errors.append(f"{where}: missing description")
        else:
            if len(desc) > MAX_DESC:
                errors.append(f"{where}: description is {len(desc)} characters (max {MAX_DESC})")
            if not re.search(r"\b[Uu]se (when|before|after|for|whenever|at)\b", desc):
                warnings.append(f"{where}: description does not say when to use the skill ('Use when ...')")
        n = text.count("\n") + 1
        if n > MAX_LINES:
            errors.append(f"{where}: {n} lines (max {MAX_LINES}); move detail into a vault note and link it")
        elif n > WARN_LINES:
            warnings.append(f"{where}: {n} lines (over {WARN_LINES})")
        for path in sorted(set(PATH_RE.findall(text))):
            target = root / path.rstrip("/.,:;)")
            if target.exists() or "..." in path:
                continue
            if target.suffix and path.split("/")[0] in OUTPUT_ROOTS:
                warnings.append(f"{where}: names `{path}`, absent (fine if the skill creates it)")
            else:
                errors.append(f"{where}: names `{path}`, and its folder does not exist")
        copy = root / ".agents" / "skills" / d.name / "SKILL.md"
        if not copy.exists():
            errors.append(f"{where}: no Codex copy at .agents/skills/{d.name}/SKILL.md")
        elif copy.read_text(encoding="utf-8") != text:
            errors.append(f"{where}: .agents copy differs from .claude (copy one over the other)")
    return errors, warnings


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--root", type=Path, default=Path(__file__).resolve().parent.parent)
    a = ap.parse_args(argv)
    errors, warnings = lint(a.root.resolve())
    for w in warnings:
        print("WARN", w)
    for e in errors:
        print("ERROR", e)
    print(f"skill lint: {len(errors)} errors, {len(warnings)} warnings")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
