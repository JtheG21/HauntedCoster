--!strict
-- Ghost Cemetery habitat module (ADR-0007): the M1 graveyard's props re-laid inside the hub footprint.
-- A central plaza at the Weeping Angel, three gate paths, two side routes, grave rows in the sectors
-- between them, and the Sealed Crypt beside the Bell Tower. Deterministic (seeded), so every server
-- builds the same cemetery. TASK-0028 details it into the visual benchmark.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local World = require(Shared:WaitForChild("Config"):WaitForChild("World"))
local Habitats = require(Shared.Config:WaitForChild("Habitats"))
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

function Cemetery.build(def: Habitats.Habitat): Result
	-- Ground: the footprint's soil (meets the hub wall), the plaza, then the paths on top.
	local model = Kit.base(def, C.dirt, Enum.Material.Ground, C.cobble, Enum.Material.Cobblestone)
	local deco = Build.folder(model, "Decor")
	local rng = Random.new(1031)
	Kit.layPaths(Build.folder(model, "Paths"), def, C.cobble, Enum.Material.Cobblestone)
	Kit.lightPaths(deco, def)

	-- Landmarks (scenery and navigation, ADR-0007)
	local anchors = Kit.landmarks(model, def, landmarkBuilders)

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
				and rng:NextNumber() < 0.42
			then
				Props.tombstone(tombs, rng, jx, jz)
			end
		end
	end
	-- Dead trees
	Kit.scatter(def, rng, 16, 4, function(x, z)
		Props.deadTree(deco, rng, x, z)
	end)
	-- Cold candles in dark zones, so they stay dark but navigable
	Kit.darkCandles(deco, def, rng, C.ghost)

	return { model = model, landmarkAnchors = anchors, cryptGate = cryptGate }
end

return Cemetery
