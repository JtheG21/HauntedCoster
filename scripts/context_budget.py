#!/usr/bin/env python3
"""Measure the instruction context an AI session receives (standard library only).

Read-only. Byte counts are exact. Token figures are ESTIMATES (bytes / 4) and are
labelled as such: they are not API-reported usage (see 09 Knowledge usage notes).

Sections:
  always     files injected into every session (CLAUDE.md imports AGENTS.md)
  spawn      definitions loaded only when a subagent starts
  start      docs an agent is told to read at task start, for one role
  skills     skill descriptions (listed every session) vs bodies (loaded on invoke)
  prompt     the dispatch prompt the orchestrator builds for a sample task
  dupes      sentences repeated across the always-loaded and start docs

Usage:
  python3 scripts/context_budget.py [--root DIR] [--role executor|auditor] [--sample TASK-ID]
"""

from __future__ import annotations

import argparse
import importlib.util
import re
import sys
from pathlib import Path

ALWAYS = ("CLAUDE.md", "AGENTS.md")
SPAWN = (".claude/agents/auditor.md",)
START_DOCS = ("04 Agents/Task Intake.md", "04 Agents/Workflow.md")
ROLE_DOCS = {"executor": "04 Agents/Executor.md", "auditor": "04 Agents/Auditor.md"}
MIN_SENTENCE = 60  # shorter sentences repeat naturally ("Run the tests.")
SENTENCE_SPLIT = re.compile(r"(?<=[.!?])\s+|\n+")


def est_tokens(nbytes: int) -> int:
    return nbytes // 4


def size(root: Path, rel: str) -> int | None:
    path = root / rel
    return path.stat().st_size if path.is_file() else None


def frontmatter_description(text: str) -> str:
    if not text.startswith("---"):
        return ""
    end = text.find("\n---", 3)
    head = text[3:end] if end != -1 else ""
    m = re.search(r"(?m)^description:\s*(.*)$", head)
    return m.group(1).strip() if m else ""


def normalise(sentence: str) -> str:
    sentence = re.sub(r"[`*_|#>]|^\s*[-\d.]+\s+", " ", sentence, flags=re.M)
    return " ".join(sentence.lower().split())


def duplicate_sentences(texts: dict[str, str]) -> tuple[int, int, list[str]]:
    """Return (distinct repeated sentences, repeated bytes beyond first copy, sample)."""
    where: dict[str, set[str]] = {}
    size_of: dict[str, int] = {}
    counts: dict[str, int] = {}
    for name, text in texts.items():
        for raw in SENTENCE_SPLIT.split(text):
            key = normalise(raw)
            if len(key) < MIN_SENTENCE:
                continue
            where.setdefault(key, set()).add(name)
            size_of[key] = len(raw.encode())
            counts[key] = counts.get(key, 0) + 1
    repeated = [k for k in where if len(where[k]) > 1]
    extra = sum((counts[k] - 1) * size_of[k] for k in repeated)
    sample = sorted(repeated, key=lambda k: -size_of[k])[:3]
    return len(repeated), extra, [s[:90] for s in sample]


def load_orchestrator(root: Path):
    """Load the orchestrator that belongs to the checkout being measured, not the one running this script."""
    path = root / "scripts" / "orchestrator.py"
    if not path.is_file():
        raise FileNotFoundError(f"{path} not found; --root must be a checkout with scripts/orchestrator.py")
    spec = importlib.util.spec_from_file_location("rg1_root_orchestrator", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def sample_prompt(root: Path, role: str, task_id: str | None) -> str | None:
    orchestrator = load_orchestrator(root)
    proj = orchestrator.Project(root)
    tasks = proj.tasks
    if task_id:
        task = proj.task(task_id)
    else:
        candidates = [t for t in tasks if t.get("note")]
        if not candidates:
            return None
        task = candidates[-1]
    return proj.build_prompt(task, role)


def report(root: Path, role: str, sample: str | None) -> str:
    lines: list[str] = []

    def row(label: str, nbytes: int | None) -> None:
        if nbytes is None:
            lines.append(f"  {label:<46} missing")
        else:
            lines.append(f"  {label:<46} {nbytes:>8} B  ~{est_tokens(nbytes):>6} tok (est)")

    lines.append("always loaded (every session):")
    always_total = 0
    texts: dict[str, str] = {}
    for rel in ALWAYS:
        n = size(root, rel)
        row(rel, n)
        if n:
            always_total += n
            texts[rel] = (root / rel).read_text(encoding="utf-8")
    lines.append(f"  {'total':<46} {always_total:>8} B  ~{est_tokens(always_total):>6} tok (est)")

    lines.append("loaded when a subagent starts:")
    for rel in SPAWN:
        row(rel, size(root, rel))

    lines.append(f"task start, role '{role}' (read on instruction):")
    start_total = 0
    for rel in START_DOCS + (ROLE_DOCS[role],):
        n = size(root, rel)
        row(rel, n)
        if n:
            start_total += n
            texts[rel] = (root / rel).read_text(encoding="utf-8")
    lines.append(f"  {'total (start docs + role doc)':<46} {start_total:>8} B  ~{est_tokens(start_total):>6} tok (est)")

    skills = sorted((root / ".claude" / "skills").glob("*/SKILL.md"))
    desc_bytes = body_bytes = 0
    biggest = ("", 0)
    for path in skills:
        text = path.read_text(encoding="utf-8")
        desc_bytes += len(frontmatter_description(text).encode())
        body_bytes += len(text.encode())
        if len(text.encode()) > biggest[1]:
            biggest = (path.parent.name, len(text.encode()))
    lines.append(f"skills ({len(skills)} project skills):")
    lines.append(f"  {'descriptions (listed every session)':<46} {desc_bytes:>8} B  ~{est_tokens(desc_bytes):>6} tok (est)")
    lines.append(f"  {'bodies (only when invoked), total':<46} {body_bytes:>8} B")
    lines.append(f"  {'largest body: ' + biggest[0]:<46} {biggest[1]:>8} B")

    lines.append("dispatch prompt (orchestrator build_prompt):")
    if sample is None:
        lines.append("  no task with a note found; skipped")
    else:
        row(f"prompt for {role}", len(sample.encode()))

    count, extra, examples = duplicate_sentences(texts)
    lines.append(f"duplication (sentences >= {MIN_SENTENCE} chars across always + start docs):")
    lines.append(f"  repeated sentences: {count}; repeated bytes beyond first copy: {extra} B")
    for ex in examples:
        lines.append(f"    e.g. \"{ex}\"")
    lines.append("Token figures are estimates (bytes / 4), not API-reported usage.")
    return "\n".join(lines)


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--root", default=str(Path(__file__).resolve().parent.parent))
    ap.add_argument("--role", choices=sorted(ROLE_DOCS), default="executor")
    ap.add_argument("--sample", default=None, help="task id for the dispatch prompt sample")
    a = ap.parse_args(argv)
    root = Path(a.root).resolve()
    try:
        sample = sample_prompt(root, a.role, a.sample) if (root / "tasks" / "queue.json").is_file() else None
    except Exception as e:  # bad --root, unknown --sample or invalid queue: report it, don't guess a prompt
        print(f"error: {e}", file=sys.stderr)
        return 2
    print(report(root, a.role, sample))
    return 0


if __name__ == "__main__":
    sys.exit(main())
