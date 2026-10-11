--!strict
-- Pressure plates (TASK-0003). Tag a BasePart "PressurePlate". It is Active while a living player's
-- character or a part tagged "PlateActivator" (e.g. an Echo Clone) is standing on it.
-- An ObjectValue child named "Door" pointing at a BasePart opens that door while the plate is active.
-- Polling (10 Hz) instead of Touched/TouchEnded, which are unreliable for standing contact.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local PressurePlate = {}

PressurePlate.PlateTag = "PressurePlate"
PressurePlate.ActivatorTag = "PlateActivator"
local POLL_SECONDS = 0.1
local DETECT_HEIGHT = 3

local started = false
-- Last known door per plate. On removal the plate's "Door" link may already be torn down,
-- so the removal handler uses this cache (found by playtest, TEST-20261010-07).
local plateDoors: { [BasePart]: BasePart? } = {}

local function isActivator(part: BasePart): boolean
	if CollectionService:HasTag(part, PressurePlate.ActivatorTag) then
		return true
	end
	local model = part:FindFirstAncestorOfClass("Model")
	if not model or Players:GetPlayerFromCharacter(model) == nil then
		return false
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.Health > 0
end

local function linkedDoor(plate: BasePart): BasePart?
	local link = plate:FindFirstChild("Door")
	local door = if link and link:IsA("ObjectValue") then link.Value else nil
	return if door and door:IsA("BasePart") then door else nil
end

-- A door is open while ANY plate linked to it is active (several plates may share one door).
local function refreshDoor(door: BasePart, ignore: Instance?)
	local open = false
	for _, instance in CollectionService:GetTagged(PressurePlate.PlateTag) do
		if
			instance ~= ignore
			and instance:IsA("BasePart")
			and instance:IsDescendantOf(Workspace)
			and instance:GetAttribute("Active") == true
			and linkedDoor(instance) == door
		then
			open = true
			break
		end
	end
	door.CanCollide = not open
	door.Transparency = if open then 0.8 else 0
end

local function evaluate(plate: BasePart)
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { plate }
	local center = plate.CFrame * CFrame.new(0, plate.Size.Y / 2 + DETECT_HEIGHT / 2, 0)
	local size = Vector3.new(plate.Size.X, DETECT_HEIGHT, plate.Size.Z)

	local active, clonePresent = false, false
	for _, part in Workspace:GetPartBoundsInBox(center, size, params) do
		if isActivator(part) then
			active = true
			if CollectionService:HasTag(part, PressurePlate.ActivatorTag) then
				clonePresent = true -- an Echo Clone, not just a player (Convergence Gates need this)
				break
			end
		end
	end
	if plate:GetAttribute("ClonePresent") ~= clonePresent then
		plate:SetAttribute("ClonePresent", clonePresent)
	end
	local door = linkedDoor(plate)
	plateDoors[plate] = door
	if plate:GetAttribute("Active") ~= active then
		plate:SetAttribute("Active", active)
		if door then
			refreshDoor(door)
		end
	end
end

function PressurePlate.start()
	if started then
		return
	end
	started = true
	-- A plate removed (untagged or destroyed) while active must not leave its door open.
	CollectionService:GetInstanceRemovedSignal(PressurePlate.PlateTag):Connect(function(instance)
		if instance:IsA("BasePart") then
			local door = plateDoors[instance] or linkedDoor(instance)
			plateDoors[instance] = nil
			if door then
				refreshDoor(door, instance)
			end
		end
	end)
	task.spawn(function()
		while true do
			for _, instance in CollectionService:GetTagged(PressurePlate.PlateTag) do
				if instance:IsA("BasePart") and instance:IsDescendantOf(Workspace) then
					evaluate(instance)
				end
			end
			task.wait(POLL_SECONDS)
		end
	end)
end

return PressurePlate
