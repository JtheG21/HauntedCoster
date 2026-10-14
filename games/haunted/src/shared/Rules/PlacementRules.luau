--!strict
-- Exterior decoration placement (TASK-0047 AC4). Pure: plot-local studs, no Roblox services.
-- A placement is valid when its rotated footprint (plus the margin) stays inside the plot and clear of every
-- gameplay area (track area, pen, entrance, exhibits, spawn, beacon, trophies), of the current house tier's
-- volumes, of the lamps and entrance pillars, and of the other placed decorations.

local Shared = script.Parent.Parent
local World = require(Shared.Config.World)
local PlotDecor = require(Shared.Config.PlotDecor)
local Cosmetics = require(Shared.Config.Cosmetics)

local PlacementRules = {}

export type Rect = { x1: number, x2: number, z1: number, z2: number }
export type Placement = { key: string, id: string, x: number, z: number, rot: number }

local P = World.Plot

local function rectOf(cx: number, cz: number, sx: number, sz: number, grow: number): Rect
	return { x1 = cx - sx / 2 - grow, x2 = cx + sx / 2 + grow, z1 = cz - sz / 2 - grow, z2 = cz + sz / 2 + grow }
end

local function overlaps(a: Rect, b: Rect): boolean
	return a.x1 < b.x2 and b.x1 < a.x2 and a.z1 < b.z2 and b.z1 < a.z2
end

-- Gameplay areas no decoration may touch (independent of the house tier).
function PlacementRules.keepOut(): { [string]: Rect }
	local out: { [string]: Rect } = {
		track = P.trackBounds,
		pen = rectOf(P.pen.X, P.pen.Z, P.penSize, P.penSize, 1),
		entrance = {
			x1 = -P.entranceWidth / 2 - 2,
			x2 = P.entranceWidth / 2 + 2,
			z1 = -World.PlotSize.Y / 2,
			z2 = P.trackBounds.z1,
		},
		beacon = rectOf(P.beacon.X, P.beacon.Z, 2.5, 2.5, 1),
		trophies = rectOf(P.trophies.X, P.trophies.Z, 16, 4, 1),
		spawn = rectOf(P.spawn.X, P.spawn.Z, 0, 0, PlotDecor.SpawnClear),
	}
	for i, slot in P.exhibitSlots do
		out[`exhibit{i}`] = rectOf(slot.X, slot.Z, 0, 0, PlotDecor.ExhibitClear)
	end
	for i, lamp in PlotDecor.Lamps do
		out[`lamp{i}`] = rectOf(lamp.X, lamp.Z, 0, 0, PlotDecor.LampReach)
	end
	for i, pillar in PlotDecor.EntrancePillars do
		out[`pillar{i}`] = rectOf(pillar.X, pillar.Z, 2.6, 2.6, 0.5)
	end
	return out
end

-- The house volumes of a tier, grown by the detail margin (porches, roofs, chimneys).
function PlacementRules.houseRects(tier: number): { Rect }
	local out: { Rect } = {}
	local boxes: { PlotDecor.Box } = PlotDecor.Houses[math.clamp(tier, 0, 2)] or {}
	for _, box in boxes do
		table.insert(out, rectOf(box.center.X, box.center.Z, box.size.X, box.size.Z, PlotDecor.DetailMargin))
	end
	return out
end

-- Axis-aligned bounds of a decoration's footprint rotated by `rot` degrees (plus the margin).
function PlacementRules.bounds(id: string, x: number, z: number, rot: number): Rect?
	local item = Cosmetics.ById[id]
	if not item or item.category ~= "Decoration" or not item.footprint then
		return nil
	end
	local a = math.rad(rot)
	local c, s = math.abs(math.cos(a)), math.abs(math.sin(a))
	local fx, fz = item.footprint.x, item.footprint.z
	local w, d = fx * c + fz * s, fx * s + fz * c
	return rectOf(x, z, w, d, Cosmetics.Placement.margin / 2)
end

-- Snaps a requested position/rotation to the editor's steps (fine positioning is a smaller grid).
function PlacementRules.snap(x: number, z: number, rot: number, fine: boolean?): (number, number, number)
	local step = if fine then Cosmetics.Placement.fine else Cosmetics.Placement.grid
	local r = Cosmetics.Placement.rotationStep
	return math.round(x / step) * step, math.round(z / step) * step, (math.round(rot / r) * r) % 360
end

-- Why a placement is invalid ("ok" when it is valid). `others` are the plot's other placements.
function PlacementRules.check(
	id: string,
	x: number,
	z: number,
	rot: number,
	tier: number,
	others: { Placement },
	ignoreKey: string?
): string
	if type(x) ~= "number" or type(z) ~= "number" or type(rot) ~= "number" or x ~= x or z ~= z or rot ~= rot then
		return "bad position"
	end
	local r = PlacementRules.bounds(id, x, z, rot)
	if not r then
		return "not a decoration"
	end
	local hx, hz = World.PlotSize.X / 2 - 1.5, World.PlotSize.Y / 2 - 1.5
	if r.x1 < -hx or r.x2 > hx or r.z1 < -hz or r.z2 > hz then
		return "outside the plot"
	end
	for name, area in PlacementRules.keepOut() do
		if overlaps(r, area) then
			return `blocks the {string.gsub(name, "%d+$", "")}`
		end
	end
	for _, h in PlacementRules.houseRects(tier) do
		if overlaps(r, h) then
			return "blocks the house"
		end
	end
	for _, o in others do
		if o.key ~= ignoreKey then
			local ob = PlacementRules.bounds(o.id, o.x, o.z, o.rot)
			if ob and overlaps(r, ob) then
				return "overlaps another decoration"
			end
		end
	end
	return "ok"
end

-- After a house upgrade: placements still valid at `tier` stay; the rest go back to storage (returned).
function PlacementRules.reconcile(placements: { Placement }, tier: number): ({ Placement }, { Placement })
	local kept: { Placement } = {}
	local stored: { Placement } = {}
	for _, p in placements do
		if PlacementRules.check(p.id, p.x, p.z, p.rot, tier, kept) == "ok" then
			table.insert(kept, p)
		else
			table.insert(stored, p)
		end
	end
	return kept, stored
end

return PlacementRules
