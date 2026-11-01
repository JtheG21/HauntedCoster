--!strict
local TestRunner = require(script.Parent.TestRunner)
local CollisionRules = require(script.Parent.studio.CollisionRules)

type Rect = CollisionRules.Rect

local function rect(cx: number, cy: number, w: number, h: number, rot: number?): Rect
	return { cx = cx, cy = cy, w = w, h = h, rot = rot or 0 }
end

local function near(t: TestRunner.T, actual: number, expected: number, msg: string)
	t.eq(math.abs(actual - expected) < 1e-6, true, `{msg}: expected {expected}, got {actual}`)
end

local function el(path: string, kind: string, r: Rect): CollisionRules.Element
	return { path = string.split(path, "/"), kind = kind, rect = r }
end

return function(t: TestRunner.T)
	t.test("axis-aligned overlap area", function()
		near(t, CollisionRules.rotatedRectOverlapArea(rect(0, 0, 10, 10), rect(5, 0, 10, 10)), 50, "half overlap")
		near(t, CollisionRules.rotatedRectOverlapArea(rect(0, 0, 10, 10), rect(0, 0, 10, 10)), 100, "identical")
	end)

	t.test("rotation 0, 45 and 90 degrees", function()
		-- A 10x10 square against itself rotated: 0 and 90 give the full square, 45 gives a regular octagon.
		near(t, CollisionRules.rotatedRectOverlapArea(rect(0, 0, 10, 10), rect(0, 0, 10, 10, 90)), 100, "90 degrees")
		local octagon = 100 * 2 * (math.sqrt(2) - 1) -- area of a square rotated 45 against itself: 82.84
		near(
			t,
			CollisionRules.rotatedRectOverlapArea(rect(0, 0, 10, 10), rect(0, 0, 10, 10, 45)),
			octagon,
			"45 degrees"
		)
		-- A 20x4 bar rotated 90 about the same centre crosses a 4x20 bar as a 4x4 square.
		near(t, CollisionRules.rotatedRectOverlapArea(rect(0, 0, 20, 4), rect(0, 0, 20, 4, 90)), 16, "cross")
		-- Order does not matter.
		near(
			t,
			CollisionRules.rotatedRectOverlapArea(rect(3, 1, 8, 6, 30), rect(0, 0, 10, 10, 45)),
			CollisionRules.rotatedRectOverlapArea(rect(0, 0, 10, 10, 45), rect(3, 1, 8, 6, 30)),
			"symmetry"
		)
	end)

	t.test("a shared edge or corner is no overlap", function()
		near(t, CollisionRules.rotatedRectOverlapArea(rect(0, 0, 10, 10), rect(10, 0, 10, 10)), 0, "shared edge")
		near(t, CollisionRules.rotatedRectOverlapArea(rect(0, 0, 10, 10), rect(10, 10, 10, 10)), 0, "shared corner")
		near(t, CollisionRules.rotatedRectOverlapArea(rect(0, 0, 10, 10), rect(30, 0, 10, 10)), 0, "apart")
	end)

	t.test("containment gives the inner area", function()
		near(t, CollisionRules.rotatedRectOverlapArea(rect(0, 0, 20, 20), rect(1, 1, 4, 6)), 24, "inside")
		near(t, CollisionRules.rotatedRectOverlapArea(rect(0, 0, 20, 20), rect(0, 0, 4, 6, 33)), 24, "rotated inside")
	end)

	t.test("zero-size rectangles overlap nothing", function()
		near(t, CollisionRules.rotatedRectOverlapArea(rect(0, 0, 0, 10), rect(0, 0, 10, 10)), 0, "zero width")
		near(t, CollisionRules.rotatedRectOverlapArea(rect(0, 0, 10, 10), rect(0, 0, 10, 0)), 0, "zero height")
	end)

	t.test("owner: in-control paths resolve to their control", function()
		t.eq(CollisionRules.resolveOwner({ "Screen_main", "Play", "Group", "Content", "Label" }), "Screen_main/Play")
		t.eq(CollisionRules.resolveOwner({ "Screen_main", "Play", "Group", "Shard" }), "Screen_main/Play", "shard")
		t.eq(CollisionRules.resolveOwner({ "Screen_main", "Play", "Group", "Glow" }), "Screen_main/Play", "halo image")
	end)

	t.test("owner: X/Group/Shard resolves to X, including under a screen", function()
		t.eq(CollisionRules.resolveOwner({ "Screen_ladder", "Rung1", "Group", "Shard" }), "Screen_ladder/Rung1")
		t.eq(CollisionRules.resolveOwner({ "Toasts", "Toast", "Group", "Shard" }), "Toasts/Toast")
	end)

	t.test("owner: off-control paths are their own owner", function()
		t.eq(CollisionRules.resolveOwner({ "Screen_main", "EdgeLeft" }), "Screen_main/EdgeLeft")
		t.eq(CollisionRules.resolveOwner({ "Toasts", "Toast" }), "Toasts/Toast")
		t.eq(CollisionRules.resolveOwner({ "Screen_main", "Play", "Group" }), "Screen_main/Play/Group", "group itself")
	end)

	t.test("owner: nested controls resolve to the nearest", function()
		t.eq(
			CollisionRules.resolveOwner({ "S", "Outer", "Group", "Content", "Inner", "Group", "Content", "Label" }),
			"S/Outer/Group/Content/Inner"
		)
		t.eq(
			CollisionRules.resolveOwner({ "S", "Outer", "Group", "Content", "Plain", "Label" }),
			"S/Outer",
			"a non-control child stays with the outer control"
		)
	end)

	t.test("compare: same-owner overlap is composition, cross-owner overlap is an overlap", function()
		local result = CollisionRules.compare({
			el("S/A/Group/Shard", "shard", rect(0, 0, 100, 50)),
			el("S/A/Group/Content/Label", "label", rect(0, 0, 40, 10)),
			el("S/B/Group/Shard", "shard", rect(80, 0, 100, 50)),
			el("S/C/Group/Shard", "shard", rect(400, 0, 20, 20)),
		}, 0.5, "01-main")
		t.eq(result.composition, 1, "label over its own shard")
		t.eq(#result.overlaps, 1, "A shard over B shard")
		t.eq(result.overlaps[1].a, "S/A/Group/Shard")
		t.eq(result.overlaps[1].b, "S/B/Group/Shard")
		-- 6 pairs in all; one is same-owner.
		t.eq(result.compared, 5)
	end)

	t.test("compare: a halo overlap is informational, not an overlap; below minArea is ignored", function()
		local result = CollisionRules.compare({
			el("S/A/Group/Halo1", "halo", rect(0, 0, 100, 50)),
			el("S/B/Group/Shard", "shard", rect(60, 0, 100, 50)),
			el("S/C/Group/Shard", "shard", rect(0, 100, 10, 10)),
		}, 0.5, "f")
		t.eq(#result.halo, 1)
		t.eq(#result.overlaps, 0)
		local sliver = CollisionRules.compare({
			el("S/C/Group/Shard", "shard", rect(0, 100, 10, 10)),
			el("S/D/Group/Shard", "shard", rect(0, 109.99, 10, 10)),
		}, 0.5, "f")
		t.eq(#sliver.overlaps, 0, "0.1 px^2 sliver")
	end)

	t.test("manifest: an exact pair and a listed fixture hits, in either order", function()
		local pairs: { CollisionRules.Pair } = {
			{ a = "S/A/Group/Shard", b = "S/B/Group/Shard", fixture = "01-main", area = 10 },
			{ a = "S/C/Group/Shard", b = "S/D/Group/Shard", fixture = "01-main", area = 10 },
		}
		local manifest: { CollisionRules.ManifestEntry } = {
			{ a = "S/B/Group/Shard", b = "S/A/Group/Shard", fixtures = { "01-main" }, reason = "approved" },
		}
		local result = CollisionRules.matchManifest(pairs, manifest)
		t.eq(#result.hits, 1, "reversed order hits")
		t.eq(#result.unmatched, 1)
		t.eq(result.unmatched[1].a, "S/C/Group/Shard")
		t.eq(#result.unusedEntries, 0)
	end)

	t.test("manifest: a fixtures list hits each listed fixture and nothing else", function()
		local pairs: { CollisionRules.Pair } = {
			{ a = "S/A/Group/Shard", b = "S/B/Group/Shard", fixture = "f1", area = 10 },
			{ a = "S/A/Group/Shard", b = "S/B/Group/Shard", fixture = "f2", area = 10 },
			{ a = "S/A/Group/Shard", b = "S/B/Group/Shard", fixture = "f3", area = 10 },
		}
		local manifest: { CollisionRules.ManifestEntry } = {
			{ a = "S/A/Group/Shard", b = "S/B/Group/Shard", fixtures = { "f1", "f2" }, reason = "approved" },
		}
		local result = CollisionRules.matchManifest(pairs, manifest)
		t.eq(#result.hits, 2, "f1 and f2")
		t.eq(#result.unmatched, 1, "f3 is not listed")
		t.eq(result.unmatched[1].fixture, "f3")
		t.eq(#result.unusedEntries, 0)
		t.eq(#result.missing, 0)
	end)

	t.test("manifest: a listed fixture that lacks the pair makes the entry unused", function()
		local pairs: { CollisionRules.Pair } = {
			{ a = "S/A/Group/Shard", b = "S/B/Group/Shard", fixture = "f1", area = 10 },
		}
		local manifest: { CollisionRules.ManifestEntry } = {
			{ a = "S/A/Group/Shard", b = "S/B/Group/Shard", fixtures = { "f1", "f2" }, reason = "approved" },
		}
		local result = CollisionRules.matchManifest(pairs, manifest)
		t.eq(#result.hits, 1)
		t.eq(#result.unusedEntries, 1, "f2 produced no pair")
		t.eq(#result.missing, 1)
		t.eq(result.missing[1].fixture, "f2")
	end)

	t.test("manifest: the fixture must be listed", function()
		local pairs: { CollisionRules.Pair } = {
			{ a = "S/A/Group/Shard", b = "S/B/Group/Shard", fixture = "02-other", area = 10 },
		}
		local manifest: { CollisionRules.ManifestEntry } = {
			{ a = "S/A/Group/Shard", b = "S/B/Group/Shard", fixtures = { "01-main" }, reason = "approved" },
		}
		local result = CollisionRules.matchManifest(pairs, manifest)
		t.eq(#result.hits, 0)
		t.eq(#result.unmatched, 1)
		t.eq(#result.unusedEntries, 1, "wrong fixture leaves the entry unused")
	end)

	t.test("manifest: an entry that matches nothing is unused; an empty manifest hits nothing", function()
		local manifest: { CollisionRules.ManifestEntry } = {
			{ a = "S/X/Group/Shard", b = "S/Y/Group/Shard", fixtures = { "01-main" }, reason = "stale" },
			{ a = "S/P/Group/Shard", b = "S/Q/Group/Shard", fixtures = {}, reason = "no fixtures listed" },
		}
		local result = CollisionRules.matchManifest({}, manifest)
		t.eq(#result.unusedEntries, 2, "a stale entry and an entry with no fixtures")
		t.eq(result.unusedEntries[1].reason, "stale")
		local empty = CollisionRules.matchManifest({ { a = "a", b = "b", fixture = "f", area = 1 } }, {})
		t.eq(#empty.hits, 0)
		t.eq(#empty.unmatched, 1)
	end)
end
