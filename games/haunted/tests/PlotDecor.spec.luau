--!strict
-- Plot presentation stays out of the gameplay areas (TASK-0030 AC1-AC2): every house volume of every tier
-- (with room for its details), every lamp and the entrance pillars keep clear of the track area, the pen,
-- the exhibit pedestals, the spawn, the entrance, the beacon and the trophies, and stay inside the plot.
-- Each tier is bigger than the last.
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local World = require(Shared.Config.World)
local PlotDecor = require(Shared.Config.PlotDecor)

type Rect = { x1: number, x2: number, z1: number, z2: number }

local function rectOf(center: Vector3, sx: number, sz: number, grow: number): Rect
	return {
		x1 = center.X - sx / 2 - grow,
		x2 = center.X + sx / 2 + grow,
		z1 = center.Z - sz / 2 - grow,
		z2 = center.Z + sz / 2 + grow,
	}
end

local function overlaps(a: Rect, b: Rect): boolean
	return a.x1 < b.x2 and b.x1 < a.x2 and a.z1 < b.z2 and b.z1 < a.z2
end

local function distToRect(p: Vector3, r: Rect): number
	local dx = math.max(r.x1 - p.X, 0, p.X - r.x2)
	local dz = math.max(r.z1 - p.Z, 0, p.Z - r.z2)
	return math.sqrt(dx * dx + dz * dz)
end

local P = World.Plot
local keepOut: { [string]: Rect } = {
	track = P.trackBounds,
	pen = rectOf(P.pen, P.penSize, P.penSize, 1),
	entrance = {
		x1 = -P.entranceWidth / 2,
		x2 = P.entranceWidth / 2,
		z1 = -World.PlotSize.Y / 2,
		z2 = P.trackBounds.z1,
	},
	beacon = rectOf(P.beacon, 2.5, 2.5, 1),
	trophies = rectOf(P.trophies, 16, 4, 1),
}
local inside: Rect = {
	x1 = -World.PlotSize.X / 2 + 1,
	x2 = World.PlotSize.X / 2 - 1,
	z1 = -World.PlotSize.Y / 2 + 1,
	z2 = World.PlotSize.Y / 2 - 1,
}

local function clearOfGameplay(t: TestRunner.T, what: string, r: Rect)
	for name, area in keepOut do
		t.truthy(not overlaps(r, area), `{what} overlaps the {name}`)
	end
	for i, slot in P.exhibitSlots do
		t.truthy(distToRect(slot, r) >= PlotDecor.ExhibitClear, `{what} crowds exhibit {i}`)
	end
	t.truthy(distToRect(P.spawn, r) >= PlotDecor.SpawnClear, `{what} crowds the spawn`)
	t.truthy(
		r.x1 >= inside.x1 and r.x2 <= inside.x2 and r.z1 >= inside.z1 and r.z2 <= inside.z2,
		`{what} leaves the plot`
	)
end

return function(t: TestRunner.T)
	t.test("every house volume of every tier keeps clear of the gameplay areas", function()
		for tier = 0, 2 do
			for _, box in PlotDecor.Houses[tier] do
				clearOfGameplay(
					t,
					`tier {tier} {box.name}`,
					rectOf(box.center, box.size.X, box.size.Z, PlotDecor.DetailMargin)
				)
			end
		end
	end)

	t.test("lamps and entrance pillars keep clear too, and the pillars frame the entrance gap", function()
		for i, p in PlotDecor.Lamps do
			clearOfGameplay(t, `lamp {i}`, rectOf(p, 0, 0, PlotDecor.LampReach))
		end
		for i, p in PlotDecor.EntrancePillars do
			local r = rectOf(p, 2.6, 2.6, 0)
			t.truthy(math.abs(p.X) - 1.3 >= P.entranceWidth / 2, `pillar {i} stands beside the gap, not in it`)
			t.truthy(not overlaps(r, P.trackBounds), `pillar {i} is off the track area`)
		end
	end)

	t.test("each tier is bigger and taller than the last", function()
		local function measure(tier: number): (number, number)
			local area, height = 0, 0
			for _, box in PlotDecor.Houses[tier] do
				area += box.size.X * box.size.Z
				height = math.max(height, box.size.Y)
			end
			return area, height
		end
		local a0, h0 = measure(0)
		local a1, h1 = measure(1)
		local a2, h2 = measure(2)
		t.truthy(a1 > a0 * 1.4 and a2 > a1 * 1.3, `footprints {a0} {a1} {a2}`)
		t.truthy(h1 > h0 and h2 > h1, `heights {h0} {h1} {h2}`)
	end)
end
