--!strict
-- Zombie Settlement habitat module (ADR-0007, TASK-0027 blockout): a ruined village on muddy ground.
-- Straight roads meet at the cobbled square; ploughed farm rows lie east, the roofless Ruined Chapel
-- west and the Old Barn north, with broken cottages and fences between. Built-in parts only.

local Build = require(script.Parent.Parent.Build)
local Kit = require(script.Parent.Kit)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Habitats = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Habitats"))

local Settlement = {}

local C = {
	mud = Color3.fromRGB(66, 58, 46),
	road = Color3.fromRGB(96, 84, 66),
	square = Color3.fromRGB(88, 86, 84),
	wall = Color3.fromRGB(120, 112, 100),
	timber = Color3.fromRGB(70, 50, 36),
	roof = Color3.fromRGB(60, 40, 36),
	furrow = Color3.fromRGB(52, 42, 32),
	hay = Color3.fromRGB(170, 140, 70),
}

-- A wall segment: art stretched along it (ruined brick by default, `barn_wall` planks for the barn; TASK-0044/45)
-- over the old box collider.
local WALL_ART = { settle_wall = 5.6, barn_wall = 12 } -- asset key -> authored height (each is 8 long)
local function wall(parent: Instance, a: Vector3, b: Vector3, height: number, _color: Color3, key: string?)
	local d = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
	local len = d.Magnitude
	local mid = (a + b) / 2
	local art = key or "settle_wall"
	Build.artSlot(
		parent,
		art,
		CFrame.fromMatrix(Vector3.new(mid.X, 0, mid.Z), d.Unit, Vector3.yAxis),
		{ ArtStretchX = len / 8, ArtStretchY = height / WALL_ART[art] }
	)
	return Build.collider(
		parent,
		"Wall",
		Vector3.new(1, height, len),
		CFrame.lookAt(Vector3.new(mid.X, height / 2, mid.Z), Vector3.new(b.X, height / 2, b.Z))
	)
end

-- The chapel: roofless broken walls, a door facing the square (east) and a steeple stub at the west end.
local function ruinedChapel(parent: Instance, pos: Vector3): BasePart
	local x1, x2, z1, z2 = pos.X - 7, pos.X + 7, pos.Z - 11, pos.Z + 11
	local function v(x: number, z: number): Vector3
		return Vector3.new(x, 0, z)
	end
	-- Long walls with a collapsed gap each, the west wall, and the east wall either side of the door.
	wall(parent, v(x1, z1), v(x1 + 6, z1), 10, C.wall)
	wall(parent, v(x1 + 9, z1), v(x2, z1), 6, C.wall)
	wall(parent, v(x1, z2), v(x1 + 4, z2), 9, C.wall)
	wall(parent, v(x1 + 8, z2), v(x2, z2), 10, C.wall)
	wall(parent, v(x1, z1), v(x1, z2), 10, C.wall)
	wall(parent, v(x2, z1), v(x2, pos.Z - 3), 10, C.wall)
	wall(parent, v(x2, pos.Z + 3), v(x2, z2), 8, C.wall)
	-- Art (TASK-0045): a brick steeple with an open belfry and a snapped spire, and charred fallen beams.
	local steeple = Build.collider(parent, "Steeple", Vector3.new(5, 22, 5), CFrame.new(x1 + 3, 11, pos.Z))
	Build.artSlot(parent, "chapel_steeple", CFrame.new(x1 + 3, 0, pos.Z) * CFrame.Angles(0, math.rad(-90), 0))
	steeple:SetAttribute("LabelHeight", 18) -- anchor at 11; spire and finial reach about 27
	for i = 0, 2 do
		local cf = CFrame.new(pos.X + 1 + i * 2, 0.5 + i * 0.4, pos.Z - 4 + i * 4)
			* CFrame.Angles(math.rad(8), math.rad(30 + i * 40), 0)
		Build.artSlot(parent, "beam_fallen", cf * CFrame.new(0, -0.5, 0))
	end
	return steeple
end

