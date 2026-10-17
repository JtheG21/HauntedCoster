#!/usr/bin/env python3
"""Lightweight task orchestrator for the Rg1 workflow (standard library only).

Tracks tasks in tasks/queue.json (authoritative), mirrors each task's status into
its Obsidian note, enforces approval gates and revision limits, records a usage
ledger, updates project-state.json and writes Markdown health reports.
Statuses follow 00 Studio/Obsidian Conventions.md.
It never calls an AI itself: `dispatch` builds the prompt and, in dry-run mode
(the only mode currently enabled), prints what it would run.

Run `python3 scripts/orchestrator.py --help` for commands.
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import re
import sys
from pathlib import Path

STATES = {
    "inbox", "research", "proposed", "ready", "in_progress", "blocked",
    "in_review", "changes_requested", "approved", "done", "archived",
}
TERMINAL = {"done", "archived"}
NEEDS_HUMAN = ("proposed", "approved", "blocked")
GEN_START = "<!-- orchestrator:generated:start -->"
GEN_END = "<!-- orchestrator:generated:end -->"
RISKS = {"low", "medium", "high"}
ID_RE = re.compile(r"^TASK-\d{4}$")
REQUIRED = ("id", "title", "status", "risk", "depends_on", "acceptance_criteria")
USAGE_KINDS = {"subscription", "api"}


class OrchestratorError(Exception):
    pass


def now() -> str:
    return dt.datetime.now().isoformat(timespec="seconds")


class Project:
    def __init__(self, root: Path):
        self.root = root
        self.queue_path = root / "tasks" / "queue.json"
        self.budget_path = root / "00 Studio" / "budget.json"
        self.state_path = root / "project-state.json"
        self.ledger_path = root / "tasks" / "usage-ledger.jsonl"
        self.reviews_dir = root / "08 Reviews"
        self.prompts_dir = root / "tasks" / "prompts"
        self.queue = self._load(self.queue_path, {"version": 1, "tasks": []})
        self.budget = self._load(self.budget_path, {})

    @staticmethod
    def _load(path: Path, default):
        if not path.exists():
            return default
        try:
            return json.loads(path.read_text())
        except json.JSONDecodeError as e:
            raise OrchestratorError(f"{path}: invalid JSON ({e})") from e

    def save(self) -> None:
        self.queue_path.write_text(json.dumps(self.queue, indent=2) + "\n")
        self._write_state()

    # ---- lookup / validation -------------------------------------------
    @property
    def tasks(self) -> list[dict]:
        return self.queue.get("tasks", [])

    def task(self, task_id: str) -> dict:
        for t in self.tasks:
            if t.get("id") == task_id:
                return t
        raise OrchestratorError(f"unknown task {task_id}")

    def validate(self) -> list[str]:
        errors: list[str] = []
        ids = [t.get("id") for t in self.tasks]
        seen: set = set()
        for t in self.tasks:
            tid = t.get("id", "?")
            for key in REQUIRED:
                if key not in t:
                    errors.append(f"{tid}: missing '{key}'")
            if not ID_RE.match(str(tid)):
                errors.append(f"{tid}: id must look like TASK-0001")
            if tid in seen:
                errors.append(f"{tid}: duplicate id")
            seen.add(tid)
            if t.get("status") not in STATES:
                errors.append(f"{tid}: invalid status '{t.get('status')}'")
            if t.get("risk") not in RISKS:
                errors.append(f"{tid}: invalid risk '{t.get('risk')}'")
            if not t.get("acceptance_criteria"):
                errors.append(f"{tid}: needs at least one acceptance criterion")
            for dep in t.get("depends_on", []):
                if dep not in ids:
                    errors.append(f"{tid}: depends on unknown task {dep}")
            note = t.get("note")
            if note and not (self.root / note).exists():
                errors.append(f"{tid}: note not found: {note}")
        errors += self._cycles()
        for key in ("monthly_limit_usd", "max_revisions"):
            if key not in self.budget:
                errors.append(f"budget.json: missing '{key}'")
        if self.ledger_path.exists():
            for n, line in enumerate(self.ledger_path.read_text().splitlines(), 1):
                if not line.strip():
                    continue
                try:
                    json.loads(line)
                except json.JSONDecodeError:
                    errors.append(f"usage-ledger.jsonl line {n}: not valid JSON (merge conflict marker?)")
        return errors

    def _cycles(self) -> list[str]:
        graph = {t.get("id"): t.get("depends_on", []) for t in self.tasks}
        visiting, done, errors = set(), set(), []

        def visit(node, path):
            if node in done or node not in graph:
                return
            if node in visiting:
                errors.append("dependency cycle: " + " -> ".join(path + [node]))
                return
            visiting.add(node)
            for dep in graph[node]:
                visit(dep, path + [node])
            visiting.discard(node)
            done.add(node)

        for node in graph:
            visit(node, [])
        return errors

    def require_valid(self) -> None:
        errors = self.validate()
        if errors:
            raise OrchestratorError("queue invalid:\n  " + "\n  ".join(errors))

    # ---- budget / usage --------------------------------------------------
    def ledger(self) -> list[dict]:
        if not self.ledger_path.exists():
            return []
        return [json.loads(line) for line in self.ledger_path.read_text().splitlines() if line.strip()]

    def api_spend(self, month: str | None = None, task_id: str | None = None) -> float:
        month = month or dt.date.today().strftime("%Y-%m")
        total = 0.0
        for e in self.ledger():
            if e.get("kind") != "api" or not e.get("time", "").startswith(month):
                continue
            if task_id and e.get("task") != task_id:
                continue
            total += float(e.get("cost_usd") or e.get("est_cost_usd") or 0)
        return round(total, 4)

    def budget_block_reason(self, task_id: str) -> str | None:
        limit = float(self.budget.get("monthly_limit_usd", 0))
        spent = self.api_spend()
        if limit and spent >= limit:
            return f"monthly API limit reached (${spent:.2f} / ${limit:.2f})"
        per_task = float(self.budget.get("per_task_limit_usd", 0))
        task_spent = self.api_spend(task_id=task_id)
        if per_task and task_spent >= per_task:
            return f"per-task API limit reached for {task_id} (${task_spent:.2f} / ${per_task:.2f})"
        return None

    # ---- transitions -----------------------------------------------------
    def _move(self, t: dict, new: str, note: str) -> None:
        old = t["status"]
        t["status"] = new
        t.setdefault("history", []).append({"time": now(), "from": old, "to": new, "note": note})
        self._sync_note(t)

    def _sync_note(self, t: dict) -> None:
        """Mirror status/updated into the task note's frontmatter (queue is authoritative)."""
        rel = t.get("note")
        if not rel:
            return
        path = self.root / rel
        if not path.exists():
            raise OrchestratorError(f"{t['id']}: note not found: {rel}")
        text = path.read_text()
        m = re.match(r"^---\n(.*?)\n---\n", text, re.S)
        if not m:
            raise OrchestratorError(f"{rel}: no frontmatter")
        fm = m.group(1)
        today = dt.date.today().isoformat()
        for key, value in (("status", t["status"]), ("updated", today)):
            if re.search(rf"^{key}:.*$", fm, re.M):
                fm = re.sub(rf"^{key}:.*$", f"{key}: {value}", fm, count=1, flags=re.M)
            else:
                fm += f"\n{key}: {value}"
        path.write_text(f"---\n{fm}\n---\n" + text[m.end():])

    def _expect(self, t: dict, *states: str) -> None:
        if t["status"] not in states:
            raise OrchestratorError(f"{t['id']} is '{t['status']}', expected one of {sorted(states)}")

    def deps_done(self, t: dict) -> bool:
        return all(self.task(d)["status"] == "done" for d in t.get("depends_on", []))

    def ready(self) -> list[dict]:
        return [t for t in self.tasks
                if t["status"] in ("ready", "changes_requested") and self.deps_done(t)]

    def approve(self, task_id: str, by: str) -> None:
        t = self.task(task_id)
        self._expect(t, "proposed")
        t["approved_by"] = by
        self._move(t, "ready", f"plan approved by {by}")

    def start(self, task_id: str) -> None:
        t = self.task(task_id)
        self._expect(t, "ready", "changes_requested")
        if not self.deps_done(t):
            raise OrchestratorError(f"{task_id}: dependencies not done: {t['depends_on']}")
        reason = self.budget_block_reason(task_id)
        if reason:
            raise OrchestratorError(f"{task_id}: {reason}")
        self._move(t, "in_progress", "started")

    def _fail(self, t: dict, note: str) -> None:
        t["revisions"] = t.get("revisions", 0) + 1
        limit = int(self.budget.get("max_revisions", 2))
        if t["revisions"] > limit:
            self._move(t, "blocked", f"{note}; revision limit {limit} exceeded, needs human")
        else:
            self._move(t, "changes_requested", f"{note}; revision {t['revisions']}/{limit}")

    def record_exec(self, task_id: str, result: str, notes: str) -> None:
        t = self.task(task_id)
        self._expect(t, "in_progress")
        t.setdefault("executions", []).append({"time": now(), "result": result, "notes": notes})
        if result == "pass":
            self._move(t, "in_review", "execution checks passed")
        else:
            self._fail(t, "execution checks failed")

    def record_audit(self, task_id: str, result: str, report: str) -> None:
        t = self.task(task_id)
        self._expect(t, "in_review")
        if not (self.root / report).exists():
            raise OrchestratorError(f"audit report not found: {report}")
        t.setdefault("audits", []).append({"time": now(), "result": result, "report": report})
        if result == "pass":
            self._move(t, "approved", "audit passed; merge needs human approval")
        else:
            self._fail(t, "audit failed")

    def request_changes(self, task_id: str, by: str, reason: str) -> None:
        """Human sends an audited (or in-review) task back for fixes. Counts as a revision."""
        t = self.task(task_id)
        self._expect(t, "in_review", "approved")
        self._fail(t, f"changes requested by {by}: {reason}")

    def approve_merge(self, task_id: str, by: str) -> None:
        t = self.task(task_id)
        self._expect(t, "approved")
        t["merge_approved_by"] = by
        self._move(t, "done", f"merge approved by {by}")

    def unblock(self, task_id: str, to: str, by: str) -> None:
        t = self.task(task_id)
        self._expect(t, "blocked")
        if to not in ("ready", "proposed", "archived"):
            raise OrchestratorError("unblock target must be ready, proposed or archived")
        t["revisions"] = 0
        self._move(t, to, f"unblocked by {by}")

    def archive(self, task_id: str, by: str) -> None:
        t = self.task(task_id)
        if t["status"] in TERMINAL:
            raise OrchestratorError(f"{task_id} already {t['status']}")
        self._move(t, "archived", f"archived by {by}")

    def record_usage(self, task_id: str, kind: str, role: str, cost_usd: float | None,
                     est_cost_usd: float | None, tokens: int | None, model: str, note: str) -> dict:
        self.task(task_id)
        if kind not in USAGE_KINDS:
            raise OrchestratorError(f"kind must be one of {sorted(USAGE_KINDS)}")
        entry = {"time": now(), "task": task_id, "kind": kind, "role": role, "model": model,
                 "cost_usd": cost_usd, "est_cost_usd": est_cost_usd, "tokens": tokens, "note": note}
        self.ledger_path.parent.mkdir(parents=True, exist_ok=True)
        with self.ledger_path.open("a") as f:
            f.write(json.dumps(entry) + "\n")
        return entry

    # ---- dispatch (dry-run) ---------------------------------------------
    def build_prompt(self, t: dict, role: str) -> str:
        note = t.get("note", f"(task note for {t['id']})")
        lines = [
            f"You are the {role.upper()} for task {t['id']}: {t['title']}.",
            f"Follow '04 Agents/{role.capitalize()}.md' exactly. Read CLAUDE.md and '{note}'.",
            "Read only the files listed in the spec unless blocked; do not scan the whole repo.",
        ]
        if role == "executor":
            lines.append(f"Work on branch {t.get('branch', 'task/' + t['id'])}. Run scripts/check.sh before finishing.")
        if role == "auditor":
            lines.append(f"Audit `git diff main...{t.get('branch')}` against the acceptance criteria.")
        if t.get("audits") and role == "executor":
            lines.append(f"Address findings in '{t['audits'][-1]['report']}'.")
        return "\n".join(lines) + "\n"

    def dispatch(self, task_id: str, role: str, live: bool) -> str:
        t = self.task(task_id)
        expected = {"executor": ("in_progress",), "auditor": ("in_review",),
                    "planner": ("proposed",), "researcher": ("proposed", "research")}[role]
        self._expect(t, *expected)
        reason = self.budget_block_reason(task_id)
        if reason:
            raise OrchestratorError(reason)
        prompt = self.build_prompt(t, role)
        out = self.prompts_dir / f"{task_id}-{role}.md"
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(prompt)
        if live or self.budget.get("dispatch_mode") == "live":
            raise OrchestratorError("live dispatch is not enabled yet: run the prompt manually in Claude Code")
        rel = out.relative_to(self.root)
        return (f"[dry-run] prompt written to {rel}\n"
                f"[dry-run] would run (subscription, interactive): claude \"$(cat {rel})\"\n"
                f"[dry-run] no AI call made; nothing recorded in the ledger")

    # ---- state & reports -------------------------------------------------
    def counts(self) -> dict:
        c: dict = {}
        for t in self.tasks:
            c[t["status"]] = c.get(t["status"], 0) + 1
        return c

    def _write_state(self) -> None:
        state = self._load(self.state_path, {})
        state.update({
            "updated": now(),
            "task_counts": self.counts(),
            "ready": [t["id"] for t in self.ready()],
            "needs_human": [t["id"] for t in self.tasks if t["status"] in NEEDS_HUMAN],
            "api_spend_this_month_usd": self.api_spend(),
        })
        self.state_path.write_text(json.dumps(state, indent=2) + "\n")

    def report(self) -> Path:
        today = dt.date.today().isoformat()
        stamp = today.replace("-", "")
        header = [
            "---", f"id: HLT-{stamp}", f"title: Health report {today}", "type: health", "status: done",
            f"created: {today}", f"updated: {today}", "tags:", "  - workflow/health", "---",
            f"# Health report: {today}", "",
        ]
        lines = [
            GEN_START, f"## Task snapshot (generated {now()})", "",
            "| Task | Title | Status | Risk | Revisions |", "|---|---|---|---|---|",
        ]
        for t in self.tasks:
            name = Path(t["note"]).stem if t.get("note") else t["id"]
            lines.append(f"| [[{name}]] | {t['title']} | {t['status']} | {t['risk']} | {t.get('revisions', 0)} |")
        needs = [t for t in self.tasks if t["status"] in NEEDS_HUMAN]
        lines += ["", "## Needs human"]
        lines += [f"- {t['id']} ({t['status']})" for t in needs] or ["- nothing"]
        ledger = self.ledger()
        subs = sum(1 for e in ledger if e.get("kind") == "subscription")
        lines += ["", "## Usage",
                  f"- API spend this month: ${self.api_spend():.2f} / ${float(self.budget.get('monthly_limit_usd', 0)):.2f}",
                  f"- Subscription sessions logged: {subs}", GEN_END]
        block = "\n".join(lines)
        out = self.reviews_dir / f"HLT-{stamp}.md"
        out.parent.mkdir(parents=True, exist_ok=True)
        if out.exists():
            # Never discard hand-written content: replace only the generated block, or append it.
            text = out.read_text()
            if GEN_START in text and GEN_END in text:
                head, rest = text.split(GEN_START, 1)
                text = head + block + rest.split(GEN_END, 1)[1]
            else:
                text = text.rstrip("\n") + "\n\n" + block + "\n"
            text = re.sub(r"^updated:.*$", f"updated: {today}", text, count=1, flags=re.M)
            out.write_text(text)
        else:
            out.write_text("\n".join(header) + "\n" + block + "\n\nRelated: [[Studio Index]]\n")
        self._write_state()
        return out


