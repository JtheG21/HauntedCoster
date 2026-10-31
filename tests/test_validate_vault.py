"""Tests for scripts/validate_vault.py. Run: python3 -m unittest discover -s tests"""

import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "scripts"))
import validate_vault as vv  # noqa: E402

GAME = "03 Games/GAME-001 Test"


def note(id_, type_, status="done", project=None, body="", **extra):
    lines = ["---", f"id: {id_}", f"title: {id_}", f"type: {type_}", f"status: {status}",
             "created: 2026-10-10", "updated: 2026-10-10"]
    if project:
        lines.append(f"project: {project}")
    lines += [f"{k}: {v}" for k, v in extra.items()]
    return "\n".join(lines + ["---", body, ""])


class VaultTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.write(f"{GAME}/00 Overview.md", note("GAME-001", "overview", project="GAME-001",
                                                 body="[[TASK-0001-Thing]] [[Notes.base]]"))
        self.write(f"{GAME}/06 Tasks/TASK-0001-Thing.md", note("TASK-0001", "task", project="GAME-001",
                                                             body="[[00 Overview]] `[[not-a-link]]`"))
        self.write("00 Studio/Notes.base", "views: []\n")
        self.write("99 Templates/T - Task.md", "---\nid: TASK-0000\ntype: task\nstatus: proposed\n---\n[[TASK-0000-...]]\n")
        self.queue([{"id": "TASK-0001", "status": "done", "note_path": f"{GAME}/06 Tasks/TASK-0001-Thing.md"}])

    def tearDown(self):
        self.tmp.cleanup()

    def write(self, rel, text):
        p = self.root / rel
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(text)

    def queue(self, tasks):
        self.write("tasks/queue.json", json.dumps({"tasks": tasks}))

    def errors(self):
        return "\n".join(vv.validate(self.root).errors)

    def test_clean_vault(self):
        self.assertEqual(self.errors(), "")

    def test_broken_link(self):
        self.write("09 Knowledge/LES-0001-X.md", note("LES-0001", "lesson", body="[[Nope]]"))
        self.assertIn("broken link [[Nope]]", self.errors())

    def test_bad_status_type_and_date(self):
        self.write("09 Knowledge/LES-0001-X.md", note("LES-0001", "lesson", status="completed").replace(
            "updated: 2026-10-10", "updated: 10/10/2026"))
        errs = self.errors()
        self.assertIn("invalid status 'completed'", errs)
        self.assertIn("'updated' must be YYYY-MM-DD", errs)

    def test_missing_frontmatter_and_fields(self):
        self.write("02 Research/RSH-20261010-Topic.md", "# no frontmatter\n")
        self.write("09 Knowledge/LES-0002-Y.md", "---\nid: LES-0002\ntype: lesson\n---\n")
        errs = self.errors()
        self.assertIn("missing YAML frontmatter", errs)
        self.assertIn("missing 'status'", errs)

    def test_filename_folder_and_id(self):
        self.write("06 QA/AUD-2026-10-10.md", note("AUD-x", "audit"))
        self.write("02 Research/LES-0003-Misplaced.md", note("LES-0003", "lesson"))
        self.write("09 Knowledge/LES-0004-Wrong-Id.md", note("LES-9999", "lesson"))
        errs = self.errors()
        self.assertIn("filename doesn't match the audit pattern", errs)
        self.assertIn("lesson notes belong in", errs)
        self.assertIn("id 'LES-9999' should be 'LES-0004'", errs)

    def test_duplicate_id_and_project(self):
        self.write(f"{GAME}/06 Tasks/TASK-0001-Copy.md", note("TASK-0001", "task", project="GAME-002"))
        errs = self.errors()
        self.assertIn("duplicate id 'TASK-0001'", errs)
        self.assertIn("project must be GAME-001", errs)

    def test_queue_status_mismatch_flagged(self):
        self.queue([{"id": "TASK-0001", "status": "review", "note_path": f"{GAME}/06 Tasks/TASK-0001-Thing.md"}])
        self.assertIn("status mismatch", self.errors())

    def test_queue_missing_note(self):
        self.queue([{"id": "TASK-0002", "status": "backlog", "note_path": "nowhere.md"}])
        self.assertIn("note not found", self.errors())

    def test_task_note_not_in_queue_warns(self):
        self.queue([])
        rep = vv.validate(self.root)
        self.assertTrue(any("isn't in tasks/queue.json" in w for w in rep.warnings))

    def test_overview_table_matches_queue(self):
        self.write(f"{GAME}/00 Overview.md", note("GAME-001", "overview", project="GAME-001",
                                                 body="| [[TASK-0001-Thing]] | done | — |"))
        rep = vv.validate(self.root)
        self.assertFalse(any("task table" in w for w in rep.warnings))
        self.write(f"{GAME}/00 Overview.md", note("GAME-001", "overview", project="GAME-001",
                                                 body="| [[TASK-0001-Thing]] | in_progress (old) | — |"))
        rep = vv.validate(self.root)
        self.assertTrue(any("shows TASK-0001 as 'in_progress'" in w for w in rep.warnings))

    def test_plugin_folders_ignored(self):
        self.write("Agents/whatever.md", "[[broken]]")
        self.write(".obsidian/x.md", "[[broken]]")
        self.assertEqual(self.errors(), "")

    def test_path_link_resolves(self):
        self.write("09 Knowledge/LES-0001-X.md", note("LES-0001", "lesson", body="[[GAME-001 Test/00 Overview|ov]]"))
        self.assertEqual(self.errors(), "")


if __name__ == "__main__":
    unittest.main()
