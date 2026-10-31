--!strict
-- Where an exterior decoration may stand (TASK-0065). Pure, in plot-local studs, so the server (which decides)
-- and the editor (which shows live valid or invalid feedback) share one answer. DRAFT: the margins, grid and
-- fine-placement bound below are assumptions for jg to review. A decoration is art only: it never changes
-- income, capacity, rarity or capture, and it stays off every gameplay area listed in `keepOut`.

local World = require(script.Parent.Parent.Config.World)
local PlotDecor = require(script.Parent.Parent.Config.PlotDecor)

local PlacementRules = {}

PlacementRules.Grid = 2 -- studs: the coarse snap
PlacementRules.Fine = 1 -- studs: the most a fine nudge may move a decoration off the grid
PlacementRules.Step = 0.5 -- studs: the smallest position the server accepts
PlacementRules.DefaultFootprint = { x = 2, z = 2 }
PlacementRules.EdgeMargin = 3 -- keep this far inside the plot bounds

export type Rect = { x1: number, x2: number, z1: number, z2: number }
export type Footprint = { x: number, z: number }

local function around(c: Vector3, hx: number, hz: number): Rect
	return { x1 = c.X - hx, x2 = c.X + hx, z1 = c.Z - hz, z2 = c.Z + hz }
end

local keepOutCache: { [number]: { Rect } } = {}

-- Every gameplay area a decoration must stay clear of at house tier `tier`: the house, the pen, the entrance,
-- the spawn, each exhibit pedestal, the track editor area, the beacon, the trophies and the lamps.
function PlacementRules.keepOut(tier: number): { Rect }
	local t = math.clamp(math.floor(tier), 0, 2)
	local cached = keepOutCache[t]
	if cached then
		return cached
	end
	local out: { Rect } = {}
	for _, box in PlotDecor.Houses[t] do
		table.insert(out, around(box.center, box.size.X / 2 + 2, box.size.Z / 2 + 2))
	end
	local P = World.Plot
	table.insert(out, around(P.pen, P.penSize / 2 + 3, P.penSize / 2 + 3))
	table.insert(
		out,
		{ x1 = P.entrance.X - P.entranceWidth / 2, x2 = P.entrance.X + P.entranceWidth / 2, z1 = -60, z2 = -32 }
	)
	table.insert(out, around(P.spawn, PlotDecor.SpawnClear + 2, PlotDecor.SpawnClear + 2))
	for _, slot in P.exhibitSlots do
		table.insert(out, around(slot, PlotDecor.ExhibitClear, PlotDecor.ExhibitClear))
	end
	local tb = P.trackBounds
	table.insert(out, { x1 = tb.x1 - 2, x2 = tb.x2 + 2, z1 = tb.z1 - 2, z2 = tb.z2 + 2 })
	table.insert(out, around(P.beacon, 4, 4))
	table.insert(out, around(P.trophies, 8, 8))
	for _, lamp in PlotDecor.Lamps do
		table.insert(out, around(lamp, PlotDecor.LampReach + 1, PlotDecor.LampReach + 1))
	end
	for _, pillar in PlotDecor.EntrancePillars do
		table.insert(out, around(pillar, 3, 3))
	end
	keepOutCache[t] = out
	return out
end

-- The footprint's half-extents after a quarter-turn rotation (0, 90, 180, 270).
local function halves(fp: Footprint, rot: number): (number, number)
	if rot == 90 or rot == 270 then
		return fp.z / 2, fp.x / 2
	end
	return fp.x / 2, fp.z / 2
end

function PlacementRules.rectOf(x: number, z: number, fp: Footprint, rot: number): Rect
	local hx, hz = halves(fp, rot)
	return { x1 = x - hx, x2 = x + hx, z1 = z - hz, z2 = z + hz }
end

local function overlaps(a: Rect, b: Rect): boolean
	return a.x1 < b.x2 and a.x2 > b.x1 and a.z1 < b.z2 and a.z2 > b.z1
end

-- A number on the 0.5-stud step inside the plot: finite, not NaN. Untrusted, so type-checked first.
function PlacementRules.cleanCoord(v: any): number?
	if type(v) ~= "number" or v ~= v or v == math.huge or v == -math.huge then
		return nil
	end
	return math.floor(v / PlacementRules.Step + 0.5) * PlacementRules.Step
end

