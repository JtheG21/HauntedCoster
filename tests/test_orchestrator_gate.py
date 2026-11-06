"""Tests for the audit-head gate in scripts/orchestrator.py: record-audit, approve-merge, mark-merged, --post-merge.

The first group replays the TASK-0138 timeline: a PASS measured at A, source changed after it, merged anyway.
Run: python3 -m unittest discover tests
"""

import hashlib
import sys
import unittest
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "scripts"))
import orchestrator as orch  # noqa: E402
from test_orchestrator import Base, task  # noqa: E402

TID = "TASK-0001"


class GateBase(Base):
    """A task in `review` whose seed commit A holds a source file, ready for record-audit."""

    tier = "standard"

    def setUp(self):
        super().setUp()
        t = task(TID)
        t["tier"] = self.tier
        t["owner_agent"] = "claude-code"
        t["note_path"] = "03 Games/T/TASK-0001.md"
        note = self.root / t["note_path"]
        note.parent.mkdir(parents=True)
        note.write_text("---\nstatus: backlog\nupdated: 2000-01-01\n---\n# Body\n")
        self.write_queue([t])
        (self.root / "games").mkdir()
        (self.root / "games" / "x.luau").write_text("-- v1\n")
        self.sha = self.commit("A: source")
        p = self.proj()
        p.approve(TID, "jg")
        p.start(TID)
        p.record_exec(TID, "pass", "")
        p.save()
        self.commit("task in review")

    def audited(self, verdict="pass", auditor="codex", sha=None):
        """Record the audit measured at A (a report in 06 QA/ naming A), save, commit; returns (project, head)."""
        p = self.proj()
        name = "AUD-1"
        rel = self.report(name, verdict)
        if sha:
            (self.root / rel).write_text(f"---\nverdict: {verdict}\n---\nmeasured {sha}\n")
        p.record_audit(TID, verdict, rel, self.sha, ["games/"], auditor)
        p.save()
        return p, self.commit("audit record")

    def change_source(self):
        (self.root / "games" / "x.luau").write_text("-- v2, after the audit\n")
        return self.commit("B: source change")

    def approve(self, p, head, text="Merge PR 7", **pr_extra):
        with mock.patch.object(orch, "gh_pr_view", return_value=self.open_pr(head, **pr_extra)):
            p.approve_merge(TID, "jg", 7, text)


class TestTask0138Timeline(GateBase):
    def test_source_change_after_the_pass_is_refused(self):
        p, _ = self.audited()
        head_b = self.change_source()
        with self.assertRaises(orch.OrchestratorError) as cm:
            self.approve(p, head_b)
        self.assertIn("games/x.luau", str(cm.exception))
        self.assertIn("not covered", str(cm.exception))
        self.assertNotIn("merge_approval", p.task(TID))

    def test_only_audit_and_task_records_after_the_pass_is_allowed(self):
        p, head = self.audited()
        (self.root / "06 QA" / "extra-finding.md").write_text("later note\n")
        (self.root / "docs" / "workflow" / "evidence" / "TASK-0001").mkdir(parents=True)
        (self.root / "docs" / "workflow" / "evidence" / "TASK-0001" / "run.txt").write_text("evidence\n")
        head_b = self.commit("records only")
        self.approve(p, head_b)
        self.assertEqual(p.task(TID)["merge_approval"]["head_sha"], head_b)

    def test_the_task_note_may_change_after_the_pass(self):
        p, _ = self.audited()
        (self.root / "03 Games" / "T" / "TASK-0001.md").write_text("---\nstatus: approved\n---\n# Body\nOutcome\n")
        head_b = self.commit("note")
        self.approve(p, head_b)

    def test_another_note_is_source_to_the_gate(self):
        p, _ = self.audited()
        (self.root / "03 Games" / "T" / "Other.md").write_text("x\n")
        head_b = self.commit("other note")
        with self.assertRaises(orch.OrchestratorError) as cm:
            self.approve(p, head_b)
        self.assertIn("Other.md", str(cm.exception))