def cycle_report(proj: "Project") -> str:
    """Per-task cycle data from the queue and usage ledger: the baseline for any claim that a workflow change is faster."""
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    import refs
    tokens = refs.usage_tokens(proj.root)
    rows, hours, revs = [], [], []
    for t in proj.tasks:
        c = refs.task_cycle(t)
        if c["hours"] is not None:
            hours.append(c["hours"])
        revs.append(c["revisions"])
        tok = tokens.get(t["id"])
        rows.append(f"{t['id']:9} {t['status']:15} rev={c['revisions']} exec={c['executions']} audits={c['audits']} "
                    f"hours={c['hours'] if c['hours'] is not None else 'n/a':>5} tokens={tok if tok else 'n/a'}")
    summary = (f"{len(proj.tasks)} tasks; mean revisions {sum(revs) / max(len(revs), 1):.2f}; "
               + (f"median start-to-review {sorted(hours)[len(hours) // 2]} h over {len(hours)} tasks" if hours else "no timed tasks")
               + ". Tokens are only what record-usage logged. "
               "Queue times mark when the orchestrator was called, which can differ from real working time.")
    return "\n".join(rows + [summary])


def files_expected(proj: "Project", t: dict) -> tuple[set[str], bool]:
    """Paths listed under '## Files expected to change' in the task note, and whether its Tests mention Studio."""
    note = proj.root / t.get("note", "")
    if not note.is_file():
        return set(), False
    text = note.read_text(encoding="utf-8")
    m = re.search(r"(?ms)^## Files expected to change\s*\n(.*?)(?=^## |\Z)", text)
    paths = set()
    for line in (m.group(1) if m else "").splitlines():
        line = line.strip()
        if line.startswith("-") and len(line) > 1:
            found = re.findall(r"`([^`]+)`", line)
            paths |= set(found) if found else {line.lstrip("- ").strip()}
    tests = re.search(r"(?ms)^## Tests\s*\n(.*?)(?=^## |\Z)", text)
    return {p for p in paths if p}, bool(tests and re.search(r"Studio", tests.group(1)))


