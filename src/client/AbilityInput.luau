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
		local actionName = `Ability_{abilityId}`
		ContextActionService:BindAction(actionName, function(_, inputState)
			if inputState == Enum.UserInputState.Begin then
				remote:FireServer(abilityId)
			end
			return Enum.ContextActionResult.Sink
		end, true, def.keyCode)
		ContextActionService:SetTitle(actionName, def.label)
	end
end

return AbilityInput
