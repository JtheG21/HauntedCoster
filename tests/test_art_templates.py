"""The art templates and asset modules call only functions that exist in the shared hcart modules.

Blender's bpy isn't available here, so this reads the code (AST) instead of importing it: every
`sourced.X` / `surface.X` used in art/templates/*.py and art/assets/*.py must be defined in that module.
"""

import ast
import unittest
from pathlib import Path

ART = Path(__file__).resolve().parent.parent / "games" / "haunted" / "art"
MODULES = ("sourced", "surface")


def defined(name: str) -> set[str]:
    tree = ast.parse((ART / "hcart" / f"{name}.py").read_text())
    out = set()
    for node in tree.body:
        if isinstance(node, (ast.FunctionDef, ast.ClassDef)):
            out.add(node.name)
        elif isinstance(node, ast.Assign):
            out |= {t.id for t in node.targets if isinstance(t, ast.Name)}
        elif isinstance(node, (ast.Import, ast.ImportFrom)):
            out |= {(a.asname or a.name).split(".")[0] for a in node.names}
    return out


@unittest.skipUnless((ART / "hcart" / "sourced.py").exists(), "no art pipeline in this checkout")
class ArtTemplates(unittest.TestCase):
    def test_shared_calls_exist(self):
        have = {m: defined(m) for m in MODULES}
        missing = []
        for f in sorted(list((ART / "templates").glob("*.py")) + list((ART / "assets").glob("*.py"))):
            for node in ast.walk(ast.parse(f.read_text())):
                if isinstance(node, ast.Attribute) and isinstance(node.value, ast.Name) and node.value.id in MODULES:
                    if node.attr not in have[node.value.id]:
                        missing.append(f"{f.relative_to(ART)}: {node.value.id}.{node.attr}")
        self.assertEqual(missing, [], "\n".join(missing))

    def test_template_is_not_registered(self):
        # Templates live outside art/assets/, so build.py never registers their placeholder names.
        self.assertFalse((ART / "assets" / "sourced_creature.py").exists())
        self.assertIn("creature_TODO", (ART / "templates" / "sourced_creature.py").read_text())


if __name__ == "__main__":
    unittest.main()
