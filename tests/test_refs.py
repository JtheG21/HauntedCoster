"""Tests for scripts/refs.py. Run: python3 -m unittest discover -s tests"""

import contextlib
import io
import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "scripts"))
import refs  # noqa: E402

NOTE = """---
id: {id}
title: {title}
type: reference
status: {status}
area: {area}
source: https://example.com
created: 2026-10-16
updated: 2026-10-16
related:
  - "[[REF-MAP-002-Other]]"
tags:
  - reference/{tag}
---
# {title}
- **Purpose:** test purpose
- **Local source:** `{local}`

## Intent
- jg likes this.

## Open questions
- Which one?

![[clip.mp4]]
"""


def note(id_="REF-MAP-001", title="One", status="proposed", area="map", tag="map", local="10 References/02 Map/x.txt"):
    return NOTE.format(id=id_, title=title, status=status, area=area, tag=tag, local=local)


class RefsTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.write("10 References/02 Map/REF-MAP-001-One.md", note())
        self.write("10 References/02 Map/REF-MAP-002-Other.md", note("REF-MAP-002", "Other", "approved"))
        self.write("10 References/02 Map/x.txt", "x")
        self.write("10 References/02 Map/Media/clip.mp4", "v")
        self.write("00 Studio/Reference Review Index.md",
                   "| [ ] | [[REF-MAP-001-One]] — One | q |\n| [x] | [[REF-MAP-002-Other]] — Other | q |\n")
        self.write("00 Studio/Resource Catalog.md",
                   "| [[REF-MAP-001-One]] | `x` | captured | n |\n| [[REF-MAP-002-Other]] | `x` | approved | n |\n")
        self.write("03 Games/GAME-001 T/06 Tasks/TASK-0001-A.md",
                   "- **Category → workflow, depth:** Map → [[Map Workflow]], standard\n- **References:** REF-MAP-001\n")

    def tearDown(self):
        self.tmp.cleanup()

    def write(self, rel, text):
        p = self.root / rel
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(text)

    def run_cmd(self, *argv):
        out = io.StringIO()
        with contextlib.redirect_stdout(out), contextlib.redirect_stderr(out):
            code = refs.main(["--root", str(self.root), *argv])
        return code, out.getvalue()

    def test_clean_lint(self):
        code, out = self.run_cmd("lint")
        self.assertEqual(code, 0, out)

    def test_lint_catches_problems(self):
        self.write("10 References/02 Map/REF-MAP-001-One.md",
                   note(status="done?").replace("![[clip.mp4]]", "![[missing.png]]").replace("x.txt", "gone.txt"))
        code, out = self.run_cmd("lint")
        self.assertEqual(code, 1)
        for fragment in ("controlled vocabulary", "missing.png", "gone.txt"):
            self.assertIn(fragment, out)

    def test_lint_id_area_and_rows(self):
        self.write("10 References/02 Map/REF-MAP-003-New.md", note("REF-MAP-004", "New", area="vfx"))
        _, out = self.run_cmd("lint")
        self.assertIn("does not match filename prefix", out)
        self.assertIn("no row in the Reference Review Index", out)
        self.assertIn("no row in the Resource Catalog", out)
        self.assertIn("area 'vfx'", out)

    def test_catalog_state_mismatch(self):
        self.write("00 Studio/Resource Catalog.md",
                   "| [[REF-MAP-001-One]] | `x` | approved | n |\n| [[REF-MAP-002-Other]] | `x` | approved | n |\n")
        _, out = self.run_cmd("lint")
        self.assertIn("Catalog state 'approved'", out)

    def test_lint_file_ignores_non_ref(self):
        self.write("00 Studio/other.md", "x")
        self.assertEqual(self.run_cmd("lint", "--file", str(self.root / "00 Studio/other.md"))[0], 0)

    def test_list_and_trace(self):
        _, out = self.run_cmd("list")
        self.assertIn("REF-MAP-001", out)
        self.assertRegex(out, r"REF-MAP-002\s+approved\s+yes")
        _, out = self.run_cmd("trace")
        self.assertIn("REF-MAP-001: TASK-0001", out)
        self.assertIn("not cited by any task (1): REF-MAP-002", out)

    def test_brief_by_category_and_task(self):
        code, out = self.run_cmd("brief", "--category", "map")
        self.assertEqual(code, 0)
        self.assertIn("jg likes this", out)
        self.assertIn("Which one?", out)
        self.assertIn("clip.mp4", out)
        self.assertIn("Also see: REF-MAP-002", out)
        _, out = self.run_cmd("brief", "--task", "TASK-0001")
        self.assertIn("REF-MAP-001", out)
        self.assertEqual(self.run_cmd("brief", "--category", "bogus")[0], 2)
        self.assertEqual(self.run_cmd("brief")[0], 2)

    def test_brief_clips_long_sections(self):
        body = note().replace("- jg likes this.", "\n".join(f"- line {i}" for i in range(30)))
        self.write("10 References/02 Map/REF-MAP-001-One.md", body)
        _, out = self.run_cmd("brief", "--ids", "REF-MAP-001", "--max-lines", "3")
        self.assertIn("(+27 more lines in the note)", out)

    def test_new_scaffold(self):
        self.write("99 Templates/T - Reference.md", "---\nid: REF-AREA-000\ntitle: \"{{title}}\"\narea: map\n"
                   "created: {{date:YYYY-MM-DD}}\n---\n# {{title}}\n")
        code, _ = self.run_cmd("new", "--area", "map", "--title", "Fresh Idea")
        self.assertEqual(code, 0)
        made = self.root / "10 References/02 Map/REF-MAP-003-Fresh-Idea.md"
        self.assertTrue(made.exists())
        self.assertIn("id: REF-MAP-003", made.read_text())
        self.assertNotIn("{{", made.read_text())
        self.assertEqual(self.run_cmd("new", "--area", "nope", "--title", "x")[0], 2)

    def test_guard_issues(self):
        old, new = note(), note().replace("jg likes this.", "changed").replace("proposed", "approved")
        issues = refs.guard_issues("f", old, new)
        self.assertEqual(len(issues), 2)
        self.assertEqual(refs.guard_issues("f", old, old.replace("test purpose", "other")), [])
        self.assertEqual(refs.guard_issues("f", None, new), [])  # a new capture


