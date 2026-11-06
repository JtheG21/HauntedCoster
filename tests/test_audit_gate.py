"""Tests for scripts/audit_gate.py (the CI audit-gate) and .github/workflows/audit-gate.yml.

Each `TestBypass*` test reproduces a bypass from AUD-20261105-TASK-0140-01 against a real Git history and shows the
gate refuses it. Run: python3 -m unittest discover tests"""

import hashlib
import io
import json
import os
import re
import subprocess
import sys
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "scripts"))
import audit_gate as gate  # noqa: E402

TID = "TASK-0100"
BRANCH = "task/TASK-0100-thing"
NOTE = "03 Games/G/06 Tasks/TASK-0100-Thing.md"
SRC = "games/mathshow/src/a.luau"


class Repo(unittest.TestCase):
    """main holds the source; the branch registers TASK-0100 in its own first commit (a new task)."""

    tier = "standard"
    owner = "claude-code"

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.git("init", "-q", "-b", "main")
        self.git("config", "user.email", "t@example.com")
        self.git("config", "user.name", "T")
        self.write(SRC, "-- v1\n")
        self.write("AGENTS.md", "rules\n")
        self.main = self.commit("main")
        self.git("checkout", "-q", "-b", BRANCH)
        self.registration = {"id": TID, "branch": BRANCH, "tier": self.tier, "owner_agent": self.owner,
                             "note_path": NOTE}
        self.write_task([])
        self.write(NOTE, "---\nstatus: in_progress\n---\n")
        self.commit("register the task")

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

    def write_task(self, audits, **changes):
        self.write(f"tasks/items/{TID}.json", json.dumps(self.registration | {"audits": audits} | changes))

    def task(self):
        return json.loads((self.root / "tasks" / "items" / f"{TID}.json").read_text())

    def edit_task(self, fn):
        data = self.task()
        fn(data)
        self.write(f"tasks/items/{TID}.json", json.dumps(data))
        return self.commit("edit the task JSON")

    def report(self, name, verdict, measured, reviewer="codex", task_id=TID):
        rel = f"06 QA/{name}.md"
        text = (f"---\nid: {name}\ntask_id: {task_id}\nverdict: {verdict}\nreviewed_commit: {measured}\n"
                f"reviewer: {reviewer}\n---\n# Audit\n")
        self.write(rel, text)
        return rel, {"result": verdict, "measured_sha": measured, "auditor": reviewer, "report": rel,
                     "report_sha256": hashlib.sha256(text.encode()).hexdigest()}

    def audited(self, verdict="pass", reviewer="codex", name="AUD-1"):
        """Commit the audited source (A), then the report and its index entry; returns (A, head)."""
        self.write(SRC, f"-- audited {name}\n")
        measured = self.commit("A: the audited source")
        _, entry = self.report(name, verdict, measured, reviewer)
        self.write_task(self.task()["audits"] + [entry])
        return measured, self.commit("audit record")

    def run_gate(self, head=None, branch=BRANCH, draft=False, base="main"):
        out = io.StringIO()
        args = ["--root", str(self.root), "--head", head or self.git("rev-parse", "HEAD"), "--branch", branch]
        args += (["--base", base] if base else []) + (["--draft"] if draft else [])
        with redirect_stdout(out):
            code = gate.main(args)
        return code, out.getvalue()

    def assertRefused(self, *needles, head=None, branch=BRANCH, code=1):
        got, out = self.run_gate(head, branch)
        self.assertEqual(got, code, out)
        for n in needles:
            self.assertIn(n, out)
        return out


