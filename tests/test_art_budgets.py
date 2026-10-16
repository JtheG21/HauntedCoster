"""Triangle budgets for GAME-002 art (SYS-Haunted-Art-Direction, "Budgets").

Reads the Tris / TrisLod1 attributes the art build writes into games/haunted/assets/ArtData/*.model.json and
fails when an asset is over its class budget. Asset kinds without a budget row (tree, rock, part) are not checked.
KNOWN_OVER lists overages that existed when the test was added: they are reported, not failed, and each needs a
decision (cut it, or raise the budget in the SYS note). Remove an entry once it is fixed; never add one silently.
"""

import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ART = ROOT / "games" / "haunted" / "assets" / "ArtData"

# Kind attribute -> (LOD0, LOD1) from the SYS note's budget table.
BUDGETS = {
    "creature": (8500, 6000),
    "prop": (3200, 1100),  # "repeated prop" row; one-off props are listed in KNOWN_OVER until a row exists for them
    "landmark": (12000, 4000),
    "house": (16000, 5000),  # "mansion tier"
    "vehicle": (6000, 2000),  # "cart / station"
}

# asset -> reason. Pre-existing on 2026-10-16 (chore/art-automation); jg to decide.
KNOWN_OVER = {
    "house_t2": "LOD1 5512 > 5000",
    "pen_cage": "LOD0 3484 > 3200, LOD1 1752 > 1100",
    "pumpkin": "LOD0 3828 > 3200, LOD1 1308 > 1100",
    "pumpkin_lit": "LOD0 3828 > 3200, LOD1 1308 > 1100",
    "ruin_wall": "LOD0 3672 > 3200",
    "scare_arch": "LOD0 4284 > 3200, LOD1 1372 > 1100",
    "settle_wall": "LOD0 4916 > 3200, LOD1 1550 > 1100",
    "train_station": "LOD0 3416 > 3200, LOD1 1346 > 1100",
}


def assets():
    for f in sorted(ART.glob("*.model.json")):
        a = json.loads(f.read_text())["attributes"]
        yield a.get("Asset", f.stem), a.get("Kind"), a.get("Tris"), a.get("TrisLod1")


def over_budget():
    out = []
    for name, kind, tris, lod1 in assets():
        if kind not in BUDGETS or tris is None:
            continue
        b0, b1 = BUDGETS[kind]
        problems = []
        if tris > b0:
            problems.append(f"LOD0 {tris} > {b0}")
        if lod1 is not None and lod1 > b1:
            problems.append(f"LOD1 {lod1} > {b1}")
        if problems:
            out.append((name, kind, ", ".join(problems)))
    return out


@unittest.skipUnless(ART.is_dir(), "no ArtData in this checkout")
class ArtBudgets(unittest.TestCase):
    def test_no_new_overages(self):
        new = [f"{n} ({k}): {p}" for n, k, p in over_budget() if n not in KNOWN_OVER]
        self.assertEqual(new, [], "over the SYS-Haunted-Art-Direction triangle budget:\n" + "\n".join(new))

    def test_known_overages_still_over(self):
        # A fixed asset must leave KNOWN_OVER, so the list never hides a later regression.
        still = {n for n, _, _ in over_budget()}
        fixed = sorted(n for n in KNOWN_OVER if n not in still and (ART / f"{n}.model.json").exists())
        self.assertEqual(fixed, [], "now within budget; remove from KNOWN_OVER: " + ", ".join(fixed))


if __name__ == "__main__":
    unittest.main()
