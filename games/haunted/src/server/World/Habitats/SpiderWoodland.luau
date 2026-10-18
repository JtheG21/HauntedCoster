--!strict
-- Spider Woodland habitat module (ADR-0007, TASK-0027 blockout): dark leaf litter and pale silk trails
-- between dead trees hung with web sheets, the Brood Tree's nest to the north and a cluster of cocoons in
-- the west hollow. Webs and cocoons don't collide, so trails and zones stay walkable. Built-in parts only.

local Build = require(script.Parent.Parent.Build)
local Props = require(script.Parent.Parent.Props)
local Kit = require(script.Parent.Kit)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Habitats = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Habitats"))

local SpiderWoodland = {}

local C = {
	litter = Color3.fromRGB(40, 36, 44),
	silk = Color3.fromRGB(150, 148, 140),
	glade = Color3.fromRGB(56, 52, 58),
	bark = Color3.fromRGB(38, 32, 34),
	web = Color3.fromRGB(225, 225, 235),
	cocoon = Color3.fromRGB(210, 205, 190),
	eye = Color3.fromRGB(255, 40, 40),
}

local function webSheet(parent: Instance, a: Vector3, b: Vector3, height: number, bottom: number?)
	local mid = (a + b) / 2
	local d = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
	local len = d.Magnitude
	if len < 1 then
		return
	end
	-- Art (TASK-0044): a torn radial web stretched across the gap; non-colliding as before.
	Build.artSlot(
		parent,
		"web_sheet",
		CFrame.fromMatrix(Vector3.new(mid.X, height / 2 + (bottom or 3), mid.Z), d.Unit, Vector3.yAxis),
		{ ArtStretchX = len / 8, ArtStretchY = height / 6 }
	)
end

local function cocoon(parent: Instance, x: number, z: number, size: number, hang: number?)
	Build.artSlot(parent, "cocoon", CFrame.new(x, hang or 0, z), { ArtScale = size })
end

-- A giant dead tree (art TASK-0045, `landmark_broodtree`): a pale silk-whitened trunk with four limbs drooping
-- along the diagonals, torn webs strung between the limb tips, red eyes in the hollow and cocoons hanging below.
local function broodTree(parent: Instance, pos: Vector3): BasePart
	local trunk = Build.collider(parent, "Trunk", Vector3.new(7, 30, 7), CFrame.new(pos.X, 15, pos.Z))
	Build.artSlot(parent, "landmark_broodtree", CFrame.new(pos.X, 0, pos.Z) * CFrame.Angles(0, math.pi, 0))
	trunk:SetAttribute("LabelHeight", 21) -- the anchor sits at 15; the art tops out at 33
	local tips: { Vector3 } = {}
	for i = 0, 3 do
		local a = math.rad(i * 90 + 45)
		local cf = CFrame.new(pos.X, 24, pos.Z) * CFrame.Angles(0, a, 0) * CFrame.Angles(math.rad(-30), 0, 0)
		table.insert(tips, (cf * CFrame.new(0, 0, -17)).Position)
	end
	for i = 1, 4 do
		local a, b = tips[i], tips[i % 4 + 1]
		webSheet(parent, a, b, 10, a.Y - 9) -- hung from the drooping tips
	end
	for _, dx in { -1.2, 1.2 } do
		Build.part({
			name = "Eye",
			size = Vector3.new(0.6, 0.6, 0.2),
			cframe = CFrame.new(pos.X + dx * 0.8, 6, pos.Z + 2.9),
			color = C.eye,
			material = Enum.Material.Neon,
			collide = false,
			parent = parent,
		})
	end
	-- Cocoons hanging from the limbs
	for i, tip in tips do
		cocoon(parent, tip.X * 0.7 + pos.X * 0.3, tip.Z * 0.7 + pos.Z * 0.3, 1.6 + i * 0.2, 10)
	end
	return trunk
end

-- A broken stump with a heap of cocoons round it (the anchor is the stump).
local function cocoonCluster(parent: Instance, pos: Vector3): BasePart
	local stump = Build.collider(parent, "Stump", Vector3.new(4, 6, 4), CFrame.new(pos.X, 3, pos.Z))
	Build.artSlot(parent, "stump_broken", CFrame.new(pos.X, 0, pos.Z))
	local spots = { { 4, 1, 2.2 }, { -3.5, 2.5, 2.6 }, { 1, -4, 1.8 }, { -2, -3.5, 2.4 }, { 3.5, -2, 1.6 } }
	for _, s in spots do
		cocoon(parent, pos.X + s[1], pos.Z + s[2], s[3])
	end
	webSheet(parent, pos + Vector3.new(-6, 0, -4), pos + Vector3.new(6, 0, -4), 8)
	return stump
end

function SpiderWoodland.build(def: Habitats.Habitat): Kit.Result
	local model = Kit.base(def, C.litter, Enum.Material.Ground, C.glade, Enum.Material.Slate)
	local deco = Build.folder(model, "Decor")
	local rng = Random.new(2029)
	Kit.layPaths(Build.folder(model, "Paths"), def, C.silk, Enum.Material.Sand)
	Kit.lightPaths(deco, def)
	local anchors = Kit.landmarks(model, def, { BroodTree = broodTree, CocoonCluster = cocoonCluster })

	-- Dead trees, with a web sheet to the previous tree when it is close enough.
	local last: Vector3? = nil
	Kit.scatter(def, rng, 40, 3, function(x, z)
		if not Kit.clearOfZoneCentres(def, x, z, 7) then
			return
		end
		Props.deadTree(deco, rng, x, z)
		local here = Vector3.new(x, 0, z)
		if last and (last - here).Magnitude < 22 and Kit.freeGround(def, (x + last.X) / 2, (z + last.Z) / 2, 1) then
			webSheet(deco, last, here, rng:NextNumber(6, 10))
		end
		last = here
	end)
	Kit.scatter(def, rng, 14, 2, function(x, z)
		if Kit.clearOfZoneCentres(def, x, z, 6) then
			cocoon(deco, x, z, rng:NextNumber(1.2, 2.2))
		end
	end)
	Kit.darkCandles(deco, def, rng, Color3.fromRGB(200, 60, 60))
	Kit.mist(model, Random.new(77), 24, Color3.fromRGB(120, 220, 160))
	return { model = model, landmarkAnchors = anchors, cryptGate = nil }
end

return SpiderWoodland