-- The barn: open to the square (south, +Z), with a sagging two-slope roof (the anchor is the back wall).
local function oldBarn(parent: Instance, pos: Vector3): BasePart
	local x1, x2, z1, z2 = pos.X - 9, pos.X + 9, pos.Z - 8, pos.Z + 8
	local back = wall(parent, Vector3.new(x1, 0, z1), Vector3.new(x2, 0, z1), 12, C.timber, "barn_wall")
	for _, x in { x1, x2 } do
		wall(parent, Vector3.new(x, 0, z1), Vector3.new(x, 0, z2), 12, C.timber, "barn_wall")
	end
	-- Art (TASK-0045): a sagging shingle roof with torn rafters, and a tied hay bale.
	for _, s in { -1, 1 } do
		local cf = CFrame.new(pos.X + s * 4.6, 15, pos.Z) * CFrame.Angles(0, 0, math.rad(-s * 35))
		Build.collider(parent, "Roof", Vector3.new(11, 0.8, 18), cf)
		Build.artSlot(parent, "barn_roof", if s < 0 then cf else cf * CFrame.Angles(0, math.pi, 0))
	end
	Build.collider(parent, "HayBale", Vector3.new(4, 3, 3), CFrame.new(pos.X - 5, 1.5, pos.Z - 5))
	Build.artSlot(parent, "hay_bale", CFrame.new(pos.X - 5, 0, pos.Z - 5) * CFrame.Angles(0, math.rad(8), 0))
	return back
end

-- A roofless cottage: three walls, the open side facing `yaw`.
local function cottage(parent: Instance, rng: Random, x: number, z: number)
	local yaw = math.rad(rng:NextNumber(0, 360))
	local cf = CFrame.new(x, 0, z) * CFrame.Angles(0, yaw, 0)
	local function p(lx: number, lz: number): Vector3
		return (cf * CFrame.new(lx, 0, lz)).Position
	end
	wall(parent, p(-4, -4), p(4, -4), rng:NextNumber(5, 8), C.wall)
	wall(parent, p(-4, -4), p(-4, 4), rng:NextNumber(3, 7), C.wall)
	wall(parent, p(4, -4), p(4, 2), rng:NextNumber(4, 7), C.wall)
end

local function brokenFence(parent: Instance, rng: Random, x: number, z: number)
	local cf = CFrame.new(x, 0, z) * CFrame.Angles(0, math.rad(rng:NextNumber(0, 180)), 0)
	-- Same draws as the old post-by-post builder, so the settlement layout is unchanged.
	-- Posts collide where the old builder put them (gaps kept); the rail never collided.
	for i = -2, 2 do
		if rng:NextNumber() < 0.75 then
			rng:NextNumber()
			Build.collider(parent, "FencePost", Vector3.new(0.5, 3.5, 0.5), cf * CFrame.new(i * 2.5, 1.75, 0))
		end
	end
	rng:NextNumber()
	Build.artSlot(parent, "fence_wood", cf)
end

function Settlement.build(def: Habitats.Habitat): Kit.Result
	local model = Kit.base(def, C.mud, Enum.Material.Mud, C.square, Enum.Material.Cobblestone)
	local deco = Build.folder(model, "Decor")
	local rng = Random.new(2031)
	Kit.layPaths(Build.folder(model, "Paths"), def, C.road, Enum.Material.Ground)
	Kit.lightPaths(deco, def)
	local anchors = Kit.landmarks(model, def, { RuinedChapel = ruinedChapel, OldBarn = oldBarn })

	-- Ploughed rows across the farm (low and non-colliding, so they never block a walk).
	local farm = def.zones[1].rect
	for _, zone in def.zones do
		if zone.id == "Farm" then
			farm = zone.rect
		end
	end
	for z = farm.z1 + 3, farm.z2 - 3, 4 do
		local a, b = Vector3.new(farm.x1 + 2, 0, z), Vector3.new(farm.x2 - 2, 0, z)
		if
			Kit.freeGround(def, a.X, z, 1)
			and Kit.freeGround(def, b.X, z, 1)
			and Kit.freeGround(def, (a.X + b.X) / 2, z, 1)
		then
			local furrow = Build.strip(deco, "Furrow", a, b, 1.6, C.furrow, Enum.Material.Ground, 0.45)
			furrow.CanCollide = false
		end
	end
	Kit.scatter(def, rng, 7, 7, function(x, z)
		if Kit.clearOfZoneCentres(def, x, z, 10) then
			cottage(deco, rng, x, z)
		end
	end)
	Kit.scatter(def, rng, 10, 3, function(x, z)
		if Kit.clearOfZoneCentres(def, x, z, 6) then
			brokenFence(deco, rng, x, z)
		end
	end)
	Kit.scatter(def, rng, 8, 2, function(x, z)
		if Kit.clearOfZoneCentres(def, x, z, 6) then
			Build.block(
				deco,
				"HayBale",
				Vector3.new(4, 3, 3),
				x,
				0,
				z,
				C.hay,
				Enum.Material.Fabric,
				rng:NextNumber(0, 90)
			)
		end
	end)
	Kit.darkCandles(deco, def, rng, Color3.fromRGB(255, 190, 110))
	Kit.mist(model, Random.new(77), 24, Color3.fromRGB(130, 220, 150))
	return { model = model, landmarkAnchors = anchors, cryptGate = nil }
end

return Settlement
