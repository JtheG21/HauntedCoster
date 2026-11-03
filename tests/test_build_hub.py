"""Guards on the generated hub map (games/mathshow/map/Hub.rbxmx), run by scripts/check.sh with the other Python tests.

Pad trigger volumes (TASK-0127 audit F1): ModePadService polls a player's root position against each ModePad part with
ModePadRules.isInside (games/mathshow/src/shared/ModePadRules.luau): inside the yaw-rotated footprint of the pad's
Size.X by Size.Z, edges included, and from the pad's top surface up to ModePadConfig.VerticalTolerance studs above it
(games/mathshow/src/shared/ModePadConfig.luau). A collidable part inside that volume stops a player reaching part of the
pad, so no CanCollide=true part may intersect it. Parts are compared as oriented boxes (a cylinder or ball by its
bounding box, which is conservative).
"""

import base64
import math
import re
import unittest
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
HUB = ROOT / "games" / "mathshow" / "map" / "Hub.rbxmx"
PAD_CONFIG = ROOT / "games" / "mathshow" / "src" / "shared" / "ModePadConfig.luau"
MIN_LEG_CLEARANCE = 1.0


def vertical_tolerance() -> float:
	match = re.search(r"VerticalTolerance\s*=\s*([0-9.]+)", PAD_CONFIG.read_text(encoding="utf-8"))
	assert match, "ModePadConfig.VerticalTolerance not found"
	return float(match.group(1))


def _prop(item: ET.Element, tag: str, name: str):
	for el in item.find("Properties"):
		if el.tag == tag and el.get("name") == name:
			return el
	return None


def _box(item: ET.Element):
	"""(centre, rotation rows, size) of a part, or None when it has no CFrame and Size."""
	cf = _prop(item, "CoordinateFrame", "CFrame")
	size = _prop(item, "Vector3", "Size") or _prop(item, "Vector3", "size")
	if cf is None or size is None:
		return None
	v = {k: float(cf.find(k).text) for k in ("X", "Y", "Z", "R00", "R01", "R02", "R10", "R11", "R12", "R20", "R21", "R22")}
	rot = ((v["R00"], v["R01"], v["R02"]), (v["R10"], v["R11"], v["R12"]), (v["R20"], v["R21"], v["R22"]))
	return (v["X"], v["Y"], v["Z"]), rot, tuple(float(size.find(k).text) for k in "XYZ")


def _tags(item: ET.Element) -> list[str]:
	el = _prop(item, "BinaryString", "Tags")
	if el is None or not (el.text or "").strip():
		return []
	return base64.b64decode(el.text).decode().split("\0")


def load_parts(path: Path = HUB) -> list[dict]:
	parts = []

	def walk(node: ET.Element, trail: str) -> None:
		for item in node.findall("Item"):
			name = _prop(item, "string", "Name").text or ""
			box = _box(item)
			if box is not None:
				collide = _prop(item, "bool", "CanCollide")
				parts.append({
					"path": f"{trail}/{name}",
					"box": box,
					"collide": collide is None or collide.text == "true",
					"pad": "ModePad" in _tags(item),
				})
			walk(item, f"{trail}/{name}")

	walk(ET.parse(path).getroot(), "")
	return parts


def trigger_volume(pad_box, tolerance: float, grow: float = 0.0):
	"""The ModePadRules.isInside volume as an oriented box: the pad footprint (grown by `grow`) from its top surface up `tolerance`."""
	(cx, cy, cz), rot, (sx, sy, sz) = pad_box
	top = cy + sy / 2
	return (cx, top + tolerance / 2, cz), rot, (sx + 2 * grow, tolerance, sz + 2 * grow)