class TestRecordAudit(GateBase):
    def test_a_report_without_the_measured_sha_is_refused(self):
        p = self.proj()
        rel = self.report("AUD-1", "pass")
        (self.root / rel).write_text("---\nverdict: pass\n---\nno sha here\n")
        with self.assertRaises(orch.OrchestratorError) as cm:
            p.record_audit(TID, "pass", rel, self.sha, ["games/"], "codex")
        self.assertIn("does not contain the measured SHA", str(cm.exception))
        self.assertEqual(p.task(TID)["status"], "review")

    def test_a_report_citing_a_different_sha_is_refused(self):
        p = self.proj()
        rel = self.report("AUD-1", "pass")
        (self.root / rel).write_text(f"---\nverdict: pass\n---\nmeasured {'a' * 40}\n")
        with self.assertRaises(orch.OrchestratorError):
            p.record_audit(TID, "pass", rel, self.sha, ["games/"], "codex")

    def test_a_verdict_line_that_disagrees_is_refused(self):
        p = self.proj()
        rel = self.report("AUD-1", "fail")
        with self.assertRaises(orch.OrchestratorError) as cm:
            p.record_audit(TID, "pass", rel, self.sha, ["games/"], "codex")
        self.assertIn("do not match", str(cm.exception))

    def test_a_report_with_no_verdict_line_is_refused(self):
        p = self.proj()
        rel = self.report("AUD-1", "pass")
        (self.root / rel).write_text(f"# audit of {self.sha}\nlooks fine\n")
        with self.assertRaises(orch.OrchestratorError) as cm:
            p.record_audit(TID, "pass", rel, self.sha, ["games/"], "codex")
        self.assertIn("no verdict line", str(cm.exception))

    def test_a_short_or_unknown_sha_is_refused(self):
        p = self.proj()
        rel = self.report("AUD-1", "pass")
        with self.assertRaises(orch.OrchestratorError):
            p.record_audit(TID, "pass", rel, self.sha[:12], ["games/"], "codex")
        (self.root / rel).write_text(f"---\nverdict: pass\n---\n{'b' * 40}\n")
        with self.assertRaises(orch.OrchestratorError) as cm:
            p.record_audit(TID, "pass", rel, "b" * 40, ["games/"], "codex")
        self.assertIn("not a commit", str(cm.exception))

    def test_the_executor_cannot_audit_its_own_task(self):
        p = self.proj()
        rel = self.report("AUD-1", "pass")
        for who in ("claude-code", " Claude-Code "):
            with self.assertRaises(orch.OrchestratorError) as cm:
                p.record_audit(TID, "pass", rel, self.sha, ["games/"], who)
            self.assertIn("executor", str(cm.exception))
        self.assertEqual(p.task(TID)["status"], "review")

    def test_applies_to_and_auditor_are_required(self):
        p = self.proj()
        rel = self.report("AUD-1", "pass")
        with self.assertRaises(orch.OrchestratorError):
            p.record_audit(TID, "pass", rel, self.sha, [], "codex")
        with self.assertRaises(orch.OrchestratorError):
            p.record_audit(TID, "pass", rel, self.sha, ["games/"], " ")

    def test_the_binding_is_stored(self):
        p, _ = self.audited()
        a = p.task(TID)["audits"][-1]
        rel = "06 QA/AUD-1.md"
        self.assertEqual(a["measured_sha"], self.sha)
        self.assertEqual(a["applies_to"], ["games/"])
        self.assertEqual(a["auditor"], "codex")
        self.assertEqual(a["report"], rel)
        self.assertEqual(a["report_sha256"], hashlib.sha256((self.root / rel).read_bytes()).hexdigest())
        self.assertEqual(p.task(TID)["status"], "approved")

    def test_the_cli_takes_the_new_flags(self):
        rel = self.report("AUD-1", "pass")
        code, out = self.cli("record-audit", TID, "--verdict", "pass", "--report", rel, "--measured-sha", self.sha,
                             "--applies-to", "games/", "docs/", "--auditor", "codex")
        self.assertEqual(code, 0, out)
        self.assertEqual(self.proj().task(TID)["audits"][-1]["applies_to"], ["games/", "docs/"])
        with self.assertRaises(SystemExit):  # argparse: the binding flags are required
            self.cli("record-audit", TID, "--result", "pass", "--report", rel)


