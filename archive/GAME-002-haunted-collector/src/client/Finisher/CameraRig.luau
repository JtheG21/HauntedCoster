--!strict
-- Camera handler for the finisher. Every active camera cue contributes: the latest one with a position
-- decides where the camera sits, the latest with a fov sets the field of view, shakes add up. When the
-- last camera cue stops, the camera type and field of view are restored.

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local FinisherRules = require(ReplicatedStorage.Shared.Rules.FinisherRules)
local Sequence = require(ReplicatedStorage.Shared.Sequence)

local CameraRig = {}

local BASE_FOV = 70 -- only a fallback; the swing is based on the player's own field of view once a run starts
local ORBIT_SPEED = 0.5 -- rad/s the camera circles the monster

type Active = { id: string, startedAt: number, p: { [string]: any } }

function CameraRig.new(anchor: BasePart, reduced: boolean): (cue: Sequence.Cue) -> (() -> ())?
	local active: { Active } = {}
	local conn: RBXScriptConnection? = nil
	local saved: { type: Enum.CameraType, fov: number }? = nil
	local fov = BASE_FOV

	local function step(dt: number)
		local cam = Workspace.CurrentCamera
		if not cam or #active == 0 then
			return
		end
		local now = os.clock()
		local posCue: Active?
		local fovCue: Active?
		local shake = 0
		for _, a in active do
			if a.p.pos then
				posCue = a
			end
			if a.p.fov then
				fovCue = a
			end
			shake += FinisherRules.scale("shake", a.p.shake or 0, reduced)
		end
		if posCue then
			local p = posCue.p
			local angle = (now - posCue.startedAt) * ORBIT_SPEED
			local height = if p.pos == "low" then 1.5 else p.height or 5
			local pos = anchor.Position + Vector3.new(math.cos(angle) * p.radius, height, math.sin(angle) * p.radius)
			local offset = Vector3.new(math.noise(now * 20, 1), math.noise(now * 20, 2), math.noise(now * 20, 3))
				* shake
			cam.CFrame = CFrame.lookAt(pos + offset, anchor.Position + Vector3.new(0, 3, 0))
		end
		if fovCue then
			local goal = FinisherRules.fov(if saved then saved.fov else BASE_FOV, fovCue.p.fov, reduced)
			fov += (goal - fov) * math.min(1, dt * 3)
			cam.FieldOfView = fov
		end
	end

	return function(cue)
		local cam = Workspace.CurrentCamera
		if not cam or not RunService:IsClient() then
			return nil
		end
		if not saved then
			saved = { type = cam.CameraType, fov = cam.FieldOfView }
			fov = cam.FieldOfView
			cam.CameraType = Enum.CameraType.Scriptable
			conn = RunService.RenderStepped:Connect(step)
		end
		local entry: Active = { id = cue.id, startedAt = os.clock(), p = cue.params or {} }
		table.insert(active, entry)
		return function()
			local i = table.find(active, entry)
			if i then
				table.remove(active, i)
			end
			-- Cuts replace one camera cue with the next in the same frame (the runner stops the old cue
			-- first). Restoring now would flash the player's camera for a frame, so check again after.
			task.defer(function()
				if #active > 0 or not saved then
					return
				end
				if conn then
					conn:Disconnect()
					conn = nil
				end
				local current = Workspace.CurrentCamera
				if current then
					current.CameraType = saved.type
					current.FieldOfView = saved.fov
				end
				saved = nil
			end)
		end
	end
end

return CameraRig
