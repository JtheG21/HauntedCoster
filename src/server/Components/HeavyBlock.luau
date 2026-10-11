--!strict
-- Heavy blocks (TASK-0004). Tag a BasePart "HeavyBlock". The server unanchors it and keeps network
-- ownership of its physics, so pushes are authoritative and identical for every client.
-- (Spike decision: server ownership for shared pushable objects; see the TASK-0004 implementation record.)

local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local HeavyBlock = {}

HeavyBlock.Tag = "HeavyBlock"

local started = false

local function setup(instance: Instance)
	if not instance:IsA("BasePart") then
		return
	end
	if not instance:IsDescendantOf(Workspace) then
		return
	end
	instance.Anchored = false
	-- Server owns the physics: clients can't move it by simulating it locally.
	local ok, err = pcall(function()
		instance:SetNetworkOwner(nil)
	end)
	if not ok then
		warn(`[HeavyBlock] could not set server ownership for {instance:GetFullName()}: {err}`)
	end
end

function HeavyBlock.isBlock(part: BasePart): boolean
	return CollectionService:HasTag(part, HeavyBlock.Tag)
end

-- Gives the block's whole assembly a velocity change of `velocity` (studs/s).
function HeavyBlock.push(part: BasePart, velocity: Vector3)
	part:ApplyImpulse(velocity * part.AssemblyMass)
end

function HeavyBlock.start()
	if started then
		return
	end
	started = true
	CollectionService:GetInstanceAddedSignal(HeavyBlock.Tag):Connect(setup)
	for _, instance in CollectionService:GetTagged(HeavyBlock.Tag) do
		setup(instance)
	end
end

return HeavyBlock
