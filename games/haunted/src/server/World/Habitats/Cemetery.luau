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
local Kit = require(script.Parent.Kit)

local Cemetery = {}

export type Result = Kit.Result

local C = Props.C

local landmarkBuilders: { [string]: Kit.LandmarkBuilder } = {
	Angel = Props.angel,
	Hearse = Props.hearse,
	OldWell = Props.well,
	BellTower = Props.bellTower,
	Mausoleum = function(parent: Instance, pos: Vector3): BasePart
		return Props.mausoleum(parent, pos.X, pos.Z, 1.3, "HollowMausoleum")
	end,
}

local function pathById(def: Habitats.Habitat, id: string): Habitats.Path?
	for _, p in def.paths do
		if p.id == id then
			return p
		end
	end
	return nil
end

-- A point `t` (0-1) along segment i of `path`, pushed `offset` studs to its side (+ = left of travel).
local function along(path: Habitats.Path, i: number, t: number, offset: number): Vector3
	local a, b = path.points[i], path.points[i + 1]
	local d = Vector3.new(b.X - a.X, 0, b.Z - a.Z).Unit
	return a:Lerp(b, t) + Vector3.new(-d.Z, 0, d.X) * offset
end

-- The finished vignette (TASK-0028, the quality benchmark): the South Path from its gate to the Weeping
-- Angel, plus the Old Rows loop as the side route. An iron gate arch at the entrance, short fences framing
-- the first stretch, edge stones, moss, carved pumpkins and grave candles along a lit walk, and ruined
-- masonry by the side route. Returns the spots it used, so the grave grid and trees keep clear of them.
local function vignette(parent: Instance, def: Habitats.Habitat, rng: Random): { { at: Vector3, r: number } }
	local used: { { at: Vector3, r: number } } = {}
	local function use(at: Vector3, r: number)
		table.insert(used, { at = at, r = r })
	end
	local main = pathById(def, "SouthPath")
	local side = pathById(def, "OldRowsLoop")
	if not (main and side) then
		return used
	end
	local w = main.width
	-- Gate arch where the path enters the cemetery proper, and fences framing the first stretch.
	local gateAt = along(main, 1, 0.6, 0)
	Props.cemeteryGate(parent, gateAt, main.points[2] - main.points[1], w + 2)
	use(gateAt, w / 2 + 5)
	local posts = {}
	for _, sideSign in { -1, 1 } do
		local a = along(main, 1, 0.66, sideSign * (w / 2 + 2.5))
		local b = along(main, 1, 0.94, sideSign * (w / 2 + 2.5))
		Props.fenceLine(parent, a, b, posts)
		use((a + b) / 2, 7)
	end
	-- Edge stones on the main path and the side route; moss patches softening the edges.
	for _, path in { main, side } do
		for i = 1, #path.points - 1 do
			Props.curbStones(parent, path.points[i], path.points[i + 1], path.width, rng)
			for k = 1, 3 do
				local sideSign = if (i + k) % 2 == 0 then 1 else -1
				local p = along(path, i, k / 4, sideSign * (path.width / 2 + 2))
				if HabitatRules.pathClearance(def, p.X, p.Z) > 0.5 then
					Props.mossPatch(parent, p.X, p.Z, rng:NextNumber(1.8, 3), 0.13 + 0.002 * k)
				end
			end
		end
	end
	-- Carved pumpkins and grave candles beside the walk to the Angel (a few lit, within the light budget).
	local n = 0
	for i = 1, #main.points - 1 do
		for _, t in { 0.3, 0.75 } do
			n += 1
			local sideSign = if n % 2 == 0 then 1 else -1
			local p = along(main, i, t, sideSign * (w / 2 + 2.2))
			if HabitatRules.pathClearance(def, p.X, p.Z) > 0.8 then
				Props.pumpkin(parent, p.X, p.Z, rng:NextNumber(1.6, 2.4), rng:NextNumber(-30, 30), n % 2 == 1)
				use(p, 2.5)
			end
			local q = along(main, i, t + 0.12, -sideSign * (w / 2 + 3.5))
			if HabitatRules.pathClearance(def, q.X, q.Z) > 1.5 then
				Props.candles(parent, rng, q.X, q.Z, n % 3 == 0)
				use(q, 2)
			end
		end
	end
	-- Ruined masonry along the side route
	for i = 1, #side.points - 1, 2 do
		local p = along(side, i, 0.5, 7)
		if Kit.freeGround(def, p.X, p.Z, 4) then
			local d = side.points[i + 1] - side.points[i]
			Props.ruinedWall(parent, rng, p.X, p.Z, math.deg(math.atan2(d.X, d.Z)) + 90)
			use(p, 7)
		end
	end
	return used
end

local function clearOf(used: { { at: Vector3, r: number } }, x: number, z: number): boolean
	for _, u in used do
		if Vector3.new(u.at.X - x, 0, u.at.Z - z).Magnitude < u.r + 1.5 then
			return false
		end
	end
	return true
end

function Cemetery.build(def: Habitats.Habitat): Result
	-- Ground: dark moss over the footprint (meets the hub wall), the plaza, then the paths on top.
	local model = Kit.base(def, Color3.fromRGB(40, 54, 42), Enum.Material.Grass, C.cobble, Enum.Material.Cobblestone)
	local deco = Build.folder(model, "Decor")
	local rng = Random.new(1031)
	Kit.layPaths(Build.folder(model, "Paths"), def, C.cobble, Enum.Material.Cobblestone)
	Kit.lightPaths(deco, def)

	-- Landmarks (scenery and navigation, ADR-0007)
	local anchors = Kit.landmarks(model, def, landmarkBuilders)
	local used = vignette(Build.folder(model, "Vignette"), def, Random.new(4028))

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
				Kit.freeGround(def, jx, jz, 2.5)
				and Kit.freeGround(def, jx, jz + 3, 1.5) -- the grave mound in front of the stone
				and not World.inRect({ x1 = 82, x2 = 94, z1 = -22, z2 = -6 }, jx, jz) -- the Old Rows mausoleum
				and clearOf(used, jx, jz)
				and clearOf(used, jx, jz + 3)
				and rng:NextNumber() < 0.42
			then
				Props.tombstone(tombs, rng, jx, jz)
			end
		end
	end
	-- Dead trees
	Kit.scatter(def, rng, 16, 4, function(x, z)
		if clearOf(used, x, z) then
			Props.deadTree(deco, rng, x, z)
		end
	end)
	-- Cold candles in dark zones, so they stay dark but navigable
	Kit.darkCandles(deco, def, rng, C.ghost)
	Kit.mist(model, Random.new(77), 34, Color3.fromRGB(110, 235, 150))

	return { model = model, landmarkAnchors = anchors, cryptGate = cryptGate }
end

return Cemetery