class TestGate(Repo):
    def test_a_draft_is_skipped(self):
        code, out = self.run_gate(draft=True)
        self.assertEqual(code, 0)
        self.assertIn("draft", out)

    def test_a_chore_without_source_passes_trivially(self):
        self.git("checkout", "-q", "-b", "chore/rules", "main")
        self.write("AGENTS.md", "more rules\n")
        self.commit()
        code, out = self.run_gate(branch="chore/rules")
        self.assertEqual(code, 0, out)
        self.assertIn("nothing to audit", out)

    def test_a_chore_that_touches_scripts_or_ci_needs_a_task(self):
        for path in ("scripts/tool.py", ".github/workflows/x.yml", ".gitmodules"):
            self.git("checkout", "-q", "-B", "chore/tool", "main")
            self.write(path, "x\n")
            self.commit()
            self.assertRefused("no tasks/items", branch="chore/tool")

    def test_a_chore_that_renames_source_out_of_scripts_needs_a_task(self):
        self.git("checkout", "-q", "-b", "chore/move", "main")
        self.write("scripts/tool.py", "print(1)\n")
        self.git("add", "-A")
        self.git("commit", "-q", "-m", "tool")
        self.git("update-ref", "refs/heads/main", "HEAD")
        (self.root / "docs").mkdir()
        self.git("mv", "scripts/tool.py", "docs/tool.py")
        self.commit("move it")
        self.assertRefused("no tasks/items", branch="chore/move")

    def test_a_source_change_without_a_task_fails(self):
        self.git("checkout", "-q", "-b", "task/TASK-0999-x", "main")
        self.write(SRC, "-- v2\n")
        self.commit()
        self.assertRefused("no tasks/items", branch="task/TASK-0999-x")

    def test_a_task_with_no_audit_fails(self):
        self.write(SRC, "-- v2\n")
        self.commit()
        self.assertRefused("no audit is recorded")

    def test_a_pass_that_covers_the_head_passes(self):
        _, head = self.audited()
        code, out = self.run_gate(head)
        self.assertEqual(code, 0, out)
        self.assertIn("covers head", out)

    def test_records_after_the_pass_still_pass(self):
        self.audited()
        self.write("06 QA/AUD-other.md", "later\n")
        self.write("docs/workflow/evidence/TASK-0100/e.txt", "e\n")
        self.write(NOTE, "---\nstatus: review\n---\nOutcome\n")
        head = self.commit("records")
        self.assertEqual(self.run_gate(head)[0], 0)

    def test_source_changed_after_the_pass_fails_and_names_the_file(self):
        self.audited()
        self.write(SRC, "-- v3, after the audit\n")
        self.assertRefused(SRC, head=self.commit("B"))

    def test_a_failed_audit_fails(self):
        self.audited(verdict="fail")
        self.assertRefused("says fail, not PASS")

    def test_a_missing_head_or_base_is_undecidable(self):
        self.assertEqual(self.run_gate("0" * 40)[0], 2)
        self.assertEqual(self.run_gate(base=None)[0], 2)
        self.assertEqual(self.run_gate(base="no-such-ref")[0], 2)


class TestLight(Repo):
    tier = "light"

    def test_light_tier_pinned_at_registration_passes_without_an_audit(self):
        self.write(SRC, "-- v2\n")
        code, out = self.run_gate(self.commit())
        self.assertEqual(code, 0, out)
        self.assertIn("light tier", out)


class TestBypassReportIsTheRecord(Repo):
    """B2/X2: the JSON is an index. The verdict, commit and reviewer come from the immutable report."""

    def test_json_verdict_edited_fail_to_pass_after_a_fail_is_refused(self):
        self.audited(verdict="fail")
        self.edit_task(lambda d: d["audits"][-1].update(result="pass"))
        self.assertRefused("the task JSON says 'pass' but the report", "says 'fail'")

    def test_json_measured_sha_edited_after_a_source_change_is_refused(self):
        self.audited()
        self.write(SRC, "-- v3\n")
        b = self.commit("B: source after the audit")
        self.edit_task(lambda d: d["audits"][-1].update(measured_sha=b))
        self.assertRefused("measured_sha", "reviewed_commit")

    def test_a_json_pass_with_no_report_fields_is_refused(self):
        self.audited()
        self.edit_task(lambda d: d["audits"].append({"result": "pass", "auditor": "codex"}))
        self.assertRefused("decisive report path None")

    def test_a_report_edited_after_recording_is_refused(self):
        self.audited()
        rel = self.root / "06 QA" / "AUD-1.md"
        rel.write_text(rel.read_text() + "later edit\n")
        self.edit_task(lambda d: d["audits"][-1].update(report_sha256=hashlib.sha256(rel.read_bytes()).hexdigest()))
        self.assertRefused("changed after it was recorded")

    def test_a_report_rewritten_from_fail_to_pass_is_refused(self):
        a, _ = self.audited(verdict="fail")
        _, entry = self.report("AUD-1", "pass", a)
        self.write_task([entry])
        self.assertRefused("changed after it was recorded", head=self.commit("rewrite the report"))

    def test_a_second_report_for_the_same_audit_id_is_refused(self):
        self.audited()
        text = (self.root / "06 QA" / "AUD-1.md").read_text().replace(TID, "TASK-0200")
        self.write("06 QA/AUD-1-b.md", text)  # claims id AUD-1 too
        self.assertRefused("claimed by more than one report", head=self.commit("second report"))

    def test_a_report_for_the_task_that_the_json_does_not_index_is_refused(self):
        a, _ = self.audited(verdict="pass")
        self.report("AUD-2", "fail", a)  # a later FAIL, left out of the JSON
        self.assertRefused("AUD-2.md names this task but the task JSON does not index it", head=self.commit())

    def test_a_report_deleted_and_added_again_is_refused(self):
        self.audited()
        rel = self.root / "06 QA" / "AUD-1.md"
        text = rel.read_text()
        rel.unlink()
        self.commit("drop")
        rel.write_text(text)
        self.assertRefused("added 2 times", head=self.commit("re-add"))

    def test_a_symlinked_report_is_refused(self):
        a, _ = self.audited()
        (self.root / "06 QA" / "AUD-1.md").rename(self.root / "06 QA" / "real.md")
        os.symlink("real.md", self.root / "06 QA" / "AUD-1.md")
        self.assertRefused(head=self.commit("symlink"))

    def test_a_later_report_indexed_out_of_order_is_refused(self):
        a, _ = self.audited(verdict="pass", name="AUD-1")
        _, fail = self.report("AUD-2", "fail", a)
        self.commit("AUD-2 committed")
        self.write_task([fail, self.task()["audits"][0]])  # JSON puts the older PASS last
        self.assertRefused("was not added before the decisive report", head=self.commit())


