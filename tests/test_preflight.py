"""Tests for scripts/preflight.sh. Run: python3 -m unittest discover tests"""

import subprocess
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).resolve().parent.parent / "scripts" / "preflight.sh"


def git(cwd, *args):
    subprocess.run(["git", "-C", str(cwd), *args], check=True, capture_output=True)


class TestPreflight(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.repo = Path(self.tmp.name) / "repo"
        self.repo.mkdir()
        git(self.repo, "init", "-q", "-b", "main")
        git(self.repo, "config", "user.email", "t@example.com")
        git(self.repo, "config", "user.name", "t")
        (self.repo / "a.txt").write_text("a")
        git(self.repo, "add", "a.txt")
        git(self.repo, "commit", "-q", "-m", "init")

    def tearDown(self):
        self.tmp.cleanup()

    def run_pf(self, *args, cwd=None):
        return subprocess.run(["bash", str(SCRIPT), *args], capture_output=True, text=True,
                              cwd=cwd or self.tmp.name)

    def test_ok_on_expected_root_and_branch(self):
        r = self.run_pf("--root", str(self.repo), "--branch", "main", "--clean")
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertIn("preflight: OK", r.stdout)

    def test_missing_checkout_fails_without_fallback(self):
        # The original incident: the worktree was cleaned up and the merge ran elsewhere.
        r = self.run_pf("--root", str(Path(self.tmp.name) / "gone"), "--branch", "main", cwd=self.repo)
        self.assertEqual(r.returncode, 1)
        self.assertIn("does not exist", r.stderr)

    def test_wrong_branch_fails(self):
        git(self.repo, "switch", "-q", "-c", "task/x")
        r = self.run_pf("--root", str(self.repo), "--branch", "main")
        self.assertEqual(r.returncode, 1)
        self.assertIn("expected 'main'", r.stderr)

    def test_subfolder_is_not_a_checkout(self):
        sub = self.repo / "sub"
        sub.mkdir()
        r = self.run_pf("--root", str(sub), "--branch", "main")
        self.assertEqual(r.returncode, 1)
        self.assertIn("not a checkout itself", r.stderr)

    def test_not_a_repo_fails(self):
        plain = Path(self.tmp.name) / "plain"
        plain.mkdir()
        r = self.run_pf("--root", str(plain))
        self.assertEqual(r.returncode, 1)

    def test_dirty_fails_with_clean_but_allowed_paths_are_ignored(self):
        (self.repo / "a.txt").write_text("changed")
        (self.repo / "Untitled.canvas").write_text("user scratch")
        r = self.run_pf("--root", str(self.repo), "--clean", "--allow", "Untitled.canvas")
        self.assertEqual(r.returncode, 1)
        self.assertIn("a.txt", r.stderr)
        git(self.repo, "checkout", "-q", "--", "a.txt")
        r = self.run_pf("--root", str(self.repo), "--clean", "--allow", "Untitled.canvas")
        self.assertEqual(r.returncode, 0, r.stderr)

    def test_root_is_required(self):
        r = self.run_pf("--branch", "main", cwd=self.repo)
        self.assertEqual(r.returncode, 2)

    def test_worktree_is_its_own_checkout(self):
        wt = Path(self.tmp.name) / "wt"
        git(self.repo, "worktree", "add", "-q", "-b", "chore/y", str(wt))
        self.assertEqual(self.run_pf("--root", str(wt), "--branch", "chore/y").returncode, 0)
        self.assertEqual(self.run_pf("--root", str(wt), "--branch", "main").returncode, 1)


if __name__ == "__main__":
    unittest.main()