class PinRightsLedgerTest(RefsTest):
    def setUp(self):
        super().setUp()
        self.write("10 References/02 Map/REF-MAP-001-One.md",
                   note().replace("source: https://example.com", "source: https://github.com/own/repo/tree/main"))
        self.calls = []
        self._gh = refs.gh

        def fake(*args):
            self.calls.append(args)
            joined = " ".join(args)
            if "commits/HEAD" in joined:
                return self.sha
            if joined.endswith(".default_branch"):
                return "main"
            if "/license" in joined:
                return self.lic
            return None
        self.sha, self.lic = "a" * 40, "MIT"
        refs.gh = fake
        self.addCleanup(setattr, refs, "gh", self._gh)

    def test_pin_and_drift(self):
        code, out = self.run_cmd("pin")
        self.assertEqual(code, 0, out)
        self.assertIn("own/repo main@aaaaaaaaaa licence MIT", out)
        self.assertIn("skip", self.run_cmd("pin", "--ids", "REF-MAP-002")[1])
        self.assertIn("unchanged", self.run_cmd("drift")[1])
        self.sha = "b" * 40
        code, out = self.run_cmd("drift")
        self.assertEqual(code, 0)
        self.assertIn("upstream moved aaaaaaaaaa -> bbbbbbbbbb", out)
        self.lic = "AGPL-3.0"
        code, out = self.run_cmd("drift")
        self.assertEqual(code, 1)
        self.assertIn("LICENCE CHANGED MIT -> AGPL-3.0", out)

    def test_drift_before_pin_and_unreachable(self):
        code, out = self.run_cmd("drift")
        self.assertEqual(code, 1)
        self.assertIn("never pinned", out)
        refs.gh = lambda *a: None
        self.assertEqual(self.run_cmd("pin")[0], 1)

    def test_rights_gate_and_lint(self):
        self.write("00 Studio/reference-rights.json", json.dumps({"notes": {
            "REF-MAP-001": {"class": "copyleft", "basis": "AGPL"},
            "REF-MAP-002": {"class": "permissive-verified", "basis": "read LICENSE"}}}))
        self.assertEqual(self.run_cmd("lint")[0], 0)
        code, out = self.run_cmd("rights", "--check", "REF-MAP-001", "--use", "code")
        self.assertEqual(code, 1)
        self.assertIn("BLOCKED", out)
        self.assertEqual(self.run_cmd("rights", "--check", "REF-MAP-001", "--use", "method")[0], 0)
        self.assertEqual(self.run_cmd("rights", "--check", "REF-MAP-002", "--use", "asset")[0], 0)
        self.assertEqual(self.run_cmd("rights", "--check", "REF-NOPE-001")[0], 2)
        self.write("00 Studio/reference-rights.json", json.dumps({"notes": {
            "REF-MAP-001": {"class": "bogus", "basis": "x"}, "REF-GONE-001": {"class": "unknown", "basis": "x"}}}))
        _, out = self.run_cmd("lint")
        self.assertIn("needs a class", out)
        self.assertIn("no entry for REF-MAP-002", out)
        self.assertIn("unknown note REF-GONE-001", out)

    def test_ledger(self):
        self.assertIn("no task cites", self.run_cmd("ledger", "--refs", "REF-MAP-002")[1])
        self.write("tasks/queue.json", json.dumps({"tasks": [{"id": "TASK-0001", "status": "done", "revisions": 1,
            "executions": [{}, {}], "audits": [{}],
            "history": [{"time": "2026-10-10T10:00:00", "to": "in_progress"}, {"time": "2026-10-10T12:30:00", "to": "in_review"}]}]}))
        self.write("tasks/usage-ledger.jsonl",
                   '{"task": "TASK-0001", "tokens": 1000}\n{"task": "TASK-0001", "tokens": 500}\n')
        p = self.root / "03 Games/GAME-001 T/06 Tasks/TASK-0001-A.md"
        p.write_text(p.read_text() + "Reference floor met: partly (jg)\n")
        code, out = self.run_cmd("ledger")
        self.assertEqual(code, 0)
        self.assertRegex(out, r"TASK-0001\s+done\s+1\s+2\s+1\s+2\.5\s+1500\s+partly \(jg\)\s+REF-MAP-001")


