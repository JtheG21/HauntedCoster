--!strict
-- Builds the starter graveyard, the lantern road and the lighting from Config.World.
-- Deterministic (seeded) so every server gets the same layout.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local World = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("World"))
local Build = require(script.Parent.Build)

local GraveyardBuilder = {}

export type Result = {
	folder: Folder,
	landmarkAnchors: { [string]: BasePart },
	cryptGate: BasePart,
	shortcutGate: BasePart,
}

local C = {
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

local function lantern(parent: Instance, x: number, z: number)
	Build.block(parent, "LanternPost", Vector3.new(0.5, 7, 0.5), x, 0, z, C.iron, Enum.Material.Metal)
	local head = Build.part({
		name = "Lantern",
		size = Vector3.new(1.2, 1.4, 1.2),
		cframe = CFrame.new(x, 7.6, z),
		color = C.lantern,
		material = Enum.Material.Neon,
		collide = false,
		parent = parent,
	})
	Build.light(head, C.lantern, 22, 1.6)
end

local placedPosts: { [string]: boolean } = {}

local function fenceLine(parent: Instance, a: Vector3, b: Vector3)
	local dir = b - a
	local len = dir.Magnitude
	if len < 0.5 then
		return
	end
	local unit = dir.Unit
	local n = math.max(1, math.floor(len / 4))
	for i = 0, n do
		local p = a + unit * (len * i / n)
		-- Fence lines share corner endpoints; skip a post already placed there (coincident = z-fighting).
		local key = `{math.floor(p.X * 10 + 0.5)}:{math.floor(p.Z * 10 + 0.5)}`
		if not placedPosts[key] then
			placedPosts[key] = true
			Build.block(parent, "FencePost", Vector3.new(0.4, 6, 0.4), p.X, 0, p.Z, C.iron, Enum.Material.Metal)
		end
	end
	for _, h in { 2, 5 } do
		local mid = (a + b) / 2
		Build.part({
			name = "FenceRail",
			size = Vector3.new(0.2, 0.2, len),
			cframe = CFrame.lookAt(Vector3.new(mid.X, h, mid.Z), Vector3.new(b.X, h, b.Z)),
			color = C.iron,
			material = Enum.Material.Metal,
			parent = parent,
		})
	end
	-- Invisible wall so the fence actually blocks (rails alone have gaps).
	local mid = (a + b) / 2
	Build.part({
		name = "FenceCollider",
		size = Vector3.new(0.6, 8, len),
		cframe = CFrame.lookAt(Vector3.new(mid.X, 4, mid.Z), Vector3.new(b.X, 4, b.Z)),
		transparency = 1,
		parent = parent,
	})
end

local function tombstone(parent: Instance, rng: Random, x: number, z: number)
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

local function deadTree(parent: Instance, rng: Random, x: number, z: number)
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

local function mausoleum(parent: Instance, x: number, z: number, scale: number, name: string): Part
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

local function landmarkAngel(parent: Instance, pos: Vector3): BasePart
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
	lantern(parent, x + 5, z + 3)
	lantern(parent, x - 5, z + 3)
	return anchor
end

local function landmarkHearse(parent: Instance, pos: Vector3): BasePart
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

local function landmarkWell(parent: Instance, pos: Vector3): BasePart
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

local function landmarkBellTower(parent: Instance, pos: Vector3): BasePart
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

-- Returns the crypt gate (closed iron bars).
local function crypt(parent: Instance): BasePart
	local r = World.Graveyard.crypt
	local gateX = World.Graveyard.cryptGate.X
	local gw = World.Graveyard.cryptGateWidth
	local h = 12
	local function wall(a: Vector3, b: Vector3)
		local mid = (a + b) / 2
		local len = (b - a).Magnitude
		-- North/south walls are 0.2 taller so overlapping corner tops never share a plane.
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
	wall(Vector3.new(r.x1, 0, r.z1), Vector3.new(r.x2, 0, r.z1))
	wall(Vector3.new(r.x1, 0, r.z1), Vector3.new(r.x1, 0, r.z2))
	wall(Vector3.new(r.x2, 0, r.z1), Vector3.new(r.x2, 0, r.z2))
	wall(Vector3.new(r.x1, 0, r.z2), Vector3.new(gateX - gw / 2, 0, r.z2))
	wall(Vector3.new(gateX + gw / 2, 0, r.z2), Vector3.new(r.x2, 0, r.z2))
	local gate = Build.part({
		name = "CryptGate",
		size = Vector3.new(gw, h - 2, 1),
		cframe = CFrame.new(gateX, (h - 2) / 2, r.z2),
		color = C.iron,
		material = Enum.Material.DiamondPlate,
		transparency = 0.25,
		parent = parent,
	})
	Build.billboard(gate, "SEALED CRYPT", Color3.fromRGB(200, 120, 255), 7, 120, 1.2)
	-- Coffins and an eerie glow inside
	local rng = Random.new(77)
	for _ = 1, 6 do
		local x = rng:NextNumber(r.x1 + 6, r.x2 - 6)
		local z = rng:NextNumber(r.z1 + 5, r.z2 - 8)
		Build.block(
			parent,
			"Coffin",
			Vector3.new(3, 1.4, 7),
			x,
			0,
			z,
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

local function nearAny(x: number, z: number, keepOut: { Vector3 }, radius: number): boolean
	for _, p in keepOut do
		if math.abs(p.X - x) < radius and math.abs(p.Z - z) < radius then
			return true
		end
	end
	return false
end

local function setupLighting()
	Lighting.ClockTime = 0
	Lighting.Brightness = 1
	Lighting.Ambient = Color3.fromRGB(42, 42, 58)
	Lighting.OutdoorAmbient = Color3.fromRGB(86, 86, 118)
	Lighting.EnvironmentDiffuseScale = 0.3
	if not Lighting:FindFirstChildOfClass("Atmosphere") then
		local atm = Instance.new("Atmosphere")
		atm.Density = 0.36
		atm.Offset = 0.1
		atm.Color = Color3.fromRGB(70, 70, 105)
		atm.Decay = Color3.fromRGB(45, 35, 70)
		atm.Glare = 0
		atm.Haze = 1.4
		atm.Parent = Lighting
	end
	if not Lighting:FindFirstChildOfClass("ColorCorrectionEffect") then
		local cc = Instance.new("ColorCorrectionEffect")
		cc.Saturation = -0.15
		cc.Contrast = 0.08
		cc.TintColor = Color3.fromRGB(225, 225, 255)
		cc.Parent = Lighting
	end
end

-- A Baseplate left by a mis-synced project (e.g. GAME-001's Rojo tree) sits exactly at ground level and
-- z-fights with our ground everywhere. This game owns its Workspace, so remove it.
local function removeStrayBaseplate(parent: Instance)
	local stray = parent:FindFirstChild("Baseplate")
	if stray and stray:IsA("BasePart") then
		warn("[World] removed a stray Workspace.Baseplate (it z-fights with the graveyard ground)")
		stray:Destroy()
	end
end

function GraveyardBuilder.build(parent: Instance): Result
	removeStrayBaseplate(parent)
	setupLighting()
	local folder = Instance.new("Folder")
	folder.Name = "Graveyard"
	local deco = Build.folder(folder, "Decor")
	local rng = Random.new(1031)
	local g = World.Graveyard
	local r = g.rect

	-- Ground and roads
	Build.part({
		name = "Ground",
		size = Vector3.new(1400, 2, 1400),
		cframe = CFrame.new(0, -1, -100),
		color = C.grass,
		material = Enum.Material.Grass,
		parent = folder,
	})
	Build.part({
		name = "GraveyardSoil",
		size = Vector3.new(r.x2 - r.x1, 0.1, r.z2 - r.z1),
		cframe = CFrame.new((r.x1 + r.x2) / 2, 0.03, (r.z1 + r.z2) / 2),
		color = C.dirt,
		material = Enum.Material.Ground,
		parent = folder,
	})
	Build.strip(
		folder,
		"LanternRoad",
		Vector3.new(0, 0, 30),
		Vector3.new(0, 0, g.gate.Z),
		10,
		C.cobble,
		Enum.Material.Cobblestone
	)
	Build.strip(
		folder,
		"PlotAvenue",
		Vector3.new(-310, 0, 30),
		Vector3.new(310, 0, 30),
		12,
		C.cobble,
		Enum.Material.Cobblestone,
		0.09 -- above the LanternRoad where they cross (no shared top face)
	)
	for z = 20, g.gate.Z + 10, -26 do
		lantern(deco, -7, z)
		lantern(deco, 7, z)
	end
	-- Inner paths
	Build.strip(
		folder,
		"MainPath",
		Vector3.new(0, 0, g.gate.Z),
		Vector3.new(0, 0, -318),
		8,
		C.cobble,
		Enum.Material.Cobblestone,
		0.1
	)
	Build.strip(
		folder,
		"CrossPath",
		Vector3.new(r.x1 + 4, 0, -235),
		Vector3.new(r.x2 - 4, 0, -235),
		7,
		C.cobble,
		Enum.Material.Cobblestone,
		0.13 -- above MainPath at the crossing
	)
	Build.strip(
		folder,
		"CryptPath",
		Vector3.new(0, 0, -318),
		Vector3.new(g.cryptGate.X, 0, -318),
		6,
		C.cobble,
		Enum.Material.Cobblestone,
		0.16 -- above MainPath where it branches off
	)
	Build.strip(
		folder,
		"ShortcutPath",
		g.shortcut + Vector3.new(-4, 0, 0),
		Vector3.new(-250, 0, 30),
		6,
		C.dirt,
		Enum.Material.Ground
	)
	for _, z in { -205, -260, -300 } do
		lantern(deco, -5, z)
	end
	lantern(deco, -60, -238)
	lantern(deco, -110, -238)

	-- Fence with the main gate and the (initially overgrown) west shortcut
	local fence = Build.folder(folder, "Fence")
	local gw = g.gateWidth / 2
	fenceLine(fence, Vector3.new(r.x1, 0, r.z2), Vector3.new(-gw, 0, r.z2))
	fenceLine(fence, Vector3.new(gw, 0, r.z2), Vector3.new(r.x2, 0, r.z2))
	fenceLine(fence, Vector3.new(r.x1, 0, r.z1), Vector3.new(r.x2, 0, r.z1))
	fenceLine(fence, Vector3.new(r.x2, 0, r.z1), Vector3.new(r.x2, 0, r.z2))
	local sw = g.shortcutWidth / 2
	fenceLine(fence, Vector3.new(r.x1, 0, r.z1), Vector3.new(r.x1, 0, g.shortcut.Z - sw))
	fenceLine(fence, Vector3.new(r.x1, 0, g.shortcut.Z + sw), Vector3.new(r.x1, 0, r.z2))
	local shortcutGate = Build.part({
		name = "OvergrownGate",
		size = Vector3.new(1.5, 8, g.shortcutWidth),
		cframe = CFrame.new(r.x1, 4, g.shortcut.Z),
		color = Color3.fromRGB(30, 60, 30),
		material = Enum.Material.LeafyGrass,
		parent = folder,
	})
	Build.billboard(shortcutGate, "Overgrown", Color3.fromRGB(120, 200, 120), 5, 40, 0.7)
	-- Gate arch
	for _, side in { -1, 1 } do
		Build.block(
			folder,
			"GatePillar",
			Vector3.new(3, 14, 3),
			side * (gw + 1.5),
			0,
			r.z2,
			C.darkStone,
			Enum.Material.Cobblestone
		)
		lantern(deco, side * (gw + 4), r.z2 + 3)
	end
	local arch =
		Build.block(folder, "GateArch", Vector3.new(g.gateWidth + 6, 2, 2), 0, 14, r.z2, C.iron, Enum.Material.Metal)
	Build.billboard(arch, "OLD GRAVEYARD", Color3.fromRGB(255, 190, 120), 3, 300, 1.5)

	-- Landmarks
	local anchors: { [string]: BasePart } = {}
	local lmFolder = Build.folder(folder, "Landmarks")
	for _, lm in World.Landmarks do
		local m = Build.model(lmFolder, lm.id)
		local anchor: BasePart
		if lm.id == "Angel" then
			anchor = landmarkAngel(m, lm.position)
		elseif lm.id == "Hearse" then
			anchor = landmarkHearse(m, lm.position)
		elseif lm.id == "Mausoleum" then
			anchor = mausoleum(m, lm.position.X, lm.position.Z, 1.3, "HollowMausoleum")
		elseif lm.id == "OldWell" then
			anchor = landmarkWell(m, lm.position)
		else
			anchor = landmarkBellTower(m, lm.position)
		end
		anchor.Name = "Anchor"
		Build.billboard(anchor, lm.name, Color3.fromRGB(230, 220, 255), 9, 90, 0.9)
		anchors[lm.id] = anchor
		m.PrimaryPart = anchor
	end

	-- Crypt
	local cryptFolder = Build.folder(folder, "Crypt")
	local cryptGate = crypt(cryptFolder)
	local sign = Build.block(
		cryptFolder,
		"CryptSign",
		Vector3.new(6, 3, 0.4),
		g.cryptGate.X + 9,
		0,
		g.crypt.z2 + 2,
		C.wood,
		Enum.Material.Wood
	)
	Build.billboard(
		sign,
		`Needs {g.cryptLandmarksNeeded} landmarks + a Restored Manor`,
		Color3.fromRGB(255, 220, 160),
		3,
		60,
		1.1
	)

	-- Decorative mausoleums in the Old Rows and the dark Hollow
	mausoleum(deco, -100, -285, 0.8, "Mausoleum")
	mausoleum(deco, 105, -235, 0.8, "Mausoleum")
	mausoleum(deco, 100, -320, 0.7, "Mausoleum")

	-- Tombstones: rows avoiding paths, landmarks and the crypt
	local keepOut: { Vector3 } = { g.gate, g.cryptGate }
	for _, lm in World.Landmarks do
		table.insert(keepOut, lm.position)
	end
	local tombs = Build.folder(folder, "Tombstones")
	for z = r.z2 - 14, r.z1 + 8, -9 do
		for x = r.x1 + 8, r.x2 - 8, 7 do
			local jx = x + rng:NextNumber(-1.5, 1.5)
			local jz = z + rng:NextNumber(-1.5, 1.5)
			local onPath = math.abs(jx) < 8 or math.abs(jz + 235) < 7 or (jz < -310 and jz > -324)
			local inCrypt = World.inRect(g.crypt, jx, jz) or World.inRect(g.crypt, jx, jz + 6)
			if not onPath and not inCrypt and not nearAny(jx, jz, keepOut, 11) and rng:NextNumber() < 0.42 then
				tombstone(tombs, rng, jx, jz)
			end
		end
	end
	for _ = 1, 14 do
		local x = rng:NextNumber(r.x1 + 6, r.x2 - 6)
		local z = rng:NextNumber(r.z1 + 6, r.z2 - 6)
		if math.abs(x) > 10 and not World.inRect(g.crypt, x, z) and not nearAny(x, z, keepOut, 12) then
			deadTree(deco, rng, x, z)
		end
	end
	-- A few cold candles in the dark Hollow so it is dark but navigable
	for _ = 1, 5 do
		local x = rng:NextNumber(30, 120)
		local z = rng:NextNumber(-330, -215)
		local candle =
			Build.block(deco, "GhostCandle", Vector3.new(0.4, 1.2, 0.4), x, 0, z, C.ghost, Enum.Material.Neon)
		Build.light(candle, C.ghost, 12, 0.8)
	end

	folder.Parent = parent
	return {
		folder = folder,
		landmarkAnchors = anchors,
		cryptGate = cryptGate,
		shortcutGate = shortcutGate,
	}
end

return GraveyardBuilder
