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
	lantern = Color3.fromRGB(205, 82, 18), -- warm orange glass; Neon brightens it (TASK-0028)
	lanternLight = Color3.fromRGB(255, 145, 70),
	pumpkin = Color3.fromRGB(214, 98, 24),
	moss = Color3.fromRGB(52, 78, 50),
	marble = Color3.fromRGB(205, 205, 210),
	ghost = Color3.fromRGB(140, 120, 255),
}
local C = Props.C

-- The lamp family (TASK-0028): an iron post with a short arm and a hanging glass lantern. `shadows` is for
-- the few key lights only (the light budget allows shadows on a handful).
function Props.lantern(parent: Instance, x: number, z: number, y: number?, shadows: boolean?)
	local base = y or 0
	Build.block(parent, "LanternPost", Vector3.new(0.5, 8, 0.5), x, base, z, C.iron, Enum.Material.Metal)
	Build.part({
		name = "LanternArm",
		size = Vector3.new(0.3, 0.3, 1.6),
		cframe = CFrame.new(x, base + 7.8, z + 0.7),
		color = C.iron,
		material = Enum.Material.Metal,
		collide = false,
		parent = parent,
	})
	Build.part({
		name = "LanternCap",
		size = Vector3.new(1.3, 0.4, 1.3),
		cframe = CFrame.new(x, base + 7.4, z + 1.3) * CFrame.Angles(0, math.rad(45), 0),
		color = C.iron,
		material = Enum.Material.Metal,
		collide = false,
		parent = parent,
	})
	local head = Build.part({
		name = "Lantern",
		size = Vector3.new(0.9, 1.2, 0.9),
		cframe = CFrame.new(x, base + 6.6, z + 1.3),
		color = C.lantern,
		material = Enum.Material.Neon,
		collide = false,
		parent = parent,
	})
	Build.light(head, C.lanternLight, 30, 2.6, shadows)
end

-- A carved pumpkin with a warm glow (map reference 3). No light of its own unless `lit`, to keep the budget.
function Props.pumpkin(parent: Instance, x: number, z: number, size: number, yaw: number, lit: boolean?)
	local body = Build.part({
		name = "Pumpkin",
		size = Vector3.new(size, size, size),
		cframe = CFrame.new(x, size * 0.42, z) * CFrame.Angles(0, math.rad(yaw), 0),
		color = C.pumpkin,
		material = Enum.Material.SmoothPlastic,
		shape = Enum.PartType.Ball,
		collide = false,
		parent = parent,
	})
	Build.part({
		name = "PumpkinStem",
		size = Vector3.new(0.25, size * 0.3, 0.25),
		cframe = body.CFrame * CFrame.new(0, size * 0.55, 0),
		color = Color3.fromRGB(60, 80, 40),
		material = Enum.Material.Wood,
		collide = false,
		parent = parent,
	})
	-- The face: two eyes and a mouth on the front (-Z) side.
	for _, f in { { -0.2, 0.12, 0.16 }, { 0.2, 0.12, 0.16 }, { 0, -0.12, 0.42 } } do
		Build.part({
			name = "PumpkinFace",
			size = Vector3.new(size * f[3], size * 0.14, 0.1),
			cframe = body.CFrame * CFrame.new(size * f[1], size * f[2], -size * 0.49),
			color = Color3.fromRGB(255, 190, 80),
			material = Enum.Material.Neon,
			collide = false,
			parent = parent,
		})
	end
	if lit then
		Build.light(body, C.lanternLight, 10, 1)
	end
end