class ReviewDriverTest(RefsTest):
    def test_review_next_packet(self):
        code, out = self.run_cmd("review-next")
        self.assertEqual(code, 0, out)
        self.assertIn("Review packet: REF-MAP-001", out)
        self.assertIn("1 unchecked", out)
        self.assertIn("jg likes this", out)
        self.assertIn("Which one?", out)
        self.assertIn("refs.py decide", out)
        self.assertEqual(self.run_cmd("review-next", "--id", "REF-NOPE-001")[0], 2)

    def test_review_next_when_done_and_spec_section(self):
        self.write("00 Studio/Reference Review Index.md",
                   "| [x] | [[REF-MAP-001-One]] — One | q |\n| [x] | [[REF-MAP-002-Other]] — Other | q |\n")
        self.assertIn("every item", self.run_cmd("review-next")[1])
        self.write(refs.SPEC, "## Part C\n### 1. REF-MAP-001 One\n- **Automations:** do a thing\n### 2. REF-MAP-002 Other\n- x\n")
        _, out = self.run_cmd("review-next", "--id", "REF-MAP-001")
        self.assertIn("do a thing", out)
        self.assertNotIn("REF-MAP-002 Other", out)

    ARGS = ["decide", "REF-MAP-001", "--summary", "Useful | for fog", "--inspected", "README and one video",
            "--unverified", "rights", "--by", "jg"]

    def test_decide_dry_run_changes_nothing(self):
        before = (self.root / "10 References/02 Map/REF-MAP-001-One.md").read_text()
        code, out = self.run_cmd(*self.ARGS, "--outcome", "keep")
        self.assertEqual(code, 0, out)
        self.assertIn("DRY RUN", out)
        self.assertEqual((self.root / "10 References/02 Map/REF-MAP-001-One.md").read_text(), before)

    def test_decide_apply(self):
        code, out = self.run_cmd(*self.ARGS, "--outcome", "experiment", "--next", "try one fog pack", "--apply")
        self.assertEqual(code, 0, out)
        note_path = self.root / "10 References/02 Map/REF-MAP-001-One.md"
        text = note_path.read_text()
        self.assertIn("## Review decision (", text)
        self.assertIn("propose a scoped experiment", text)
        self.assertIn("Useful / for fog", text)
        self.assertIn("**Next action:** try one fog pack", text)
        self.assertIn("| [x] | [[REF-MAP-001-One]]", (self.root / "00 Studio/Reference Review Index.md").read_text())
        self.assertRegex((self.root / "00 Studio/Resource Catalog.md").read_text(), r"Review \d{4}-\d{2}-\d{2}: propose a scoped experiment")
        # Intent and status untouched
        self.assertEqual(refs.section(text, "Intent"), refs.section(note(), "Intent"))
        self.assertEqual(refs.parse_frontmatter(text)["status"], "proposed")

    def test_decide_requires_next_and_by(self):
        self.assertEqual(self.run_cmd(*self.ARGS, "--outcome", "investigate")[0], 2)
        args = [a for a in self.ARGS]
        args[args.index("--by") + 1] = " "
        self.assertEqual(self.run_cmd(*args, "--outcome", "keep")[0], 2)
        self.assertEqual(self.run_cmd("decide", "REF-NOPE-001", "--outcome", "keep", "--summary", "s", "--inspected", "i",
                                      "--unverified", "u", "--by", "jg")[0], 2)

    def test_decision_passes_the_guard(self):
        self.run_cmd(*self.ARGS, "--outcome", "keep", "--apply")
        old = note()
        new = (self.root / "10 References/02 Map/REF-MAP-001-One.md").read_text()
        self.assertEqual(refs.guard_issues("f", old, new), [])


class GuardGitTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.note = self.root / "10 References/02 Map/REF-MAP-001-One.md"
        self.note.parent.mkdir(parents=True)
        self.note.write_text(note())
        for args in (["init", "-q", "-b", "main"], ["config", "user.email", "t@e.com"], ["config", "user.name", "t"],
                     ["add", "-A"], ["commit", "-q", "-m", "init"]):
            subprocess.run(["git", "-C", str(self.root), *args], check=True, capture_output=True)

    def tearDown(self):
        self.tmp.cleanup()

    def guard(self, env=None):
        out = io.StringIO()
        old = dict(os.environ)
        os.environ.pop("REFS_JG_APPROVED", None)
        os.environ.update(env or {})
        try:
            with contextlib.redirect_stdout(out):
                code = refs.main(["--root", str(self.root), "guard", "--staged"])
        finally:
            os.environ.clear()
            os.environ.update(old)
        return code, out.getvalue()

    def stage(self, text):
        self.note.write_text(text)
        subprocess.run(["git", "-C", str(self.root), "add", "-A"], check=True, capture_output=True)

    def test_staged_intent_edit_blocks_until_jg_approves(self):
        self.stage(note().replace("jg likes this.", "Claude summary."))
        code, out = self.guard()
        self.assertEqual(code, 1)
        self.assertIn("Intent", out)
        self.assertEqual(self.guard({"REFS_JG_APPROVED": "1"})[0], 0)

    def test_other_edits_pass(self):
        self.stage(note().replace("test purpose", "new purpose text"))
        self.assertEqual(self.guard()[0], 0)


if __name__ == "__main__":
    unittest.main()
