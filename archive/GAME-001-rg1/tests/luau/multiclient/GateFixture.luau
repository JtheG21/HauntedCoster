--!strict
-- Test fixture (TASK-0005): builds one Convergence Gate with all its inputs at `origin`.
-- Layout along +Z: approach zone, Shinobi plate + Ki target, gate barrier, pass zone; bypass to the side.
-- Not a scenario (returns a table): StudioTestHook ignores modules that aren't functions.

local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

export type Gate = {
	folder: Folder,
	gate: BasePart,
	plate: BasePart,
	kiTarget: BasePart,
	passZone: BasePart,
	approach: BasePart,
	bypass: BasePart,
}

local GateFixture = {}

local function part(folder: Folder, name: string, size: Vector3, position: Vector3, props: { [string]: any }?): BasePart
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.Position = position
	if props then
		for key, value in props do
			(p :: any)[key] = value
		end
	end
	p.Parent = folder
	return p
end

local function link(from: Instance, name: string, to: Instance)
	local value = Instance.new("ObjectValue")
	value.Name = name
	value.Value = to
	value.Parent = from
end

function GateFixture.build(origin: Vector3, powers: string?): Gate
	local folder = Instance.new("Folder")
	folder.Name = "TestGate"
	folder.Parent = Workspace

	local zoneProps = { CanCollide = false, Transparency = 0.9, CanTouch = false }
	local approach = part(folder, "ApproachZone", Vector3.new(16, 6, 6), origin + Vector3.new(0, 3, -10), zoneProps)
	local plate = part(folder, "ShinobiPlate", Vector3.new(5, 1, 5), origin + Vector3.new(-5, 0.5, -4))
	local kiTarget = part(
		folder,
		"KiTarget",
		Vector3.new(3, 3, 1),
		origin + Vector3.new(5, 2.5, -2),
		{ Color = Color3.fromRGB(240, 170, 40) }
	)
	local gate = part(folder, "Gate", Vector3.new(16, 10, 1), origin + Vector3.new(0, 5, 0))
	local passZone = part(folder, "PassZone", Vector3.new(16, 6, 6), origin + Vector3.new(0, 3, 5), zoneProps)
	local bypass = part(folder, "BypassBlocker", Vector3.new(1, 10, 6), origin + Vector3.new(14, 5, 0))

	CollectionService:AddTag(plate, "PressurePlate")
	CollectionService:AddTag(kiTarget, "KiTarget")
	link(gate, "ShinobiPlate", plate)
	link(gate, "KiTarget", kiTarget)
	link(gate, "PassZone", passZone)
	link(gate, "ApproachZone", approach)
	link(gate, "Bypass", bypass)
	if powers then
		gate:SetAttribute("Powers", powers)
	end
	CollectionService:AddTag(gate, "ConvergenceGate")

	return {
		folder = folder,
		gate = gate,
		plate = plate,
		kiTarget = kiTarget,
		passZone = passZone,
		approach = approach,
		bypass = bypass,
	}
end

-- Stand-in for an Echo Clone on the plate (same tag the real clone uses).
function GateFixture.fakeClone(g: Gate): BasePart
	local clone = Instance.new("Part")
	clone.Name = "FakeEchoClone"
	clone.Anchored = true
	clone.CanCollide = false
	clone.Size = Vector3.new(2, 5, 1)
	clone.Position = g.plate.Position + Vector3.new(0, 3, 0)
	CollectionService:AddTag(clone, "PlateActivator")
	clone.Parent = g.folder
	return clone
end

return GateFixture
