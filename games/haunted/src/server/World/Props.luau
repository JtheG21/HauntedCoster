--!strict
-- Shared prop kit for the hub and the habitat modules: lanterns, fences, graves, trees, mausoleums, the
-- landmark builders and the walled crypt. Simple parts and built-in materials only (ADR-0007). Moved from
-- the TASK-0012 graveyard builder; TASK-0028 details the Weeping Angel and Bell Tower.

local Build = require(script.Parent.Build)

local Props = {}

Props.C = {
	grass = Color3.fromRGB(38, 52, 40),
	dirt = Color3.fromRGB(58, 50, 44),
	stone = Color3.fromRGB(105, 105, 112),
	darkStone = Color3.fromRGB(70, 70, 78),
	iron = Color3.fromRGB(25, 25, 28),
	cobble = Color3.fromRGB(82, 80, 84),
	wood = Color3.fromRGB(70, 52, 38),
	lantern = Color3.fromRGB(255, 170, 80),
	ghost = Color3.fromRGB(140, 120, 255),
}
local C = Props.C

function Props.lantern(parent: Instance, x: number, z: number, y: number?)
	local base = y or 0
	Build.block(parent, "LanternPost", Vector3.new(0.5, 7, 0.5), x, base, z, C.iron, Enum.Material.Metal)
	local head = Build.part({
		name = "Lantern",
		size = Vector3.new(1.2, 1.4, 1.2),
		cframe = CFrame.new(x, base + 7.6, z),
		color = C.lantern,
		material = Enum.Material.Neon,
		collide = false,
		parent = parent,
	})
	Build.light(head, C.lantern, 22, 1.6)
end

-- An iron fence between a and b with an invisible collider (rails alone have gaps). `posts` remembers
-- placed posts so fence lines that share a corner don't stack coincident posts (z-fighting).
function Props.fenceLine(parent: Instance, a: Vector3, b: Vector3, posts: { [string]: boolean })
	local dir = b - a
	local len = dir.Magnitude
	if len < 0.5 then
		return
	end
	local unit = dir.Unit
	local n = math.max(1, math.floor(len / 4))
	for i = 0, n do
		local p = a + unit * (len * i / n)
		local key = `{math.floor(p.X * 10 + 0.5)}:{math.floor(p.Z * 10 + 0.5)}`
		if not posts[key] then
			posts[key] = true
			Build.block(parent, "FencePost", Vector3.new(0.4, 6, 0.4), p.X, 0, p.Z, C.iron, Enum.Material.Metal)
		end
	end
	local mid = (a + b) / 2
	for _, h in { 2, 5 } do
		Build.part({
			name = "FenceRail",
			size = Vector3.new(0.2, 0.2, len),
			cframe = CFrame.lookAt(Vector3.new(mid.X, h, mid.Z), Vector3.new(b.X, h, b.Z)),
			color = C.iron,
			material = Enum.Material.Metal,
			parent = parent,
		})
	end
	Build.part({
		name = "FenceCollider",
		size = Vector3.new(0.6, 8, len),
		cframe = CFrame.lookAt(Vector3.new(mid.X, 4, mid.Z), Vector3.new(b.X, 4, b.Z)),
		transparency = 1,
		parent = parent,
	})
end

