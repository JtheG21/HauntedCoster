"""Include the local viewer's stdlib package and path checks in the vault suite."""
import pathlib
import unittest


def load_tests(loader, tests, pattern):
    directory = pathlib.Path(__file__).resolve().parents[1] / 'tools/model-viewer/tests'
    return unittest.TestLoader().discover(str(directory), pattern='test_*.py', top_level_dir=str(directory))
