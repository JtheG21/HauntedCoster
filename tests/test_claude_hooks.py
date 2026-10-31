"""Tests for the Claude Code hooks in .claude/hooks/, the Codex skill copies and scripts/studio-preflight.sh.
Run: python3 -m unittest discover tests"""

import json
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
GUARD = ROOT / ".claude" / "hooks" / "guard.sh"
FORMAT = ROOT / ".claude" / "hooks" / "luau-format.sh"
STUDIO = ROOT / "scripts" / "studio-preflight.sh"
REFLINT = ROOT / ".claude" / "hooks" / "ref-lint.sh"


def run_hook(script, tool, **tool_input):
    payload = json.dumps({"tool_name": tool, "tool_input": tool_input})
    return subprocess.run(["bash", str(script)], input=payload, capture_output=True, text=True)


def decision(result):
    """block, ask or allow, as Claude Code reads a PreToolUse hook's result."""
    if result.returncode == 2:
        return "block"
    if result.stdout.strip():
        return json.loads(result.stdout)["hookSpecificOutput"]["permissionDecision"]
    return "allow"


def make_checkout(parent):
    repo = Path(parent) / "repo"
    repo.mkdir()
    subprocess.run(["git", "-C", str(repo), "init", "-q"], check=True)
    (repo / "scripts").mkdir(exist_ok=True)
    (repo / "scripts" / "active-game.env").write_text("")
    return repo


class TestGuardBash(unittest.TestCase):
    CASES = [
        ("block", 'git -C "/Users/jg/Desktop/Rg1" merge --no-ff task/x'),
        ("block", "cd x && git commit -m hi"),
        ("block", "git checkout -- file.luau"),
        ("block", "git branch -D old"),
        ("block", "git push origin chore/x"),
        ("allow", "scripts/preflight.sh --root . --branch main && git -C . push"),
        ("allow", "git log --grep merge"),
        ("allow", "git status && git diff main...task/x"),
        ("allow", "git branch --list"),
        ("block", "rojo serve"),
        ("block", "cd ../x && rojo serve --port 34872"),
        ("allow", "rojo serve mathshow.project.json"),
        ("allow", 'ps aux | grep "rojo serve"'),
        ("block", "cat .env"),
        ("block", "source /Users/jg/Desktop/Rg1/.env"),
        ("allow", "cat .env.example"),
        ("allow", 'scripts/preflight.sh --root . --branch b && git -C . commit -m "never read .env"'),
        ("ask", "gh pr merge 57 --repo JtheG21/HauntedCoster --merge"),
        ("allow", "gh pr view 57"),
        ("ask", "rojo upload --asset_id 1"),
    ]

    def test_commands(self):
        for expected, command in self.CASES:
            with self.subTest(command=command):
                self.assertEqual(decision(run_hook(GUARD, "Bash", command=command)), expected)

    def test_block_message_names_the_fix(self):
        r = run_hook(GUARD, "Bash", command="git commit -m x")
        self.assertIn("scripts/preflight.sh", r.stderr)


