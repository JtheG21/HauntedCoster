--!strict
-- Test ability proving the pipeline (TASK-0002). The server picks the direction from the
-- character's facing; the client supplies nothing.
--
-- Replication approach: the player's client owns its character's physics, so the server adds a
-- short-lived LinearVelocity constraint instead of writing velocity directly. The constraint
-- replicates to the owning client, which simulates it, and the movement then replicates to everyone.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AbilityConfig = require(Shared:WaitForChild("AbilityConfig"))
local AbilityRules = require(Shared:WaitForChild("AbilityRules"))

local Dash = {}

function Dash.handler(_player: Player, _character: Model, root: BasePart)
	local direction = AbilityRules.horizontalDirection(root.CFrame.LookVector)

	local attachment = Instance.new("Attachment")
	attachment.Name = "DashAttachment"
	attachment.Parent = root

	local velocity = Instance.new("LinearVelocity")
	velocity.Name = "DashVelocity"
	velocity.Attachment0 = attachment
	velocity.RelativeTo = Enum.ActuatorRelativeTo.World
	velocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
	velocity.PrimaryTangentAxis = Vector3.new(1, 0, 0)
	velocity.SecondaryTangentAxis = Vector3.new(0, 0, 1)
	velocity.PlaneVelocity = Vector2.new(direction.X, direction.Z) * AbilityConfig.Dash.Speed
	velocity.MaxForce = AbilityConfig.Dash.MaxForce
	velocity.Parent = root

	task.delay(AbilityConfig.Dash.Duration, function()
		velocity:Destroy()
		attachment:Destroy()
	end)
end

return Dash
