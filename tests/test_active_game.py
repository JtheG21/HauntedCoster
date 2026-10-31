"""scripts/active-game.env is the one source for the active game: the files that can't read it must agree with it."""

import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class ActiveGame(unittest.TestCase):
    def setUp(self):
        lines = (ROOT / "scripts" / "active-game.env").read_text().splitlines()
        self.env = dict(line.split("=", 1) for line in lines if "=" in line and not line.startswith("#"))

    def test_paths_exist(self):
        self.assertTrue((ROOT / self.env["ACTIVE_GAME_ROOT"] / "src").is_dir())
        self.assertTrue((ROOT / self.env["ACTIVE_GAME_PROJECT"]).is_file())

    def test_project_name_matches(self):
        project = json.loads((ROOT / self.env["ACTIVE_GAME_PROJECT"]).read_text())
        self.assertEqual(project["name"], self.env["ACTIVE_GAME_NAME"])

    def test_vscode_agrees_and_project_state_holds_only_fixed_facts(self):
        vscode = json.loads((ROOT / ".vscode" / "settings.json").read_text())
        self.assertEqual(vscode["luau-lsp.sourcemap.rojoProjectFile"], self.env["ACTIVE_GAME_PROJECT"])
        state = json.loads((ROOT / "project-state.json").read_text())
        self.assertEqual(sorted(state), ["conventions", "phase", "project"])


if __name__ == "__main__":
    unittest.main()
