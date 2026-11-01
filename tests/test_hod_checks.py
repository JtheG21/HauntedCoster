"""Fault injection into isolated HOD copies; never edits the user's source or Studio."""
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class HodGateTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        for folder in ('games/hike-or-die', 'scripts', '.agents/skills/roblox-map/scripts',
                       '.agents/skills/roblox-map/profiles'):
            if folder == 'scripts':
                (self.root / folder).mkdir()
                for name in ('check-hod.sh', 'check_hod_map.py'):
                    shutil.copy(ROOT / folder / name, self.root / folder / name)
            else:
                shutil.copytree(ROOT / folder, self.root / folder)
        for name in ('hike-or-die.project.json', 'stylua.toml', 'selene.toml', 'rokit.toml'):
            shutil.copy(ROOT / name, self.root / name)

    def gate(self):
        return subprocess.run(['bash', 'scripts/check-hod.sh'], cwd=self.root,
                              capture_output=True, text=True)

    def test_clean_gate(self):
        result = self.gate()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('6 passed, 0 failed', result.stdout)
        self.assertIn('generated source reproducibility', result.stdout)

    def test_injected_faults_fail_gate(self):
        # Each independent sabotage gets restored in the temporary copy only.
        faults = [
            ('format', 'games/hike-or-die/src/shared/Net.luau', lambda s: s.replace('return table.freeze({', 'return  table.freeze( {'), 'Diff in'),
            ('lint', 'games/hike-or-die/src/shared/Net.luau', lambda s: s.replace('--!strict', '--!strict\nmissingHodGlobal()'), 'undefined_variable'),
            ('spec', 'games/hike-or-die/tests/lune/evidence-rules.spec.luau', lambda s: s.replace('return passed', 'error("injected spec failure")\nreturn passed'), 'injected spec failure'),
            ('build', 'hike-or-die.project.json', lambda s: s.replace('games/hike-or-die/src/server', 'games/hike-or-die/missing'), 'Rojo'),
            ('map', 'games/hike-or-die/map/hike-trail.json', lambda s: s.replace('"roles": [', '"invalid_roles": ['), 'role'),
            ('json', 'games/hike-or-die/map/profile.json', lambda s: '{invalid', 'JSONDecodeError'),
            ('drift', 'games/hike-or-die/src/server/World/TrailMapGenerated.luau', lambda s: s.replace('local ws =', '-- injected drift\nlocal ws ='), 'differs from JSON'),
        ]
        for name, relative, mutate, diagnostic in faults:
            with self.subTest(name=name):
                path = self.root / relative
                original = path.read_text()
                try:
                    path.write_text(mutate(original))
                    result = self.gate()
                    self.assertNotEqual(result.returncode, 0, name)
                    self.assertIn(diagnostic, result.stdout + result.stderr)
                finally:
                    path.write_text(original)


if __name__ == '__main__':
    unittest.main()
