--!strict
-- Builds a home plot: ground pad, house (per tier), containment pen, exhibit pedestals, beacon, trophies.
-- The ghost-train track is built separately by TrainService. Everything is built at plot-local coordinates
-- and then placed with the plot's frame (World.plotFrame), so plots can face the hub from any angle.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local World = require(Config:WaitForChild("World"))
local Monsters = require(Config:WaitForChild("Monsters"))
local PlotDecor = require(Config:WaitForChild("PlotDecor"))
local Cosmetics = require(Config:WaitForChild("Cosmetics"))
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
		local len = (b - a).Magnitude
		Build.collider(
			plot,
			"Border",
			Vector3.new(1, h, len),
			CFrame.lookAt(Vector3.new(mid.X, h / 2, mid.Z), Vector3.new(b.X, h / 2, b.Z))
		)
		-- Art (TASK-0046): fieldstone wall runs of about 8 studs.
		local along = (b - a).Unit
		local n = math.max(1, math.round(len / 8))
		for i = 0, n - 1 do
			local c = mid + along * ((i + 0.5) / n - 0.5) * len
			Build.artSlot(
				plot,
				"plot_wall",
				CFrame.fromMatrix(Vector3.new(c.X, 0, c.Z), along, Vector3.yAxis),
				{ ArtStretchX = len / n / 8, ArtStretchY = h / 1.7, ArtCull = 260 }
			)
		end
	end

	-- Owner sign at the entrance
	local sign = Build.block(plot, "Sign", Vector3.new(8, 4, 0.5), 0, 0, -hz + 1, C.plank, Enum.Material.Wood)
	sign.Transparency = 1 -- art: posts and an arched board lettered with the owner's name (TASK-0046)
	Build.billboard(sign, "Vacant Plot", Color3.fromRGB(255, 220, 160), 4, 120, 1)
	Build.artSlot(plot, "plot_sign", CFrame.new(0, 0, -hz + 1))
	local board = Build.part({
		name = "SignBoard",
		size = Vector3.new(6.6, 1.8, 0.32),
		cframe = CFrame.new(0, 2.8, -hz + 1),
		transparency = 1,
		collide = false,
		parent = plot,
	})
	board.CanQuery = false
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		Build.lettering(board, face, "Vacant Plot")
	end

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
		transparency = 1, -- art: slate floor, glowing rune circle and iron fencing (TASK-0046)
		parent = pen,
	})
	Build.artSlot(pen, "pen_cage", CFrame.new(penPos))
	local rune = Build.part({
		name = "PenRune",
		size = Vector3.new(6, 0.1, 6),
		cframe = CFrame.new(penPos + Vector3.new(0, 0.47, 0)), -- clear of the pad top (0.40)
		color = C.purple,
		material = Enum.Material.Neon,
		transparency = 1, -- the art rune glows; this part keeps the light
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
				transparency = 1, -- collider; the fencing is art
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
		ped.Transparency = 1 -- art: stepped marble pedestal with stanchions (TASK-0046)
		Build.artSlot(exhibits, "exhibit_plinth", CFrame.new(p.X, 0, p.Z))
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
		-- Art (TASK-0046): the graveyard kit's stone gate pillar (2 x 9) at 1.2 scale, a wall lantern on its front.
		Build.collider(dressing, "GatePillar", Vector3.new(2.6, 8, 2.6), CFrame.new(p.X, 4, p.Z))
		Build.artSlot(dressing, "gate_pillar", CFrame.new(p.X, 0, p.Z), { ArtScale = 1.2 })
		Build.artSlot(dressing, "lantern_wall", CFrame.new(p.X, 6.4, p.Z - 1.3))
		local glass = Build.part({
			name = "GateLantern",
			size = Vector3.new(0.6, 0.6, 0.6),
			cframe = CFrame.new(p.X, 5.8, p.Z - 2),
			transparency = 1,
			collide = false,
			parent = dressing,
		})
		glass.CanQuery = false
		Build.light(glass, Props.C.lanternLight, 26, 2)
	end
	local span = pillars[2].X - pillars[1].X
	Build.artSlot(
		dressing,
		"gate_arch",
		CFrame.fromMatrix(
			Vector3.new((pillars[1].X + pillars[2].X) / 2, 10.8, pillars[1].Z),
			Vector3.xAxis,
			Vector3.yAxis
		),
		{ ArtStretchX = span / 8 }
	)
	for _, p in PlotDecor.Lamps do
		Props.lantern(dressing, p.X, p.Z)
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

local function findBox(tier: number, name: string): PlotDecor.Box
	for _, b in PlotDecor.Houses[tier] do
		if b.name == name then
			return b
		end
	end
	error(`no house box {name} for tier {tier}`)
end

-- A gable roof's two slabs as colliders over `box` (ridge along X), the shape the old part roofs had.
local function roofCollider(parent: Instance, box: PlotDecor.Box, pitch: number, overhang: number)
	local p = math.rad(pitch)
	local half = box.size.Z / 2 + overhang
	local ridge = box.size.Y + (box.size.Z / 2) * math.tan(p)
	for _, s in { -1, 1 } do
		Build.collider(
			parent,
			"Roof",
			Vector3.new(box.size.X + overhang * 2, 0.8, half / math.cos(p)),
			CFrame.new(box.center.X, ridge - half * math.tan(p) / 2, box.center.Z + s * half / 2)
				* CFrame.Angles(s * p, 0, 0)
		)
	end
end

-- An invisible light source placed where the house art has a lit window or lamp.
local function lightAt(parent: Instance, pos: Vector3, color: Color3, range: number, brightness: number)
	local l = Build.part({
		name = "HouseLight",
		size = Vector3.new(0.4, 0.4, 0.4),
		cframe = CFrame.new(pos),
		transparency = 1,
		collide = false,
		parent = parent,
	})
	l.CanQuery = false
	Build.light(l, color, range, brightness)
end

-- House tiers (TASK-0030 volumes, art TASK-0046): every PlotDecor.Houses box is a collider (so the PlotDecor spec
-- still proves the house keeps clear of the track area, the pen and the exhibits), the main roofs collide as
-- before, and one art asset per tier (house_t0/1/2, authored around the house point) carries the look. Lights sit
-- at the art's lit windows; the Grand Mansion's tower lamp keeps its purple light.
local HOUSE_ART = { [0] = "house_t0", [1] = "house_t1", [2] = "house_t2" }
local WARM = Color3.fromRGB(255, 200, 110)
function PlotBuilder.buildHouse(plot: Model, index: number, tier: number, tint: { [string]: Color3 }?)
	local houseFolder = plot:FindFirstChild("House") :: Folder
	houseFolder:ClearAllChildren()
	local t = math.clamp(tier, 0, 2)
	local labelPart: BasePart? = nil
	for _, box in PlotDecor.Houses[t] do
		local c =
			Build.collider(houseFolder, box.name, box.size, CFrame.new(box.center + Vector3.new(0, box.size.Y / 2, 0)))
		if box.name == "Shack" or box.name == "Manor" then
			labelPart = c
		end
	end
	local anchor = Build.artSlot(houseFolder, HOUSE_ART[t], CFrame.new(World.Plot.house))
	anchor.Name = "HouseArt"
	-- A mansion theme (TASK-0047) tints the art's theme slots (Walls, Trim, Roof, Glass...).
	for part, color in (tint or {}) :: { [string]: Color3 } do
		anchor:SetAttribute("Tint_" .. part, color)
	end
	local label: string
	if t == 0 then
		local shack = findBox(0, "Shack")
		roofCollider(houseFolder, shack, 24, 0.9)
		lightAt(
			houseFolder,
			Vector3.new(shack.center.X + 4, 4.8, shack.center.Z - shack.size.Z / 2 - 0.6),
			WARM,
			14,
			0.8
		)
		label = "Shabby Shack"
	else
		local main = findBox(t, "Manor")
		roofCollider(houseFolder, main, if t == 1 then 32 else 38, 1)
		local front = main.center.Z - main.size.Z / 2 - 0.6
		local edge = if t == 1 then 9 else 12
		lightAt(houseFolder, Vector3.new(main.center.X + edge, main.size.Y * 0.32, front), WARM, 14, 0.8)
		if t == 1 then
			lightAt(houseFolder, Vector3.new(main.center.X - edge, main.size.Y * 0.32, front), WARM, 14, 0.8)
		end
		lightAt(houseFolder, Vector3.new(main.center.X, 6.6, front - 0.4), WARM, 12, 0.7) -- door lanterns
		if t >= 2 then
			local tower = findBox(2, "Tower")
			lightAt(houseFolder, Vector3.new(tower.center.X, 37.6, tower.center.Z), C.purple, 40, 1.5)
		end
		label = if t == 1 then "Restored Manor" else "Grand Mansion"
	end
	local lp = labelPart :: BasePart
	Build.billboard(lp, label, Color3.fromRGB(255, 220, 170), lp.Size.Y / 2 + 8, 150, 1.1)
	Build.toFrame(houseFolder, World.plotFrame(index))
end

-- Exterior decorations (TASK-0047): the owner's validated placements, rebuilt whenever they change. Art only (no
-- collision: PlacementRules already keeps them off paths and gameplay areas); lamps and candles add a light.
function PlotBuilder.buildDecorations(plot: Model, index: number, placements: { any })
	local folder = plot:FindFirstChild("Decorations") :: Folder?
	if not folder then
		local f = Instance.new("Folder")
		f.Name = "Decorations"
		f.Parent = plot
		folder = f
	end
	local root = folder :: Folder
	root:ClearAllChildren()
	for _, p in placements do
		local item = Cosmetics.ById[p.id]
		if item and item.look.art then
			local cf = CFrame.new(p.x, 0, p.z) * CFrame.Angles(0, math.rad(p.rot), 0)
			local anchor = Build.artSlot(root, item.look.art, cf, { ArtScale = item.look.scale or 1, ArtCull = 220 })
			anchor.Name = p.key
			anchor:SetAttribute("Decoration", p.id)
			if item.look.light then
				local glow = Build.part({
					name = "Glow",
					size = Vector3.new(0.3, 0.3, 0.3),
					cframe = cf * CFrame.new(0, 2, 0),
					transparency = 1,
					collide = false,
					parent = root,
				})
				glow.CanQuery = false
				Build.light(glow, Color3.fromRGB(255, 160, 80), 14, 1)
			end
		end
	end
	Build.toFrame(root, World.plotFrame(index))
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
		-- Art (TASK-0046): a gilded urn on a dark plinth, tinted per trophy; the parts keep names and labels.
		Build.collider(folder, "TrophyBase", Vector3.new(2, 1.5, 2), CFrame.new(x, 0.75, tp.Z))
		local cup = Build.part({
			name = t.name,
			size = Vector3.new(1.6, 2.2, 1.6),
			cframe = CFrame.new(x, 2.6, tp.Z),
			color = t.color,
			material = Enum.Material.Foil,
			transparency = 1,
			parent = folder,
		})
		Build.billboard(cup, t.name, t.color, 2.2, 40, 0.5)
		Build.artSlot(folder, "trophy", CFrame.new(x, 0, tp.Z), { Tint_Cup = t.color })
	end
	Build.toFrame(folder, World.plotFrame(index))
end

function PlotBuilder.setOwner(plot: Model, player: Player?)
	plot:SetAttribute("OwnerUserId", if player then player.UserId else 0)
	local sign = plot:FindFirstChild("Sign")
	local label = sign and sign:FindFirstChild("Label")
	local text = label and label:FindFirstChild("Text")
	local name = if player then `{player.DisplayName}'s Haunt` else "Vacant Plot"
	if text and text:IsA("TextLabel") then
		text.Text = name
	end
	local board = plot:FindFirstChild("SignBoard")
	if board then
		for _, sg in board:GetChildren() do
			local t = sg:FindFirstChild("Text")
			if t and t:IsA("TextLabel") then
				t.Text = name
			end
		end
	end
end

return PlotBuilder
