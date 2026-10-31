--!strict
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TrackRules = require(ReplicatedStorage.Shared.TrackRules)

return function(t: TestRunner.T)
	t.test("all returns six distinct tracks in a stable order", function()
		local all = TrackRules.all()
		t.eq(#all, 6)
		t.eq(all[1], "groupBattle:direct")
		t.eq(all[2], "groupBattle:choice")
		t.eq(all[6], "blitz:choice")
		local seen: { [string]: boolean } = {}
		for _, id in all do
			t.eq(seen[id], nil)
			seen[id] = true
		end
		t.eq(TrackRules.all()[3], all[3])
	end)

	t.test("make then parse round-trips every track", function()
		for _, id in TrackRules.all() do
			local mode, format = TrackRules.parse(id)
			t.truthy(mode and format)
			t.eq(TrackRules.make(mode, format), id)
		end
	end)

	t.test("make rejects unknown parts", function()
		t.eq(TrackRules.make("groupBattle", "essay"), nil)
		t.eq(TrackRules.make("vs", "direct"), nil)
		t.eq(TrackRules.make(nil, "direct"), nil)
	end)

	t.test("parse is strict", function()
		for _, bad in
			{
				"",
				":",
				"blitz",
				"blitz:",
				":direct",
				"Blitz:direct",
				"blitz:Direct",
				"blitz:direct:x",
				"blitz: direct",
				"blitz:direct ",
				"vs:direct",
				"blitz:essay",
			}
		do
			local mode, format = TrackRules.parse(bad)
			t.eq(mode, nil, bad)
			t.eq(format, nil, bad)
		end
		t.eq((TrackRules.parse(5)), nil)
	end)

	t.test("isRanked is true only for the ranked playlist", function()
		t.eq(TrackRules.isRanked("ranked"), true)
		t.eq(TrackRules.isRanked("casual"), false)
		t.eq(TrackRules.isRanked("Ranked"), false)
		t.eq(TrackRules.isRanked(nil), false)
	end)
end
