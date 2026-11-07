"""Tests for the audit-head gate in scripts/orchestrator.py: record-audit, approve-merge, mark-merged, --post-merge.

The first group replays the TASK-0138 timeline (a PASS measured at A, source changed after it, merged anyway). The
`TestBypass*` groups reproduce each bypass in AUD-20261105-TASK-0140-01 and show it is refused.
Run: python3 -m unittest discover tests
"""

import hashlib
import json
import subprocess
import sys
import unittest
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "scripts"))
import orchestrator as orch  # noqa: E402
from test_orchestrator import Base, task  # noqa: E402

TID = "TASK-0001"
NOTE = "03 Games/G/06 Tasks/TASK-0001-Thing.md"


class GateBase(Base):
    """A task in `review` whose registration commit A (also the PR base) holds a source file."""

    tier = "standard"

    def setUp(self):
        super().setUp()
        t = task(TID)
        t["tier"] = self.tier
        t["owner_agent"] = "claude-code"
        t["note_path"] = NOTE
        note = self.root / NOTE
        note.parent.mkdir(parents=True)
        note.write_text("---\nstatus: backlog\nupdated: 2000-01-01\n---\n# Body\n")
        self.write_queue([t])
        (self.root / "games").mkdir()
        (self.root / "games" / "x.luau").write_text("-- v1\n")
        self.sha = self.base_sha = self.commit("A: source and registration")
        p = self.proj()
        p.approve(TID, "jg")
        p.start(TID)
        p.record_exec(TID, "pass", "")
        p.save()
        self.commit("task in review")

    def task_json(self) -> dict:
        return json.loads((self.root / "tasks" / "items" / f"{TID}.json").read_text())

    def edit_task_json(self, fn, message="edit task JSON"):
        data = self.task_json()
        fn(data)
        (self.root / "tasks" / "items" / f"{TID}.json").write_text(json.dumps(data))
        return self.commit(message)

    def audited(self, verdict="pass", auditor="codex", name="AUD-1"):
        """Record the audit measured at A (report in 06 QA/), save, commit; returns (project, head)."""
        p = self.proj()
        rel = self.report(name, verdict, TID, auditor)
        p.record_audit(TID, verdict, rel, self.sha, ["games/"], auditor)
        p.save()
        return p, self.commit("audit record")

    def change_source(self):
        (self.root / "games" / "x.luau").write_text("-- v2, after the audit\n")
        return self.commit("B: source change")

    def approve(self, p, head, text="Merge PR 7", **pr_extra):
        with mock.patch.object(orch, "gh_pr_view", return_value=self.open_pr(head, **pr_extra)):
            p.approve_merge(TID, "jg", 7, text)

    def refused(self, p, head, *needles, **pr_extra):
        with self.assertRaises(orch.OrchestratorError) as cm:
            self.approve(p, head, **pr_extra)
        for n in needles:
            self.assertIn(n, str(cm.exception))
        self.assertNotIn("merge_approval", p.task(TID))
        return str(cm.exception)


class TestTask0138Timeline(GateBase):
    def test_source_change_after_the_pass_is_refused(self):
        p, _ = self.audited()
        self.refused(p, self.change_source(), "games/x.luau", "refused by the audit gate")

    def test_only_audit_and_task_records_after_the_pass_is_allowed(self):
        p, head = self.audited()
        (self.root / "06 QA" / "extra-finding.md").write_text("later note\n")
        (self.root / "docs" / "workflow" / "evidence" / "TASK-0001").mkdir(parents=True)
        (self.root / "docs" / "workflow" / "evidence" / "TASK-0001" / "run.txt").write_text("evidence\n")
        head_b = self.commit("records only")
        self.approve(p, head_b)
        self.assertEqual(p.task(TID)["merge_approval"]["head_sha"], head_b)
        self.assertEqual(p.task(TID)["merge_approval"]["base_sha"], self.base_sha)

    def test_the_task_note_may_change_after_the_pass(self):
        p, _ = self.audited()
        (self.root / NOTE).write_text("---\nstatus: approved\n---\n# Body\nOutcome\n")
        self.approve(p, self.commit("note"))

    def test_another_note_is_source_to_the_gate(self):
        p, _ = self.audited()
        (self.root / "03 Games" / "G" / "06 Tasks" / "Other.md").write_text("x\n")
        self.refused(p, self.commit("other note"), "Other.md")