def overlap(a: str, b: str) -> bool:
    a, b = a.rstrip("/"), b.rstrip("/")
    return a == b or a.startswith(b + "/") or b.startswith(a + "/")


def parallel_report(proj: "Project") -> str:
    """Which ready tasks could run side by side. Reports only: starting parallel work needs jg (delegation budget)."""
    ready = proj.ready()
    if len(ready) < 2:
        return f"{len(ready)} ready task(s); nothing to compare."
    info = {t["id"]: files_expected(proj, t) for t in ready}
    lines = []
    for i, a in enumerate(ready):
        for b in ready[i + 1:]:
            (fa, sa), (fb, sb) = info[a["id"]], info[b["id"]]
            reasons = []
            if not fa or not fb:
                reasons.append("a task lists no expected files, so overlap is unknown")
            elif any(overlap(x, y) for x in fa for y in fb):
                reasons.append("expected files overlap")
            if sa and sb:
                reasons.append("both need Studio (one assistant at a time)")
            lines.append(f"{a['id']} + {b['id']}: " + ("NOT SAFE: " + "; ".join(reasons) if reasons else "no overlap found"))
    lines.append("A report, not approval: a second parallel agent still needs jg's explicit authorization (AGENTS.md).")
    return "\n".join(lines)


def reference_brief(root: Path, task_id: str) -> None:
    """Print the task's reference brief (Task Intake step 5). Best effort: never blocks a start."""
    try:
        sys.path.insert(0, str(Path(__file__).resolve().parent))
        import refs
        print()
        refs.cmd_brief(root, None, task_id, None, "standard", 6)
    except (SystemExit, Exception) as e:  # noqa: BLE001
        print(f"(no reference brief: {e})")


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--root", type=Path, default=Path(__file__).resolve().parent.parent)
    sub = p.add_subparsers(dest="cmd", required=True)
    sub.add_parser("validate", help="validate queue.json and budget.json")
    sub.add_parser("status", help="list tasks")
    s = sub.add_parser("next", help="show tasks ready to start")
    s.add_argument("--parallel-safe", action="store_true", help="also report which ready tasks could run side by side")
    sub.add_parser("cycles", help="per-task revisions, start-to-review hours and tokens (baseline data)")
    sub.add_parser("report", help="write 08 Reviews/HLT-<date>.md and update project-state.json")
    for name in ("approve", "approve-merge", "archive"):
        s = sub.add_parser(name)
        s.add_argument("id")
        s.add_argument("--by", required=True, help="name of the human approving")
    s = sub.add_parser("start"); s.add_argument("id")
    s = sub.add_parser("request-changes", help="HUMAN: send an in_review/approved task back for fixes (counts as a revision)")
    s.add_argument("id"); s.add_argument("--by", required=True); s.add_argument("--reason", required=True)
    s = sub.add_parser("unblock"); s.add_argument("id"); s.add_argument("--to", required=True); s.add_argument("--by", required=True)
    s = sub.add_parser("record-exec"); s.add_argument("id"); s.add_argument("--result", choices=["pass", "fail"], required=True); s.add_argument("--notes", default="")
    s = sub.add_parser("record-audit"); s.add_argument("id"); s.add_argument("--result", choices=["pass", "fail"], required=True); s.add_argument("--report", required=True)
    s = sub.add_parser("record-usage"); s.add_argument("id"); s.add_argument("--kind", choices=sorted(USAGE_KINDS), required=True)
    s.add_argument("--role", default=""); s.add_argument("--model", default=""); s.add_argument("--cost-usd", type=float)
    s.add_argument("--est-cost-usd", type=float); s.add_argument("--tokens", type=int); s.add_argument("--note", default="")
    s = sub.add_parser("dispatch", help="build role prompt (dry-run only for now)")
    s.add_argument("id"); s.add_argument("--role", choices=["executor", "auditor", "planner", "researcher"], required=True)
    s.add_argument("--live", action="store_true", help="not enabled yet")
    a = p.parse_args(argv)

    try:
        proj = Project(a.root)
        if a.cmd == "validate":
            errors = proj.validate()
            for e in errors:
                print("ERROR", e)
            print(f"{len(proj.tasks)} tasks, {len(errors)} errors")
            return 1 if errors else 0
        proj.require_valid()
        if a.cmd == "status":
            for t in proj.tasks:
                deps = ",".join(t["depends_on"]) or "-"
                print(f"{t['id']:9} {t['status']:15} {t['risk']:6} deps={deps:10} {t['title']}")
            print(f"API spend this month: ${proj.api_spend():.2f}")
            return 0
        if a.cmd == "next":
            ready = proj.ready()
            for t in ready:
                block = proj.budget_block_reason(t["id"])
                print(f"{t['id']} ({t['status']}): {t['title']}" + (f"  [BLOCKED: {block}]" if block else ""))
            if not ready:
                print("nothing ready (approve a proposed task, or finish dependencies)")
            if a.parallel_safe:
                print(parallel_report(proj))
            return 0
        if a.cmd == "cycles":
            print(cycle_report(proj))
            return 0
        if a.cmd == "report":
            print(f"wrote {proj.report().relative_to(proj.root)}")
            return 0
        if a.cmd == "dispatch":
            print(proj.dispatch(a.id, a.role, a.live))
            return 0
        if a.cmd == "record-usage":
            print(json.dumps(proj.record_usage(a.id, a.kind, a.role, a.cost_usd, a.est_cost_usd, a.tokens, a.model, a.note)))
            proj._write_state()
            return 0
        actions = {
            "approve": lambda: proj.approve(a.id, a.by),
            "approve-merge": lambda: proj.approve_merge(a.id, a.by),
            "archive": lambda: proj.archive(a.id, a.by),
            "start": lambda: proj.start(a.id),
            "unblock": lambda: proj.unblock(a.id, a.to, a.by),
            "request-changes": lambda: proj.request_changes(a.id, a.by, a.reason),
            "record-exec": lambda: proj.record_exec(a.id, a.result, a.notes),
            "record-audit": lambda: proj.record_audit(a.id, a.result, a.report),
        }
        actions[a.cmd]()
        proj.save()
        print(f"{a.id} -> {proj.task(a.id)['status']}")
        if a.cmd == "start":
            reference_brief(proj.root, a.id)
        return 0
    except OrchestratorError as e:
        print(f"error: {e}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
