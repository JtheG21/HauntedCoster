--!strict
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local World = require(ReplicatedStorage.Shared.Config.World)
local PlacementRules = require(ReplicatedStorage.Shared.Rules.PlacementRules)

local FP = PlacementRules.DefaultFootprint

return function(t: TestRunner.T)
	t.test("every house tier leaves room for a decoration", function()
		for tier = 0, 2 do
			local x, z = PlacementRules.firstSpot(FP, 0, tier)
			t.truthy(x ~= nil and z ~= nil, `tier {tier} has no free spot`)
			if x and z then
				t.eq(PlacementRules.refusal(x, z, FP, 0, tier), nil)
			end
		end
	end)

	t.test("gameplay areas are refused", function()
		local P = World.Plot
		t.eq(PlacementRules.refusal(P.spawn.X, P.spawn.Z, FP, 0, 0), "blocked")
		t.eq(PlacementRules.refusal(P.pen.X, P.pen.Z, FP, 0, 0), "blocked")
		t.eq(PlacementRules.refusal(P.exhibitSlots[1].X, P.exhibitSlots[1].Z, FP, 0, 0), "blocked")
		t.eq(PlacementRules.refusal(P.entrance.X, -40, FP, 0, 0), "blocked")
		t.eq(PlacementRules.refusal(P.house.X, P.house.Z, FP, 0, 0), "blocked")
		t.eq(PlacementRules.refusal(P.trophies.X, P.trophies.Z, FP, 0, 0), "blocked")
	end)

	t.test("outside the plot bounds is refused", function()
		t.eq(PlacementRules.refusal(60, 0, FP, 0, 0), "outOfPlot")
		t.eq(PlacementRules.refusal(0, -60, FP, 0, 0), "outOfPlot")
		t.eq(PlacementRules.refusal(-48.5, 0, FP, 0, 0), "outOfPlot") -- inside the plot but past the margin
	end)

	t.test("a bigger house takes more room", function()
		-- Beside the Grand Mansion's east wing: free at the Shack, blocked at tier 2.
		t.eq(PlacementRules.refusal(27, 33, FP, 0, 0), nil)
		t.eq(PlacementRules.refusal(27, 33, FP, 0, 2), "blocked")
	end)

	t.test("rotation swaps the footprint's extents", function()
		local wide = { x = 8, z = 2 }
		local a = PlacementRules.rectOf(0, 0, wide, 0)
		local b = PlacementRules.rectOf(0, 0, wide, 90)
		t.eq(a.x2 - a.x1, 8)
		t.eq(b.x2 - b.x1, 2)
		t.eq(b.z2 - b.z1, 8)
		local c = PlacementRules.rectOf(0, 0, wide, 270)
		t.eq(c.z2 - c.z1, 8)
	end)

	t.test("snap uses the coarse grid and bounds the fine nudge", function()
		t.eq(PlacementRules.snap(5.2, 0), 6)
		t.eq(PlacementRules.snap(5.2, 0.5), 6.5)
		t.eq(PlacementRules.snap(5.2, 9), 7) -- clamped to +1
		t.eq(PlacementRules.snap(5.2, -9), 5)
	end)

	t.test("cleanCoord rejects non-numbers, NaN and infinity", function()
		t.eq(PlacementRules.cleanCoord("3"), nil)
		t.eq(PlacementRules.cleanCoord(0 / 0), nil)
		t.eq(PlacementRules.cleanCoord(math.huge), nil)
		t.eq(PlacementRules.cleanCoord(-math.huge), nil)
		t.eq(PlacementRules.cleanCoord(nil), nil)
		t.eq(PlacementRules.cleanCoord(3.2), 3)
		t.eq(PlacementRules.cleanCoord(3.3), 3.5)
	end)

	t.test("a house upgrade stores placements that now collide", function()
		local x, z = PlacementRules.firstSpot(FP, 0, 2)
		local placements = {
			{ id = "Lantern", x = x :: number, z = z :: number, r = 0 },
			{ id = "Lantern", x = 27, z = 33, r = 0 }, -- free at tier 0, blocked by the Grand Mansion
		}
		local function fp(_: string): PlacementRules.Footprint
			return FP
		end
		local kept, stored = PlacementRules.afterUpgrade(placements, fp, 2)
		t.eq(stored, 1)
		t.eq(#kept, 1)
		t.eq(kept[1].x, x)
		local keptAll, none = PlacementRules.afterUpgrade({ placements[1] }, fp, 2)
		t.eq(none, 0)
		t.eq(#keptAll, 1)
	end)

	t.test("messages are friendly and generic for the unexpected", function()
		t.truthy(string.find(PlacementRules.message("blocked"), "way") ~= nil)
		t.eq(PlacementRules.message("zzz"), "Something went wrong. Try again.")
	end)

	t.test("parseEdit accepts well-formed place, move and store", function()
		local p = PlacementRules.parseEdit("place", "Lantern", 6.2, -3, 90)
		t.truthy(p ~= nil and p.action == "place" and p.id == "Lantern" and p.x == 6 and p.z == -3 and p.r == 90)
		local m = PlacementRules.parseEdit("move", 2, 4, 4, 270)
		t.truthy(m ~= nil and m.action == "move" and m.index == 2)
		local s = PlacementRules.parseEdit("store", 3)
		t.truthy(s ~= nil and s.index == 3)
	end)

	t.test("parseEdit rejects bad actions, ids, indexes, coordinates and rotations", function()
		t.eq(PlacementRules.parseEdit("destroy", 1), nil)
		t.eq(PlacementRules.parseEdit(nil, 1), nil)
		t.eq(PlacementRules.parseEdit("place", 5, 0, 0, 0), nil)
		t.eq(PlacementRules.parseEdit("place", "a b", 0, 0, 0), nil)
		t.eq(PlacementRules.parseEdit("place", "Lantern", "1", 0, 0), nil)
		t.eq(PlacementRules.parseEdit("place", "Lantern", 0 / 0, 0, 0), nil)
		t.eq(PlacementRules.parseEdit("place", "Lantern", math.huge, 0, 0), nil)
		t.eq(PlacementRules.parseEdit("place", "Lantern", 0, 0, 45), nil)
		t.eq(PlacementRules.parseEdit("place", "Lantern", 0, 0, "90"), nil)
		t.eq(PlacementRules.parseEdit("move", 0, 0, 0, 0), nil)
		t.eq(PlacementRules.parseEdit("move", 1.5, 0, 0, 0), nil)
		t.eq(PlacementRules.parseEdit("move", 1000, 0, 0, 0), nil)
		t.eq(PlacementRules.parseEdit("store", {}), nil)
		t.eq(PlacementRules.parseEdit("store", -1), nil)
	end)
end