function Props.tombstone(parent: Instance, rng: Random, x: number, z: number)
	local kind = rng:NextInteger(1, 4)
	local rot = rng:NextNumber(-12, 12)
	local shade = rng:NextNumber(0.85, 1.1)
	local col =
		Color3.new(math.min(1, C.stone.R * shade), math.min(1, C.stone.G * shade), math.min(1, C.stone.B * shade))
	if kind == 1 then
		Build.block(parent, "Tombstone", Vector3.new(2.4, 3.2, 0.6), x, 0, z, col, Enum.Material.Slate, rot)
	elseif kind == 2 then
		Build.block(parent, "Cross", Vector3.new(0.6, 4, 0.6), x, 0, z, col, Enum.Material.Slate, rot)
		Build.part({
			name = "CrossArm",
			size = Vector3.new(2.4, 0.6, 0.6),
			cframe = CFrame.new(x, 2.9, z) * CFrame.Angles(0, math.rad(rot), 0),
			color = col,
			material = Enum.Material.Slate,
			parent = parent,
		})
	elseif kind == 3 then
		Build.block(parent, "Obelisk", Vector3.new(1.2, 5.5, 1.2), x, 0, z, col, Enum.Material.Marble, rot)
	else
		local slab = Build.block(parent, "LeaningStone", Vector3.new(2.2, 2.6, 0.5), x, 0, z, col, Enum.Material.Slate)
		slab.CFrame = slab.CFrame * CFrame.Angles(math.rad(rng:NextNumber(-18, 18)), math.rad(rot), 0)
	end
	-- Grave mound
	Build.block(parent, "Mound", Vector3.new(2.6, 0.4, 5), x, 0, z + 3, C.dirt, Enum.Material.Ground, rot)
end

function Props.deadTree(parent: Instance, rng: Random, x: number, z: number)
	local h = rng:NextNumber(10, 16)
	Build.block(parent, "Trunk", Vector3.new(1.4, h, 1.4), x, 0, z, Color3.fromRGB(45, 35, 30), Enum.Material.Wood)
	for i = 1, 3 do
		local y = h * rng:NextNumber(0.55, 0.95)
		local yaw = rng:NextNumber(0, 360)
		local len = rng:NextNumber(4, 7)
		local cf = CFrame.new(x, y, z) * CFrame.Angles(0, math.rad(yaw), 0) * CFrame.Angles(0, 0, math.rad(55))
		Build.part({
			name = "Branch" .. i,
			size = Vector3.new(len, 0.5, 0.5),
			cframe = cf * CFrame.new(len / 2, 0, 0),
			color = Color3.fromRGB(45, 35, 30),
			material = Enum.Material.Wood,
			collide = false,
			parent = parent,
		})
	end
end

function Props.mausoleum(parent: Instance, x: number, z: number, scale: number, name: string): Part
	local s = scale
	local base = Build.block(parent, name, Vector3.new(12 * s, 1, 10 * s), x, 0, z, C.darkStone, Enum.Material.Slate)
	Build.block(parent, name .. "Body", Vector3.new(10 * s, 9 * s, 8 * s), x, 1, z, C.stone, Enum.Material.Marble)
	Build.block(
		parent,
		name .. "Roof",
		Vector3.new(12 * s, 1.5, 10 * s),
		x,
		1 + 9 * s,
		z,
		C.darkStone,
		Enum.Material.Slate
	)
	Build.block(
		parent,
		name .. "Door",
		Vector3.new(3 * s, 5 * s, 0.4),
		x,
		1,
		z + 4 * s + 0.1,
		C.iron,
		Enum.Material.Metal
	)
	for _, dx in { -4, 4 } do
		Build.block(
			parent,
			"Column",
			Vector3.new(1, 9 * s + 0.6, 1), -- reaches into the roof so its top isn't level with the body
			x + dx * s,
			1,
			z + 4.6 * s,
			C.stone,
			Enum.Material.Marble
		)
	end
	return base
end

function Props.angel(parent: Instance, pos: Vector3): BasePart
	local x, z = pos.X, pos.Z
	local anchor = Build.block(parent, "AngelPedestal", Vector3.new(5, 3, 5), x, 0, z, C.darkStone, Enum.Material.Slate)
	local white = Color3.fromRGB(205, 205, 210)
	Build.block(parent, "AngelRobe", Vector3.new(2.6, 5, 2), x, 3, z, white, Enum.Material.Marble)
	Build.part({
		name = "AngelHead",
		size = Vector3.new(1.6, 1.6, 1.6),
		cframe = CFrame.new(x, 9, z) * CFrame.Angles(math.rad(25), 0, 0),
		color = white,
		material = Enum.Material.Marble,
		shape = Enum.PartType.Ball,
		parent = parent,
	})
	for _, side in { -1, 1 } do
		Build.part({
			name = "AngelWing",
			size = Vector3.new(0.4, 5, 3),
			cframe = CFrame.new(x + side * 1.8, 7, z + 1.2) * CFrame.Angles(math.rad(-20), math.rad(side * 30), 0),
			color = white,
			material = Enum.Material.Marble,
			parent = parent,
		})
	end
	Props.lantern(parent, x + 5, z + 3)
	Props.lantern(parent, x - 5, z + 3)
	return anchor