-- Low edge stones along both sides of a path segment (path edges in the kit).
function Props.curbStones(parent: Instance, a: Vector3, b: Vector3, width: number, rng: Random)
	local d = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
	local len = d.Magnitude
	if len < 1 then
		return
	end
	local unit = d / len
	local perp = Vector3.new(-unit.Z, 0, unit.X)
	for side = -1, 1, 2 do
		local t = 1.5
		while t < len - 1.5 do
			local p = a + unit * t + perp * side * (width / 2 + 0.5)
			local shade = rng:NextNumber(0.8, 1.1)
			Build.part({
				name = "EdgeStone",
				size = Vector3.new(rng:NextNumber(0.8, 1.3), rng:NextNumber(0.35, 0.6), rng:NextNumber(1.2, 2)),
				cframe = CFrame.lookAt(Vector3.new(p.X, 0.2, p.Z), Vector3.new(p.X, 0.2, p.Z) + unit)
					* CFrame.Angles(0, math.rad(rng:NextNumber(-10, 10)), 0),
				color = Color3.new(C.stone.R * shade, C.stone.G * shade, C.stone.B * shade),
				material = Enum.Material.Slate,
				collide = false,
				parent = parent,
			})
			t += rng:NextNumber(2.4, 3.4)
		end
	end
end

-- A mossy grass patch on the ground (soft ground transitions beside paths).
function Props.mossPatch(parent: Instance, x: number, z: number, radius: number, top: number)
	return Props.disc(parent, "Moss", Vector3.new(x, 0, z), radius, top, C.moss, Enum.Material.Grass)
end

-- A spiked iron arch over a path: two stone pillars with caps and lamps, and an iron arch between them.
-- `centre` is on the path; the arch spans `width` across `facing` (the direction along the path).
function Props.cemeteryGate(parent: Instance, centre: Vector3, facing: Vector3, width: number)
	local unit = Vector3.new(facing.X, 0, facing.Z).Unit
	local perp = Vector3.new(-unit.Z, 0, unit.X)
	for side = -1, 1, 2 do
		local p = centre + perp * side * (width / 2 + 1)
		Build.block(parent, "GatePillar", Vector3.new(2, 9, 2), p.X, 0, p.Z, C.darkStone, Enum.Material.Slate)
		Build.block(parent, "GatePillarCap", Vector3.new(2.6, 0.8, 2.6), p.X, 9, p.Z, C.stone, Enum.Material.Slate)
		Props.lantern(parent, p.X + perp.X * side * 1.6, p.Z + perp.Z * side * 1.6)
	end
	local top = centre + Vector3.new(0, 10.5, 0)
	Build.part({
		name = "GateArch",
		size = Vector3.new(0.5, 0.5, width + 2),
		cframe = CFrame.lookAt(top, top + perp),
		color = C.iron,
		material = Enum.Material.Metal,
		collide = false,
		parent = parent,
	})
	for i = -3, 3 do
		local p = top + perp * (i * (width / 7))
		Build.part({
			name = "GateSpike",
			size = Vector3.new(0.25, 1.4 - math.abs(i) * 0.12, 0.25),
			cframe = CFrame.new(p + Vector3.new(0, 0.8, 0)),
			color = C.iron,
			material = Enum.Material.Metal,
			collide = false,
			parent = parent,
		})
	end
end

-- A broken stretch of old wall (ruined masonry): uneven blocks, one fallen.
function Props.ruinedWall(parent: Instance, rng: Random, x: number, z: number, yaw: number)
	local cf = CFrame.new(x, 0, z) * CFrame.Angles(0, math.rad(yaw), 0)
	for i = -2, 2 do
		local h = rng:NextNumber(1.5, 5)
		Build.part({
			name = "RuinBlock",
			size = Vector3.new(2, h, 1.4),
			cframe = cf * CFrame.new(i * 2.05, h / 2, 0),
			color = C.darkStone,
			material = Enum.Material.Cobblestone,
			parent = parent,
		})
	end
	Build.part({
		name = "RuinFallen",
		size = Vector3.new(2, 1.2, 1.4),
		cframe = cf
			* CFrame.new(rng:NextNumber(-3, 3), 0.6, 2.4)
			* CFrame.Angles(0, math.rad(rng:NextNumber(0, 60)), 0),
		color = C.darkStone,
		material = Enum.Material.Cobblestone,
		parent = parent,
	})
end

