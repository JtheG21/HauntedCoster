--!strict
-- Client ability input (TASK-0002): keyboard binding plus an on-screen touch button per ability.
-- The client only sends the ability id; the server decides everything else.

local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AbilityConfig = require(Shared:WaitForChild("AbilityConfig"))

local AbilityInput = {}

function AbilityInput.start()
	local remote = ReplicatedStorage:WaitForChild(AbilityConfig.RemoteName) :: RemoteEvent

	for abilityId, def in AbilityConfig.Abilities do
		local keyCode = def.keyCode
		if keyCode == nil then
			continue -- fired only as another ability's release
		end
		local releaseId = def.releaseId
		local actionName = `Ability_{abilityId}`
		ContextActionService:BindAction(actionName, function(_, inputState)
			if inputState == Enum.UserInputState.Begin then
				remote:FireServer(abilityId)
			elseif inputState == Enum.UserInputState.End and releaseId then
				remote:FireServer(releaseId)
			end
			return Enum.ContextActionResult.Sink
		end, true, keyCode)
		ContextActionService:SetTitle(actionName, def.label or abilityId)
	end
end

return AbilityInput
