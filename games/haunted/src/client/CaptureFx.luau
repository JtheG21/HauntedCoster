--!strict
-- Equipped capture effect (TASK-0063): a short cosmetic burst where the player just captured something, or in
-- a local preview. Purely visual: a hidden marker part holds the emitter and is destroyed after the effect, and
-- nothing here is read by capture code. ReduceEffects shortens and thins it.

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CaptureFxRules = require(Shared.Rules.CaptureFxRules)
local CosmeticLooks = require(Shared.Config.CosmeticLooks)
local State = require(script.Parent.State)

local CaptureFx = {}

local MAX_DISTANCE = 120 -- studs: a capture this far from the player is not one they just made
local lastPreview = 0

local function reduceEffects(): boolean
	return Players.LocalPlayer:GetAttribute("ReduceEffects") == true
end

-- Plays effect `id` at `position`. Returns false for an unknown effect.
function CaptureFx.play(id: string, position: Vector3): boolean
	local look = CosmeticLooks.CaptureEffects[id]
	if not look then
		return false
	end
	local reduced = reduceEffects()
	local marker = Instance.new("Part")
	marker.Name = "CaptureFxMarker"
	marker.Anchored = true
	marker.CanCollide = false
	marker.CanQuery = false
	marker.CanTouch = false
	marker.Transparency = 1
	marker.Size = Vector3.one
	marker.Position = position
	local pe = Instance.new("ParticleEmitter")
	pe.Color = ColorSequence.new(look.color)
	pe.LightEmission = 0.9
	pe.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})
	pe.Size = NumberSequence.new(0.5, 0.05)
	pe.Lifetime = NumberRange.new(0.6, if reduced then 0.9 else look.seconds)
	pe.Speed = NumberRange.new(6, 14)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Acceleration = Vector3.new(0, 4, 0)
	pe.Rate = 0
	pe.Enabled = false
	pe.Parent = marker
	marker.Parent = Workspace
	pe:Emit(if reduced then math.floor(look.count / 3) else look.count)
	Debris:AddItem(marker, look.seconds + 1)
	return true
end

-- Replays the effect at the player's feet; rate limited and never touches any live model.
function CaptureFx.preview(id: string): boolean
	local now = os.clock()
	if now - lastPreview < CaptureFxRules.PreviewCooldown then
		return false
	end
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (root and root:IsA("BasePart")) then
		return false
	end
	lastPreview = now
	return CaptureFx.play(id, root.Position + Vector3.new(0, 1, -4))
end

function CaptureFx.mount()
	local event = State.remote("CaptureFx") :: RemoteEvent
	event.OnClientEvent:Connect(function(info)
		local character = Players.LocalPlayer.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not (root and root:IsA("BasePart")) then
			return
		end
		local payload = CaptureFxRules.parsePayload(info, CosmeticLooks.CaptureEffects, root.Position, MAX_DISTANCE)
		if payload then
			CaptureFx.play(payload.id, payload.position)
		end
	end)
end

return CaptureFx