end

function Props.hearse(parent: Instance, pos: Vector3): BasePart
	local x, z = pos.X, pos.Z
	local black = Color3.fromRGB(20, 18, 22)
	local anchor = Build.block(parent, "HearseBody", Vector3.new(6, 4, 12), x, 1, z, black, Enum.Material.Wood, 15)
	Build.block(parent, "HearseRoof", Vector3.new(5, 1, 9), x, 5, z, black, Enum.Material.Wood, 15)
	for i, off in { Vector3.new(-3, 0, -4), Vector3.new(3, 0, -4), Vector3.new(-3, 0, 4) } do
		local wp = CFrame.new(x, 0, z) * CFrame.Angles(0, math.rad(15), 0) * CFrame.new(off)
		Build.part({
			name = "Wheel" .. i,
			size = Vector3.new(0.6, 2.4, 2.4),
			cframe = CFrame.new(wp.Position + Vector3.new(0, 1.2, 0)) * CFrame.Angles(0, math.rad(15), 0),
			color = C.wood,
			material = Enum.Material.Wood,
			shape = Enum.PartType.Cylinder,
			parent = parent,
		})
	end
	return anchor
end

function Props.well(parent: Instance, pos: Vector3): BasePart
	local x, z = pos.X, pos.Z
	local anchor = Build.part({
		name = "WellRing",
		size = Vector3.new(3, 6, 6),
		cframe = CFrame.new(x, 1.5, z) * CFrame.Angles(0, 0, math.rad(90)),
		color = C.stone,
		material = Enum.Material.Cobblestone,
		shape = Enum.PartType.Cylinder,
		parent = parent,
	})
	for _, dx in { -2.6, 2.6 } do
		Build.block(parent, "WellPost", Vector3.new(0.5, 6, 0.5), x + dx, 0, z, C.wood, Enum.Material.Wood)
	end
	Build.block(parent, "WellRoof", Vector3.new(7, 0.6, 4), x, 6, z, C.wood, Enum.Material.Wood)
	return anchor
end

function Props.bellTower(parent: Instance, pos: Vector3): BasePart
	local x, z = pos.X, pos.Z
	local anchor = Build.block(parent, "TowerBase", Vector3.new(8, 2, 8), x, 0, z, C.darkStone, Enum.Material.Slate)
	Build.block(parent, "Tower", Vector3.new(6, 26, 6), x, 2, z, C.stone, Enum.Material.Cobblestone)
	Build.block(parent, "TowerTop", Vector3.new(8, 1, 8), x, 28, z, C.darkStone, Enum.Material.Slate)
	local bell = Build.part({
		name = "Bell",
		size = Vector3.new(3, 3, 3),
		cframe = CFrame.new(x, 31, z),
		color = Color3.fromRGB(180, 140, 60),
		material = Enum.Material.Metal,
		shape = Enum.PartType.Ball,
		parent = parent,
	})
	Build.light(bell, Color3.fromRGB(255, 200, 90), 30, 1.2)
	return anchor
end

