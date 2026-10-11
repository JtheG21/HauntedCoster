--!strict
-- Builds a home plot: ground pad, house (per tier), containment pen, exhibit pedestals, beacon, trophies.
-- The ghost-train track is built separately by TrainService.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local World = require(Config:WaitForChild("World"))
local Monsters = require(Config:WaitForChild("Monsters"))
local Build = require(script.Parent.Build)

local PlotBuilder = {}

local C = {
	lawn = Color3.fromRGB(44, 58, 42),
	border = Color3.fromRGB(60, 50, 44),
	plank = Color3.fromRGB(92, 70, 52),
	rot = Color3.fromRGB(70, 60, 50),
	paint = Color3.fromRGB(80, 70, 95),
	roof = Color3.fromRGB(40, 34, 44),
	window = Color3.fromRGB(255, 200, 110),
	iron = Color3.fromRGB(25, 25, 28),
	purple = Color3.fromRGB(170, 110, 255),
}

-- Distinct beacon colours per plot index.
PlotBuilder.Colors = {
	Color3.fromRGB(255, 120, 80),
	Color3.fromRGB(120, 220, 255),
	Color3.fromRGB(170, 255, 120),
	Color3.fromRGB(255, 220, 90),
	Color3.fromRGB(230, 130, 255),
	Color3.fromRGB(255, 140, 190),
}

function PlotBuilder.toWorld(origin: Vector3, localPos: Vector3): Vector3
	return origin + localPos
end

function PlotBuilder.build(parent: Instance, index: number): Model
	local origin = World.PlotCenters[index]
	local size = World.PlotSize
	local plot = Instance.new("Model")
	plot.Name = `Plot{index}`
	plot:SetAttribute("PlotIndex", index)
	plot:SetAttribute("OwnerUserId", 0)

	local base = Build.part({
		name = "Base",
		size = Vector3.new(size.X, 0.2, size.Y),
		cframe = CFrame.new(origin + Vector3.new(0, 0.1, 0)),
		color = C.lawn,
		material = Enum.Material.Grass,
		parent = plot,
	})
	plot.PrimaryPart = base
	-- Low border wall with a front opening facing the avenue/graveyard
	local hx, hz = size.X / 2, size.Y / 2
	for _, seg in
		{
			{ Vector3.new(-hx, 0, hz), Vector3.new(hx, 0, hz) },
			{ Vector3.new(-hx, 0, -hz), Vector3.new(-hx, 0, hz) },
			{ Vector3.new(hx, 0, -hz), Vector3.new(hx, 0, hz) },
			{ Vector3.new(-hx, 0, -hz), Vector3.new(-12, 0, -hz) },
			{ Vector3.new(12, 0, -hz), Vector3.new(hx, 0, -hz) },
		}
	do
		local a, b = origin + seg[1], origin + seg[2]
		local mid = (a + b) / 2
		Build.part({
			name = "Border",
			size = Vector3.new(1, 1.6, (b - a).Magnitude),
			cframe = CFrame.lookAt(Vector3.new(mid.X, 0.8, mid.Z), Vector3.new(b.X, 0.8, b.Z)),
			color = C.border,
			material = Enum.Material.Cobblestone,
			parent = plot,
		})
	end

	-- Owner sign at the entrance
	local sign =
		Build.block(plot, "Sign", Vector3.new(8, 4, 0.5), origin.X, 0, origin.Z - hz + 1, C.plank, Enum.Material.Wood)
	Build.billboard(sign, "Vacant Plot", Color3.fromRGB(255, 220, 160), 4, 120, 1)

	-- Containment pen
	local penPos = origin + World.Plot.pen
	local ps = World.Plot.penSize
	local pen = Build.folder(plot, "Pen")
	local pad = Build.part({
		name = "PenPad",
		size = Vector3.new(ps, 0.3, ps),
		cframe = CFrame.new(penPos + Vector3.new(0, 0.25, 0)),
		color = Color3.fromRGB(50, 40, 70),
		material = Enum.Material.Slate,
		parent = pen,
	})
	local rune = Build.part({
		name = "PenRune",
		size = Vector3.new(6, 0.1, 6),
		cframe = CFrame.new(penPos + Vector3.new(0, 0.45, 0)),
		color = C.purple,
		material = Enum.Material.Neon,
		collide = false,
		parent = pen,
	})
	Build.light(rune, C.purple, 16, 1)
	for i = 0, 3 do
		local yaw = i * 90
		local cf = CFrame.new(penPos) * CFrame.Angles(0, math.rad(yaw), 0) * CFrame.new(0, 2, ps / 2)
		if i ~= 0 then -- front side (+Z after rotation 0) left open
			Build.part({
				name = "PenBars",
				size = Vector3.new(ps, 4, 0.3),
				cframe = cf,
				color = C.iron,
				material = Enum.Material.DiamondPlate,
				transparency = 0.4,
				parent = pen,
			})
		end
	end
	Build.billboard(pad, "Containment Pen", C.purple, 6, 80, 0.9)
	Build.folder(pen, "Residents")

	-- Exhibit pedestals (activated by tier)
	local exhibits = Build.folder(plot, "Exhibits")
	for i, lp in World.Plot.exhibitSlots do
		local p = origin + lp
		local ped = Build.block(
			exhibits,
			`Exhibit{i}`,
			Vector3.new(4, 1, 4),
			p.X,
			0,
			p.Z,
			Color3.fromRGB(60, 55, 70),
			Enum.Material.Marble
		)
		ped:SetAttribute("Slot", i)
		Build.billboard(ped, `Exhibit {i}`, Color3.fromRGB(220, 200, 255), 3, 60, 0.6)
	end

	-- Home beacon (owner-coloured light pillar, visible from the graveyard)
	local bp = origin + World.Plot.beacon
	local beacon = Build.part({
		name = "Beacon",
		size = Vector3.new(2.5, 80, 2.5),
		cframe = CFrame.new(bp + Vector3.new(0, 40, 0)),
		color = PlotBuilder.Colors[index],
		material = Enum.Material.Neon,
		transparency = 0.55,
		collide = false,
		parent = plot,
	})
	Build.light(beacon, PlotBuilder.Colors[index], 30, 1)

	Build.folder(plot, "House")
	Build.folder(plot, "Trophies")
	Build.folder(plot, "Track")
	plot.Parent = parent
	PlotBuilder.buildHouse(plot, index, 0)
	return plot