class TestGuardMainCheckout(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.main = Path(self.tmp.name) / "main"
        self.main.mkdir()
        for args in (["init", "-q", "-b", "main"], ["config", "user.email", "t@example.com"], ["config", "user.name", "t"],
                     ["commit", "-q", "--allow-empty", "-m", "init"], ["branch", "task/x"]):
            subprocess.run(["git", "-C", str(self.main), *args], check=True, capture_output=True)
        self.wt = Path(self.tmp.name) / "wt"
        subprocess.run(["git", "-C", str(self.main), "worktree", "add", "-q", str(self.wt), "task/x"], check=True,
                       capture_output=True)

    def tearDown(self):
        self.tmp.cleanup()

    def guard(self, command):
        pf = "scripts/preflight.sh --root x --branch y && "
        return decision(run_hook(GUARD, "Bash", command=pf + command))

    def test_main_checkout_stays_on_main(self):
        self.assertEqual(self.guard(f"git -C {self.main} switch task/x"), "block")
        self.assertEqual(self.guard(f"git -C {self.main} switch -c chore/new"), "block")
        self.assertEqual(self.guard(f"git -C {self.main} switch main"), "allow")

    def test_worktrees_may_switch(self):
        self.assertEqual(self.guard(f"git -C {self.wt} switch -c chore/other"), "allow")


class TestGuardPaths(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.repo = make_checkout(self.tmp.name)

    def tearDown(self):
        self.tmp.cleanup()

    def check(self, expected, tool, rel):
        r = run_hook(GUARD, tool, file_path=str(self.repo / rel))
        self.assertEqual(decision(r), expected, f"{tool} {rel}: {r.stderr}")

    def test_credentials(self):
        self.check("block", "Read", ".env")
        self.check("block", "Read", ".env.local")
        self.check("allow", "Read", ".env.example")

    def test_do_not_edit_folders(self):
        self.check("allow", "Read", "Agents/notes.md")
        self.check("block", "Edit", "Agents/notes.md")
        self.check("block", "Write", ".obsidian/app.json")
        self.check("block", "Write", "Chats/new/dir/x.md")  # folders that don't exist yet
        self.check("allow", "Edit", "04 Agents/Auditor.md")

    def test_references_ask(self):
        self.check("ask", "Edit", "10 References/01 UI/x.md")

    def test_older_checkout_without_the_env_file_stays_protected(self):
        (self.repo / "scripts" / "active-game.env").unlink()
        (self.repo / "AGENTS.md").write_text("")
        self.check("block", "Write", "Agents/x.md")

    def test_other_repos_are_left_alone(self):
        (self.repo / "scripts" / "active-game.env").unlink()
        self.check("allow", "Write", "Agents/x.md")


@unittest.skipUnless(shutil.which("jq"), "needs jq")
class TestRefLint(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.repo = make_checkout(self.tmp.name)
        (self.repo / "scripts").mkdir(exist_ok=True)
        shutil.copy(ROOT / "scripts" / "refs.py", self.repo / "scripts" / "refs.py")
        shutil.copy(ROOT / "scripts" / "validate_vault.py", self.repo / "scripts" / "validate_vault.py")
        self.note = self.repo / "10 References" / "01 UI" / "REF-UI-001-X.md"
        self.note.parent.mkdir(parents=True)

    def tearDown(self):
        self.tmp.cleanup()

    def test_reports_a_bad_note(self):
        self.note.write_text("---\nid: REF-UI-001\n---\n# x\n")
        r = run_hook(REFLINT, "Edit", file_path=str(self.note))
        self.assertEqual(r.returncode, 2)
        self.assertIn("missing 'title'", r.stderr)

    def test_ignores_other_files(self):
        other = self.repo / "notes.md"
        other.write_text("x")
        self.assertEqual(run_hook(REFLINT, "Edit", file_path=str(other)).returncode, 0)
        self.assertEqual(run_hook(REFLINT, "Edit", file_path=str(self.repo / "10 References" / "01 UI" / "gone.md")).returncode, 0)


@unittest.skipUnless(shutil.which("stylua") and shutil.which("selene") and shutil.which("jq"), "needs stylua, selene, jq")
class TestLuauFormat(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.repo = make_checkout(self.tmp.name)
        for name in ("stylua.toml", "selene.toml", "rokit.toml"):
            shutil.copy(ROOT / name, self.repo / name)

    def tearDown(self):
        self.tmp.cleanup()

    def write(self, rel, text):
        path = self.repo / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text)
        return path

    def test_formats_game_code(self):
        path = self.write("games/x/A.luau", "local  t = {1,2}\nif t then\n    return t\nend\nreturn nil\n")
        r = run_hook(FORMAT, "Edit", file_path=str(path))
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertEqual(path.read_text(), "local t = { 1, 2 }\nif t then\n\treturn t\nend\nreturn nil\n")

    def test_lint_problems_reach_claude(self):
        path = self.write("games/x/B.luau", "return undefinedGlobal\n")
        r = run_hook(FORMAT, "Write", file_path=str(path))
        self.assertEqual(r.returncode, 2)
        self.assertIn("undefined_variable", r.stderr)

    def test_files_outside_checked_roots_untouched(self):
        text = "local  y=1\nreturn y\n"
        path = self.write(".claude/skills/third-party/x.luau", text)
        r = run_hook(FORMAT, "Write", file_path=str(path))
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertEqual(path.read_text(), text)


class TestCodexSkillCopies(unittest.TestCase):
    def test_copies_match(self):
        # Codex reads .agents/skills/; Claude reads .claude/skills/. Edit one, copy it to the other.
        for name in ("task-close", "studio-preflight", "art-import", "codex-handoff", "reference-review", "reference-brief",
                     "roblox-map", "roblox-sfx"):
            with self.subTest(skill=name):
                claude = (ROOT / ".claude" / "skills" / name / "SKILL.md").read_text()
                codex = (ROOT / ".agents" / "skills" / name / "SKILL.md").read_text()
                self.assertEqual(codex, claude)


class TestStudioPreflightUsage(unittest.TestCase):
    def test_rejects_a_non_checkout(self):
        with tempfile.TemporaryDirectory() as d:
            r = subprocess.run(["bash", str(STUDIO), "--root", d], capture_output=True, text=True)
        self.assertEqual(r.returncode, 2)
        self.assertIn("not a MathShow checkout", r.stderr)

    def test_rejects_unknown_arguments(self):
        r = subprocess.run(["bash", str(STUDIO), "--bogus"], capture_output=True, text=True)
        self.assertEqual(r.returncode, 2)


if __name__ == "__main__":
    unittest.main()
