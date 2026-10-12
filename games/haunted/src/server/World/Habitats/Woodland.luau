--!strict
-- Cursed Woodland habitat module (ADR-0007, TASK-0027 blockout): grass and dirt trails under dark pines,
-- a ring of standing stones in the central clearing, the Hollow Oak in the black thicket to the north, and
-- hound dens east and west. Built-in parts only; deterministic (seeded) like the cemetery.

local Build = require(script.Parent.Parent.Build)
local Props = require(script.Parent.Parent.Props)
local Kit = require(script.Parent.Kit)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Habitats = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Habitats"))

local Woodland = {}

local C = {
	grass = Color3.fromRGB(34, 48, 34),
	moss = Color3.fromRGB(46, 62, 40),
	trail = Color3.fromRGB(86, 70, 52),
	bark = Color3.fromRGB(52, 38, 28),
	pine = Color3.fromRGB(28, 54, 36),
	stone = Color3.fromRGB(96, 98, 92),
	den = Color3.fromRGB(40, 34, 28),
	eye = Color3.fromRGB(255, 120, 60),
}

-- A ring of tall slabs round a flat altar (the anchor). Gaps between slabs keep the clearing walkable.
local function standingStones(parent: Instance, pos: Vector3): BasePart
	local altar = Build.block(parent, "Altar", Vector3.new(5, 1.6, 3), pos.X, 0, pos.Z, C.stone, Enum.Material.Slate)
	for i = 0, 6 do
		local a = math.rad(i * 360 / 7 + 10)
		local x, z = pos.X + math.sin(a) * 10, pos.Z + math.cos(a) * 10
		local h = if i % 2 == 0 then 11 else 8
		Build.block(parent, "Stone", Vector3.new(3, h, 1.6), x, 0, z, C.stone, Enum.Material.Slate, math.deg(a))
	end
	return altar
end

-- A huge oak with a split trunk, splayed roots and a few heavy limbs (the anchor is the trunk).
local function hollowOak(parent: Instance, pos: Vector3): BasePart
	local trunk = Build.block(parent, "Trunk", Vector3.new(8, 28, 8), pos.X, 0, pos.Z - 2, C.bark, Enum.Material.Wood)
	-- The hollow: a dark opening facing the clearing (south, +Z).
	Build.part({
		name = "Hollow",
		size = Vector3.new(3.6, 6, 0.4),
		cframe = CFrame.new(pos.X, 3.2, pos.Z + 2.1),
		color = Color3.fromRGB(10, 8, 8),
		material = Enum.Material.SmoothPlastic,
		collide = false,
		parent = parent,
	})
	for i = 0, 5 do
		local a = math.rad(i * 60 + 15)
		Build.part({
			name = "Root",
			size = Vector3.new(2, 2, 9),
			cframe = CFrame.new(pos.X + math.sin(a) * 6, 0.6, pos.Z - 2 + math.cos(a) * 6)
				* CFrame.Angles(0, a, 0)
				* CFrame.Angles(math.rad(12), 0, 0),
			color = C.bark,
			material = Enum.Material.Wood,
			parent = parent,
		})
	end
	for i = 0, 3 do
		local a = math.rad(i * 90 + 40)
		Build.part({
			name = "Limb",
			size = Vector3.new(2.4, 2.4, 16),
			cframe = CFrame.new(pos.X, 22 + i, pos.Z - 2)
				* CFrame.Angles(0, a, 0)
				* CFrame.Angles(math.rad(-25), 0, 0)
				* CFrame.new(0, 0, -8),
			color = C.bark,
			material = Enum.Material.Wood,
			collide = false,
			parent = parent,
		})
	end
	Build.part({
		name = "Canopy",
		size = Vector3.new(26, 8, 26),
		cframe = CFrame.new(pos.X, 31, pos.Z - 2),
		color = C.pine,
		material = Enum.Material.LeafyGrass,
		collide = false,
		parent = parent,
	})
	return trunk
end

