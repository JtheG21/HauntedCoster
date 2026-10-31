"""Handoff templates, PARALLEL.md and intake keep their required sections."""

import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SECTIONS = ("## Goal", "## In scope", "## Out of scope", "## Files expected to change", "## Owned files",
            "## Acceptance criteria and evidence", "## Tier", "## Test steps", "## Approval gates", "## Remote-change triple")


class Templates(unittest.TestCase):
    def test_every_template_has_every_section(self):
        for name in ("claude-code", "codex", "claude-design", "task-audit"):
            text = (ROOT / "docs" / "workflow" / "templates" / f"{name}.md").read_text()
            for section in SECTIONS:
                with self.subTest(template=name, section=section):
                    self.assertIn(section, text)

    def test_design_template_covers_exports(self):
        text = (ROOT / "docs" / "workflow" / "templates" / "claude-design.md").read_text()
        for needle in ("Export formats", ".rbxmx", "MeshId", "TextureID", "games/mathshow/assets/"):
            self.assertIn(needle, text)


class Parallel(unittest.TestCase):
    def test_rules(self):
        text = (ROOT / "docs" / "workflow" / "PARALLEL.md").read_text()
        for needle in ("Disjoint `files_owned`", "Shared contracts land first", "Others consume"):
            self.assertIn(needle, text)


class Intake(unittest.TestCase):
    def test_readme(self):
        text = (ROOT / "intake" / "README.md").read_text()
        for needle in ("Triage table", "Licence", "Secrets", "Dependencies", "Queue task", 'Definition of "triaged"'):
            self.assertIn(needle, text)
        self.assertTrue((ROOT / "intake" / "inbox" / ".gitkeep").exists())


if __name__ == "__main__":
    unittest.main()
