--!strict
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ShapeProfiles = require(ReplicatedStorage.Shared.ShapeProfiles)

-- Art v2 (ART_V2_README): canvas size at 1x and whether the shard is a horizontal 9-slice.
local V2: { [string]: { w: number, h: number, sliced: boolean } } = {
	["shard-menu-row-indigo-v2"] = { w = 300, h = 38, sliced = true },
	["shard-menu-row-green-v2"] = { w = 300, h = 38, sliced = true },
	["shard-menu-toast-silver-v2"] = { w = 320, h = 46, sliced = true },
	["shard-menu-toast-green-v2"] = { w = 320, h = 46, sliced = true },
	["shard-menu-toast-red-v2"] = { w = 320, h = 46, sliced = true },
	["shard-menu-banner-violet-v2"] = { w = 480, h = 48, sliced = false },
	["shard-menu-h2h-silver-v2"] = { w = 344, h = 52, sliced = false },
	["shard-menu-count-blue-v2"] = { w = 200, h = 184, sliced = false },
	["shard-menu-count-red-v2"] = { w = 200, h = 184, sliced = false },
	["shard-menu-title-violet-v2"] = { w = 330, h = 104, sliced = false },
}

return function(t: TestRunner.T)
	t.test("every Art v2 profile exists with the README canvas size and slice flag", function()
		for key, want in V2 do
			local p = ShapeProfiles[key]
			t.truthy(p ~= nil, `{key} has a profile`)
			t.eq(p.w, want.w, `{key} w`)
			t.eq(p.h, want.h, `{key} h`)
			t.eq(p.sliced, want.sliced, `{key} sliced`)
		end
	end)

	t.test("every profile has one l/r entry per band and no empty edge but an empty band", function()
		for key, p in ShapeProfiles do
			local bands = math.ceil(p.h / p.step)
			t.eq(#p.l, bands, `{key} l length`)
			t.eq(#p.r, bands, `{key} r length`)
		end
	end)

	t.test("sliced right insets stay inside the 24 px caps and old profiles are not sliced", function()
		for key, p in ShapeProfiles do
			if p.sliced then
				for i = 1, #p.l do
					t.truthy(p.l[i] < 30 and p.r[i] < 30, `{key} band {i} edges lie in the caps`)
				end
			elseif not V2[key] then
				t.eq(p.sliced, false, `{key} (pre-v2) is not sliced`)
			end
		end
	end)
end
