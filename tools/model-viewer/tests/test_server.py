import importlib.util
import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('viewer_server', ROOT / 'serve.py')
server = importlib.util.module_from_spec(spec)
spec.loader.exec_module(server)

class ServerTests(unittest.TestCase):
    def test_paths_cannot_escape_viewer_or_serve_internal_files(self):
        handler = object.__new__(server.Handler)
        for path in ['/../../AGENTS.md', '/%2e%2e/AGENTS.md', '/.hidden-test', '/scripts/library.py', '/library/.hidden', '/src/../../private-file', '/library/..%5c..%5cprivate-file']:
            self.assertEqual(handler.translate_path(path), str(ROOT / '__not_served__'), path)
        self.assertEqual(handler.translate_path('/'), str(ROOT / 'index.html'))
        self.assertEqual(handler.translate_path('/src/state.js'), str(ROOT / 'src/state.js'))
        self.assertEqual(handler.translate_path('/library/model/model.glb?x=1'), str(ROOT / 'library/model/model.glb'))

if __name__ == '__main__':
    unittest.main()
