--!strict
-- Ghost Cemetery habitat module (ADR-0007): the M1 graveyard's props re-laid inside the hub footprint.
-- A central plaza at the Weeping Angel, three gate paths, two side routes, grave rows in the sectors
-- between them, and the Sealed Crypt beside the Bell Tower. Deterministic (seeded), so every server
-- builds the same cemetery. TASK-0028 details it into the visual benchmark.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local World = require(Shared:WaitForChild("Config"):WaitForChild("World"))
local Habitats = require(Shared.Config:WaitForChild("Habitats"))
local HabitatRules = require(Shared:WaitForChild("Rules"):WaitForChild("HabitatRules"))
local Build = require(script.Parent.Parent.Build)
local Props = require(script.Parent.Parent.Props)

local Cemetery = {}

export type Result = {
	model: Model,
	landmarkAnchors: { [string]: BasePart },
	cryptGate: BasePart?,
}

local C = Props.C

local landmarkBuilders: { [string]: (Instance, Vector3) -> BasePart } = {
	Angel = Props.angel,
	Hearse = Props.hearse,
	OldWell = Props.well,
	BellTower = Props.bellTower,
	Mausoleum = function(parent: Instance, pos: Vector3): BasePart
		return Props.mausoleum(parent, pos.X, pos.Z, 1.3, "HollowMausoleum")
	end,
}

-- Paths are strips per segment with a disc at each bend. Every piece gets its own top height so pieces that
-- overlap at bends and junctions never share a plane (z-fighting).
local function layPaths(parent: Instance, def: Habitats.Habitat)
	local k = 0
	local function nextTop(): number
		k += 1
		return 0.16 + 0.011 * (k % 11)
	end
	for _, path in def.paths do
		local pts = path.points
		for i = 1, #pts - 1 do
			Build.strip(parent, path.id, pts[i], pts[i + 1], path.width, C.cobble, Enum.Material.Cobblestone, nextTop())
			if i > 1 then
				Props.disc(
					parent,
					path.id .. "Bend",
					pts[i],
					path.width / 2,
					nextTop(),
					C.cobble,
					Enum.Material.Cobblestone
				)
			end
		end
	end
end

-- Lanterns along the gate paths, alternating sides, so the way in and out is lit.
local function lightPaths(parent: Instance, def: Habitats.Habitat)
	for _, id in def.gatePaths do
		for _, path in def.paths do
			if path.id == id then
				local side = 1
				for i = 1, #path.points - 1 do
					local a, b = path.points[i], path.points[i + 1]
					local d = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
					local len = d.Magnitude
					local n = math.max(1, math.floor(len / 22))
					local perp = Vector3.new(-d.Z, 0, d.X).Unit
					for j = 0, n - 1 do
						local p = a + d * ((j + 0.5) / n) + perp * side * (path.width / 2 + 1.5)
						Props.lantern(parent, p.X, p.Z)
						side = -side
					end
				end
			end
		end
	end
end

local function nearLandmark(def: Habitats.Habitat, x: number, z: number, radius: number): boolean
	for _, lm in def.landmarks do
		if Vector3.new(lm.position.X - x, 0, lm.position.Z - z).Magnitude < radius then
			return true
		end
	end
	return false
end

local function inCrypt(def: Habitats.Habitat, x: number, z: number, margin: number): boolean
	local crypt = def.crypt
	if not crypt then
		return false
	end
	local r = crypt.rect
	return x > r.x1 - margin and x < r.x2 + margin and z > r.z1 - margin and z < r.z2 + margin
end

-- Free ground for scenery: in the footprint, off the plaza and paths, clear of gates, landmarks and crypt.
local function freeGround(def: Habitats.Habitat, x: number, z: number, clearance: number): boolean
	local plaza = def.plaza
	return HabitatRules.inFootprint(x, z, 5)
		and not (plaza and World.hubDistance(x, z) < plaza.radius + clearance + 2)
		and HabitatRules.pathClearance(def, x, z) > clearance
		and not HabitatRules.inGateCorridor(x, z)
		and not nearLandmark(def, x, z, 11)
		and not inCrypt(def, x, z, 6)
end