class TestRecordAudit(GateBase):
    def record(self, rel, verdict="pass", sha=None, auditor="codex"):
        self.proj().record_audit(TID, verdict, rel, sha or self.sha, ["games/"], auditor)

    def test_a_report_without_reviewed_commit_is_refused(self):
        rel = self.report("AUD-1", "pass")
        (self.root / rel).write_text(f"---\nid: AUD-1\ntask_id: {TID}\nverdict: pass\nreviewer: codex\n---\n{self.sha}\n")
        with self.assertRaises(orch.OrchestratorError) as cm:
            self.record(rel)
        self.assertIn("reviewed_commit", str(cm.exception))
        self.assertEqual(self.proj().task(TID)["status"], "review")

    def test_a_report_citing_a_different_sha_is_refused(self):
        rel = self.report("AUD-1", "pass", sha="a" * 40)
        with self.assertRaises(orch.OrchestratorError):
            self.record(rel)

    def test_a_verdict_that_disagrees_is_refused(self):
        rel = self.report("AUD-1", "fail")
        with self.assertRaises(orch.OrchestratorError) as cm:
            self.record(rel, "pass")
        self.assertIn("verdict is 'fail'", str(cm.exception))

    def test_a_reviewer_that_disagrees_is_refused(self):
        rel = self.report("AUD-1", "pass", reviewer="someone")
        with self.assertRaises(orch.OrchestratorError) as cm:
            self.record(rel, auditor="codex")
        self.assertIn("reviewer", str(cm.exception))

    def test_a_report_with_no_frontmatter_verdict_is_refused(self):
        rel = self.report("AUD-1", "pass")
        (self.root / rel).write_text(f"# audit of {self.sha}\nverdict: pass\n")
        with self.assertRaises(orch.OrchestratorError) as cm:
            self.record(rel)
        self.assertIn("verdict must be pass or fail", str(cm.exception))

    def test_a_report_for_another_task_or_with_a_wrong_id_is_refused(self):
        for rel in (self.report("AUD-1", "pass", task_id="TASK-0002"), "06 QA/AUD-x.md"):
            if rel.endswith("AUD-x.md"):
                (self.root / rel).write_text(f"---\nid: AUD-1\ntask_id: {TID}\nverdict: pass\n"
                                             f"reviewed_commit: {self.sha}\nreviewer: codex\n---\n")
            with self.assertRaises(orch.OrchestratorError, msg=rel):
                self.record(rel)

    def test_a_report_outside_06_qa_is_refused(self):
        rel = self.report("AUD-1", "pass")
        (self.root / "06 QA" / "sub").mkdir()
        (self.root / "06 QA" / "sub" / "AUD-1.md").write_text((self.root / rel).read_text())
        with self.assertRaises(orch.OrchestratorError):
            self.record("06 QA/sub/AUD-1.md")

    def test_a_short_or_unknown_sha_is_refused(self):
        rel = self.report("AUD-1", "pass")
        with self.assertRaises(orch.OrchestratorError):
            self.record(rel, sha=self.sha[:12])
        rel = self.report("AUD-1", "pass", sha="b" * 40)
        with self.assertRaises(orch.OrchestratorError) as cm:
            self.record(rel, sha="b" * 40)
        self.assertIn("not a commit", str(cm.exception))

    def test_the_executor_cannot_audit_its_own_task(self):
        for who in ("claude-code", " Claude-Code "):
            rel = self.report("AUD-1", "pass", reviewer=who.strip().lower())
            with self.assertRaises(orch.OrchestratorError) as cm:
                self.record(rel, auditor=who)
            self.assertIn("executor", str(cm.exception))
        self.assertEqual(self.proj().task(TID)["status"], "review")

    def test_applies_to_and_auditor_are_required(self):
        p = self.proj()
        rel = self.report("AUD-1", "pass")
        with self.assertRaises(orch.OrchestratorError):
            p.record_audit(TID, "pass", rel, self.sha, [], "codex")
        with self.assertRaises(orch.OrchestratorError):
            p.record_audit(TID, "pass", rel, self.sha, ["games/"], " ")

    def test_the_same_report_cannot_be_recorded_twice(self):
        p, _ = self.audited("fail")
        p.start(TID)
        p.record_exec(TID, "pass", "")
        with self.assertRaises(orch.OrchestratorError) as cm:
            p.record_audit(TID, "fail", "06 QA/AUD-1.md", self.sha, ["games/"], "codex")
        self.assertIn("already indexes", str(cm.exception))

    def test_the_index_entry_is_stored(self):
        p, _ = self.audited()
        a = p.task(TID)["audits"][-1]
        rel = "06 QA/AUD-1.md"
        self.assertEqual((a["measured_sha"], a["applies_to"], a["auditor"], a["report"]), (self.sha, ["games/"], "codex", rel))
        self.assertEqual(a["report_sha256"], hashlib.sha256((self.root / rel).read_bytes()).hexdigest())
        self.assertEqual(p.task(TID)["status"], "approved")

    def test_the_cli_takes_the_flags(self):
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
        self.assertEqual((t["merge_approval"]["pr"], t["merge_approved_by"], t["merge_approval"]["head_sha"]),
                         (7, "jg", head))

    def test_it_refuses_empty_text_an_agent_a_draft_a_closed_pr_and_a_foreign_branch(self):
        p, head = self.audited()
        with self.assertRaises(orch.OrchestratorError):
            self.approve(p, head, "  ")
        with mock.patch.object(orch, "gh_pr_view", return_value=self.open_pr(head)):
            with self.assertRaises(orch.OrchestratorError):
                p.approve_merge(TID, "codex", 7, "merge")
        for extra in ({"isDraft": True}, {"state": "CLOSED"}, {"headRefName": "task/other"}):
            self.refused(p, head, **extra)

    def test_incomplete_github_metadata_is_refused(self):
        p, head = self.audited()
        for extra in ({"isDraft": None}, {"headRefName": None}, {"baseRefOid": None}, {"baseRefOid": "abc"},
                      {"headRefOid": head[:12]}):
            self.refused(p, head, **extra)

    def test_a_missing_audit_cannot_be_approved_even_when_status_says_approved(self):
        p = self.proj()
        p.task(TID)["status"] = "approved"  # as if someone edited the file
        self.refused(p, self.sha, "no audit is recorded")

    def test_status_approved_with_a_json_pass_and_no_report_is_refused(self):
        """GATE-07: `approved` plus a JSON PASS is not sufficient; the report decides."""
        p = self.proj()
        head = self.edit_task_json(lambda d: d.update(status="approved", audits=[
            {"result": "pass", "report": "06 QA/AUD-9.md", "measured_sha": self.sha, "auditor": "codex",
             "report_sha256": "0" * 64}]))
        self.refused(self.proj(), head, "AUD-9.md is missing")

    def test_an_edited_audit_report_is_refused(self):
        p, _ = self.audited()
        rel = "06 QA/AUD-1.md"
        (self.root / rel).write_text((self.root / rel).read_text() + "edited later\n")
        self.refused(p, self.commit("tampered report"), "changed after it was recorded")

    def test_a_head_that_does_not_descend_from_the_audited_commit_is_refused(self):
        p, _ = self.audited()
        subprocess.run(["git", "-C", str(self.root), "checkout", "-q", "--orphan", "other"], check=True)
        (self.root / "y.txt").write_text("y")
        self.refused(p, self.commit("unrelated history"), "merge base")


