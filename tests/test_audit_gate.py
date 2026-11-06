"""Tests for scripts/audit_gate.py (the CI audit-gate) and .github/workflows/audit-gate.yml.
Run: python3 -m unittest discover tests"""

import hashlib
import io
import json
import subprocess
import sys
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "scripts"))
import audit_gate as gate  # noqa: E402

BRANCH = "task/TASK-0100-thing"


class Repo(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.git("init", "-q", "-b", "main")
        self.git("config", "user.email", "t@example.com")
        self.git("config", "user.name", "T")
        self.write("games/mathshow/src/a.luau", "-- v1\n")
        self.write("AGENTS.md", "rules\n")
        self.main = self.commit("main")
        self.git("checkout", "-q", "-b", BRANCH)

    def tearDown(self):
        self.tmp.cleanup()

    def git(self, *args):
        return subprocess.run(["git", "-C", str(self.root), *args], capture_output=True, text=True, check=True).stdout.strip()

    def write(self, rel, text):
        path = self.root / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text)

    def commit(self, message="c"):
        self.git("add", "-A")
        self.git("commit", "-q", "--allow-empty", "-m", message)
        return self.git("rev-parse", "HEAD")

    def task_file(self, audit=None, tier="standard", branch=BRANCH):
        data = {"id": "TASK-0100", "branch": branch, "tier": tier, "owner_agent": "claude-code",
                "note_path": "03 Games/T/TASK-0100.md", "audits": [audit] if audit else []}
        self.write("tasks/items/TASK-0100.json", json.dumps(data))

    def run_gate(self, head=None, branch=BRANCH, draft=False):
        out = io.StringIO()
        with redirect_stdout(out):
            code = gate.main(["--root", str(self.root), "--head", head or self.git("rev-parse", "HEAD"),
                              "--branch", branch, "--base", "main"] + (["--draft"] if draft else []))
        return code, out.getvalue()

    def audited(self, auditor="codex", verdict="pass"):
        """Commit the audited source (A), then the audit record; returns (A, head)."""
        self.write("games/mathshow/src/a.luau", "-- v2 audited\n")
        measured = self.commit("A: the audited source")
        report = f"---\nverdict: {verdict}\nreviewed_commit: {measured}\n---\n"
        self.write("06 QA/AUD-1.md", report)
        self.task_file({"result": verdict, "measured_sha": measured, "auditor": auditor, "report": "06 QA/AUD-1.md",
                        "report_sha256": hashlib.sha256(report.encode()).hexdigest()})
        return measured, self.commit("audit record")


class TestGate(Repo):
    def test_a_draft_is_skipped(self):
        self.task_file()
        self.commit()
        code, out = self.run_gate(draft=True)
        self.assertEqual(code, 0)
        self.assertIn("draft", out)

    def test_a_chore_without_source_passes_trivially(self):
        self.git("checkout", "-q", "-b", "chore/rules")
        self.write("AGENTS.md", "more rules\n")
        self.commit()
        code, out = self.run_gate(branch="chore/rules")
        self.assertEqual(code, 0, out)
        self.assertIn("nothing to audit", out)

    def test_a_chore_that_touches_scripts_needs_a_task(self):
        self.git("checkout", "-q", "-b", "chore/tool")
        self.write("scripts/tool.py", "print(1)\n")
        self.commit()
        code, out = self.run_gate(branch="chore/tool")
        self.assertEqual(code, 1)
        self.assertIn("no tasks/items", out)

    def test_a_source_change_without_a_task_fails(self):
        self.write("games/mathshow/src/a.luau", "-- v2\n")
        self.commit()
        code, out = self.run_gate()
        self.assertEqual(code, 1)
        self.assertIn("no tasks/items", out)

    def test_a_task_with_no_audit_fails(self):
        self.write("games/mathshow/src/a.luau", "-- v2\n")
        self.task_file()
        self.commit()
        code, out = self.run_gate()
        self.assertEqual(code, 1)
        self.assertIn("no audit is recorded", out)

    def test_a_pass_that_covers_the_head_passes(self):
        _, head = self.audited()
        code, out = self.run_gate(head)
        self.assertEqual(code, 0, out)
        self.assertIn("covers head", out)

    def test_records_after_the_pass_still_pass(self):
        self.audited()
        self.write("06 QA/AUD-2.md", "later\n")
        self.write("docs/workflow/evidence/TASK-0100/e.txt", "e\n")
        head = self.commit("records")
        self.assertEqual(self.run_gate(head)[0], 0)

    def test_source_changed_after_the_pass_fails_and_names_the_file(self):
        self.audited()
        self.write("games/mathshow/src/a.luau", "-- v3, after the audit\n")
        head = self.commit("B")
        code, out = self.run_gate(head)
        self.assertEqual(code, 1)
        self.assertIn("games/mathshow/src/a.luau", out)

    def test_a_deep_task_needs_codex(self):
        _, head = self.audited(auditor="claude-auditor")
        data = json.loads((self.root / "tasks/items/TASK-0100.json").read_text())
        data["tier"] = "deep"
        self.write("tasks/items/TASK-0100.json", json.dumps(data))
        head = self.commit("deep")
        code, out = self.run_gate(head)
        self.assertEqual(code, 1)
        self.assertIn("Codex", out)

    def test_a_failed_audit_fails(self):
        _, head = self.audited(verdict="fail")
        code, out = self.run_gate(head)
        self.assertEqual(code, 1)
        self.assertIn("not a PASS", out)

    def test_light_tier_passes_without_an_audit(self):
        self.write("games/mathshow/src/a.luau", "-- v2\n")
        self.task_file(tier="light")
        head = self.commit()
        self.assertEqual(self.run_gate(head)[0], 0)

    def test_a_missing_head_is_undecidable(self):
        code, out = self.run_gate("0" * 40)
        self.assertEqual(code, 2)


class TestWorkflowFile(unittest.TestCase):
    text = (ROOT / ".github" / "workflows" / "audit-gate.yml").read_text()

    def test_the_job_and_trigger(self):
        self.assertIn("\n  audit-gate:\n", self.text)
        self.assertIn("pull_request:", self.text)
        self.assertNotIn("pull_request_target", self.text)

    def test_least_privilege_and_no_secrets(self):
        self.assertIn("permissions:\n  contents: read\n", self.text)
        self.assertNotIn("secrets.", self.text)
        self.assertNotIn("GITHUB_TOKEN", self.text)

    def test_it_checks_out_the_pr_head_with_history(self):
        self.assertIn("ref: ${{ github.event.pull_request.head.sha }}", self.text)
        self.assertIn("fetch-depth: 0", self.text)

    def test_untrusted_names_go_through_env_not_the_script(self):
        run = self.text.split("run: |", 1)[1]
        self.assertNotIn("${{", run)


if __name__ == "__main__":
    unittest.main()