class TestBypassPaths(Repo):
    """B1: --no-renames, directory-exact matching, regular files only, one linked note."""

    def after_pass(self, fn):
        self.audited()
        fn()
        return self.commit("after the pass")

    def test_a_source_rename_into_06_qa_is_refused(self):
        head = self.after_pass(lambda: self.git("mv", SRC, "06 QA/a.md"))
        self.assertRefused(SRC, "source changed", head=head)

    def test_a_prefix_lookalike_directory_is_source(self):
        for path in ("06 QA-x/n.md", "06 QAx/n.md", "x/06 QA/n.md", "tasks/items-x/t.json", "docs/workflow/evidence-x/e.txt"):
            with self.subTest(path=path):
                self.git("checkout", "-q", "-B", BRANCH, "main")
                self.write_task([])
                self.write(NOTE, "---\n---\n")
                self.commit("register")
                self.assertRefused(path, head=self.after_pass(lambda: self.write(path, "x\n")))

    def test_a_symlink_in_an_allowed_directory_is_refused(self):
        def link():
            (self.root / "docs" / "workflow" / "evidence").mkdir(parents=True)
            os.symlink("../../../games/mathshow/src/a.luau", self.root / "docs/workflow/evidence/link.txt")
        self.assertRefused("a symlink or submodule", head=self.after_pass(link))

    def test_a_submodule_in_an_allowed_directory_is_refused(self):
        self.audited()
        self.git("update-index", "--add", "--cacheinfo", f"160000,{self.main},docs/workflow/evidence/sub")
        self.git("commit", "-q", "-m", "gitlink")
        self.assertRefused("a symlink or submodule")

    def test_a_mode_change_in_an_allowed_directory_is_refused(self):
        self.write("docs/workflow/evidence/run.sh", "echo\n")
        self.commit("evidence before the audit")
        self.audited()
        (self.root / "docs/workflow/evidence/run.sh").chmod(0o755)
        self.assertRefused("mode or type change", head=self.commit("chmod"))

    def test_a_wrong_extension_in_06_qa_is_refused(self):
        self.assertRefused("only .md files", head=self.after_pass(lambda: self.write("06 QA/x.luau", "x\n")))


class TestBypassNoteException(Repo):
    def test_a_note_path_naming_a_source_file_is_no_exception(self):
        for note in ("scripts/x.py", "AGENTS.md", "03 Games/G/06 Tasks/TASK-0100-x.luau", "03 Games/G/Other.md"):
            with self.subTest(note=note):
                self.git("checkout", "-q", "-B", BRANCH, "main")
                self.registration["note_path"] = note
                self.write_task([])
                self.commit("register with a bad note path")
                self.audited()
                self.write(note, "changed after the audit\n")
                self.assertRefused(note, head=self.commit())