class TestBypassJsonIsIndexOnly(GateBase):
    """B2/X2: one-field JSON edits used to turn a real FAIL or a stale PASS into an accepted PASS."""

    def test_json_verdict_edited_fail_to_pass_after_a_fail_is_refused(self):
        p, _ = self.audited("fail")
        head = self.edit_task_json(lambda d: (d["audits"][-1].update(result="pass"), d.update(status="approved")))
        self.refused(self.proj(), head, "the task JSON says 'pass' but the report", "says 'fail'")

    def test_json_measured_sha_edited_after_a_source_change_is_refused(self):
        p, _ = self.audited()
        head_b = self.change_source()
        head = self.edit_task_json(lambda d: d["audits"][-1].update(measured_sha=head_b))
        self.refused(p, head, "measured_sha", "reviewed_commit")

    def test_a_json_record_with_no_report_fields_is_refused(self):
        p, _ = self.audited()
        head = self.edit_task_json(lambda d: d["audits"].append({"result": "pass"}))
        self.refused(p, head)

    def test_dropping_a_later_fail_from_the_json_is_refused(self):
        p, _ = self.audited("pass")
        rel = self.report("AUD-2", "fail")
        self.commit("a later failing report")
        # the JSON never indexes AUD-2: the report itself names the task
        self.refused(p, self.commit(), "AUD-2.md names this task but the task JSON does not index it")
        self.assertTrue((self.root / rel).exists())

    def test_a_second_report_with_the_same_audit_id_is_refused(self):
        p, _ = self.audited()
        text = (self.root / "06 QA" / "AUD-1.md").read_text().replace(f"task_id: {TID}", "task_id: TASK-0002")
        (self.root / "06 QA" / "AUD-1-copy.md").write_text(text)  # same id: AUD-1, another file
        self.refused(p, self.commit("second report, same id"), "claimed by more than one report")

    def test_a_report_deleted_and_added_again_is_refused(self):
        p, _ = self.audited()
        rel = self.root / "06 QA" / "AUD-1.md"
        text = rel.read_text()
        rel.unlink()
        self.commit("remove report")
        rel.write_text(text)
        self.refused(p, self.commit("re-add report"), "added 2 times")


