--!strict
-- The persistent outer world (ADR-0007): ground, the ring road joining the six plots, the hub wall with its
-- three gates, the spokes from each plot entrance, lanterns and global lighting. Habitat modules fill the
-- footprint inside the wall and can be swapped; nothing here changes when they do.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local World = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("World"))
local Build = require(script.Parent.Build)
local Props = require(script.Parent.Props)
local Atmosphere = require(script.Parent.Atmosphere)
local GroundPainter = require(script.Parent.GroundPainter)

local HubBuilder = {}

export type Result = {
	folder: Folder,
	gateLabels: { TextLabel },
}

local C = Props.C
local WALL_HEIGHT = 3
local WALL_COLLIDER = 10 -- taller than a jump, so the gates are the only way in or out

-- A Baseplate left by a mis-synced project (e.g. GAME-001's Rojo tree) sits exactly at ground level and
-- z-fights with our ground everywhere. This game owns its Workspace, so remove it.
local function removeStrayBaseplate(parent: Instance)
	local stray = parent:FindFirstChild("Baseplate")
	if stray and stray:IsA("BasePart") then
		warn("[World] removed a stray Workspace.Baseplate (it z-fights with the ground)")
		stray:Destroy()
	end
end

local function wallArc(parent: Instance, fromAngle: number, toAngle: number)
	local r = World.Hub.wallRadius
	local steps = math.max(1, math.ceil((toAngle - fromAngle) / 6))
	for i = 0, steps - 1 do
		local a = World.polar(fromAngle + (toAngle - fromAngle) * i / steps, r)
		local b = World.polar(fromAngle + (toAngle - fromAngle) * (i + 1) / steps, r)
		local mid = (a + b) / 2
		local len = (b - a).Magnitude
		local along = Vector3.new(b.X - a.X, 0, b.Z - a.Z).Unit
		-- Art (TASK-0044): a coped stone run with an iron railing and a pier, stretched to the segment.
		Build.artSlot(
			parent,
			"hub_wall",
			CFrame.fromMatrix(Vector3.new(mid.X, 0, mid.Z), along, Vector3.yAxis),
			{ ArtStretchX = (len + 0.6) / 12 }
		)
		Build.collider(
			parent,
			"HubWall",
			Vector3.new(1.6, WALL_HEIGHT, len + 0.6),
			CFrame.lookAt(Vector3.new(mid.X, WALL_HEIGHT / 2, mid.Z), Vector3.new(b.X, WALL_HEIGHT / 2, b.Z))
		)
		Build.part({
			name = "HubWallCollider",
			size = Vector3.new(1, WALL_COLLIDER, len + 0.8),
			cframe = CFrame.lookAt(
				Vector3.new(mid.X, WALL_COLLIDER / 2, mid.Z),
				Vector3.new(b.X, WALL_COLLIDER / 2, b.Z)
			),
			transparency = 1,
			parent = parent,
		})
	end
end

-- One face of the hanging gate sign: the habitat name lettered on the board (TASK-0044).
local function signFace(sign: BasePart, face: Enum.NormalId): TextLabel
	return Build.lettering(sign, face, "HUNTING GROUNDS")
end

local function gate(parent: Instance, index: number): { TextLabel }
	local hub = World.Hub
	local angle = hub.gateAngles[index]
	local half = math.deg(math.asin((hub.gateWidth / 2 + 1.5) / hub.wallRadius))
	local pillars = {}
	local outward = World.polar(angle, 1) - World.polar(angle, 0)
	outward = Vector3.new(outward.X, 0, outward.Z).Unit
	for _, side in { -1, 1 } do
		local p = World.polar(angle + side * half, hub.wallRadius)
		table.insert(pillars, p)
		Build.collider(parent, "GatePillar", Vector3.new(3, 14, 3), CFrame.new(p.X, 7, p.Z))
		Build.artSlot(
			parent,
			"hub_gate_pillar",
			CFrame.lookAt(Vector3.new(p.X, 0, p.Z), Vector3.new(p.X, 0, p.Z) + outward)
		)
		local lamp = World.polar(angle + side * (half + 3), hub.wallRadius + 3)
		Props.lantern(parent, lamp.X, lamp.Z)
	end
	local a, b = pillars[1], pillars[2]
	local mid = (a + b) / 2
	local across = Vector3.new(b.X - a.X, 0, b.Z - a.Z).Unit
	Build.artSlot(
		parent,
		"hub_gate_arch",
		CFrame.fromMatrix(Vector3.new(mid.X, 12.9, mid.Z), across, Vector3.yAxis),
		{ ArtStretchX = (b - a).Magnitude / 20 }
	)
	local signCF = CFrame.fromMatrix(Vector3.new(mid.X, 10.6, mid.Z), across, Vector3.yAxis)
	Build.artSlot(parent, "hub_gate_sign", signCF)
	local sign = Build.part({
		name = "GateSign",
		size = Vector3.new(8.4, 1.5, 0.34),
		cframe = signCF,
		transparency = 1,
		collide = false,
		parent = parent,
	})
	sign.CanQuery = false
	return { signFace(sign, Enum.NormalId.Front), signFace(sign, Enum.NormalId.Back) }
end

function HubBuilder.build(parent: Instance): Result
	removeStrayBaseplate(parent)
	Atmosphere.apply()
	local hub = World.Hub
	local folder = Instance.new("Folder")
	folder.Name = "World"
	local deco = Build.folder(folder, "Decor")

	local ground = Build.part({
		name = "Ground",
		size = Vector3.new(1400, 2, 1400),
		cframe = CFrame.new(hub.center.X, -1, hub.center.Z),
		color = C.grass,
		material = Enum.Material.Grass,
		parent = folder,
	})
	-- Stacked discs with distinct top heights (no coplanar faces): road, then the verge inside it.
	Props.disc(folder, "RingRoad", hub.center, hub.ringOuter, 0.06, C.cobble, Enum.Material.Cobblestone)
	Props.disc(folder, "HubVerge", hub.center, hub.ringInner, 0.09, Color3.fromRGB(34, 46, 36), Enum.Material.Grass)

	-- Hub wall: arcs between the gates
	local walls = Build.folder(folder, "HubWall")
	local gateHalf = math.deg(math.asin((hub.gateWidth / 2 + 3) / hub.wallRadius))
	local n = #hub.gateAngles
	for i = 1, n do
		local from = hub.gateAngles[i] + gateHalf
		local to = hub.gateAngles[i % n + 1] + (if i == n then 360 else 0) - gateHalf
		wallArc(walls, from, to)
	end
	local gates = Build.folder(folder, "Gates")
	local labels: { TextLabel } = {}
	for i = 1, n do
		for _, label in gate(gates, i) do
			table.insert(labels, label)
		end
	end

	-- Spokes: each plot entrance to the ring road, with a lantern pair at the road edge
	for i = 1, #World.PlotCenters do
		local entrance = World.plotToWorld(i, World.Plot.entrance)
		local roadEdge = World.polar(World.PlotAngles[i], hub.ringOuter - 1)
		Build.strip(folder, "Spoke", roadEdge, entrance, 14, C.cobble, Enum.Material.Cobblestone, 0.075)
		for _, side in { -1, 1 } do
			local lamp = World.polar(World.PlotAngles[i] + side * 4.5, hub.ringOuter + 2)
			Props.lantern(deco, lamp.X, lamp.Z)
		end
	end
	-- Warm lights along the inner edge of the ring road, between plots and gates
	for a = 15, 345, 30 do
		local lamp = World.polar(a, hub.ringInner - 1.5)
		Props.lantern(deco, lamp.X, lamp.Z)
	end
	-- Dead trees in the wedges between plots that hold no gate
	local rng = Random.new(4242)
	for _, wedge in { 60, 180, 300 } do
		for _ = 1, 3 do
			local p = World.polar(wedge + rng:NextNumber(-6, 6), rng:NextNumber(150, 215))
			Props.deadTree(deco, rng, p.X, p.Z)
		end
	end

	folder.Parent = parent
	GroundPainter.style()
	GroundPainter.paintOuter(ground, 330) -- terrain across the hub and every plot; the part shows beyond
	GroundPainter.paint(folder, { [Enum.Material.Grass] = Enum.Material.LeafyGrass })
	return { folder = folder, gateLabels = labels }
end

-- The arch signs name the active habitat.
function HubBuilder.setGateLabel(result: Result, text: string)
	for _, label in result.gateLabels do
		label.Text = string.upper(text)
	end
end

return HubBuilder
