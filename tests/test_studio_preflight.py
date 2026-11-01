"""Offline rejection tests. No test connects to or changes Studio/Rojo."""
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location('studio_preflight', ROOT / 'scripts/studio_preflight.py')
pf = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(pf)


class StudioPreflightTests(unittest.TestCase):
    def test_every_game_project_checkout_pairing(self):
        for game, (project, _) in pf.GAMES.items():
            good = {'cwd': str(ROOT), 'args': [project]}
            pf.validate_servers(ROOT, project, [good])
            for bad in ([], [good, good], [{'cwd': '', 'args': [project]}],
                        [{'cwd': '/tmp', 'args': [project]}]):
                with self.subTest(game=game, bad=bad), self.assertRaises(ValueError):
                    pf.validate_servers(ROOT, project, bad)
            for other, _ in pf.GAMES.values():
                if other != project:
                    with self.assertRaises(ValueError):
                        pf.validate_servers(ROOT, project, [{'cwd': str(ROOT), 'args': [other]}])
        # Implicit Rojo project is GAME-001 only; absolute foreign project also fails.
        pf.validate_servers(ROOT, 'default.project.json', [{'cwd': str(ROOT), 'args': []}])
        with self.assertRaises(ValueError):
            pf.validate_servers(ROOT, 'hike-or-die.project.json', [{'cwd': str(ROOT), 'args': []}])
        with self.assertRaises(ValueError):
            pf.validate_servers(ROOT, 'hike-or-die.project.json', [{'cwd': str(ROOT), 'args': ['/tmp/hike-or-die.project.json']}])

    def test_stamp_cannot_mask_missing_empty_or_stale_source(self):
        expected = {'ReplicatedStorage/Shared/Rules': 'return 123', 'ServerScriptService/Server/Main': 'print(1)'}
        good = {'name': 'HikeOrDieGate1', 'edit': True, 'sources': expected}
        pf.validate_snapshot(good, expected, 'HikeOrDieGate1')
        for change in ({'name': 'HauntedCollector'}, {'edit': False}, {'sources': {}},
                       {'sources': {**expected, 'extra': ''}},
                       {'sources': {**expected, 'ReplicatedStorage/Shared/Rules': ''}},
                       {'sources': {**expected, 'ReplicatedStorage/Shared/Rules': 'return 122'}}):
            with self.subTest(change=change), self.assertRaises(ValueError):
                pf.validate_snapshot({**good, 'stamp': 'current', **change}, expected, 'HikeOrDieGate1')

    def test_rojo_resolved_inventory_includes_client_and_generated_module(self):
        source = pf.sources(ROOT, 'hike-or-die.project.json')
        self.assertIn('ServerScriptService/Server/World/TrailMapGenerated', source)
        self.assertIn('StarterPlayer/StarterPlayerScripts/Client/CameraClient', source)
        self.assertEqual(len(source), 12)
        query = pf.probe(source)
        self.assertIn('node.Source', query)
        self.assertNotIn('require(', query)
        self.assertNotIn('Instance.new', query)

    def test_cli_requires_evidence_and_exact_place(self):
        with tempfile.TemporaryDirectory() as tmp:
            place = Path(tmp) / 'HikeOrDieGate1.rbxl'
            place.touch()
            expected = {'ReplicatedStorage/Shared/Module': 'return true'}
            snapshot = Path(tmp) / 'snapshot.json'
            snapshot.write_text(json.dumps({'name': 'HikeOrDieGate1', 'edit': True, 'sources': expected}))
            server = [{'cwd': str(ROOT), 'args': ['hike-or-die.project.json']}]
            args = ['--root', str(ROOT), '--game', 'GAME-003', '--place', str(place), '--snapshot', str(snapshot)]
            with patch.object(pf, 'sources', return_value=expected), patch.object(pf, 'inspect_processes', return_value=(server, [f'/Applications/RobloxStudio.app/Contents/MacOS/RobloxStudio -protocolString file://{place}'])):
                self.assertEqual(pf.main(args), 0)
                self.assertEqual(pf.main(args + ['--project', 'haunted.project.json']), 1)
                for studios in ([], ['unknown'], ['one', 'two'], ['/Applications/RobloxStudio.app/Contents/MacOS/RobloxStudio -protocolString file:///tmp/HauntedCollector.rbxl']):
                    with patch.object(pf, 'inspect_processes', return_value=(server, studios)):
                        self.assertEqual(pf.main(args), 1)
                self.assertEqual(pf.main(['--root', str(ROOT)]), 1)


if __name__ == '__main__':
    unittest.main()
