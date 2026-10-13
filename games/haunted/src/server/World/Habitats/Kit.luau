--!strict
-- Shared building steps for habitat modules (ADR-0007): footprint ground, plaza, paths with z-fight-free
-- heights, gate-path lanterns, landmark models with labels, free-ground tests for scenery and seeded
-- scatter. Each module (Cemetery, Woodland, SpiderWoodland, Settlement) adds its own props on top.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local World = require(Shared:WaitForChild("Config"):WaitForChild("World"))
local Habitats = require(Shared.Config:WaitForChild("Habitats"))
local HabitatRules = require(Shared:WaitForChild("Rules"):WaitForChild("HabitatRules"))
local Build = require(script.Parent.Parent.Build)
local Props = require(script.Parent.Parent.Props)

local Kit = {}

export type Result = {
	model: Model,
	landmarkAnchors: { [string]: BasePart },
	cryptGate: BasePart?,
}

export type LandmarkBuilder = (Instance, Vector3) -> BasePart

-- A new module model with the footprint ground (meets the hub wall) and the plaza.
function Kit.base(
	def: Habitats.Habitat,
	ground: Color3,
	groundMaterial: Enum.Material,
	plazaColor: Color3,
	plazaMaterial: Enum.Material
): Model
	local model = Instance.new("Model")
	model.Name = def.id
	model:SetAttribute("Habitat", def.id)
	Props.disc(model, "HabitatGround", World.Hub.center, World.Hub.wallRadius, 0.12, ground, groundMaterial)
	local plaza = def.plaza
	if plaza then
		Props.disc(model, "Plaza", plaza.center, plaza.radius, 0.15, plazaColor, plazaMaterial)
	end
	return model
end

-- Paths are strips per segment with a disc at each bend. Every piece gets its own top height so pieces that
-- overlap at bends and junctions never share a plane (z-fighting).
function Kit.layPaths(parent: Instance, def: Habitats.Habitat, color: Color3, material: Enum.Material)
	local k = 0
	local function nextTop(): number
		k += 1
		return 0.16 + 0.011 * (k % 11)
	end
	for _, path in def.paths do
		local pts = path.points
		for i = 1, #pts - 1 do
			Build.strip(parent, path.id, pts[i], pts[i + 1], path.width, color, material, nextTop())
			if i > 1 then
				Props.disc(parent, path.id .. "Bend", pts[i], path.width / 2, nextTop(), color, material)
			end
		end
	end
end

-- Lanterns along the gate paths, alternating sides, so the way in and out is lit.
function Kit.lightPaths(parent: Instance, def: Habitats.Habitat)
	for _, id in def.gatePaths do
		for _, path in def.paths do
			if path.id == id then
				local side = 1
				for i = 1, #path.points - 1 do
					local a, b = path.points[i], path.points[i + 1]
					local d = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
					local n = math.max(1, math.floor(d.Magnitude / 22))
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

-- Landmark models with their labels. A landmark without a builder is skipped (and reported by the caller's
-- tests, since every module names a builder for each of its landmarks).
function Kit.landmarks(
	model: Model,
	def: Habitats.Habitat,
	builders: { [string]: LandmarkBuilder }
): { [string]: BasePart }
	local anchors: { [string]: BasePart } = {}
	local folder = Build.folder(model, "Landmarks")
	for _, lm in def.landmarks do
		local builder = builders[lm.id]
		if builder then
			local m = Build.model(folder, lm.id)
			local anchor = builder(m, lm.position)
			anchor.Name = "Anchor"
			Build.billboard(anchor, lm.name, Color3.fromRGB(230, 220, 255), 9, 90, 0.9)
			anchors[lm.id] = anchor
			m.PrimaryPart = anchor
		end
	end
	return anchors
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