class TestApproveMerge(GateBase):
    def test_it_records_the_approval_verbatim_and_never_sets_done(self):
        p, head = self.audited()
        text = '  "yes, merge PR 7"  '
        self.approve(p, head, text)
        t = p.task(TID)
        self.assertEqual(t["status"], "approved")
        self.assertEqual(t["merge_approval"]["text"], text)
        self.assertEqual((t["merge_approval"]["pr"], t["merge_approved_by"]), (7, "jg"))

    def test_it_refuses_empty_text_an_agent_a_draft_a_closed_pr_and_a_foreign_branch(self):
        p, head = self.audited()
        with self.assertRaises(orch.OrchestratorError):
            self.approve(p, head, "  ")
        with mock.patch.object(orch, "gh_pr_view", return_value=self.open_pr(head)):
            with self.assertRaises(orch.OrchestratorError):
                p.approve_merge(TID, "codex", 7, "merge")
        for extra in ({"isDraft": True}, {"state": "CLOSED"}, {"headRefName": "task/other"}):
            with self.assertRaises(orch.OrchestratorError, msg=str(extra)):
                self.approve(p, head, **extra)
        self.assertNotIn("merge_approval", p.task(TID))

    def test_a_fail_or_a_missing_audit_cannot_be_approved(self):
        p = self.proj()
        head = self.sha
        t = p.task(TID)
        t["status"] = "approved"  # as if someone edited the file
        with self.assertRaises(orch.OrchestratorError) as cm:
            self.approve(p, head)
        self.assertIn("no audit is recorded", str(cm.exception))

    def test_a_pass_recorded_before_head_binding_is_refused(self):
        p, head = self.audited()
        a = p.task(TID)["audits"][-1]
        del a["measured_sha"]
        with self.assertRaises(orch.OrchestratorError) as cm:
            self.approve(p, head)
        self.assertIn("measured_sha", str(cm.exception))

    def test_an_edited_audit_report_is_refused(self):
        p, _ = self.audited()
        (self.root / "06 QA" / "AUD-1.md").write_text(f"---\nverdict: pass\n---\n{self.sha} edited later\n")
        head_b = self.commit("tampered report")
        with self.assertRaises(orch.OrchestratorError) as cm:
            self.approve(p, head_b)
        self.assertIn("sha256 differs", str(cm.exception))

    def test_a_head_that_does_not_descend_from_the_audited_commit_is_refused(self):
        p, _ = self.audited()
        import subprocess
        subprocess.run(["git", "-C", str(self.root), "checkout", "-q", "--orphan", "other"], check=True)
        (self.root / "y.txt").write_text("y")
        other = self.commit("unrelated history")
        with self.assertRaises(orch.OrchestratorError) as cm:
            self.approve(p, other)
        self.assertIn("not an ancestor", str(cm.exception))


class TestDeepTier(GateBase):
    tier = "deep"

    def test_a_deep_task_needs_a_codex_pass(self):
        p, head = self.audited(auditor="claude-auditor")
        with self.assertRaises(orch.OrchestratorError) as cm:
            self.approve(p, head)
        self.assertIn("Codex", str(cm.exception))

    def test_a_codex_pass_is_enough(self):
        p, head = self.audited(auditor="codex")
        self.approve(p, head)


class TestLightTier(GateBase):
    tier = "light"

    def setUp(self):
        super().setUp()
        p = self.proj()
        t = p.task(TID)
        self.assertEqual(t["status"], "approved")  # light tier skips the audit

    def test_green_checks_stand_in_for_a_pass(self):
        p = self.proj()
        for rollup in (None, [], [{"conclusion": "FAILURE"}], [{"conclusion": "SUCCESS"}, {"status": "IN_PROGRESS"}]):
            with self.assertRaises(orch.OrchestratorError, msg=str(rollup)):
                self.approve(p, self.sha, statusCheckRollup=rollup)
        self.approve(p, self.sha, statusCheckRollup=[{"conclusion": "SUCCESS"}, {"conclusion": "NEUTRAL"}])