-- A few candles of different heights on a grave or a step.
function Props.candles(parent: Instance, rng: Random, x: number, z: number, lit: boolean)
	local tallest: Part? = nil
	for i = 1, 3 do
		local h = rng:NextNumber(0.6, 1.4)
		local c = Build.block(
			parent,
			"Candle",
			Vector3.new(0.3, h, 0.3),
			x + rng:NextNumber(-0.6, 0.6),
			0,
			z + rng:NextNumber(-0.6, 0.6),
			Color3.fromRGB(235, 225, 200),
			Enum.Material.SmoothPlastic
		)
		c.CanCollide = false
		Build.part({
			name = "Flame",
			size = Vector3.new(0.18, 0.3, 0.18),
			cframe = c.CFrame * CFrame.new(0, h / 2 + 0.15, 0),
			color = C.lantern,
			material = Enum.Material.Neon,
			collide = false,
			parent = parent,
		})
		if i == 1 then
			tallest = c
		end
	end
	if lit and tallest then
		Build.light(tallest, C.lanternLight, 9, 0.9)
	end
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
	-- Roots splaying into the ground (kit: trees and roots)
	for i = 0, 2 do
		local a = math.rad(i * 120 + rng:NextNumber(-20, 20))
		Build.part({
			name = "Root",
			size = Vector3.new(0.7, 0.7, 3.2),
			cframe = CFrame.new(x + math.sin(a) * 1.4, 0.3, z + math.cos(a) * 1.4)
				* CFrame.Angles(0, a, 0)
				* CFrame.Angles(math.rad(14), 0, 0),
			color = Color3.fromRGB(45, 35, 30),
			material = Enum.Material.Wood,
			collide = false,
			parent = parent,
		})
	end
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

-- The Weeping Angel (TASK-0028): a stepped plinth, a flared robe, a bowed head with both hands over the
-- face, and tall folded wings, so the silhouette reads from 80+ studs. Faces south (+Z), towards the main
-- gate path. Two shadow-casting lanterns light it (key lights).
function Props.angel(parent: Instance, pos: Vector3): BasePart
	local x, z = pos.X, pos.Z
	local anchor =
		Build.block(parent, "AngelPedestal", Vector3.new(8, 1.2, 8), x, 0, z, C.darkStone, Enum.Material.Slate)
	Build.block(parent, "AngelStep", Vector3.new(6, 1.2, 6), x, 1.2, z, C.stone, Enum.Material.Slate)
	Build.block(parent, "AngelPlinth", Vector3.new(4, 2.6, 4), x, 2.4, z, C.darkStone, Enum.Material.Marble)
	local function piece(name: string, size: Vector3, cf: CFrame, shape: Enum.PartType?)
		return Build.part({
			name = name,
			size = size,
			cframe = cf,
			color = C.marble,
			material = Enum.Material.Marble,
			shape = shape,
			parent = parent,
		})
	end
	local base = CFrame.new(x, 5, z) -- top of the plinth
	piece("AngelRobeHem", Vector3.new(3.4, 1.6, 2.8), base * CFrame.new(0, 0.8, 0))
	piece("AngelRobe", Vector3.new(2.8, 4.4, 2.2), base * CFrame.new(0, 3.8, 0))
	piece("AngelChest", Vector3.new(2.4, 2, 1.8), base * CFrame.new(0, 6.6, 0.1) * CFrame.Angles(math.rad(-10), 0, 0))
	piece("AngelHead", Vector3.new(1.5, 1.5, 1.5), base * CFrame.new(0, 8.2, 0.5), Enum.PartType.Ball)
	for side = -1, 1, 2 do
		-- Forearms raised so the hands cover the face (the weeping pose)
		piece(
			"AngelArm",
			Vector3.new(0.6, 2.4, 0.6),
			base * CFrame.new(side * 0.9, 7.3, 0.9) * CFrame.Angles(math.rad(35), 0, math.rad(side * -25))
		)
		piece("AngelHand", Vector3.new(0.6, 0.8, 0.4), base * CFrame.new(side * 0.35, 8.3, 1.25))
		-- Wings: three overlapping feathered slabs per side, swept back and up
		for i = 0, 2 do
			piece(
				"AngelWing",
				Vector3.new(0.35, 6 - i * 1.4, 2.4 - i * 0.4),
				base
					* CFrame.new(side * (1.3 + i * 0.25), 7 + i * 0.6, -1.1 - i * 0.5)
					* CFrame.Angles(math.rad(-18 - i * 8), math.rad(side * (28 + i * 6)), math.rad(side * -6))
			)
		end
	end
	Props.lantern(parent, x + 5.5, z + 4, nil, true)
	Props.lantern(parent, x - 5.5, z + 4, nil, true)
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

