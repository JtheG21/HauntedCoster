--!strict
-- Plot capacity (TASK-0037, AUDIT-002/012): one plot per player, the server cap never exceeds the plots,
-- and a 7th player on a full server gets no plot (and no one else's).
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local World = require(ReplicatedStorage.Shared.Config.World)
local PlotRules = require(ReplicatedStorage.Shared.Rules.PlotRules)

return function(t: TestRunner.T)
	t.test("the player cap fits the plots", function()
		t.eq(#World.PlotCenters, World.PlotRing.count, "plot centres")
		t.eq(World.MaxPlayers, 6, "documented cap")
		t.eq(World.MaxPlayers <= #World.PlotCenters, true, "cap <= plots")
	end)

	t.test("players get the lowest free plot", function()
		t.eq(PlotRules.firstFree({}, 6), 1)
		t.eq(PlotRules.firstFree({ [1] = "a", [2] = "b" }, 6), 3)
		t.eq(PlotRules.firstFree({ [1] = "a", [3] = "c" }, 6), 2)
	end)

	t.test("with all six plots taken, a 7th player gets none", function()
		local owners = {}
		for i = 1, World.MaxPlayers do
			local got = PlotRules.firstFree(owners, #World.PlotCenters)
			t.eq(got, i, `player {i}`)
			owners[got :: number] = `p{i}`
		end
		t.eq(PlotRules.firstFree(owners, #World.PlotCenters), nil, "7th player")
		for i = 1, World.MaxPlayers do
			t.eq(owners[i], `p{i}`, `plot {i} keeps its owner`)
		end
	end)

	t.test("a freed plot is reused", function()
		local owners = { "a", "b", "c", "d", "e", "f" }
		owners[4] = nil
		t.eq(PlotRules.firstFree(owners, 6), 4)
	end)
end