class TestBypassTierAndRole(GateBase):
    tier = "deep"

    def test_tier_changed_to_light_on_the_branch_is_refused(self):
        p, _ = self.audited("fail")
        head = self.edit_task_json(lambda d: d.update(tier="light", status="approved"))
        self.refused(self.proj(), head, "tier changed on the branch", "'deep'", "'light'",
                     statusCheckRollup=[{"conclusion": "SUCCESS"}])

    def test_owner_changed_on_the_branch_is_refused(self):
        p, _ = self.audited()
        self.refused(p, self.edit_task_json(lambda d: d.update(owner_agent="someone")), "owner_agent changed")

    def test_an_executor_transition_to_approved_is_refused(self):
        p = self.proj()
        t = p.task(TID)
        with self.assertRaises(orch.OrchestratorError) as cm:
            p._move(t, "approved", "executor says so")
        self.assertIn("only record-audit", str(cm.exception))
        self.assertEqual(t["status"], "review")

    def test_a_non_independent_pass_is_advisory_and_does_not_approve(self):
        p, _ = self.audited(auditor="claude-auditor")
        t = p.task(TID)
        self.assertEqual(t["status"], "review")
        self.assertTrue(t["audits"][-1]["advisory"])

    def test_a_deep_task_needs_a_codex_pass(self):
        p, _ = self.audited(auditor="claude-auditor")
        p.task(TID)["status"] = "approved"  # hand-edited
        self.refused(p, self.commit(), "independent auditor")

    def test_a_codex_pass_is_enough(self):
        p, head = self.audited(auditor="codex")
        self.approve(p, head)


class TestStandardIsDeep(GateBase):
    tier = "standard"

    def test_record_exec_never_approves_a_standard_task(self):
        self.assertEqual(self.proj().task(TID)["status"], "review")

    def test_a_standard_task_without_a_codex_pass_is_refused(self):
        p, _ = self.audited(auditor="claude-auditor")
        p.task(TID)["status"] = "approved"
        self.refused(p, self.commit(), "independent auditor", "'claude-auditor'")


class TestLightTier(GateBase):
    tier = "light"

    def test_green_checks_stand_in_for_a_pass(self):
        p = self.proj()
        self.assertEqual(p.task(TID)["status"], "approved")  # light tier skips the audit
        for rollup in (None, [], [{"conclusion": "FAILURE"}], [{"conclusion": "SUCCESS"}, {"status": "IN_PROGRESS"}]):
            with self.assertRaises(orch.OrchestratorError, msg=str(rollup)):
                self.approve(p, self.sha, statusCheckRollup=rollup)
        self.approve(p, self.sha, statusCheckRollup=[{"conclusion": "SUCCESS"}, {"conclusion": "NEUTRAL"}])