-- The Bell Tower (TASK-0028): a buttressed stone shaft, an open belfry with four corner piers and arches,
-- the bell lit warm inside (the one shadow-casting light up high), and a steep stepped spire - a tall,
-- distinct silhouette from anywhere in the cemetery.
function Props.bellTower(parent: Instance, pos: Vector3): BasePart
	local x, z = pos.X, pos.Z
	local anchor = Build.block(parent, "TowerBase", Vector3.new(10, 2, 10), x, 0, z, C.darkStone, Enum.Material.Slate)
	Build.block(parent, "Tower", Vector3.new(7, 22, 7), x, 2, z, C.stone, Enum.Material.Cobblestone)
	for _, c in { { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } } do
		-- Buttresses: stepped blocks at each corner
		Build.block(
			parent,
			"Buttress",
			Vector3.new(2, 10, 2),
			x + c[1] * 4,
			2,
			z + c[2] * 4,
			C.darkStone,
			Enum.Material.Slate
		)
		Build.block(
			parent,
			"ButtressTop",
			Vector3.new(1.4, 6, 1.4),
			x + c[1] * 3.8,
			12,
			z + c[2] * 3.8,
			C.darkStone,
			Enum.Material.Slate
		)
		-- Belfry piers
		Build.block(
			parent,
			"BelfryPier",
			Vector3.new(1.4, 7, 1.4),
			x + c[1] * 3,
			24,
			z + c[2] * 3,
			C.stone,
			Enum.Material.Cobblestone
		)
	end
	Build.block(parent, "BelfryFloor", Vector3.new(8, 0.6, 8), x, 23.4, z, C.darkStone, Enum.Material.Slate)
	for _, d in { { 0, -1 }, { 0, 1 }, { -1, 0 }, { 1, 0 } } do
		Build.block(
			parent,
			"BelfryArch",
			if d[1] == 0 then Vector3.new(6, 1.2, 1.2) else Vector3.new(1.2, 1.2, 6),
			x + d[1] * 3,
			29.6,
			z + d[2] * 3,
			C.stone,
			Enum.Material.Cobblestone
		)
	end
	Build.block(parent, "BelfryRoof", Vector3.new(8.4, 0.8, 8.4), x, 31, z, C.darkStone, Enum.Material.Slate)
	for i = 0, 4 do
		local w = 7 - i * 1.5
		Build.part({
			name = "Spire",
			size = Vector3.new(w, 2.2, w),
			cframe = CFrame.new(x, 32.9 + i * 2.2, z) * CFrame.Angles(0, math.rad(45), 0),
			color = Color3.fromRGB(58, 50, 70),
			material = Enum.Material.Slate,
			parent = parent,
		})
	end
	Build.block(parent, "SpireCross", Vector3.new(0.3, 2.4, 0.3), x, 43.9, z, C.iron, Enum.Material.Metal)
	local bell = Build.part({
		name = "Bell",
		size = Vector3.new(3, 3, 3),
		cframe = CFrame.new(x, 27, z),
		color = Color3.fromRGB(180, 140, 60),
		material = Enum.Material.Metal,
		shape = Enum.PartType.Ball,
		parent = parent,
	})
	Build.light(bell, Color3.fromRGB(255, 190, 90), 34, 1.4, true)
	Build.block(
		parent,
		"TowerDoor",
		Vector3.new(3, 5, 0.4),
		x,
		2,
		z + 3.6,
		Color3.fromRGB(30, 22, 18),
		Enum.Material.Wood
	)
	Props.lantern(parent, x + 2.6, z + 6)
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