def boxes_intersect(a, b) -> bool:
	"""Separating-axis test for two oriented boxes (touching counts as intersecting)."""
	(ca, ra, sa), (cb, rb, sb) = a, b
	axes_a = [tuple(ra[i][k] for i in range(3)) for k in range(3)]
	axes_b = [tuple(rb[i][k] for i in range(3)) for k in range(3)]
	axes = list(axes_a) + list(axes_b)
	for u in axes_a:
		for w in axes_b:
			cross = (u[1] * w[2] - u[2] * w[1], u[2] * w[0] - u[0] * w[2], u[0] * w[1] - u[1] * w[0])
			if math.sqrt(sum(c * c for c in cross)) > 1e-9:
				axes.append(cross)
	delta = tuple(cb[i] - ca[i] for i in range(3))
	for axis in axes:
		length = math.sqrt(sum(c * c for c in axis))
		if length < 1e-9:
			continue
		n = tuple(c / length for c in axis)
		ra_ = sum(sa[k] / 2 * abs(sum(n[i] * axes_a[k][i] for i in range(3))) for k in range(3))
		rb_ = sum(sb[k] / 2 * abs(sum(n[i] * axes_b[k][i] for i in range(3))) for k in range(3))
		if abs(sum(n[i] * delta[i] for i in range(3))) > ra_ + rb_ + 1e-9:
			return False
	return True


def violations(parts: list[dict], grow: float = 0.0) -> list[str]:
	tolerance = vertical_tolerance()
	volumes = [(p["path"], trigger_volume(p["box"], tolerance, grow)) for p in parts if p["pad"]]
	found = []
	for part in parts:
		if not part["collide"] or part["pad"]:
			continue
		for pad_path, volume in volumes:
			if boxes_intersect(part["box"], volume):
				found.append(f"{part['path']} intersects the trigger volume of {pad_path}")
	return found


class HubPadTriggerTests(unittest.TestCase):
	def test_hub_has_the_six_pads(self):
		self.assertEqual(sum(1 for p in load_parts() if p["pad"]), 6)

	def test_no_collidable_part_intersects_a_pad_trigger_volume(self):
		self.assertEqual(violations(load_parts()), [])

	def test_collidable_parts_keep_a_stud_clear_of_the_arched_pads(self):
		# The three competitive pads sit under ModeArch: their leg colliders must clear the footprint by MIN_LEG_CLEARANCE.
		parts = load_parts()
		arched = [p for p in parts if p["pad"] and any(m in p["path"] for m in ("Pad_VS", "Pad_Blitz", "Pad_Group"))]
		self.assertEqual(len(arched), 3)
		legs = [p for p in parts if "_Leg" in p["path"] and p["collide"]]
		self.assertEqual(len(legs), 6)
		tolerance = vertical_tolerance()
		for pad in arched:
			volume = trigger_volume(pad["box"], tolerance, MIN_LEG_CLEARANCE)
			for leg in legs:
				self.assertFalse(boxes_intersect(leg["box"], volume), f"{leg['path']} is within {MIN_LEG_CLEARANCE} stud of {pad['path']}")

	def test_checker_catches_an_intrusion(self):
		# The guard itself: a collidable box dropped on a pad edge is reported, one beside it is not.
		pad = {"path": "/Pad_T", "box": ((0.0, 0.45, 0.0), ((1, 0, 0), (0, 1, 0), (0, 0, 1)), (10.0, 0.5, 10.0)), "collide": True, "pad": True}
		rot = ((1, 0, 0), (0, 1, 0), (0, 0, 1))
		inside = {"path": "/Leg_in", "box": ((4.4, 3.5, 0.0), rot, (3.14, 7.0, 5.2)), "collide": True, "pad": False}
		beside = {"path": "/Leg_out", "box": ((9.6, 3.5, 0.0), rot, (3.14, 7.0, 5.2)), "collide": True, "pad": False}
		ghost = {"path": "/Ghost", "box": ((4.4, 3.5, 0.0), rot, (3.14, 7.0, 5.2)), "collide": False, "pad": False}
		below = {"path": "/Floor", "box": ((0.0, 0.0, 0.0), rot, (40.0, 0.4, 40.0)), "collide": True, "pad": False}
		self.assertEqual(len(violations([pad, inside, beside, ghost, below])), 1)


if __name__ == "__main__":
	unittest.main()