-- nil if (x, z) with this footprint and rotation is fine at `tier`; otherwise why not:
-- "outOfPlot" (past the margin) or "blocked" (touches a gameplay area).
function PlacementRules.refusal(x: number, z: number, fp: Footprint, rot: number, tier: number): string?
	local r = PlacementRules.rectOf(x, z, fp, rot)
	local limX = World.PlotSize.X / 2 - PlacementRules.EdgeMargin
	local limZ = World.PlotSize.Y / 2 - PlacementRules.EdgeMargin
	if r.x1 < -limX or r.x2 > limX or r.z1 < -limZ or r.z2 > limZ then
		return "outOfPlot"
	end
	for _, area in PlacementRules.keepOut(tier) do
		if overlaps(r, area) then
			return "blocked"
		end
	end
	return nil
end

-- Snaps to the coarse grid, then applies a fine nudge limited to +/- Fine.
function PlacementRules.snap(v: number, fine: number): number
	local g = PlacementRules.Grid
	local base = math.floor(v / g + 0.5) * g
	return base + math.clamp(fine, -PlacementRules.Fine, PlacementRules.Fine)
end

-- The first valid grid cell scanning from the front-left, for a new decoration's starting spot (nil if the
-- plot has no room).
function PlacementRules.firstSpot(fp: Footprint, rot: number, tier: number): (number?, number?)
	local g = PlacementRules.Grid
	local limX = World.PlotSize.X / 2
	local limZ = World.PlotSize.Y / 2
	local z = -limZ
	while z <= limZ do
		local x = -limX
		while x <= limX do
			if PlacementRules.refusal(x, z, fp, rot, tier) == nil then
				return x, z
			end
			x += g
		end
		z += g
	end
	return nil, nil
end

export type Edit = { action: string, id: string?, index: number?, x: number?, z: number?, r: number? }

local ROTATIONS = { 0, 90, 180, 270 }

local function isIndex(v: any): boolean
	return type(v) == "number" and v == math.floor(v) and v >= 1 and v <= 200
end

-- Untrusted remote arguments in, one validated edit out:
--   place (id, x, z, r), move (index, x, z, r), store (index).
function PlacementRules.parseEdit(action: any, a: any, b: any, c: any, d: any): (Edit?, string?)
	local bad = "Something went wrong. Try again."
	if action == "store" then
		if not isIndex(a) then
			return nil, bad
		end
		return { action = "store", index = a :: number }, nil
	elseif action ~= "place" and action ~= "move" then
		return nil, bad
	end
	local x, z = PlacementRules.cleanCoord(b), PlacementRules.cleanCoord(c)
	if x == nil or z == nil or type(d) ~= "number" or table.find(ROTATIONS, d) == nil then
		return nil, bad
	end
	if action == "place" then
		if type(a) ~= "string" or #a == 0 or #a > 64 or string.match(a, "^[%w_%-]+$") == nil then
			return nil, bad
		end
		return { action = "place", id = a :: string, x = x, z = z, r = d :: number }, nil
	end
	if not isIndex(a) then
		return nil, bad
	end
	return { action = "move", index = a :: number, x = x, z = z, r = d :: number }, nil
end

local MESSAGES: { [string]: string } = {
	outOfPlot = "That spot is outside your plot.",
	blocked = "That spot is in the way of something you use.",
	limit = "You've placed every copy of that decoration.",
	full = "Your plot is full of decorations.",
	notOwned = "You don't own that decoration yet.",
	unknown = "That decoration isn't available.",
	wrongCategory = "That isn't a decoration.",
	rotation = "Something went wrong. Try again.",
	noPlacement = "That decoration isn't placed.",
}

function PlacementRules.message(reason: string?): string
	return MESSAGES[reason or ""] or "Something went wrong. Try again."
end

-- After a house upgrade: placements that now touch the bigger house are stored (kept owned, removed from the
-- plot). Returns the placements that stay and how many were stored.
function PlacementRules.afterUpgrade(
	placements: { { id: string, x: number, z: number, r: number } },
	footprintOf: (string) -> Footprint,
	newTier: number
): ({ { id: string, x: number, z: number, r: number } }, number)
	local kept = {}
	local stored = 0
	for _, p in placements do
		if PlacementRules.refusal(p.x, p.z, footprintOf(p.id), p.r, newTier) == nil then
			table.insert(kept, p)
		else
			stored += 1
		end
	end
	return kept, stored
end

return PlacementRules