function Cemetery.build(def: Habitats.Habitat): Result
	local model = Instance.new("Model")
	model.Name = def.id
	model:SetAttribute("Habitat", def.id)
	local deco = Build.folder(model, "Decor")
	local rng = Random.new(1031)

	-- Ground: the footprint's soil (meets the hub wall), the plaza, then the paths on top.
	Props.disc(model, "HabitatGround", World.Hub.center, World.Hub.wallRadius, 0.12, C.dirt, Enum.Material.Ground)
	local plaza = def.plaza
	if plaza then
		Props.disc(model, "Plaza", plaza.center, plaza.radius, 0.15, C.cobble, Enum.Material.Cobblestone)
	end
	layPaths(Build.folder(model, "Paths"), def)
	lightPaths(deco, def)

	-- Landmarks (scenery and navigation, ADR-0007)
	local anchors: { [string]: BasePart } = {}
	local lmFolder = Build.folder(model, "Landmarks")
	for _, lm in def.landmarks do
		local builder = landmarkBuilders[lm.id]
		if builder then
			local m = Build.model(lmFolder, lm.id)
			local anchor = builder(m, lm.position)
			anchor.Name = "Anchor"
			Build.billboard(anchor, lm.name, Color3.fromRGB(230, 220, 255), 9, 90, 0.9)
			anchors[lm.id] = anchor
			m.PrimaryPart = anchor
		end
	end

	-- The Sealed Crypt
	local cryptGate: BasePart? = nil
	local crypt = def.crypt
	if crypt then
		local cryptFolder = Build.folder(model, "Crypt")
		cryptGate = Props.crypt(cryptFolder, crypt.rect, crypt.gateSide, crypt.gateAt, crypt.gateWidth)
		local gate = cryptGate :: BasePart
		local sign = Build.block(
			cryptFolder,
			"CryptSign",
			Vector3.new(0.4, 3, 6),
			gate.Position.X + 2,
			0,
			gate.Position.Z + crypt.gateWidth / 2 + 4,
			C.wood,
			Enum.Material.Wood
		)
		Build.billboard(sign, "Restored Manor owners only", Color3.fromRGB(255, 220, 160), 3, 60, 1.1)
	end

	-- Decorative mausoleums in Old Rows and the Hollow
	Props.mausoleum(deco, 88, -14, 0.8, "Mausoleum")
	Props.mausoleum(deco, -30, -86, 0.7, "Mausoleum")
	Props.mausoleum(deco, 30, -88, 0.7, "Mausoleum")

	-- Grave rows: a jittered grid over the free ground
	local tombs = Build.folder(model, "Tombstones")
	local r = World.Hub.moduleRadius
	for z = -r, r, 9 do
		for x = -r, r, 7 do
			local jx = x + rng:NextNumber(-1.5, 1.5)
			local jz = z + rng:NextNumber(-1.5, 1.5)
			if
				freeGround(def, jx, jz, 2.5)
				and freeGround(def, jx, jz + 3, 1.5) -- the grave mound in front of the stone
				and not World.inRect({ x1 = 82, x2 = 94, z1 = -22, z2 = -6 }, jx, jz) -- the Old Rows mausoleum
				and rng:NextNumber() < 0.42
			then
				Props.tombstone(tombs, rng, jx, jz)
			end
		end
	end
	-- Dead trees
	local placed = 0
	for _ = 1, 80 do
		local x = rng:NextNumber(-r, r)
		local z = rng:NextNumber(-r, r)
		if freeGround(def, x, z, 4) then
			Props.deadTree(deco, rng, x, z)
			placed += 1
			if placed >= 16 then
				break
			end
		end
	end
	-- Cold candles in dark zones, so they stay dark but navigable
	for _, zone in def.zones do
		if zone.dark and not zone.gated then
			for _ = 1, 6 do
				local x = rng:NextNumber(zone.rect.x1 + 4, zone.rect.x2 - 4)
				local z = rng:NextNumber(zone.rect.z1 + 4, zone.rect.z2 - 4)
				local candle =
					Build.block(deco, "GhostCandle", Vector3.new(0.4, 1.2, 0.4), x, 0, z, C.ghost, Enum.Material.Neon)
				Build.light(candle, C.ghost, 12, 0.8)
			end
		end
	end

	return { model = model, landmarkAnchors = anchors, cryptGate = cryptGate }
end

return Cemetery