end

local function windowAt(parent: Instance, pos: Vector3, lit: boolean)
	local w = Build.part({
		name = "Window",
		size = Vector3.new(2.4, 2.4, 0.3),
		cframe = CFrame.new(pos),
		color = if lit then C.window else Color3.fromRGB(30, 30, 40),
		material = if lit then Enum.Material.Neon else Enum.Material.Glass,
		collide = false,
		parent = parent,
	})
	if lit then
		Build.light(w, C.window, 12, 0.7)
	end
end

function PlotBuilder.buildHouse(plot: Model, index: number, tier: number)
	local houseFolder = plot:FindFirstChild("House") :: Folder
	houseFolder:ClearAllChildren()
	local origin = World.PlotCenters[index]
	local hp = origin + World.Plot.house
	local x, z = hp.X, hp.Z
	if tier <= 0 then
		-- Shabby shack: small, crooked, one dim window
		local body =
			Build.block(houseFolder, "Shack", Vector3.new(16, 9, 12), x, 0, z, C.rot, Enum.Material.WoodPlanks, 3)
		local roof =
			Build.block(houseFolder, "Roof", Vector3.new(18, 1.2, 14), x, 9, z, C.roof, Enum.Material.Slate, -4)
		roof.CFrame = roof.CFrame * CFrame.Angles(math.rad(6), 0, 0)
		Build.block(houseFolder, "Door", Vector3.new(3, 6, 0.4), x, 0, z - 6.1, C.plank, Enum.Material.Wood)
		windowAt(houseFolder, Vector3.new(x + 4, 5, z - 6.2), false)
		windowAt(houseFolder, Vector3.new(x - 4, 5, z - 6.2), true)
		Build.block(
			houseFolder,
			"BrokenPlank",
			Vector3.new(6, 0.4, 0.6),
			x + 9,
			0,
			z - 4,
			C.plank,
			Enum.Material.Wood,
			30
		)
		Build.billboard(body, "Shabby Shack", Color3.fromRGB(200, 180, 160), 7, 120, 1)
		return
	end
	local w = if tier == 1 then 26 else 34
	local h = if tier == 1 then 12 else 15
	local body = Build.block(houseFolder, "Manor", Vector3.new(w, h, 14), x, 0, z, C.paint, Enum.Material.WoodPlanks)
	Build.block(houseFolder, "Roof", Vector3.new(w + 2, 1.5, 16), x, h, z, C.roof, Enum.Material.Slate)
	Build.block(houseFolder, "Porch", Vector3.new(10, 0.6, 5), x, 0, z - 9.5, C.plank, Enum.Material.WoodPlanks)
	Build.block(
		houseFolder,
		"Door",
		Vector3.new(4, 7, 0.4),
		x,
		0,
		z - 7.1,
		Color3.fromRGB(60, 30, 40),
		Enum.Material.Wood
	)
	for i = -2, 2 do
		if i ~= 0 then
			windowAt(houseFolder, Vector3.new(x + i * (w / 5.5), h * 0.55, z - 7.2), true)
		end
	end
	-- West wing
	Build.block(
		houseFolder,
		"Wing",
		Vector3.new(10, h - 3, 12),
		x - w / 2 - 5,
		0,
		z + 1,
		C.paint,
		Enum.Material.WoodPlanks
	)
	windowAt(houseFolder, Vector3.new(x - w / 2 - 5, (h - 3) * 0.55, z - 5.2), true)
	local label = if tier == 1 then "Restored Manor" else "Grand Mansion"
	if tier >= 2 then
		-- Tower with a purple lantern
		local tx = x + w / 2 - 4
		Build.block(houseFolder, "Tower", Vector3.new(7, h + 12, 7), tx, 0, z + 3, C.paint, Enum.Material.WoodPlanks)
		local cap =
			Build.block(houseFolder, "TowerCap", Vector3.new(8, 2, 8), tx, h + 12, z + 3, C.roof, Enum.Material.Slate)
		local lamp = Build.part({
			name = "TowerLamp",
			size = Vector3.new(2, 2, 2),
			cframe = cap.CFrame + Vector3.new(0, 2, 0),
			color = C.purple,
			material = Enum.Material.Neon,
			collide = false,
			parent = houseFolder,
		})
		Build.light(lamp, C.purple, 40, 1.5)
	end
	Build.billboard(body, label, Color3.fromRGB(255, 220, 170), h / 2 + 3, 150, 1.1)