local function pine(parent: Instance, rng: Random, x: number, z: number)
	local h = rng:NextNumber(14, 22)
	Build.block(parent, "PineTrunk", Vector3.new(1.4, h, 1.4), x, 0, z, C.bark, Enum.Material.Wood)
	for i = 0, 2 do
		local w = (3 - i) * rng:NextNumber(2.6, 3.4)
		Build.part({
			name = "PineTier",
			size = Vector3.new(w, 4, w),
			cframe = CFrame.new(x, h * 0.45 + i * 3.6, z) * CFrame.Angles(0, math.rad(rng:NextNumber(0, 90)), 0),
			color = C.pine,
			material = Enum.Material.LeafyGrass,
			collide = false,
			parent = parent,
		})
	end
end

local function boulder(parent: Instance, rng: Random, x: number, z: number)
	local s = rng:NextNumber(3, 6)
	Build.part({
		name = "Boulder",
		size = Vector3.new(s * 1.3, s * 0.8, s),
		cframe = CFrame.new(x, s * 0.3, z)
			* CFrame.Angles(0, math.rad(rng:NextNumber(0, 180)), math.rad(rng:NextNumber(-8, 8))),
		color = C.stone,
		material = Enum.Material.Slate,
		parent = parent,
	})
end

local function fallenLog(parent: Instance, rng: Random, x: number, z: number)
	Build.part({
		name = "FallenLog",
		size = Vector3.new(2, 2, rng:NextNumber(9, 14)),
		cframe = CFrame.new(x, 1, z) * CFrame.Angles(0, math.rad(rng:NextNumber(0, 180)), 0),
		color = C.bark,
		material = Enum.Material.Wood,
		parent = parent,
	})
end

-- A hound den: an earth mound with a dark mouth and two glowing eyes inside.
local function den(parent: Instance, x: number, z: number, facing: number)
	local cf = CFrame.new(x, 0, z) * CFrame.Angles(0, math.rad(facing), 0)
	Build.part({
		name = "DenMound",
		size = Vector3.new(10, 5, 8),
		cframe = cf * CFrame.new(0, 2.5, 0),
		color = C.den,
		material = Enum.Material.Ground,
		parent = parent,
	})
	Build.part({
		name = "DenMouth",
		size = Vector3.new(4, 3, 0.4),
		cframe = cf * CFrame.new(0, 1.5, -4.1),
		color = Color3.fromRGB(8, 6, 6),
		collide = false,
		parent = parent,
	})
	for _, dx in { -0.7, 0.7 } do
		Build.part({
			name = "DenEye",
			size = Vector3.new(0.4, 0.3, 0.2),
			cframe = cf * CFrame.new(dx, 2, -4.4),
			color = C.eye,
			material = Enum.Material.Neon,
			collide = false,
			parent = parent,
		})
	end
end

function Woodland.build(def: Habitats.Habitat): Kit.Result
	local model = Kit.base(def, C.grass, Enum.Material.Grass, C.moss, Enum.Material.LeafyGrass)
	local deco = Build.folder(model, "Decor")
	local rng = Random.new(2027)
	Kit.layPaths(Build.folder(model, "Paths"), def, C.trail, Enum.Material.Ground)
	Kit.lightPaths(deco, def)
	local anchors = Kit.landmarks(model, def, { StandingStones = standingStones, HollowOak = hollowOak })

	local function open(x: number, z: number): boolean
		return Kit.clearOfZoneCentres(def, x, z, 7)
	end
	Kit.scatter(def, rng, 46, 3, function(x, z)
		if open(x, z) then
			pine(deco, rng, x, z)
		end
	end)
	Kit.scatter(def, rng, 12, 3, function(x, z)
		if open(x, z) then
			boulder(deco, rng, x, z)
		end
	end)
	Kit.scatter(def, rng, 6, 8, function(x, z)
		if open(x, z) then
			fallenLog(deco, rng, x, z)
		end
	end)
	den(deco, 76, 48, 200)
	den(deco, 44, 12, 160)
	den(deco, -76, 48, 160)
	den(deco, -44, 12, 200)
	Props.deadTree(deco, rng, 20, -60)
	Props.deadTree(deco, rng, -20, -60)
	Kit.darkCandles(deco, def, rng, Color3.fromRGB(120, 255, 150))
	Kit.mist(model, Random.new(77), 24, Color3.fromRGB(110, 230, 150))
	return { model = model, landmarkAnchors = anchors, cryptGate = nil }
end

return Woodland
