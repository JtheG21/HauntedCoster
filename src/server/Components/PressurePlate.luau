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

local function setDoor(plate: BasePart, open: boolean)
	local link = plate:FindFirstChild("Door")
	local door = if link and link:IsA("ObjectValue") then link.Value else nil
	if door and door:IsA("BasePart") then
		door.CanCollide = not open
		door.Transparency = if open then 0.8 else 0
	end
end

local function evaluate(plate: BasePart)
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { plate }
	local center = plate.CFrame * CFrame.new(0, plate.Size.Y / 2 + DETECT_HEIGHT / 2, 0)
	local size = Vector3.new(plate.Size.X, DETECT_HEIGHT, plate.Size.Z)

	local active = false
	for _, part in Workspace:GetPartBoundsInBox(center, size, params) do
		if isActivator(part) then
			active = true
			break
		end
	end
	if plate:GetAttribute("Active") ~= active then
		plate:SetAttribute("Active", active)
		setDoor(plate, active)
	end
end

function PressurePlate.start()
	if started then
		return
	end
	started = true
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
