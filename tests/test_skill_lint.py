"""Tests for scripts/skill_lint.py. Run: python3 -m unittest discover -s tests"""

import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "scripts"))
import skill_lint  # noqa: E402

GOOD = "---\nname: demo\ndescription: Does a thing. Use when jg asks for the thing.\n---\n# Demo\nRun `scripts/x.py`.\n"


class SkillLintTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.write(".claude/skills/demo/SKILL.md", GOOD)
        self.write(".agents/skills/demo/SKILL.md", GOOD)
        self.write("scripts/x.py", "")

    def tearDown(self):
        self.tmp.cleanup()

    def write(self, rel, text):
        p = self.root / rel
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(text)

    def result(self):
        e, w = skill_lint.lint(self.root)
        return "\n".join(e), "\n".join(w)

    def test_clean(self):
        self.assertEqual(self.result(), ("", ""))

    def test_frontmatter_problems(self):
        bad = GOOD.replace("name: demo", "name: other")
        self.write(".claude/skills/demo/SKILL.md", bad)
        self.write(".agents/skills/demo/SKILL.md", bad)
        self.assertIn("does not match the folder", self.result()[0])
        nodesc = "---\nname: demo\n---\nx\n"
        self.write(".claude/skills/demo/SKILL.md", nodesc)
        self.write(".agents/skills/demo/SKILL.md", nodesc)
        self.assertIn("missing description", self.result()[0])

    def test_description_without_trigger_warns(self):
        text = GOOD.replace(" Use when jg asks for the thing.", "")
        self.write(".claude/skills/demo/SKILL.md", text)
        self.write(".agents/skills/demo/SKILL.md", text)
        self.assertIn("does not say when to use", self.result()[1])

    def test_long_description_and_oversize(self):
        text = GOOD.replace("Does a thing.", "x" * 1100)
        self.write(".claude/skills/demo/SKILL.md", text)
        self.write(".agents/skills/demo/SKILL.md", text)
        self.assertIn("1024", self.result()[0])
        big = GOOD + "line\n" * 420
        self.write(".claude/skills/demo/SKILL.md", big)
        self.write(".agents/skills/demo/SKILL.md", big)
        self.assertIn("lines (max 400)", self.result()[0])

    def test_dead_paths(self):
        text = GOOD + "See `scripts/gone.py` and `games/g/out.rbxm`.\n"
        self.write(".claude/skills/demo/SKILL.md", text)
        self.write(".agents/skills/demo/SKILL.md", text)
        errors, warnings = self.result()
        self.assertIn("scripts/gone.py", errors)
        self.assertIn("games/g/out.rbxm", warnings)
        self.assertNotIn("games/g/out.rbxm", errors)

    def test_codex_copy(self):
        self.write(".agents/skills/demo/SKILL.md", GOOD + "extra\n")
        self.assertIn("differs", self.result()[0])
        (self.root / ".agents/skills/demo/SKILL.md").unlink()
        self.assertIn("no Codex copy", self.result()[0])

    def test_third_party_skipped(self):
        self.write(".claude/skills/PROVENANCE.md", "| `vendor` | url | abc | none |\n")
        self.write(".claude/skills/vendor/SKILL.md", "no frontmatter at all")
        self.assertEqual(self.result(), ("", ""))


if __name__ == "__main__":
    unittest.main()