class TestMarkMerged(GateBase):
    def approved(self):
        p, head = self.audited()
        self.approve(p, head)
        p.save()  # the approval record stays out of the PR branch: committing it would move the approved head
        return p, head

    def mark(self, p, head, pr=7, **extra):
        with mock.patch.object(orch, "gh_pr_view", return_value=self.merged_pr(head) | extra):
            p.mark_merged(TID, pr)

    def test_an_open_pr_is_not_done(self):
        p, head = self.approved()
        with self.assertRaises(orch.OrchestratorError) as cm:
            self.mark(p, head, state="OPEN")
        self.assertIn("not MERGED", str(cm.exception))
        self.assertEqual(p.task(TID)["status"], "approved")

    def test_a_merged_pr_sets_done_and_records_the_merge(self):
        p, head = self.approved()
        self.mark(p, head)
        t = p.task(TID)
        self.assertEqual(t["status"], "done")
        self.assertEqual((t["merged"]["merge_commit"], t["merged"]["head_sha"]), ("f" * 40, head))
        self.assertEqual((t["merged"]["merged_at"], t["merged"]["pr"]), ("2026-11-05T00:00:00Z", 7))

    def test_it_needs_a_recorded_approval_for_that_pr(self):
        p, head = self.audited()
        with self.assertRaises(orch.OrchestratorError) as cm:
            self.mark(p, head)
        self.assertIn("no merge approval recorded", str(cm.exception))
        self.approve(p, head)
        with self.assertRaises(orch.OrchestratorError):
            self.mark(p, head, pr=8)
        self.assertEqual(p.task(TID)["status"], "approved")

    def test_a_merged_head_other_than_the_approved_head_is_refused(self):
        """GATE-06: even a records-only commit after the approval is not the approved head."""
        p, _ = self.approved()
        later = self.commit("approval record pushed after approval")
        with self.assertRaises(orch.OrchestratorError) as cm:
            self.mark(p, later)
        self.assertIn("jg approved", str(cm.exception))
        self.assertEqual(p.task(TID)["status"], "approved")

    def test_a_pr_merged_with_source_the_audit_never_saw_is_not_marked_done(self):
        p, _ = self.approved()
        with self.assertRaises(orch.OrchestratorError) as cm:
            self.mark(p, self.change_source())
        self.assertIn("post-merge finding", str(cm.exception))

    def test_incomplete_merge_metadata_is_refused(self):
        p, head = self.approved()
        for extra in ({"mergeCommit": {"oid": "abc"}}, {"mergeCommit": None}, {"mergedAt": ""}, {"headRefName": "x"}):
            with self.assertRaises(orch.OrchestratorError, msg=str(extra)):
                self.mark(p, head, **extra)
        self.assertEqual(p.task(TID)["status"], "approved")

    def test_the_cli_commands(self):
        _, head = self.audited()
        with mock.patch.object(orch, "gh_pr_view", return_value=self.open_pr(head)):
            code, out = self.cli("approve-merge", TID, "--by", "jg", "--pr", "7", "--approval-text", "Merge PR 7")
        self.assertEqual((code, out.strip()), (0, f"{TID} -> approved"))
        with mock.patch.object(orch, "gh_pr_view", return_value=self.merged_pr(head)):
            code, out = self.cli("mark-merged", TID, "--pr", "7")
        self.assertEqual((code, out.strip()), (0, f"{TID} -> done"))
        with self.assertRaises(SystemExit):  # --pr and --approval-text are required
            self.cli("approve-merge", TID, "--by", "jg")


class TestPostMerge(GateBase):
    def done(self):
        p, head = self.audited()
        self.approve(p, head)
        with mock.patch.object(orch, "gh_pr_view", return_value=self.merged_pr(head)):
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
        rel = self.report("AUD-2", "fail")
        p.record_audit(TID, "fail", rel, self.sha, ["games/"], "codex", post_merge=True, remediation="TASK-0002")
        t = p.task(TID)
        self.assertEqual(t["status"], "done")
        self.assertEqual(t["history"], history)
        last = t["audits"][-1]
        self.assertEqual((last["result"], last["post_merge"], last["remediation"]), ("fail", True, "TASK-0002"))
        self.assertEqual(t.get("revisions", 0), 0)

    def test_a_post_merge_finding_needs_a_remediation_task(self):
        p = self.done()
        rel = self.report("AUD-2", "fail")
        for remediation in (None, "TASK-0001", "TASK-9999"):
            with self.assertRaises(orch.OrchestratorError, msg=str(remediation)):
                p.record_audit(TID, "fail", rel, self.sha, ["games/"], "codex", post_merge=True,
                               remediation=remediation)

    def test_post_merge_is_only_for_done_tasks(self):
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
