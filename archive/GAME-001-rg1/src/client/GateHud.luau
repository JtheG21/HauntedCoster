--!strict
-- Client HUD for Convergence Gates (TASK-0005): a billboard on each gate that shows which faction
-- powers it needs, whether it's open, and the Echo Shrine countdown. Display only; the server
-- decides everything.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local FactionConfig = require(Shared:WaitForChild("FactionConfig"))
local GateConfig = require(Shared:WaitForChild("GateConfig"))

local GateHud = {}

local labels: { [BasePart]: TextLabel } = {}

local function describe(gate: BasePart): string
	if gate:GetAttribute("State") == "open" then
		return "OPEN: go through to earn Echoes"
	end
	local required = gate:GetAttribute("Required")
	local names = {}
	if typeof(required) == "string" and #required > 0 then
		for _, faction in string.split(required, ",") do
			local def = FactionConfig.Factions[faction]
			table.insert(names, if def then def.displayName else faction)
		end
	end
	local needs = if #names > 0 then "Needs: " .. table.concat(names, " + ") else "Needs: Echo Shrine"
	if gate:GetAttribute("HasBypass") ~= true then
		return needs
	end
	if gate:GetAttribute("ShrineOpen") == true then
		return needs .. "\nEcho Shrine path is OPEN"
	end
	local shrineAt = gate:GetAttribute("ShrineAt")
	if typeof(shrineAt) == "number" then
		-- ShrineAt is server os.clock() time, not comparable on the client, so no exact countdown (M3 polish).
		return needs .. "\nEcho Shrine opening soon"
	end
	return needs
end

local function attach(instance: Instance)
	if not instance:IsA("BasePart") or labels[instance] then
		return
	end
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "GateHud"
	billboard.Size = UDim2.fromOffset(260, 70)
	billboard.StudsOffset = Vector3.new(0, instance.Size.Y / 2 + 2, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 120
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 0.35
	label.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = billboard
	billboard.Adornee = instance
	billboard.Parent = instance
	labels[instance] = label
end

function GateHud.start()
	CollectionService:GetInstanceAddedSignal(GateConfig.Tag):Connect(attach)
	CollectionService:GetInstanceRemovedSignal(GateConfig.Tag):Connect(function(instance)
		if instance:IsA("BasePart") then
			labels[instance] = nil
		end
	end)
	for _, instance in CollectionService:GetTagged(GateConfig.Tag) do
		attach(instance)
	end
	local accumulated = 0
	RunService.Heartbeat:Connect(function(dt)
		accumulated += dt
		if accumulated < 0.25 then
			return
		end
		accumulated = 0
		for gate, label in labels do
			if gate:IsDescendantOf(Workspace) then
				label.Text = describe(gate)
			end
		end
	end)
end

return GateHud
