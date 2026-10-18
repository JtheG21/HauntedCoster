--!strict
-- Handlers for the demo sequence: an FOV push on the camera and an aura or burst of particles on a
-- part. Each returns its own undo so SequencePlayer can always restore the scene.

local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local SequencePlayer = require(script.Parent.SequencePlayer)

local SequenceDemoHandlers = {}

-- anchor: the part effects attach to. Returns handlers plus the emitter count seen at peak.
function SequenceDemoHandlers.make(anchor: BasePart): SequencePlayer.Handlers
	return {
		camera = function(cue)
			local cam = Workspace.CurrentCamera
			if not cam then
				return nil
			end
			local before = cam.FieldOfView
			local goal = (cue.params and cue.params.fov) or before
			TweenService:Create(cam, TweenInfo.new(0.35, Enum.EasingStyle.Quad), { FieldOfView = goal }):Play()
			return function()
				TweenService:Create(cam, TweenInfo.new(0.35, Enum.EasingStyle.Quad), { FieldOfView = before }):Play()
			end
		end,
		effect = function(cue)
			local p = Instance.new("ParticleEmitter")
			p.Name = "SeqEmitter_" .. cue.id
			p.Color = ColorSequence.new(Color3.fromRGB(150, 90, 255))
			p.LightEmission = 0.6
			p.Lifetime = NumberRange.new(0.6, 1.2)
			p.Speed = NumberRange.new(2, 6)
			p.Size = NumberSequence.new(0.5, 0)
			local params: { [string]: any } = cue.params or {}
			if params.effect == "burst" then
				p.Enabled = false
				p.Parent = anchor
				p:Emit(params.count or 30)
			else
				p.Rate = params.rate or 20
				p.Parent = anchor
			end
			return function()
				p:Destroy()
			end
		end,
	}
end

return SequenceDemoHandlers
