--!strict
-- Builds a home plot: ground pad, house (per tier), containment pen, exhibit pedestals, beacon, trophies.
-- The ghost-train track is built separately by TrainService. Everything is built at plot-local coordinates
-- and then placed with the plot's frame (World.plotFrame), so plots can face the hub from any angle.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local World = require(Config:WaitForChild("World"))
local Monsters = require(Config:WaitForChild("Monsters"))
local PlotDecor = require(Config:WaitForChild("PlotDecor"))
local Build = require(script.Parent.Build)
local GroundPainter = require(script.Parent.GroundPainter)
local Props = require(script.Parent.Props)

local PlotBuilder = {}

local C = {
	lawn = Color3.fromRGB(44, 58, 42),
	border = Color3.fromRGB(60, 50, 44),
	plank = Color3.fromRGB(92, 70, 52),
	rot = Color3.fromRGB(70, 60, 50),
	paint = Color3.fromRGB(80, 70, 95),
	roof = Color3.fromRGB(40, 34, 44),
	window = Color3.fromRGB(255, 200, 110),
	trim = Color3.fromRGB(150, 130, 160),
	shutter = Color3.fromRGB(52, 40, 66),
	brick = Color3.fromRGB(90, 52, 46),
	stone = Color3.fromRGB(92, 88, 100),
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

function PlotBuilder.build(parent: Instance, index: number): Model
	local frame = World.plotFrame(index)
	local size = World.PlotSize
	local plot = Instance.new("Model")
	plot.Name = `Plot{index}`
	plot:SetAttribute("PlotIndex", index)
	plot:SetAttribute("OwnerUserId", 0)

	local base = Build.part({
		name = "Base",
		size = Vector3.new(size.X, 0.2, size.Y),
		cframe = CFrame.new(0, 0.1, 0),
		color = C.lawn,
		material = Enum.Material.Grass,
		parent = plot,
	})
	plot.PrimaryPart = base
	GroundPainter.mark(base) -- the lawn is terrain once the plot is placed (TASK-0044)
	-- Low border wall with a front opening facing the hub
	-- Walls are inset half a stud so neighbouring plots' boundary walls don't overlap (z-fighting).
	local hx, hz = size.X / 2 - 0.5, size.Y / 2 - 0.5
	local gap = World.Plot.entranceWidth / 2
	for _, seg in
		{
			{ Vector3.new(-hx, 0, hz), Vector3.new(hx, 0, hz) },
			{ Vector3.new(-hx, 0, -hz), Vector3.new(-hx, 0, hz) },
			{ Vector3.new(hx, 0, -hz), Vector3.new(hx, 0, hz) },
			{ Vector3.new(-hx, 0, -hz), Vector3.new(-gap, 0, -hz) },
			{ Vector3.new(gap, 0, -hz), Vector3.new(hx, 0, -hz) },
		}
	do
		local a, b = seg[1], seg[2]
		local mid = (a + b) / 2
		-- Side walls (along Z) are a little taller so the overlapping corner tops don't z-fight.
		local h = if math.abs(a.X - b.X) < 0.01 then 1.7 else 1.6
		Build.part({
			name = "Border",
			size = Vector3.new(1, h, (b - a).Magnitude),
			cframe = CFrame.lookAt(Vector3.new(mid.X, h / 2, mid.Z), Vector3.new(b.X, h / 2, b.Z)),
			color = C.border,
			material = Enum.Material.Cobblestone,
			parent = plot,
		})
	end

	-- Owner sign at the entrance
	local sign = Build.block(plot, "Sign", Vector3.new(8, 4, 0.5), 0, 0, -hz + 1, C.plank, Enum.Material.Wood)
	Build.billboard(sign, "Vacant Plot", Color3.fromRGB(255, 220, 160), 4, 120, 1)

	-- Containment pen
	local penPos = World.Plot.pen
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
		cframe = CFrame.new(penPos + Vector3.new(0, 0.47, 0)), -- clear of the pad top (0.40)
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
				size = Vector3.new(ps - 0.4, 4, 0.3), -- shorter than the pen so corner bars don't overlap
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
	for i, p in World.Plot.exhibitSlots do
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
	local bp = World.Plot.beacon
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

	-- Plot dressing (TASK-0030, PlotDecor): stone gate pillars with lanterns and an iron arch at the entrance,
	-- warm lamps between the pen and the track area, and dressed exhibit plinths.
	local dressing = Build.folder(plot, "Dressing")
	local pillars = PlotDecor.EntrancePillars
	for _, p in pillars do
		Build.block(dressing, "GatePillar", Vector3.new(2.6, 8, 2.6), p.X, 0, p.Z, C.stone, Enum.Material.Cobblestone)
		Build.block(dressing, "GatePillarCap", Vector3.new(3.2, 0.8, 3.2), p.X, 8, p.Z, C.trim, Enum.Material.Slate)
		local glass = Build.part({
			name = "GateLantern",
			size = Vector3.new(1, 1.3, 1),
			cframe = CFrame.new(p.X, 9.6, p.Z),
			color = Props.C.lantern,
			material = Enum.Material.Neon,
			collide = false,
			parent = dressing,
		})
		Build.light(glass, Props.C.lanternLight, 26, 2)
	end
	local archY = 11
	Build.part({
		name = "GateArch",
		size = Vector3.new(pillars[2].X - pillars[1].X, 0.6, 0.6),
		cframe = CFrame.new((pillars[1].X + pillars[2].X) / 2, archY, pillars[1].Z),
		color = C.iron,
		material = Enum.Material.Metal,
		collide = false,
		parent = dressing,
	})
	for i = -6, 6 do
		Build.part({
			name = "GateSpike",
			size = Vector3.new(0.25, 1.6 - math.abs(i) * 0.08, 0.25),
			cframe = CFrame.new(i * 2, archY + 0.9, pillars[1].Z),
			color = C.iron,
			material = Enum.Material.Metal,
			collide = false,
			parent = dressing,
		})
	end
	for _, p in PlotDecor.Lamps do
		Props.lantern(dressing, p.X, p.Z)
	end
	for _, slot in World.Plot.exhibitSlots do
		local plinth = Build.block(
			dressing,
			"ExhibitPlinth",
			Vector3.new(5.6, 0.4, 5.6),
			slot.X,
			0,
			slot.Z,
			C.stone,
			Enum.Material.Slate
		)
		plinth.CanCollide = false
		for _, c in { { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } } do
			local post = Build.block(
				dressing,
				"ExhibitPost",
				Vector3.new(0.35, 2.2, 0.35),
				slot.X + c[1] * 2.6,
				0,
				slot.Z + c[2] * 2.6,
				C.iron,
				Enum.Material.Metal
			)
			post.CanCollide = false
		end
	end

	-- Place everything built so far; the house, trophies and track folders are placed as they're rebuilt.
	Build.toFrame(plot, frame)
	Build.folder(plot, "House")
	Build.folder(plot, "Trophies")
	Build.folder(plot, "Track")
	plot.Parent = parent
	GroundPainter.paint(plot, { [Enum.Material.Grass] = Enum.Material.LeafyGrass }) -- no blades over pens and exhibits
	PlotBuilder.buildHouse(plot, index, 0)
	return plot
end

-- A framed window on a wall facing -Z (the plot front). `lit` windows glow; only `light` ones cast light,
-- to keep the plot light budget small (TASK-0030).
local function windowAt(parent: Instance, pos: Vector3, lit: boolean, shutters: boolean?, light: boolean?)
	Build.part({
		name = "WindowFrame",
		size = Vector3.new(3, 3, 0.25),
		cframe = CFrame.new(pos + Vector3.new(0, 0, 0.1)),
		color = C.trim,
		material = Enum.Material.Wood,
		collide = false,
		parent = parent,
	})
	local w = Build.part({
		name = "Window",
		size = Vector3.new(2.4, 2.4, 0.3),
		cframe = CFrame.new(pos),
		color = if lit then C.window else Color3.fromRGB(30, 30, 40),
		material = if lit then Enum.Material.Neon else Enum.Material.Glass,
		collide = false,
		parent = parent,
	})
	Build.part({
		name = "WindowBar",
		size = Vector3.new(0.2, 2.4, 0.35),
		cframe = CFrame.new(pos),
		color = C.trim,
		material = Enum.Material.Wood,
		collide = false,
		parent = parent,
	})
	if shutters then
		for _, side in { -1, 1 } do
			Build.part({
				name = "Shutter",
				size = Vector3.new(1.2, 3, 0.2),
				cframe = CFrame.new(pos + Vector3.new(side * 2.2, 0, -0.05)),
				color = C.shutter,
				material = Enum.Material.WoodPlanks,
				collide = false,
				parent = parent,
			})
		end
	end
	if lit and light then
		Build.light(w, C.window, 14, 0.8)
	end
end

local function volume(parent: Instance, box: PlotDecor.Box, color: Color3, material: Enum.Material, rotY: number?)
	return Build.block(parent, box.name, box.size, box.center.X, 0, box.center.Z, color, material, rotY)
end

-- A gable roof over `box` with its ridge along X: two slabs pitched at `pitch` degrees, with an overhang.
local function gable(parent: Instance, box: PlotDecor.Box, pitch: number, overhang: number, color: Color3)
	local p = math.rad(pitch)
	local half = box.size.Z / 2 + overhang
	local ridge = box.size.Y + (box.size.Z / 2) * math.tan(p)
	local len = half / math.cos(p)
	for _, s in { -1, 1 } do
		Build.part({
			name = "Roof",
			size = Vector3.new(box.size.X + overhang * 2, 0.8, len),
			cframe = CFrame.new(box.center.X, ridge - half * math.tan(p) / 2, box.center.Z + s * half / 2)
				* CFrame.Angles(s * p, 0, 0),
			color = color,
			material = Enum.Material.Slate,
			parent = parent,
		})
	end
	Build.part({
		name = "RoofRidge",
		size = Vector3.new(box.size.X + overhang * 2, 0.6, 0.6),
		cframe = CFrame.new(box.center.X, ridge + 0.2, box.center.Z),
		color = C.trim,
		material = Enum.Material.Wood,
		parent = parent,
	})
	-- Gable ends: the triangle under the roof, as a stepped stack (simple parts only).
	for _, ex in { -1, 1 } do
		for i = 1, 3 do
			local h = (ridge - box.size.Y) / 3
			local w = box.size.Z * (1 - (i - 0.5) / 3)
			Build.part({
				name = "Gable",
				size = Vector3.new(0.6, h, w),
				cframe = CFrame.new(
					box.center.X + ex * (box.size.X / 2 - 0.3),
					box.size.Y + h * (i - 0.5),
					box.center.Z
				),
				color = C.paint,
				material = Enum.Material.WoodPlanks,
				parent = parent,
			})
		end
	end
end

-- A trim band round the top of a wall box.
local function trim(parent: Instance, box: PlotDecor.Box, y: number)
	Build.part({
		name = "Trim",
		size = Vector3.new(box.size.X + 0.4, 0.5, box.size.Z + 0.4),
		cframe = CFrame.new(box.center.X, y, box.center.Z),
		color = C.trim,
		material = Enum.Material.Wood,
		parent = parent,
	})
end

-- A columned porch on `box` (its front at -Z), with a flat roof at `height`.
local function porch(parent: Instance, box: PlotDecor.Box, height: number, balcony: boolean)
	volume(parent, box, C.plank, Enum.Material.WoodPlanks)
	local hx, hz = box.size.X / 2 - 0.4, box.size.Z / 2 - 0.4
	for _, c in { { -hx, -hz }, { hx, -hz } } do
		Build.part({
			name = "PorchColumn",
			size = Vector3.new(0.8, height, 0.8),
			cframe = CFrame.new(box.center.X + c[1], height / 2 + box.size.Y, box.center.Z + c[2]),
			color = C.trim,
			material = Enum.Material.Wood,
			parent = parent,
		})
	end
	Build.part({
		name = "PorchRoof",
		size = Vector3.new(box.size.X + 1, 0.6, box.size.Z + 0.6),
		cframe = CFrame.new(box.center.X, height + box.size.Y + 0.3, box.center.Z),
		color = C.roof,
		material = Enum.Material.Slate,
		parent = parent,
	})
	if balcony then
		Build.part({
			name = "BalconyRail",
			size = Vector3.new(box.size.X, 0.3, 0.3),
			cframe = CFrame.new(box.center.X, height + box.size.Y + 2.2, box.center.Z - hz),
			color = C.iron,
			material = Enum.Material.Metal,
			collide = false,
			parent = parent,
		})
		for i = -4, 4 do
			Build.part({
				name = "BalconyBaluster",
				size = Vector3.new(0.15, 1.6, 0.15),
				cframe = CFrame.new(box.center.X + i * box.size.X / 9, height + box.size.Y + 1.4, box.center.Z - hz),
				color = C.iron,
				material = Enum.Material.Metal,
				collide = false,
				parent = parent,
			})
		end
	end
end

local function door(parent: Instance, x: number, z: number, w: number, h: number)
	Build.block(parent, "DoorFrame", Vector3.new(w + 1, h + 0.6, 0.3), x, 0, z + 0.1, C.trim, Enum.Material.Wood)
	Build.block(parent, "Door", Vector3.new(w, h, 0.4), x, 0, z - 0.05, Color3.fromRGB(60, 30, 40), Enum.Material.Wood)
end

local function chimney(parent: Instance, x: number, z: number, base: number, h: number, tilt: number?)
	local c = Build.block(parent, "Chimney", Vector3.new(2, h, 2), x, base, z, C.brick, Enum.Material.Brick)
	if tilt then
		c.CFrame = c.CFrame * CFrame.Angles(0, 0, math.rad(tilt))
	end
end

local function findBox(tier: number, name: string): PlotDecor.Box
	for _, b in PlotDecor.Houses[tier] do
		if b.name == name then
			return b
		end
	end
	error(`no house box {name} for tier {tier}`)
end

-- House tiers (TASK-0030): every main volume comes from PlotDecor.Houses, so the PlotDecor spec proves the
-- house keeps clear of the track area, the pen and the exhibits. Each tier is visibly bigger and richer;
-- the Shabby Shack stays recognisably the old crooked shack.
function PlotBuilder.buildHouse(plot: Model, index: number, tier: number)
	local houseFolder = plot:FindFirstChild("House") :: Folder
	houseFolder:ClearAllChildren()
	local label: string
	local labelPart: BasePart
	if tier <= 0 then
		local shack = findBox(0, "Shack")
		local lean = findBox(0, "LeanTo")
		local body = volume(houseFolder, shack, C.rot, Enum.Material.WoodPlanks, 3)
		local roof = Build.block(
			houseFolder,
			"Roof",
			Vector3.new(shack.size.X + 2, 1.2, shack.size.Z + 2),
			shack.center.X,
			shack.size.Y,
			shack.center.Z,
			C.roof,
			Enum.Material.Slate,
			-4
		)
		roof.CFrame = roof.CFrame * CFrame.Angles(math.rad(6), 0, 0)
		volume(houseFolder, lean, C.rot, Enum.Material.WoodPlanks, -2)
		local leanRoof = Build.block(
			houseFolder,
			"LeanToRoof",
			Vector3.new(lean.size.X + 1, 0.6, lean.size.Z + 1),
			lean.center.X,
			lean.size.Y,
			lean.center.Z,
			C.roof,
			Enum.Material.CorrodedMetal
		)
		leanRoof.CFrame = leanRoof.CFrame * CFrame.Angles(0, 0, math.rad(12))
		volume(houseFolder, findBox(0, "Step"), C.plank, Enum.Material.Wood, 4)
		local front = shack.center.Z - shack.size.Z / 2
		door(houseFolder, shack.center.X, front - 0.1, 3, 6)
		windowAt(houseFolder, Vector3.new(shack.center.X + 4, 5, front - 0.2), false)
		windowAt(houseFolder, Vector3.new(shack.center.X - 4, 5, front - 0.2), true, false, true)
		-- Boards nailed across the dark window
		for _, r in { 35, -35 } do
			Build.part({
				name = "Board",
				size = Vector3.new(3.2, 0.4, 0.2),
				cframe = CFrame.new(shack.center.X + 4, 5, front - 0.45) * CFrame.Angles(0, 0, math.rad(r)),
				color = C.plank,
				material = Enum.Material.Wood,
				collide = false,
				parent = houseFolder,
			})
		end
		chimney(houseFolder, shack.center.X + 5, shack.center.Z + 3, shack.size.Y, 4, 8)
		label, labelPart = "Shabby Shack", body
	else
		local main = findBox(tier, "Manor")
		local body = volume(houseFolder, main, C.paint, Enum.Material.WoodPlanks)
		trim(houseFolder, main, main.size.Y - 0.25)
		trim(houseFolder, main, 0.25)
		gable(houseFolder, main, if tier == 1 then 32 else 38, 1, C.roof)
		local front = main.center.Z - main.size.Z / 2
		door(houseFolder, main.center.X, front - 0.1, 4, 7)
		-- Two rows of windows on the front, shuttered; a couple cast light.
		local cols: { number } = if tier == 1 then { -9, -4.5, 4.5, 9 } else { -12, -6, 6, 12 }
		for row, y in { main.size.Y * 0.32, main.size.Y * 0.7 } do
			for i, cx in cols do
				windowAt(
					houseFolder,
					Vector3.new(main.center.X + cx, y, front - 0.2),
					true,
					true,
					row == 1 and (i == 1 or i == #cols)
				)
			end
		end
		windowAt(houseFolder, Vector3.new(main.center.X, main.size.Y * 0.7, front - 0.2), true, false)
		chimney(houseFolder, main.center.X - main.size.X / 2 + 3, main.center.Z + 2, main.size.Y, 7)
		chimney(houseFolder, main.center.X + main.size.X / 2 - 3, main.center.Z + 2, main.size.Y, 6)
		local wings: { string } = if tier == 1 then { "Wing" } else { "WestWing", "EastWing" }
		for _, wingName in wings do
			local wing = findBox(tier, wingName)
			volume(houseFolder, wing, C.paint, Enum.Material.WoodPlanks)
			trim(houseFolder, wing, wing.size.Y - 0.25)
			gable(houseFolder, wing, 34, 0.8, C.roof)
			windowAt(
				houseFolder,
				Vector3.new(wing.center.X, wing.size.Y * 0.5, wing.center.Z - wing.size.Z / 2 - 0.2),
				true,
				true
			)
		end
		porch(houseFolder, findBox(tier, "Porch"), if tier == 1 then 6 else 7, tier >= 2)
		if tier >= 2 then
			-- Tower with a stepped spire and the purple lantern
			local tower = findBox(2, "Tower")
			volume(houseFolder, tower, C.paint, Enum.Material.WoodPlanks)
			trim(houseFolder, tower, tower.size.Y - 0.25)
			for i = 0, 3 do
				local w = tower.size.X + 1 - i * 2
				Build.block(
					houseFolder,
					"TowerSpire",
					Vector3.new(w, 2, w),
					tower.center.X,
					tower.size.Y + i * 2,
					tower.center.Z,
					C.roof,
					Enum.Material.Slate,
					45
				)
			end
			windowAt(
				houseFolder,
				Vector3.new(tower.center.X, tower.size.Y - 4, tower.center.Z - tower.size.X / 2 - 0.2),
				true,
				false
			)
			local lamp = Build.part({
				name = "TowerLamp",
				size = Vector3.new(2, 2, 2),
				cframe = CFrame.new(tower.center.X, tower.size.Y + 9.5, tower.center.Z),
				color = C.purple,
				material = Enum.Material.Neon,
				collide = false,
				parent = houseFolder,
			})
			Build.light(lamp, C.purple, 40, 1.5)
		end
		label, labelPart = if tier == 1 then "Restored Manor" else "Grand Mansion", body
	end
	Build.billboard(labelPart, label, Color3.fromRGB(255, 220, 170), labelPart.Size.Y / 2 + 8, 150, 1.1)
	Build.toFrame(houseFolder, World.plotFrame(index))
end

-- Cosmetic trophies for journal milestones (no gameplay effect).
-- The clue trophy ("Grave Scholar") was retired with clue hunting (ADR-0007).
function PlotBuilder.buildTrophies(plot: Model, index: number, caughtCount: number, variantCount: number)
	local folder = plot:FindFirstChild("Trophies") :: Folder
	folder:ClearAllChildren()
	local tp = World.Plot.trophies
	local list: { { name: string, color: Color3 } } = {}
	if caughtCount >= 1 then
		table.insert(list, { name = "First Catch", color = Color3.fromRGB(180, 120, 70) })
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
	Build.toFrame(folder, World.plotFrame(index))
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
