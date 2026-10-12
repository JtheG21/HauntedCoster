--!strict
-- The persistent outer world (ADR-0007): ground, the ring road joining the six plots, the hub wall with its
-- three gates, the spokes from each plot entrance, lanterns and global lighting. Habitat modules fill the
-- footprint inside the wall and can be swapped; nothing here changes when they do.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local World = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("World"))
local Build = require(script.Parent.Build)
local Props = require(script.Parent.Props)
local Atmosphere = require(script.Parent.Atmosphere)

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
		-- Neighbouring segments overlap a little at the joints; alternate heights so tops never share a plane.
		local h = if i % 2 == 0 then WALL_HEIGHT else WALL_HEIGHT + 0.1
		Build.part({
			name = "HubWall",
			size = Vector3.new(1.6, h, len + 0.6),
			cframe = CFrame.lookAt(Vector3.new(mid.X, h / 2, mid.Z), Vector3.new(b.X, h / 2, b.Z)),
			color = C.darkStone,
			material = Enum.Material.Cobblestone,
			parent = parent,
		})
		Build.part({
			name = "HubRail",
			size = Vector3.new(0.2, 0.2, len),
			cframe = CFrame.lookAt(Vector3.new(mid.X, 5.5, mid.Z), Vector3.new(b.X, 5.5, b.Z)),
			color = C.iron,
			material = Enum.Material.Metal,
			collide = false,
			parent = parent,
		})
		Build.block(parent, "HubSpike", Vector3.new(0.3, 3.2, 0.3), a.X, WALL_HEIGHT, a.Z, C.iron, Enum.Material.Metal)
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

local function gate(parent: Instance, index: number): TextLabel
	local hub = World.Hub
	local angle = hub.gateAngles[index]
	local half = math.deg(math.asin((hub.gateWidth / 2 + 1.5) / hub.wallRadius))
	local pillars = {}
	for _, side in { -1, 1 } do
		local p = World.polar(angle + side * half, hub.wallRadius)
		table.insert(pillars, p)
		Build.block(parent, "GatePillar", Vector3.new(3, 14, 3), p.X, 0, p.Z, C.darkStone, Enum.Material.Cobblestone)
		local lamp = World.polar(angle + side * (half + 3), hub.wallRadius + 3)
		Props.lantern(parent, lamp.X, lamp.Z)
	end
	local a, b = pillars[1], pillars[2]
	local mid = (a + b) / 2
	local arch = Build.part({
		name = "GateArch",
		size = Vector3.new(2, 2, (b - a).Magnitude + 3),
		cframe = CFrame.lookAt(Vector3.new(mid.X, 15, mid.Z), Vector3.new(b.X, 15, b.Z)),
		color = C.iron,
		material = Enum.Material.Metal,
		parent = parent,
	})
	local label = Build.billboard(arch, "HUNTING GROUNDS", Color3.fromRGB(255, 190, 120), 3, 300, 1.5)
	return label:FindFirstChild("Text") :: TextLabel
end

function HubBuilder.build(parent: Instance): Result
	removeStrayBaseplate(parent)
	Atmosphere.apply()
	local hub = World.Hub
	local folder = Instance.new("Folder")
	folder.Name = "World"
	local deco = Build.folder(folder, "Decor")

	Build.part({
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
		table.insert(labels, gate(gates, i))
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
	return { folder = folder, gateLabels = labels }
end

-- The arch signs name the active habitat.
function HubBuilder.setGateLabel(result: Result, text: string)
	for _, label in result.gateLabels do
		label.Text = string.upper(text)
	end
end

return HubBuilder