class TestBypassTier(Repo):
    tier = "deep"

    def test_tier_changed_to_light_on_the_branch_is_refused(self):
        self.write(SRC, "-- v2\n")
        self.commit()
        self.edit_task(lambda d: d.update(tier="light"))
        self.assertRefused("tier changed on the branch", "'deep'", "'light'")

    def test_tier_registered_on_the_base_is_pinned(self):
        self.git("checkout", "-q", "main")
        self.write_task([])
        self.commit("register on main")
        self.git("checkout", "-q", "-B", BRANCH, "main")
        self.edit_task(lambda d: d.update(tier="light"))
        self.write(SRC, "-- v2\n")
        self.assertRefused("tier changed", "the PR base", head=self.commit())

    def test_a_second_task_file_for_the_branch_is_refused(self):
        self.write("tasks/items/TASK-0101.json", json.dumps(self.registration | {"id": "TASK-0101", "tier": "light"}))
        self.write(SRC, "-- v2\n")
        self.assertRefused("more than one task file names branch", head=self.commit())

    def test_moving_the_base_task_off_the_branch_and_registering_a_light_one_is_refused(self):
        self.git("checkout", "-q", "main")
        self.write_task([])
        self.commit("register deep on main")
        self.git("checkout", "-q", "-B", BRANCH, "main")
        self.write_task([], branch="task/elsewhere")
        self.write("tasks/items/TASK-0101.json", json.dumps(self.registration | {"id": "TASK-0101", "tier": "light"}))
        self.write(SRC, "-- v2\n")
        self.assertRefused("more than one task file names branch", head=self.commit())

    def test_a_deep_task_needs_codex(self):
        self.audited(reviewer="claude-auditor")
        self.assertRefused("independent auditor")

    def test_a_codex_pass_is_enough(self):
        _, head = self.audited()
        self.assertEqual(self.run_gate(head)[0], 0)


class TestStandardIsDeep(Repo):
    tier = "standard"

    def test_a_standard_task_needs_codex(self):
        self.audited(reviewer="claude-auditor")
        self.assertRefused("independent auditor", "'claude-auditor'")


class TestOwnerIsNotTheAuditor(Repo):
    owner = "codex"

    def test_the_owner_cannot_pass_its_own_task(self):
        self.audited(reviewer="codex")
        self.assertRefused("is the task's owner_agent")


class TestWorkflowFile(unittest.TestCase):
    """GATE-05: base code, head as data, minimal permissions, no persisted credentials."""

    text = (ROOT / ".github" / "workflows" / "audit-gate.yml").read_text()

    def steps(self):
        body = self.text.split("    steps:\n", 1)[1]
        return ["      - " + s for s in re.split(r"(?m)^      - ", body) if s.strip()]

    def run_blocks(self):
        return [s.split("run: |", 1)[1] for s in self.steps() if "run: |" in s]

    def test_the_job_and_the_event(self):
        self.assertIn("\n  audit-gate:\n", self.text)
        self.assertRegex(self.text, r"(?m)^on:\n  pull_request_target:\n")
        self.assertNotRegex(self.text, r"(?m)^\s+pull_request:")

    def test_permissions_are_minimal_and_there_are_no_secrets(self):
        self.assertIn("permissions:\n  contents: read\n  pull-requests: read\n\n", self.text)
        self.assertEqual(self.text.count("permissions:"), 1)
        self.assertNotIn("secrets.", self.text)
        self.assertNotIn("GITHUB_TOKEN", self.text)
        self.assertNotIn("write", self.text.split("permissions:", 1)[1].split("jobs:", 1)[0])

    def test_every_checkout_is_pinned_and_keeps_no_credentials(self):
        uses = [s for s in self.steps() if "uses:" in s]
        self.assertEqual(len(uses), 2)
        for s in uses:
            self.assertRegex(s, r"uses: actions/checkout@[0-9a-f]{40} ")
            self.assertIn("persist-credentials: false", s)
        base, head = uses
        self.assertIn("ref: ${{ github.event.pull_request.base.sha }}", base)
        self.assertIn("path: gate", base)
        self.assertIn("ref: ${{ github.event.pull_request.head.sha }}", head)
        self.assertIn("path: pr-data", head)
        self.assertIn("fetch-depth: 0", head)
        self.assertNotIn("setup-python", self.text)

    def test_the_gate_runs_from_the_base_checkout_and_reads_the_head_as_data(self):
        (run,) = self.run_blocks()
        self.assertIn('python3 -I "$GITHUB_WORKSPACE/gate/scripts/audit_gate.py"', run)
        self.assertIn("working-directory: gate", self.steps()[-1])
        # the head directory appears once, as the --root data argument, and nothing else touches it
        self.assertEqual(run.count("pr-data"), 1)
        self.assertIn('--root "$GITHUB_WORKSPACE/pr-data"', run)
        for banned in (r"\bpip\b", r"\bcd\b", r"\bsource\b", r"\bbash\b", r"pr-data/", r"\bmake\b", r"\bnpm\b", r"\./"):
            self.assertNotRegex(run, banned)

    def test_untrusted_values_go_through_env_and_it_fails_closed(self):
        for run in self.run_blocks():
            self.assertNotIn("${{", run)
            self.assertIn("set -euo pipefail", run)
        self.assertIn("HEAD_REF: ${{ github.event.pull_request.head.ref }}", self.text)
        self.assertIn('if [ "$HEAD_REPO" != "$BASE_REPO" ]', self.text)


if __name__ == "__main__":
    unittest.main()
