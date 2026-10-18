--!strict
-- Plays the rare capture finisher when the server says a Rare was just captured (TASK-0055). The server fires
-- `CaptureFinisher` to the capturing player only; everything here is cosmetic. The payload is checked again
-- before use, and the carry timer already includes the finisher's time (CaptureService).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Monsters = require(ReplicatedStorage.Shared.Config.Monsters)
local FinisherRules = require(ReplicatedStorage.Shared.Rules.FinisherRules)
local RareCaptureFinisher = require(script.Parent.RareCaptureFinisher)
local State = require(script.Parent.State)

local CaptureFinisher = {}

local MAX_DISTANCE = 120 -- studs: a capture this far from the player is not one they just made
local DESTINATION_LIFT = Vector3.new(0, 1.5, 0) -- the orb lands on the player, slightly above the root

local function reduceEffects(): boolean
	return Players.LocalPlayer:GetAttribute("ReduceEffects") == true
end

function CaptureFinisher.mount()
	task.spawn(RareCaptureFinisher.preload) -- meshes are created once, off the capture moment
	local event = State.remote("CaptureFinisher") :: RemoteEvent
	event.OnClientEvent:Connect(function(info)
		local character = Players.LocalPlayer.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not root or not root:IsA("BasePart") then
			return
		end
		local payload = FinisherRules.parsePayload(info, Monsters.Species, root.Position, MAX_DISTANCE)
		if not payload then
			return
		end
		-- the monster's model is already gone, so the effects hang from a hidden part on the ground under it
		local hover = Monsters.Species[payload.species].hover
		local marker = Instance.new("Part")
		marker.Name = "FinisherMarker"
		marker.Anchored = true
		marker.CanCollide = false
		marker.CanQuery = false
		marker.Transparency = 1
		marker.Size = Vector3.one
		marker.Position = payload.position - Vector3.new(0, hover, 0)
		marker.Parent = Workspace
		-- A dead or removed character ends the carry; the finisher must not keep the camera and movement
		-- locked over the respawn, so it stops with the character.
		local guards: { RBXScriptConnection } = {}
		local run = RareCaptureFinisher.play(marker, {
			reduced = reduceEffects(),
			destination = root.Position + DESTINATION_LIFT,
			onDone = function()
				for _, c in guards do
					c:Disconnect()
				end
				marker:Destroy()
			end,
		})
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			table.insert(
				guards,
				humanoid.Died:Connect(function()
					run:stop()
				end)
			)
		end
		table.insert(
			guards,
			Players.LocalPlayer.CharacterRemoving:Connect(function()
				run:stop()
			end)
		)
	end)
end

return CaptureFinisher