-- A walled crypt with an iron gate in one wall. Returns the gate (closed: it collides on the server; the
-- client opens it locally for players whose house tier unlocks the crypt).
function Props.crypt(
	parent: Instance,
	r: { x1: number, x2: number, z1: number, z2: number },
	gateSide: string,
	gateAt: number,
	gateWidth: number
): BasePart
	local h = 12
	local function wall(a: Vector3, b: Vector3)
		local len = (b - a).Magnitude
		if len < 0.5 then
			return
		end
		local mid = (a + b) / 2
		-- Walls along X are 0.2 taller so overlapping corner tops never share a plane.
		local wh = if math.abs(a.Z - b.Z) < 0.01 then h + 0.2 else h
		Build.part({
			name = "CryptWall",
			size = Vector3.new(2, wh, len + 2),
			cframe = CFrame.lookAt(Vector3.new(mid.X, wh / 2, mid.Z), Vector3.new(b.X, wh / 2, b.Z)),
			color = C.darkStone,
			material = Enum.Material.Cobblestone,
			parent = parent,
		})
	end
	local corners: { [string]: { Vector3 } } = {
		x1 = { Vector3.new(r.x1, 0, r.z1), Vector3.new(r.x1, 0, r.z2) },
		x2 = { Vector3.new(r.x2, 0, r.z1), Vector3.new(r.x2, 0, r.z2) },
		z1 = { Vector3.new(r.x1, 0, r.z1), Vector3.new(r.x2, 0, r.z1) },
		z2 = { Vector3.new(r.x1, 0, r.z2), Vector3.new(r.x2, 0, r.z2) },
	}
	local gateCenter: Vector3 = Vector3.zero
	local alongX = false
	for side, ends in corners do
		local a, b = ends[1], ends[2]
		if side == gateSide then
			alongX = side == "z1" or side == "z2"
			local unit = (b - a).Unit
			gateCenter = if alongX then Vector3.new(gateAt, 0, a.Z) else Vector3.new(a.X, 0, gateAt)
			wall(a, gateCenter - unit * (gateWidth / 2))
			wall(gateCenter + unit * (gateWidth / 2), b)
		else
			wall(a, b)
		end
	end
	local gate = Build.part({
		name = "CryptGate",
		size = if alongX then Vector3.new(gateWidth, h - 2, 1) else Vector3.new(1, h - 2, gateWidth),
		cframe = CFrame.new(gateCenter.X, (h - 2) / 2, gateCenter.Z),
		color = C.iron,
		material = Enum.Material.DiamondPlate,
		transparency = 0.25,
		parent = parent,
	})
	Build.billboard(gate, "SEALED CRYPT", Color3.fromRGB(200, 120, 255), 7, 120, 1.2)
	-- Coffins and an eerie glow inside
	local rng = Random.new(77)
	for _ = 1, 6 do
		Build.block(
			parent,
			"Coffin",
			Vector3.new(3, 1.4, 7),
			rng:NextNumber(r.x1 + 6, r.x2 - 6),
			0,
			rng:NextNumber(r.z1 + 6, r.z2 - 6),
			C.wood,
			Enum.Material.Wood,
			rng:NextNumber(0, 180)
		)
	end
	local glow = Build.part({
		name = "CryptGlow",
		size = Vector3.new(1, 1, 1),
		cframe = CFrame.new((r.x1 + r.x2) / 2, 6, (r.z1 + r.z2) / 2),
		transparency = 1,
		collide = false,
		parent = parent,
	})
	Build.light(glow, C.ghost, 45, 1.4)
	return gate
end

-- A flat disc lying on the ground with its top face at `top` (Cylinder parts extend along X).
function Props.disc(
	parent: Instance,
	name: string,
	center: Vector3,
	radius: number,
	top: number,
	color: Color3,
	material: Enum.Material
): Part
	local thickness = 0.2
	return Build.part({
		name = name,
		size = Vector3.new(thickness, radius * 2, radius * 2),
		cframe = CFrame.new(center.X, top - thickness / 2, center.Z) * CFrame.Angles(0, 0, math.rad(90)),
		color = color,
		material = material,
		shape = Enum.PartType.Cylinder,
		parent = parent,
	})
end

return Props
