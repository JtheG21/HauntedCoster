"""One file per task: scripts/task_store.py, the migration script, validate_queue's file checks and next-id."""

import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPTS = Path(__file__).resolve().parents[1] / "scripts"
sys.path.insert(0, str(SCRIPTS))

import orchestrator  # noqa: E402
import task_store  # noqa: E402
import validate_queue  # noqa: E402


def task(tid="TASK-0001", status="done"):
    return {"id": tid, "game": "GAME-004", "title": "T", "status": status, "tier": "light", "owner_agent": "codex",
            "files_owned": [], "depends_on": [], "branch": "chore/x", "acceptance": ["works"], "evidence": [],
            "notes": "", "note_path": "n.md", "risk": "low"}


class Base(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        (self.root / "tasks").mkdir()

    def queue(self, *tasks):
        (self.root / "tasks" / "queue.json").write_text(json.dumps({"version": 2, "tasks": list(tasks)}))

    def migrate(self, *args):
        return subprocess.run([sys.executable, str(SCRIPTS / "migrate-queue-to-items.py"), "--root", str(self.root), *args],
                              capture_output=True, text=True)

    def item(self, tid):
        return self.root / "tasks" / "items" / f"{tid}.json"


class Store(Base):
    def test_save_only_writes_changes(self):
        t = task()
        self.assertTrue(task_store.save_task(self.root, t))
        self.assertFalse(task_store.save_task(self.root, t))
        t["status"] = "archived"
        self.assertTrue(task_store.save_task(self.root, t))
        self.assertEqual(task_store.load_tasks(self.root), [t])

    def test_bad_file_is_named(self):
        task_store.save_task(self.root, task())
        self.item("TASK-0002").write_text("{nope")
        items, errors = task_store.read_items(self.root)
        self.assertEqual(len(items), 1)
        self.assertIn("TASK-0002.json", errors[0])
        with self.assertRaises(task_store.TaskStoreError):
            task_store.load_tasks(self.root)


class Migration(Base):
    def test_moves_every_task_and_reruns_cleanly(self):
        self.queue(task("TASK-0001"), task("TASK-0002"))
        r = self.migrate()
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertFalse((self.root / "tasks" / "queue.json").exists())
        self.assertEqual(json.loads(self.item("TASK-0002").read_text()), task("TASK-0002"))
        self.assertEqual(self.migrate().returncode, 0)

    def test_upgrades_old_format_and_mirrors_note(self):
        (self.root / "n.md").write_text("---\nid: TASK-0105\nstatus: proposed\n---\n")
        self.queue({"id": "TASK-0105", "project": "GAME-004", "title": "T", "status": "proposed", "risk": "low",
                    "depends_on": [], "branch": "b", "note": "n.md", "acceptance_criteria": ["x"]})
        self.assertEqual(self.migrate().returncode, 0)
        t = json.loads(self.item("TASK-0105").read_text())
        self.assertEqual((t["game"], t["status"], t["note_path"]), ("GAME-004", "backlog", "n.md"))
        self.assertIn("status: backlog", (self.root / "n.md").read_text())

    def test_stops_on_a_difference_and_writes_nothing(self):
        task_store.save_task(self.root, task("TASK-0001", "done"))
        self.queue(task("TASK-0001", "approved"), task("TASK-0002"))
        r = self.migrate()
        self.assertEqual(r.returncode, 1)
        self.assertIn("TASK-0001", r.stderr)
        self.assertFalse(self.item("TASK-0002").exists())
        self.assertTrue((self.root / "tasks" / "queue.json").exists())

    def test_keep_existing(self):
        task_store.save_task(self.root, task("TASK-0001", "done"))
        self.queue(task("TASK-0001", "approved"), task("TASK-0002"))
        self.assertEqual(self.migrate("--keep-existing").returncode, 0)
        self.assertEqual(json.loads(self.item("TASK-0001").read_text())["status"], "done")
        self.assertTrue(self.item("TASK-0002").exists())

    def test_conflict_markers_stop_it(self):
        (self.root / "tasks" / "queue.json").write_text('<<<<<<< HEAD\n{}\n')
        self.assertEqual(self.migrate().returncode, 1)
        self.assertTrue((self.root / "tasks" / "queue.json").exists())


class Validator(Base):
    def run_main(self):
        return validate_queue.main(["--root", str(self.root)])

    def test_good(self):
        task_store.save_task(self.root, task())
        self.assertEqual(self.run_main(), 0)

    def test_no_files_fails(self):
        self.assertEqual(self.run_main(), 1)

    def test_file_name_must_equal_id(self):
        task_store.items_dir(self.root).mkdir()
        self.item("TASK-0009").write_text(json.dumps(task("TASK-0001")))
        self.assertEqual(self.run_main(), 1)

    def test_same_id_in_two_files_fails(self):
        task_store.save_task(self.root, task())
        self.item("TASK-0002").write_text(json.dumps(task("TASK-0001")))
        self.assertEqual(self.run_main(), 1)

    def test_leftover_queue_fails(self):
        task_store.save_task(self.root, task())
        self.queue()
        self.assertEqual(self.run_main(), 1)


class NextId(Base):
    def test_sees_other_branches(self):
        git = ["git", "-C", str(self.root), "-c", "user.name=t", "-c", "user.email=t@t"]
        subprocess.run(git + ["init", "-q", "-b", "main"], check=True)
        task_store.save_task(self.root, task("TASK-0001"))
        subprocess.run(git + ["add", "-A"], check=True)
        subprocess.run(git + ["commit", "-qm", "a"], check=True)
        subprocess.run(git + ["switch", "-qc", "new-format"], check=True)
        task_store.save_task(self.root, task("TASK-0005"))
        subprocess.run(git + ["add", "-A"], check=True)
        subprocess.run(git + ["commit", "-qm", "b"], check=True)
        subprocess.run(git + ["switch", "-q", "main"], check=True)
        subprocess.run(git + ["switch", "-qc", "old-format"], check=True)
        self.queue(task("TASK-0007"))
        subprocess.run(git + ["add", "-A"], check=True)
        subprocess.run(git + ["commit", "-qm", "c"], check=True)
        subprocess.run(git + ["switch", "-q", "main"], check=True)
        (self.root / "00 Studio").mkdir()
        self.assertEqual(orchestrator.Project(self.root).next_id(), "TASK-0008")


if __name__ == "__main__":
    unittest.main()
