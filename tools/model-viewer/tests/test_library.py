import importlib.util
import json
import pathlib
import tempfile
import struct
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('viewer_library', ROOT / 'scripts/library.py')
library = importlib.util.module_from_spec(spec)
spec.loader.exec_module(library)

class LibraryTests(unittest.TestCase):
    def test_add_validate_preserve_original_and_refuse_overwrite(self):
        source = ROOT / 'tests/fixtures/animated.glb'
        before = source.read_bytes()
        with tempfile.TemporaryDirectory() as temp:
            directory = pathlib.Path(temp)
            destination = library.add(source, 'fixture', library=directory)
            self.assertEqual((destination / 'model.glb').read_bytes(), before)
            self.assertEqual(library.rebuild(directory, True)[0]['model'], 'library/fixture/model.glb')
            with self.assertRaises(ValueError):
                library.add(source, 'fixture', library=directory)
            self.assertEqual(source.read_bytes(), before)
            (destination / 'model.glb').write_bytes(b'broken')
            with self.assertRaises(ValueError):
                library.rebuild(directory)
            self.assertEqual(len(json.loads((directory / 'index.json').read_text())), 1)

    def test_bad_glb_and_path_fail_without_creating_package(self):
        with tempfile.TemporaryDirectory() as temp:
            directory = pathlib.Path(temp)
            source = directory / 'bad.glb'
            source.write_bytes(b'broken')
            with self.assertRaises(ValueError):
                library.add(source, 'bad', library=directory / 'library')
            with self.assertRaises(ValueError):
                library.add(ROOT / 'tests/fixtures/animated.glb', '../outside', library=directory / 'library')
            self.assertFalse((directory / 'library').exists())

    def test_scene_validation_rejects_corrupt_settings(self):
        for patch in [{'speed': 0}, {'camera': [float('nan'), 1, 2]},
                      {'effect': 'arbitrary'}, {'grid': 'false'}, {'unexpected': 1},
                      {'model': '../../outside.glb'}, {'mappings': {'Idle': 'x'}}]:
            with self.subTest(patch=patch), self.assertRaises(ValueError):
                library.validate_scene({'version': 1, **patch})
        library.validate_scene({'version': 1, 'model': 'library/test/model.glb', 'speed': 1})

    def test_malformed_metadata_is_a_clear_validation_error(self):
        for patch in [{'asset': []}, {'buffers': [None]}, {'images': 'bad'},
                      {'extensionsRequired': [None]}, {'animations': [None]},
                      {'meshes': 'bad'}, {'buffers': [{'uri': 3}]}]:
            with self.subTest(patch=patch), tempfile.TemporaryDirectory() as temp:
                document = {'asset': {'version': '2.0'}, 'meshes': [{}], **patch}
                payload = json.dumps(document).encode()
                payload += b' ' * (-len(payload) % 4)
                path = pathlib.Path(temp) / 'bad.glb'
                path.write_bytes(struct.pack('<IIIII', 0x46546c67, 2, 20 + len(payload), len(payload), 0x4e4f534a) + payload)
                with self.assertRaises(ValueError):
                    library.inspect_glb(path)

    def test_hash_and_scene_mismatch_fail_closed(self):
        with tempfile.TemporaryDirectory() as temp:
            directory = pathlib.Path(temp)
            folder = library.add(ROOT / 'tests/fixtures/animated.glb', 'test', library=directory)
            scene = folder / 'scene.json'
            scene.write_text('{"version":1,"model":"library/other/model.glb"}')
            with self.assertRaises(ValueError):
                library.rebuild(directory, True)

if __name__ == '__main__':
    unittest.main()
