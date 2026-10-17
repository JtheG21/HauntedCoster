"""Tests for scripts/refs.py. Run: python3 -m unittest discover -s tests"""

import contextlib
import io
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
