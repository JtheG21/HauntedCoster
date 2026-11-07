"""Tests for scripts/orchestrator.py. Run: python3 -m unittest discover tests"""

import hashlib
import io
import json
import subprocess
import sys
import tempfile
import unittest
from contextlib import redirect_stderr, redirect_stdout
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "scripts"))
import orchestrator as orch  # noqa: E402


def task(tid, status="backlog", deps=None, note=None):
    t = {"id": tid, "title": f"Task {tid}", "status": status, "risk": "low",
         "depends_on": deps or [], "branch": f"task/{tid}", "acceptance": ["works"]}
    if note:
        t["note_path"] = note
    return t


class Base(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        (self.root / "tasks").mkdir()
        (self.root / "00 Studio").mkdir()
        (self.root / "06 QA").mkdir()
        self.write_budget({"monthly_limit_usd": 10, "per_task_limit_usd": 3, "max_revisions": 2,
                           "dispatch_mode": "dry-run"})
        self.write_queue([task("TASK-0001"), task("TASK-0002", deps=["TASK-0001"])])
        self.sha = self.init_git()
        self.base_sha = self.sha  # the PR base the fixtures report (gh baseRefOid)

    def tearDown(self):
        self.tmp.cleanup()

    def init_git(self) -> str:
        """A one-commit repo, so record-audit can check the measured SHA."""
        def run(*args):
            return subprocess.run(["git", "-C", str(self.root), *args], capture_output=True, text=True, check=True).stdout
        run("init", "-q", "-b", "main")
        run("config", "user.email", "t@example.com")
        run("config", "user.name", "T")
        (self.root / "seed.txt").write_text("seed")
        run("add", "-A")
        run("commit", "-q", "-m", "seed")
        return run("rev-parse", "HEAD").strip()

    def commit(self, message: str = "work") -> str:
        """Commit everything in the fixture repo (the PR head moves) and return the new SHA."""
        for args in (("add", "-A"), ("commit", "-q", "--allow-empty", "-m", message)):
            subprocess.run(["git", "-C", str(self.root), *args], capture_output=True, text=True, check=True)
        return subprocess.run(["git", "-C", str(self.root), "rev-parse", "HEAD"], capture_output=True, text=True,
                              check=True).stdout.strip()

    def report(self, name: str, verdict: str, task_id: str = "TASK-0001", reviewer: str = "codex",
               sha: str | None = None) -> str:
        """An audit report whose frontmatter holds the decisive fields; returns its repo path."""
        rel = f"06 QA/{name}.md"
        (self.root / rel).write_text(f"---\nid: {name}\ntask_id: {task_id}\nverdict: {verdict}\n"
                                     f"reviewed_commit: {sha or self.sha}\nreviewer: {reviewer}\n---\n# audit\n")
        return rel

    def audit(self, p, tid, verdict, name="a0", auditor="codex"):
        p.record_audit(tid, verdict, self.report(name, verdict, tid, auditor), self.sha, ["games/"], auditor)

    def write_budget(self, b):
        (self.root / "00 Studio" / "budget.json").write_text(json.dumps(b))

    def write_queue(self, tasks):
        items = self.root / "tasks" / "items"
        items.mkdir(exist_ok=True)
        for old in items.glob("*.json"):
            old.unlink()
        for n, t in enumerate(tasks):
            name = t["id"] if not (items / f"{t['id']}.json").exists() else f"{t['id']}-copy{n}"
            (items / f"{name}.json").write_text(json.dumps(t))

    def open_pr(self, head=None, **extra):
        return {"state": "OPEN", "isDraft": False, "headRefOid": head or self.sha, "headRefName": "task/TASK-0001",
                "baseRefOid": self.base_sha, **extra}

    def merged_pr(self, head=None):
        return {"state": "MERGED", "headRefOid": head or self.sha, "headRefName": "task/TASK-0001",
                "mergeCommit": {"oid": "f" * 40}, "mergedAt": "2026-11-05T00:00:00Z"}

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
        bad = task("TASK-0003", status="weird", deps=["TASK-9999"])
        self.write_queue([task("TASK-0001"), task("TASK-0001"), bad])
        errors = "\n".join(self.proj().validate())
        self.assertIn("duplicate id", errors)
        self.assertIn("invalid status", errors)
        self.assertIn("unknown task TASK-9999", errors)

    def test_corrupt_ledger_is_validation_error(self):
        (self.root / "tasks" / "usage-ledger.jsonl").write_text('{"ok": 1}\n<<<<<<< HEAD\n')
        self.assertTrue(any("usage-ledger" in e for e in self.proj().validate()))

    def test_cycle_detected(self):
        self.write_queue([task("TASK-0001", deps=["TASK-0002"]), task("TASK-0002", deps=["TASK-0001"])])
        self.assertTrue(any("cycle" in e for e in self.proj().validate()))

    def test_invalid_json_reported(self):
        (self.root / "tasks" / "items" / "TASK-0001.json").write_text("{nope")
        code, out = self.cli("validate")
        self.assertEqual(code, 2)
        self.assertIn("invalid JSON", out)


class TestWorkflow(Base):
    def test_cannot_start_without_approval(self):
        p = self.proj()
        with self.assertRaises(orch.OrchestratorError):
            p.start("TASK-0001")

    def test_dependencies_gate_start(self):
        p = self.proj()
        p.approve("TASK-0002", "jg")
        with self.assertRaises(orch.OrchestratorError):
            p.start("TASK-0002")

    def test_happy_path(self):
        p = self.proj()
        p.approve("TASK-0001", "jg")
        p.start("TASK-0001")
        p.record_exec("TASK-0001", "pass", "checks ok")
        self.audit(p, "TASK-0001", "pass")
        p.save()
        head = self.commit("audit record")
        self.assertEqual(p.task("TASK-0001")["status"], "approved")
        with mock.patch.object(orch, "gh_pr_view", return_value=self.open_pr(head)):
            p.approve_merge("TASK-0001", "jg", 7, "Merge PR 7")
        self.assertEqual(p.task("TASK-0001")["status"], "approved", "approve-merge never sets done")
        with mock.patch.object(orch, "gh_pr_view", return_value=self.merged_pr(head)):
            p.mark_merged("TASK-0001", 7)
        p.save()
        self.assertEqual(self.proj().task("TASK-0001")["status"], "done")
        self.assertEqual([t["id"] for t in self.proj().ready()], [])

    def test_light_tier_skips_audit(self):
        t = task("TASK-0001")
        t["tier"] = "light"
        self.write_queue([t])
        self.base_sha = self.sha = self.commit("registered light")
        p = self.proj()
        p.approve("TASK-0001", "jg")
        p.start("TASK-0001")
        p.record_exec("TASK-0001", "pass", "checks ok")
        self.assertEqual(p.task("TASK-0001")["status"], "approved")
        green = self.open_pr(statusCheckRollup=[{"conclusion": "SUCCESS"}])
        with mock.patch.object(orch, "gh_pr_view", return_value=green):
            p.approve_merge("TASK-0001", "jg", 7, "Merge PR 7")
        with mock.patch.object(orch, "gh_pr_view", return_value=self.merged_pr()):
            p.mark_merged("TASK-0001", 7)
        self.assertEqual(p.task("TASK-0001")["status"], "done")

    def test_non_light_still_needs_audit(self):
        p = self.proj()
        p.approve("TASK-0001", "jg")
        p.start("TASK-0001")
        p.record_exec("TASK-0001", "pass", "checks ok")
        self.assertEqual(p.task("TASK-0001")["status"], "review")

    def test_revision_limit_blocks(self):
        p = self.proj()
        p.approve("TASK-0001", "jg")
        for attempt in range(3):
            p.start("TASK-0001")
            p.record_exec("TASK-0001", "pass", "")
            self.audit(p, "TASK-0001", "fail", f"a{attempt}")
        t = p.task("TASK-0001")
        self.assertEqual(t["status"], "blocked")
        self.assertEqual(t["revisions"], 3)
        with self.assertRaises(orch.OrchestratorError):
            p.start("TASK-0001")

    def test_request_changes_after_pass(self):
        p = self.proj()
        p.approve("TASK-0001", "jg")
        p.start("TASK-0001")
        p.record_exec("TASK-0001", "pass", "")
        self.audit(p, "TASK-0001", "pass")
        p.request_changes("TASK-0001", "jg", "fix minors")
        t = p.task("TASK-0001")
        self.assertEqual((t["status"], t["revisions"]), ("changes_requested", 1))
        with self.assertRaises(orch.OrchestratorError):
            p.request_changes("TASK-0001", "jg", "again")  # not allowed from changes_requested

    def test_audit_cannot_be_skipped(self):
        p = self.proj()
        p.approve("TASK-0001", "jg")
        p.start("TASK-0001")
        with self.assertRaises(orch.OrchestratorError):
            p.approve_merge("TASK-0001", "jg", 7, "Merge PR 7")

    def test_unblock_resets(self):
        p = self.proj()
        t = p.task("TASK-0001")
        t["status"], t["revisions"] = "blocked", 3
        p.unblock("TASK-0001", "ready", "jg")
        self.assertEqual((t["status"], t["revisions"]), ("ready", 0))


class TestReopen(Base):
    def test_each_allowed_state_reopens_and_syncs_note(self):
        for status in ("blocked", "changes_requested", "approved"):
            with self.subTest(status=status):
                note = self.root / "TASK-0001-X.md"
                note.write_text(f"---\nstatus: {status}\nupdated: 2000-01-01\n---\n# Body\n")
                self.write_queue([task("TASK-0001", status, note=note.name)])
                code, out = self.cli("reopen", "TASK-0001", "--to", "review", "--reason", "scope accepted")
                self.assertEqual(code, 0, out)
                t = self.proj().task("TASK-0001")
                self.assertEqual(t["status"], "review")
                self.assertEqual(t["history"][-1], {
                    "from": status, "to": "review", "reason": "scope accepted", "by": "jg",
                    "at": t["history"][-1]["at"],
                })
                self.assertIsNotNone(orch.dt.datetime.fromisoformat(t["history"][-1]["at"]))
                self.assertIn("status: review", note.read_text())
                self.assertNotIn("2000-01-01", note.read_text())
                self.assertTrue(note.read_text().endswith("# Body\n"))
                self.assertEqual(self.cli("validate")[0], 0)

    def test_each_other_state_is_refused_without_writing(self):
        for status in ("backlog", "ready", "in_progress", "review", "done", "archived"):
            with self.subTest(status=status):
                self.write_queue([task("TASK-0001", status)])
                path = self.root / "tasks/items/TASK-0001.json"
                before = path.read_bytes()
                code, out = self.cli("reopen", "TASK-0001", "--to", "review", "--reason", "scope accepted")
                self.assertEqual(code, 2)
                self.assertIn(f"is '{status}'", out)
                self.assertIn("expected one of", out)
                self.assertEqual(path.read_bytes(), before)

    def test_missing_reason_is_required_by_cli(self):
        self.write_queue([task("TASK-0001", "blocked")])
        path = self.root / "tasks/items/TASK-0001.json"
        before = path.read_bytes()
        with self.assertRaises(SystemExit) as cm:
            self.cli("reopen", "TASK-0001", "--to", "review")
        self.assertEqual(cm.exception.code, 2)
        self.assertEqual(path.read_bytes(), before)

    def test_empty_or_whitespace_reason_is_refused(self):
        for reason in ("", " \t\n"):
            with self.subTest(reason=reason):
                self.write_queue([task("TASK-0001", "blocked")])
                path = self.root / "tasks/items/TASK-0001.json"
                before = path.read_bytes()
                code, out = self.cli("reopen", "TASK-0001", "--to", "review", "--reason", reason)
                self.assertEqual(code, 2)
                self.assertIn("non-empty --reason", out)
                self.assertEqual(path.read_bytes(), before)

    def test_target_must_be_review(self):
        self.write_queue([task("TASK-0001", "blocked")])
        for target in ("ready", "approved", "done"):
            with self.subTest(target=target), self.assertRaises(SystemExit) as cm:
                self.cli("reopen", "TASK-0001", "--to", target, "--reason", "scope accepted")
            self.assertEqual(cm.exception.code, 2)
        p = self.proj()
        with self.assertRaisesRegex(orch.OrchestratorError, "target must be review"):
            p.reopen("TASK-0001", "ready", "scope accepted")
        self.assertEqual(p.task("TASK-0001")["status"], "blocked")

    def test_appends_without_changing_history_audits_or_revisions(self):
        history = [{"time": "2026-10-10T10:00:00", "from": "review", "to": "blocked", "note": "audit failed"},
                   {"from": "blocked", "to": "blocked", "reason": "keep this", "by": "jg", "at": "2026-10-10T11:00:00"}]
        audits = [{"result": "fail", "report": "06 QA/a0.md", "time": "2026-10-10T10:00:00"},
                  {"result": "pass", "report": "06 QA/a1.md"}]
        t = task("TASK-0001", "blocked") | {"history": history, "audits": audits, "revisions": 3}
        self.write_queue([t])
        # Canonicalize with the same writer as production, then compare the original serialized entries verbatim.
        self.proj().save()
        history_bytes = [json.dumps(entry, indent=2).encode() for entry in history]
        audit_bytes = json.dumps(audits, indent=2).encode()
        reports = {path: path.read_bytes() for path in (self.root / "06 QA").glob("*.md")}
        code, out = self.cli("reopen", "TASK-0001", "--to", "review", "--reason", "scope accepted", "--by", "reviewer")
        self.assertEqual(code, 0, out)
        reopened = self.proj().task("TASK-0001")
        self.assertEqual(len(reopened["history"]), len(history) + 1)
        self.assertEqual([json.dumps(entry, indent=2).encode() for entry in reopened["history"][:-1]], history_bytes)
        self.assertEqual(json.dumps(reopened["audits"], indent=2).encode(), audit_bytes)
        self.assertEqual({path: path.read_bytes() for path in reports}, reports)
        self.assertEqual(reopened["revisions"], 3)
        self.assertEqual(reopened["history"][-1]["by"], "reviewer")


class TestNoteSync(Base):
    def setUp(self):
        super().setUp()
        self.note = self.root / "TASK-0001-X.md"
        self.note.write_text("---\nid: TASK-0001\nstatus: proposed\nupdated: 2000-01-01\n---\n# Body\n")
        self.write_queue([task("TASK-0001", note="TASK-0001-X.md")])

    def test_transition_updates_note(self):
        p = self.proj()
        p.approve("TASK-0001", "jg")
        text = self.note.read_text()
        self.assertIn("status: ready", text)
        self.assertNotIn("2000-01-01", text)
        self.assertTrue(text.endswith("# Body\n"))

    def test_missing_note_is_validation_error(self):
        self.note.unlink()
        self.assertTrue(any("note not found" in e for e in self.proj().validate()))

    def test_audit_report_must_exist(self):
        p = self.proj()
        p.approve("TASK-0001", "jg")
        p.start("TASK-0001")
        p.record_exec("TASK-0001", "pass", "")
        with self.assertRaises(orch.OrchestratorError):
            p.record_audit("TASK-0001", "pass", "06 QA/missing.md", self.sha, ["games/"], "codex")


class TestBudgetAndDispatch(Base):
    def test_api_limit_stops_start(self):
        p = self.proj()
        p.approve("TASK-0001", "jg")
        p.record_usage("TASK-0001", "api", "executor", 10.0, None, 1000, "m", "")
        with self.assertRaises(orch.OrchestratorError) as cm:
            p.start("TASK-0001")
        self.assertIn("monthly API limit", str(cm.exception))

    def test_subscription_usage_not_counted_as_spend(self):
        p = self.proj()
        p.record_usage("TASK-0001", "subscription", "executor", None, 5.0, None, "m", "")
        self.assertEqual(p.api_spend(), 0)

    def test_dispatch_dry_run_writes_prompt_only(self):
        p = self.proj()
        p.approve("TASK-0001", "jg")
        p.start("TASK-0001")
        msg = p.dispatch("TASK-0001", "executor", live=False)
        self.assertIn("[dry-run]", msg)
        prompt = (self.root / "tasks" / "prompts" / "TASK-0001-executor.md").read_text()
        self.assertIn("04 Agents/Executor.md", prompt)
        self.assertFalse((self.root / "tasks" / "usage-ledger.jsonl").exists())

    def test_dispatch_prompt_carries_criteria_and_expected_files(self):
        # Scope is read from existing queue and note fields, not stored as a new source of truth.
        note = self.root / "TASK-0001-X.md"
        note.write_text("# X\n\n## Files expected to change\n- `scripts/x.py`\n- `tests/test_x.py`\n\n## Tests\nStudio scenario\n")
        self.write_queue([task("TASK-0001", note="TASK-0001-X.md")])
        p = self.proj()
        p.queue["tasks"][0]["acceptance"] = ["first criterion", "second criterion"]
        prompt = p.build_prompt(p.task("TASK-0001"), "executor")
        self.assertIn("- first criterion\n- second criterion", prompt)
        self.assertIn("- scripts/x.py\n- tests/test_x.py", prompt)
        # Widening is allowed when justified, but never as an open-ended scan.
        self.assertIn("Open a dependency, reusable module or test outside that list only when the change needs it", prompt)
        self.assertIn("Do not scan the whole repo.", prompt)

    def test_dispatch_prompt_without_note_has_no_file_list(self):
        prompt = self.proj().build_prompt(self.proj().task("TASK-0001"), "auditor")
        self.assertNotIn("Files expected", prompt)
        self.assertIn("- works", prompt)

    def test_live_dispatch_refused(self):
        p = self.proj()
        p.approve("TASK-0001", "jg")
        p.start("TASK-0001")
        with self.assertRaises(orch.OrchestratorError):
            p.dispatch("TASK-0001", "executor", live=True)

    def test_report_preserves_handwritten_content(self):
        reviews = self.root / "08 Reviews"
        reviews.mkdir()
        self.cli("report")
        path = next(reviews.glob("HLT-*.md"))
        path.write_text(path.read_text() + "\n## Baseline audit\nhand-written\n")
        self.cli("report")
        self.cli("report")
        text = path.read_text()
        self.assertIn("hand-written", text)
        self.assertEqual(text.count(orch.GEN_START), 1)

    def test_report_and_state(self):
        code, out = self.cli("report")
        self.assertEqual(code, 0, out)
        self.assertTrue(list((self.root / "08 Reviews").glob("HLT-*.md")))
        self.assertFalse((self.root / "project-state.json").exists())  # calculated, never stored
        code, out = self.cli("state")
        self.assertEqual(code, 0, out)
        self.assertIn("TASK-0001", json.loads(out)["needs_human"])


class TestOverrideMerge(Base):
    """override-merge records jg's merge over a failed audit, verified like mark-merged (gh MERGED, the report says fail)."""

    def entry(self, name, verdict):
        rel = self.report(name, verdict)
        digest = hashlib.sha256((self.root / rel).read_bytes()).hexdigest()
        return {"result": verdict, "report": rel, "report_sha256": digest, "measured_sha": self.sha, "auditor": "codex"}

    def failed_task(self, status="changes_requested", verdicts=("fail",)):
        audits = [self.entry(f"a{i}", v) for i, v in enumerate(verdicts)]
        self.write_queue([task("TASK-0001", status) | {"audits": audits}])
        return self.commit("failed audit recorded")

    def override(self, head, *extra, reason="x", by="jg"):
        with mock.patch.object(orch, "gh_pr_view", return_value=self.merged_pr(head) | dict(extra)):
            return self.cli("override-merge", "TASK-0001", "--by", by, "--reason", reason, "--pr", "7")

    def test_records_who_and_why_and_keeps_the_fail(self):
        head = self.failed_task()
        code, out = self.override(head, reason="placeholders accepted")
        self.assertEqual(code, 0, out)
        t = self.proj().task("TASK-0001")
        self.assertEqual(t["status"], "done")
        self.assertEqual(t["merge_approved_by"], "jg")
        self.assertEqual(t["audits"][-1]["result"], "fail")
        self.assertEqual(t["audits"][-1]["merge_override"]["by"], "jg")
        self.assertEqual(t["audits"][-1]["merge_override"]["reason"], "placeholders accepted")
        self.assertEqual((t["merged"]["head_sha"], t["merged"]["override"]), (head, True))
        self.assertIn("over a failed audit", t["history"][-1]["note"])

    def test_allows_a_blocked_task(self):
        head = self.failed_task("blocked")
        self.assertEqual(self.override(head)[0], 0)
        self.assertEqual(self.proj().task("TASK-0001")["status"], "done")

    def test_refuses_other_statuses_and_a_later_passing_audit(self):
        for status in ("review", "approved"):
            head = self.failed_task(status)
            self.assertEqual(self.override(head)[0], 2)
        head = self.failed_task(verdicts=("fail", "pass"))
        self.assertEqual(self.override(head)[0], 2)

    def test_refuses_without_a_failed_audit_a_reason_a_human_or_a_merge(self):
        self.write_queue([task("TASK-0001", "changes_requested")])
        head = self.commit("no audit")
        self.assertEqual(self.override(head)[0], 2)
        head = self.failed_task()
        self.assertEqual(self.override(head, reason="  ")[0], 2)
        self.assertEqual(self.override(head, by="claude-code")[0], 2)
        self.assertEqual(self.override(head, ("state", "OPEN"))[0], 2)
        self.assertEqual(self.override(head, ("headRefName", "task/other"))[0], 2)
        self.assertEqual(self.proj().task("TASK-0001")["status"], "changes_requested")

    def test_a_json_fail_whose_report_says_pass_is_not_overridable(self):
        """The verdict is the report's: a JSON-only fail is not a failed audit."""
        rel = self.report("a0", "pass")
        digest = hashlib.sha256((self.root / rel).read_bytes()).hexdigest()
        audits = [{"result": "fail", "report": rel, "report_sha256": digest, "measured_sha": self.sha, "auditor": "codex"}]
        self.write_queue([task("TASK-0001", "changes_requested") | {"audits": audits}])
        code, out = self.override(self.commit("json says fail"))
        self.assertEqual(code, 2)
        self.assertIn("says 'pass'", out)



class TestReports(Base):
    def note(self, name, files, tests="- Studio playtest: join"):
        p = self.root / "03 Games" / f"{name}.md"
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(f"## Files expected to change\n{files}\n\n## Tests\n{tests}\n\n## Risks\n")
        return f"03 Games/{name}.md"

    def test_cycles_summarises(self):
        t = task("TASK-0001", "done")
        t["history"] = [{"time": "2026-10-10T10:00:00", "to": "in_progress"}, {"time": "2026-10-10T11:30:00", "to": "review"}]
        t["revisions"] = 1
        self.write_queue([t, task("TASK-0002")])
        code, out = self.cli("cycles")
        self.assertEqual(code, 0)
        self.assertIn("rev=1", out)
        self.assertIn("1.5", out)
        self.assertIn("2 tasks", out)

    def test_parallel_safe(self):
        a = task("TASK-0001", "ready", note=self.note("a", "- `src/a.luau`"))
        b = task("TASK-0002", "ready", note=self.note("b", "- `src/b.luau`", tests="- headless only"))
        c = task("TASK-0003", "ready", note=self.note("c", "- `src/a.luau`"))
        d = task("TASK-0004", "ready", note=self.note("d", "- `src/d.luau`"))
        self.write_queue([a, b, c, d])
        code, out = self.cli("next", "--parallel-safe")
        self.assertEqual(code, 0)
        self.assertIn("TASK-0001 + TASK-0002: no overlap found", out)
        self.assertIn("TASK-0001 + TASK-0003: NOT SAFE: expected files overlap; both need Studio", out)
        self.assertIn("TASK-0001 + TASK-0004: NOT SAFE: both need Studio", out)
        self.assertIn("still needs jg's explicit authorization", out)

    def test_parallel_unknown_files(self):
        self.write_queue([task("TASK-0001", "ready"), task("TASK-0002", "ready")])
        self.assertIn("overlap is unknown", self.cli("next", "--parallel-safe")[1])


if __name__ == "__main__":
    unittest.main()