-- Clear of every gate corridor by `margin` studs: the centre and four points around it (a prop's reach), so
-- long scenery never pokes into a corridor (AUD-20261012-TASK-0027-01 finding 1).
local function clearOfCorridors(x: number, z: number, margin: number): boolean
	for _, o in { { 0, 0 }, { margin, 0 }, { -margin, 0 }, { 0, margin }, { 0, -margin } } do
		if HabitatRules.inGateCorridor(x + o[1], z + o[2]) then
			return false
		end
	end
	return true
end

-- Free ground for scenery: in the footprint, off the plaza and paths, clear of gates, landmarks and crypt.
-- `clearance` is the prop's reach from its centre.
function Kit.freeGround(def: Habitats.Habitat, x: number, z: number, clearance: number): boolean
	local plaza = def.plaza
	return HabitatRules.inFootprint(x, z, 5)
		and not (plaza and World.hubDistance(x, z) < plaza.radius + clearance + 2)
		and HabitatRules.pathClearance(def, x, z) > clearance
		and clearOfCorridors(x, z, clearance)
		and not nearLandmark(def, x, z, 11)
		and not inCrypt(def, x, z, 6)
end

-- False within `radius` of a spawn zone's centre, so scenery never blocks the spot scenarios walk to.
function Kit.clearOfZoneCentres(def: Habitats.Habitat, x: number, z: number, radius: number): boolean
	for _, zone in def.zones do
		local r = zone.rect
		if Vector3.new((r.x1 + r.x2) / 2 - x, 0, (r.z1 + r.z2) / 2 - z).Magnitude < radius then
			return false
		end
	end
	return true
end

-- Up to `count` props on free ground, placed by `place(x, z)` at seeded random spots.
function Kit.scatter(
	def: Habitats.Habitat,
	rng: Random,
	count: number,
	clearance: number,
	place: (number, number) -> ()
): number
	local r = World.Hub.moduleRadius
	local placed = 0
	for _ = 1, count * 6 do
		local x = rng:NextNumber(-r, r)
		local z = rng:NextNumber(-r, r)
		if Kit.freeGround(def, x, z, clearance) then
			place(x, z)
			placed += 1
			if placed >= count then
				break
			end
		end
	end
	return placed
end

-- Low green ground mist (TASK-0028): soft, overlapping, see-through discs that never collide or block a
-- raycast. The sky carries the purple (Atmosphere), the mist carries the green (map reference 3).
-- Low rolling ground mist (TASK-0044): soft Smoke puffs hugging the ground instead of flat discs.
function Kit.mist(parent: Instance, rng: Random, count: number, color: Color3)
	local folder = Build.folder(parent, "Mist")
	local r = World.Hub.moduleRadius - 10
	for _ = 1, count do
		-- Same draws as the old disc builder: radius, x, z, then one more when inside.
		local size = rng:NextNumber(10, 22)
		local x, z = rng:NextNumber(-r, r), rng:NextNumber(-r, r)
		if World.hubDistance(x, z) < r then
			local k = rng:NextNumber()
			local anchor = Build.part({
				name = "Mist",
				size = Vector3.new(1, 1, 1),
				cframe = CFrame.new(x, 0.4, z),
				transparency = 1,
				collide = false,
				parent = folder,
			})
			anchor.CanQuery = false
			anchor.CanTouch = false
			local smoke = Instance.new("Smoke")
			smoke.Color = color
			smoke.Opacity = 0.05 + 0.04 * k
			smoke.RiseVelocity = 0.1 + 0.3 * (1 - k)
			smoke.Size = math.min(size * 0.8, 18)
			smoke.TimeScale = 0.35
			smoke.Parent = anchor
		end
	end
end

-- Cold candles in dark zones, so they stay dark but navigable.
function Kit.darkCandles(parent: Instance, def: Habitats.Habitat, rng: Random, color: Color3)
	for _, zone in def.zones do
		if zone.dark and not zone.gated then
			for _ = 1, 6 do
				local x = rng:NextNumber(zone.rect.x1 + 4, zone.rect.x2 - 4)
				local z = rng:NextNumber(zone.rect.z1 + 4, zone.rect.z2 - 4)
				if HabitatRules.pathClearance(def, x, z) > 1 and not nearLandmark(def, x, z, 8) then
					-- Art (TASK-0044): a dripping candle cluster burning in the habitat's ghost colour.
					Build.artSlot(
						parent,
						"candles",
						CFrame.new(x, 0, z) * CFrame.Angles(0, math.rad((x * 13.7 + z * 7.1) % 360), 0),
						{ Tint_Flames = color, ArtCull = 180 }
					)
					local glow = Build.part({
						name = "GhostCandle",
						size = Vector3.new(0.3, 0.3, 0.3),
						cframe = CFrame.new(x, 1.4, z),
						transparency = 1,
						collide = false,
						parent = parent,
					})
					glow.CanQuery = false
					Build.light(glow, color, 12, 0.8)
				end
			end
		end
	end
end

return Kit