class TestMarkMerged(GateBase):
    def approved(self):
        p, head = self.audited()
        self.approve(p, head)
        p.save()
        return p, self.commit("approval record")

    def test_an_open_pr_is_not_done(self):
        p, head = self.approved()
        with mock.patch.object(orch, "gh_pr_view", return_value=self.open_pr(head)):
            with self.assertRaises(orch.OrchestratorError) as cm:
                p.mark_merged(TID, 7)
        self.assertIn("not MERGED", str(cm.exception))
        self.assertEqual(p.task(TID)["status"], "approved")

    def test_a_merged_pr_sets_done_and_records_the_merge(self):
        p, head = self.approved()
        with mock.patch.object(orch, "gh_pr_view", return_value=self.merged_pr(head)):
            p.mark_merged(TID, 7)
        t = p.task(TID)
        self.assertEqual(t["status"], "done")
        self.assertEqual(t["merged"]["merge_commit"], "f" * 40)
        self.assertEqual((t["merged"]["merged_at"], t["merged"]["pr"]), ("2026-11-05T00:00:00Z", 7))

    def test_it_needs_a_recorded_approval(self):
        p, head = self.audited()
        with mock.patch.object(orch, "gh_pr_view", return_value=self.merged_pr(head)):
            with self.assertRaises(orch.OrchestratorError) as cm:
                p.mark_merged(TID, 7)
        self.assertIn("no merge approval recorded", str(cm.exception))

    def test_it_needs_the_approval_to_be_for_that_pr(self):
        p, head = self.approved()
        with mock.patch.object(orch, "gh_pr_view", return_value=self.merged_pr(head)):
            with self.assertRaises(orch.OrchestratorError):
                p.mark_merged(TID, 8)
        self.assertEqual(p.task(TID)["status"], "approved")

    def test_a_pr_merged_with_source_the_audit_never_saw_is_not_marked_done(self):
        p, _ = self.approved()
        head_b = self.change_source()
        with mock.patch.object(orch, "gh_pr_view", return_value=self.merged_pr(head_b)):
            with self.assertRaises(orch.OrchestratorError) as cm:
                p.mark_merged(TID, 7)
        self.assertIn("post-merge finding", str(cm.exception))
        self.assertEqual(p.task(TID)["status"], "approved")

    def test_the_cli_commands(self):
        p, head = self.audited()
        with mock.patch.object(orch, "gh_pr_view", return_value=self.open_pr(head)):
            code, out = self.cli("approve-merge", TID, "--by", "jg", "--pr", "7", "--approval-text", "Merge PR 7")
        self.assertEqual((code, out.strip()), (0, f"{TID} -> approved"))
        head2 = self.commit("approval record")
        with mock.patch.object(orch, "gh_pr_view", return_value=self.merged_pr(head2)):
            code, out = self.cli("mark-merged", TID, "--pr", "7")
        self.assertEqual((code, out.strip()), (0, f"{TID} -> done"))
        with self.assertRaises(SystemExit):  # --pr and --approval-text are required
            self.cli("approve-merge", TID, "--by", "jg")


class TestPostMerge(GateBase):
    def done(self):
        p, head = self.audited()
        self.approve(p, head)
        p.save()
        head2 = self.commit("approval record")
        with mock.patch.object(orch, "gh_pr_view", return_value=self.merged_pr(head2)):
            p.mark_merged(TID, 7)
        p.save()
        self.commit("done")
        (self.root / "tasks" / "items" / "TASK-0002.json").write_text(
            '{"id": "TASK-0002", "title": "Fix", "status": "backlog", "risk": "low", "depends_on": [], '
            '"acceptance": ["x"]}')
        return self.proj()

    def test_a_finding_on_a_done_task_is_appended_and_the_status_stays(self):
        p = self.done()
        history = list(p.task(TID)["history"])
        rel = "06 QA/AUD-2.md"
        (self.root / rel).write_text(f"---\nverdict: fail\n---\nmeasured {self.sha}\n")
        p.record_audit(TID, "fail", rel, self.sha, ["games/"], "codex", post_merge=True, remediation="TASK-0002")
        t = p.task(TID)
        self.assertEqual(t["status"], "done")
        self.assertEqual(t["history"], history)
        last = t["audits"][-1]
        self.assertEqual((last["result"], last["post_merge"], last["remediation"]), ("fail", True, "TASK-0002"))
        self.assertEqual(t.get("revisions", 0), 0)

    def test_a_post_merge_finding_needs_a_remediation_task(self):
        p = self.done()
        rel = "06 QA/AUD-2.md"
        (self.root / rel).write_text(f"---\nverdict: fail\n---\nmeasured {self.sha}\n")
        for remediation in (None, "TASK-0001", "TASK-9999"):
            with self.assertRaises(orch.OrchestratorError, msg=str(remediation)):
                p.record_audit(TID, "fail", rel, self.sha, ["games/"], "codex", post_merge=True,
                               remediation=remediation)

    def test_post_merge_is_only_for_done_tasks_and_a_pass_is_not_a_verdict_on_a_new_head(self):
        p = self.proj()  # still in review
        rel = self.report("AUD-2", "fail")
        with self.assertRaises(orch.OrchestratorError):
            p.record_audit(TID, "fail", rel, self.sha, ["games/"], "codex", post_merge=True, remediation="TASK-0002")

    def test_reopen_is_unchanged(self):
        p, _ = self.audited()
        p.reopen(TID, "review", "re-scope", "jg")
        self.assertEqual(p.task(TID)["status"], "review")
        self.assertEqual(len(p.task(TID)["audits"]), 1)


if __name__ == "__main__":
    unittest.main()
