--!strict
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ShapeProfiles = require(ReplicatedStorage.Shared.ShapeProfiles)
local TextFitRules = require(ReplicatedStorage.Shared.TextFitRules)

local function rect(x0: number, y0: number, x1: number, y1: number): TextFitRules.Rect
	return { x0 = x0, y0 = y0, x1 = x1, y1 = y1 }
end

local function fits(key: string, r: TextFitRules.Rect, margin: number?): boolean
	return TextFitRules.rectFits(ShapeProfiles[key], r, margin or 6, nil, nil)
end

-- Fixed-advance stand-in for TextService: 0.6 em per character.
local function measure(text: string, size: number): number
	return utf8.len(text) :: number * size * 0.6
end

return function(t: TestRunner.T)
	t.test("audit regression: 3-line panel bottom tag row crosses the cut", function()
		t.eq(fits("shard-menu-panel-blue", rect(50, 191, 403, 210)), false)
	end)

	t.test("audit regression: the same row moved up fits", function()
		t.eq(fits("shard-menu-panel-blue", rect(50, 176, 403, 195)), true)
	end)

	t.test("audit regression: panel title fits", function()
		t.eq(fits("shard-menu-panel-blue", rect(50, 52, 472, 102)), true)
	end)

	t.test("audit regression: 46 px title on the title shard fails, 40 px passes", function()
		t.eq(fits("shard-menu-title-violet", rect(30, 40, 326, 86)), false)
		t.eq(fits("shard-menu-title-violet", rect(30, 28, 262, 64)), true)
	end)

	t.test("audit regression: action label and mode-card tag row fit", function()
		t.eq(fits("shard-menu-action", rect(31, 22, 199, 38)), true)
		t.eq(fits("shard-menu-mode-red", rect(24, 146, 131, 165)), true)
	end)

	t.test("margin grows the keep-out: a rect that fits at 0 can fail at 6", function()
		local r = rect(50, 176, 403, 195)
		t.eq(fits("shard-menu-panel-blue", r, 0), true)
		t.eq(fits("shard-menu-panel-blue", rect(2, 100, 60, 120), 6), false)
	end)

	t.test("out of bounds and inverted rects fail", function()
		t.eq(fits("shard-menu-action", rect(-5, 20, 100, 40)), false)
		t.eq(fits("shard-menu-action", rect(40, 20, 400, 40)), false)
		t.eq(fits("shard-menu-action", rect(40, 20, 400, 80)), false)
		t.eq(fits("shard-menu-action", rect(100, 30, 50, 40)), false)
	end)

	t.test("stretched shards scale the profile", function()
		local p = ShapeProfiles["shard-score-silver"]
		t.eq(TextFitRules.rectFits(p, rect(40, 14, 250, 28), 6, 296, 44), true)
		t.eq(TextFitRules.rectFits(p, rect(0, 12, 296, 32), 6, 296, 44), false)
	end)

	t.test("profile looks up by key and misses cleanly", function()
		t.truthy(TextFitRules.profile("shard-menu-action"))
		t.eq(TextFitRules.profile("nope"), nil)
	end)

	t.test("fitSize picks the largest size that fits on one line", function()
		local sizes = { 88, 76, 64, 56, 48, 40 }
		t.eq(TextFitRules.fitSize(measure, "12+3=?", sizes, 456).size, 88)
		t.eq(TextFitRules.fitSize(measure, "12+3=?", sizes, 456).lines, 1)
		-- 13 chars: 88 -> 686, 76 -> 592, 64 -> 499, 56 -> 436 fits
		t.eq(TextFitRules.fitSize(measure, "1234567890123", sizes, 456).size, 56)
	end)

	t.test("fitSize exactly at the limit still fits", function()
		t.eq(
			TextFitRules.fitSize(function()
				return 456
			end, "x", { 88, 40 }, 456).size,
			88
		)
		t.eq(
			TextFitRules.fitSize(function(_, s)
				return if s > 40 then 457 else 456
			end, "x", { 88, 40 }, 456).size,
			40
		)
	end)

	t.test("fitSize wraps at the smallest size when nothing fits", function()
		local r = TextFitRules.fitSize(measure, "d/dx (x^3 + 2x) at x = 2 = ?", { 88, 76, 64, 56, 48, 40 }, 456)
		t.eq(r.size, 40)
		t.eq(r.lines, 2)
		local long = TextFitRules.fitSize(measure, string.rep("9", 80), { 88, 40 }, 456)
		t.truthy(long.lines >= 3)
	end)

	t.test("fitSize handles empty text and empty size lists", function()
		t.eq(TextFitRules.fitSize(measure, "", { 88, 40 }, 456).size, 88)
		t.eq(TextFitRules.fitSize(measure, "x", {}, 456).lines, 2)
	end)

	t.test("fitSize digit-heavy strings shrink with length", function()
		local sizes = { 88, 76, 64, 56, 48, 40 }
		local last = 100
		for n = 1, 20 do
			local size = TextFitRules.fitSize(measure, string.rep("8", n), sizes, 456).size
			t.truthy(size <= last, "size never grows with length")
			last = size
		end
	end)
end
