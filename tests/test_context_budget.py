"""Tests for scripts/context_budget.py: deterministic measurement on a temporary fixture."""

import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "scripts"))
import context_budget as cb  # noqa: E402

SHARED = "Every task branch gets its own worktree so parallel sessions never share a working tree."


class TestContextBudget(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        (self.root / "04 Agents").mkdir()
        (self.root / "CLAUDE.md").write_text("# Root\n\n" + SHARED + "\n")
        (self.root / "AGENTS.md").write_text("# Rules\n\n" + SHARED + "\nShort line.\n")
        (self.root / "04 Agents" / "Task Intake.md").write_text("# Intake\n\nNothing repeated here at all.\n")

    def tearDown(self):
        self.tmp.cleanup()

    def test_repeated_sentence_is_counted_once_across_files(self):
        texts = {"CLAUDE.md": (self.root / "CLAUDE.md").read_text(),
                 "AGENTS.md": (self.root / "AGENTS.md").read_text()}
        count, extra, examples = cb.duplicate_sentences(texts)
        self.assertEqual(count, 1)
        self.assertEqual(extra, len(SHARED.encode()))
        self.assertTrue(examples[0].startswith("every task branch"))

    def test_short_sentences_are_ignored(self):
        texts = {"a": "Short line.\n", "b": "Short line.\n"}
        self.assertEqual(cb.duplicate_sentences(texts)[0], 0)

    def test_report_marks_missing_files_and_labels_estimates(self):
        out = cb.report(self.root, "executor", None)
        self.assertIn("CLAUDE.md", out)
        self.assertIn("04 Agents/Executor.md", out)
        self.assertIn("missing", out)  # Executor.md and the skills folder are absent here
        self.assertIn("(est)", out)
        self.assertIn("repeated sentences: 1", out)
        self.assertIn("no task with a note found", out)

    def test_frontmatter_description(self):
        text = "---\nname: x\ndescription: Does a thing when asked.\n---\nBody"
        self.assertEqual(cb.frontmatter_description(text), "Does a thing when asked.")
        self.assertEqual(cb.frontmatter_description("no frontmatter"), "")


if __name__ == "__main__":
    unittest.main()