end

-- Cosmetic trophies for journal milestones (no gameplay effect).
function PlotBuilder.buildTrophies(
	plot: Model,
	index: number,
	caughtCount: number,
	variantCount: number,
	clueCount: number
)
	local folder = plot:FindFirstChild("Trophies") :: Folder
	folder:ClearAllChildren()
	local origin = World.PlotCenters[index]
	local tp = origin + World.Plot.trophies
	local list: { { name: string, color: Color3 } } = {}
	if caughtCount >= 1 then
		table.insert(list, { name = "First Catch", color = Color3.fromRGB(180, 120, 70) })
	end
	if clueCount >= 5 then
		table.insert(list, { name = "Grave Scholar", color = Color3.fromRGB(150, 200, 255) })
	end
	if variantCount >= 1 then
		table.insert(list, { name = "Variant Hunter", color = Color3.fromRGB(200, 200, 215) })
	end
	if caughtCount >= #Monsters.Order then
		table.insert(list, { name = "Full Collection", color = Color3.fromRGB(255, 200, 60) })
	end
	for i, t in list do
		local x = tp.X - 6 + (i - 1) * 4
		Build.block(
			folder,
			"TrophyBase",
			Vector3.new(2, 1.5, 2),
			x,
			0,
			tp.Z,
			Color3.fromRGB(40, 35, 45),
			Enum.Material.Marble
		)
		local cup = Build.part({
			name = t.name,
			size = Vector3.new(1.6, 2.2, 1.6),
			cframe = CFrame.new(x, 2.6, tp.Z),
			color = t.color,
			material = Enum.Material.Foil,
			parent = folder,
		})
		Build.billboard(cup, t.name, t.color, 2.2, 40, 0.5)
	end
end

function PlotBuilder.setOwner(plot: Model, player: Player?)
	plot:SetAttribute("OwnerUserId", if player then player.UserId else 0)
	local sign = plot:FindFirstChild("Sign")
	local label = sign and sign:FindFirstChild("Label")
	local text = label and label:FindFirstChild("Text")
	if text and text:IsA("TextLabel") then
		text.Text = if player then `{player.DisplayName}'s Haunt` else "Vacant Plot"
	end
end

return PlotBuilder
