"""Queue schema and files_owned rule (scripts/validate_queue.py), and migration (scripts/migrate_queue.py)."""

import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))

import migrate_queue  # noqa: E402
import validate_queue  # noqa: E402


def task(tid="TASK-0001", status="in_progress", files=("a/b.luau",)):
    return {"id": tid, "game": "GAME-004", "title": "T", "status": status, "tier": "light", "owner_agent": "codex",
            "files_owned": list(files), "depends_on": [], "branch": "chore/x", "acceptance": ["works"], "evidence": [],
            "notes": "", "note_path": "n.md", "risk": "low"}


class Schema(unittest.TestCase):
    def errors(self, *tasks):
        return validate_queue.validate({"tasks": list(tasks)})

    def test_good_task(self):
        self.assertEqual(self.errors(task()), [])

    def test_missing_field(self):
        t = task()
        del t["branch"]
        self.assertIn("TASK-0001: missing 'branch'", self.errors(t))

    def test_duplicate_id(self):
        self.assertIn("TASK-0001: duplicate id", self.errors(task(files=["a"]), task(status="done")))

    def test_bad_status(self):
        self.assertTrue(any("invalid status" in e for e in self.errors(task(status="proposed"))))

    def test_null_tier_only_when_finished(self):
        t = task(status="ready")
        t["tier"] = None
        self.assertTrue(self.errors(t))
        t["status"] = "done"
        self.assertEqual(self.errors(t), [])

    def test_in_progress_needs_files(self):
        self.assertTrue(any("must list files_owned" in e for e in self.errors(task(files=[]))))


class Overlap(unittest.TestCase):
    def overlap(self, a, b):
        errors = validate_queue.validate({"tasks": [task("TASK-0001", files=[a]), task("TASK-0002", files=[b])]})
        return any("overlap" in e for e in errors)

    def test_cases(self):
        for a, b, expected in [
            ("a/b.luau", "a/b.luau", True),
            ("a/b.luau", "a/c.luau", False),
            ("a/", "a/b.luau", True),
            ("a/*.luau", "a/b.luau", True),
            ("a/*.luau", "c/b.luau", False),
            ("a/*.luau", "a/*.md", True),
            ("a/**", "b/**", False),
            ("a/b/*.luau", "a", True),
            ("a/ab", "a/a", False),
            ("games/mathshow/*/Foo.luau", "games/mathshow/src/", True),
            ("a/b/c*/d.py", "a/b/c1/", True),
            ("scripts/*.py", "scripts/lib/", True),
            ("*.md", "docs/", True),
            ("a/b.md", "a/*.py", False),
            ("a/*.luau", "c/", False),
        ]:
            with self.subTest(a=a, b=b):
                self.assertEqual(self.overlap(a, b), expected)
                self.assertEqual(self.overlap(b, a), expected)

    def test_done_tasks_may_overlap(self):
        self.assertEqual(validate_queue.validate({"tasks": [task("TASK-0001"), task("TASK-0002", status="done")]}), [])


class Migrate(unittest.TestCase):
    def test_upgrades_and_reruns_cleanly(self):
        old = {"id": "TASK-0105", "project": "GAME-004", "title": "T", "status": "proposed", "risk": "low", "depends_on": [],
               "branch": "b", "note": "n.md", "acceptance_criteria": ["x"], "history": [{"to": "proposed"}],
               "audits": [{"report": "06 QA/AUD.md"}]}
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "tasks").mkdir()
            (root / "n.md").write_text("---\nid: TASK-0105\nstatus: proposed\n---\n")
            q = root / "tasks" / "queue.json"
            q.write_text(json.dumps({"version": 1, "tasks": [old]}))
            migrate_queue.main(["--root", tmp])
            first = q.read_text()
            migrate_queue.main(["--root", tmp])
            self.assertEqual(q.read_text(), first)
            t = json.loads(first)["tasks"][0]
            self.assertEqual((t["game"], t["status"], t["note_path"], t["acceptance"]), ("GAME-004", "backlog", "n.md", ["x"]))
            self.assertEqual(t["evidence"], ["06 QA/AUD.md"])
            self.assertEqual(t["history"], [{"to": "proposed"}])
            self.assertIn("status: backlog", (root / "n.md").read_text())


if __name__ == "__main__":
    unittest.main()
