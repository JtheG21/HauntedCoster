"""Tests for scripts/orchestrator.py. Run: python3 -m unittest discover tests"""

import io
import json
import sys
import tempfile
import unittest
from contextlib import redirect_stderr, redirect_stdout
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "scripts"))
import orchestrator as orch  # noqa: E402


def task(tid, status="proposed", deps=None):
    return {"id": tid, "title": f"Task {tid}", "status": status, "risk": "low",
            "depends_on": deps or [], "branch": f"task/{tid}", "acceptance_criteria": ["works"]}


class Base(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        (self.root / "tasks").mkdir()
        (self.root / "workflow").mkdir()
        self.write_budget({"monthly_limit_usd": 10, "per_task_limit_usd": 3, "max_revisions": 2,
                           "dispatch_mode": "dry-run"})
        self.write_queue([task("T-001"), task("T-002", deps=["T-001"])])

    def tearDown(self):
        self.tmp.cleanup()

    def write_budget(self, b):
        (self.root / "workflow" / "budget.json").write_text(json.dumps(b))

    def write_queue(self, tasks):
        (self.root / "tasks" / "queue.json").write_text(json.dumps({"version": 1, "tasks": tasks}))

    def proj(self):
        return orch.Project(self.root)

    def cli(self, *args):
        out, err = io.StringIO(), io.StringIO()
        with redirect_stdout(out), redirect_stderr(err):
            code = orch.main(["--root", str(self.root), *args])
        return code, out.getvalue() + err.getvalue()


class TestValidation(Base):
    def test_valid_queue(self):
        self.assertEqual(self.proj().validate(), [])

    def test_unknown_dep_bad_status_and_duplicate(self):
        bad = task("T-003", status="weird", deps=["T-999"])
        self.write_queue([task("T-001"), task("T-001"), bad])
        errors = "\n".join(self.proj().validate())
        self.assertIn("duplicate id", errors)
        self.assertIn("invalid status", errors)
        self.assertIn("unknown task T-999", errors)

    def test_cycle_detected(self):
        self.write_queue([task("T-001", deps=["T-002"]), task("T-002", deps=["T-001"])])
        self.assertTrue(any("cycle" in e for e in self.proj().validate()))

    def test_invalid_json_reported(self):
        (self.root / "tasks" / "queue.json").write_text("{nope")
        code, out = self.cli("validate")
        self.assertEqual(code, 2)
        self.assertIn("invalid JSON", out)


class TestWorkflow(Base):
    def test_cannot_start_without_approval(self):
        p = self.proj()
        with self.assertRaises(orch.OrchestratorError):
            p.start("T-001")

    def test_dependencies_gate_start(self):
        p = self.proj()
        p.approve("T-002", "jg")
        with self.assertRaises(orch.OrchestratorError):
            p.start("T-002")

    def test_happy_path(self):
        p = self.proj()
        p.approve("T-001", "jg")
        p.start("T-001")
        p.record_exec("T-001", "pass", "checks ok")
        p.record_audit("T-001", "pass", "reports/audits/T-001-attempt1.md")
        self.assertEqual(p.task("T-001")["status"], "awaiting_merge")
        p.approve_merge("T-001", "jg")
        p.save()
        self.assertEqual(self.proj().task("T-001")["status"], "done")
        self.assertEqual([t["id"] for t in self.proj().ready()], [])

    def test_revision_limit_blocks(self):
        p = self.proj()
        p.approve("T-001", "jg")
        for attempt in range(3):
            p.start("T-001")
            p.record_exec("T-001", "pass", "")
            p.record_audit("T-001", "fail", f"a{attempt}.md")
        t = p.task("T-001")
        self.assertEqual(t["status"], "blocked")
        self.assertEqual(t["revisions"], 3)
        with self.assertRaises(orch.OrchestratorError):
            p.start("T-001")

    def test_audit_cannot_be_skipped(self):
        p = self.proj()
        p.approve("T-001", "jg")
        p.start("T-001")
        with self.assertRaises(orch.OrchestratorError):
            p.approve_merge("T-001", "jg")

    def test_unblock_resets(self):
        p = self.proj()
        t = p.task("T-001")
        t["status"], t["revisions"] = "blocked", 3
        p.unblock("T-001", "approved", "jg")
        self.assertEqual((t["status"], t["revisions"]), ("approved", 0))


class TestBudgetAndDispatch(Base):
    def test_api_limit_stops_start(self):
        p = self.proj()
        p.approve("T-001", "jg")
        p.record_usage("T-001", "api", "executor", 10.0, None, 1000, "m", "")
        with self.assertRaises(orch.OrchestratorError) as cm:
            p.start("T-001")
        self.assertIn("monthly API limit", str(cm.exception))

    def test_subscription_usage_not_counted_as_spend(self):
        p = self.proj()
        p.record_usage("T-001", "subscription", "executor", None, 5.0, None, "m", "")
        self.assertEqual(p.api_spend(), 0)

    def test_dispatch_dry_run_writes_prompt_only(self):
        p = self.proj()
        p.approve("T-001", "jg")
        p.start("T-001")
        msg = p.dispatch("T-001", "executor", live=False)
        self.assertIn("[dry-run]", msg)
        prompt = (self.root / "reports" / "prompts" / "T-001-executor.md").read_text()
        self.assertIn("workflow/roles/executor.md", prompt)
        self.assertFalse((self.root / "tasks" / "usage-ledger.jsonl").exists())

    def test_live_dispatch_refused(self):
        p = self.proj()
        p.approve("T-001", "jg")
        p.start("T-001")
        with self.assertRaises(orch.OrchestratorError):
            p.dispatch("T-001", "executor", live=True)

    def test_report_and_state(self):
        code, out = self.cli("report")
        self.assertEqual(code, 0, out)
        state = json.loads((self.root / "project-state.json").read_text())
        self.assertIn("T-001", state["needs_human"])
        self.assertTrue(list((self.root / "reports" / "health").glob("progress-*.md")))


if __name__ == "__main__":
    unittest.main()
