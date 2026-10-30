--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Gameplay = require(ReplicatedStorage.Shared.Config.Gameplay)
local CameraRules = require(ReplicatedStorage.Shared.Rules.CameraRules)
local EvidenceRules = require(ReplicatedStorage.Shared.Rules.EvidenceRules)
local RoundService = require(script.Parent.RoundService)
local CryptidService = require(script.Parent.CryptidService)
local Remotes = require(script.Parent.Remotes)

local EvidenceService = {}

type Bucket = { tokens: number, at: number }
local buckets: { [Player]: { [string]: Bucket } } = {}
local lastShutterAt: { [Player]: number } = {}
local lastStateCapture: { [Player]: { state: string, at: number } } = {}
local lastProvokeAt: { [Player]: number } = {}
local lastRoundNumber: { [Player]: number } = {}

local function allow(player: Player, key: string, rate: number, burst: number): boolean
	local now = os.clock()
	local mine = buckets[player]
	if not mine then
		mine = {}
		buckets[player] = mine
	end
	local bucket = mine[key]
	if not bucket then
		bucket = { tokens = burst, at = now }
		mine[key] = bucket
	end
	bucket.tokens = math.min(burst, bucket.tokens + (now - bucket.at) * rate)
	bucket.at = now
	if bucket.tokens < 1 then
		return false
	end
	bucket.tokens -= 1
	return true
end

local function reject(player: Player, reason: string)
	RoundService.record("shot_rejected")
	RoundService.record("shot_rejected_" .. reason)
	Remotes.Event:FireClient(player, { type = "shot_rejected", message = reason })
end

local function isFiniteVector3(value: Vector3): boolean
	return value.X == value.X
		and value.Y == value.Y
		and value.Z == value.Z
		and math.abs(value.X) < math.huge
		and math.abs(value.Y) < math.huge
		and math.abs(value.Z) < math.huge
end

local function handleShutter(player: Player, aimOrigin: any, aimDirection: any)
	RoundService.record("shot_attempted")
	if player ~= RoundService.getOwner() or not RoundService.canPhotograph() then
		reject(player, "The camera is not ready for a photo.")
		return
	end
	if not allow(player, "shutter", 1.5, 2) then
		reject(player, "Let the camera settle before another shot.")
		return
	end
	local now = os.clock()
	if now - (lastShutterAt[player] or 0) < Gameplay.MinShutterInterval then
		reject(player, "Let the camera settle before another shot.")
		return
	end
	lastShutterAt[player] = now

	if typeof(aimOrigin) ~= "Vector3" or typeof(aimDirection) ~= "Vector3" then
		reject(player, "The camera aim was invalid.")
		return
	end
	if not isFiniteVector3(aimOrigin) or not isFiniteVector3(aimDirection) or aimDirection.Magnitude <= 0 then
		reject(player, "The camera aim was invalid.")
		return
	end
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	local playerRoot = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local creatureModel = CryptidService.getModel()
	local creatureRoot = CryptidService.getRoot()
	if
		not (
			head
			and head:IsA("BasePart")
			and playerRoot
			and playerRoot:IsA("BasePart")
			and humanoid
			and humanoid.Health > 0
			and creatureModel
			and creatureRoot
		)
	then
		reject(player, "The trail is not ready for a photo.")
		return
	end

	local direction = aimDirection
	local selfieFacing = -playerRoot.CFrame.LookVector
	local expectedOrigin = head.Position
		+ playerRoot.CFrame.LookVector * Gameplay.SelfieForwardOffset
		+ playerRoot.CFrame.RightVector * Gameplay.SelfieSideOffset
		+ Vector3.new(0, Gameplay.SelfieHeightOffset, 0)
	if (aimOrigin - expectedOrigin).Magnitude > Gameplay.MaxAimOriginOffset then
		reject(player, "Hold the selfie camera near your hiker.")
		return
	end
	if
		not CameraRules.isPlausibleDirection(
			direction.X,
			direction.Y,
			direction.Z,
			selfieFacing.X,
			selfieFacing.Y,
			selfieFacing.Z,
			Gameplay.MaxAimFacingDot
		)
	then
		reject(player, "Turn toward the subject before taking the photo.")
		return
	end
	direction = direction.Unit

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character :: Model }
	local hit = Workspace:Raycast(aimOrigin, direction * Gameplay.MaxPhotoRange, params)
	if not hit or not hit.Instance:IsDescendantOf(creatureModel) then
		reject(player, "No cryptid in the frame. Aim at its silhouette.")
		return
	end

	local offset = creatureRoot.Position - aimOrigin
	local distance = offset.Magnitude
	if distance <= 0 or distance > Gameplay.MaxPhotoRange then
		reject(player, "The cryptid is outside the camera's usable range.")
		return
	end
	local frameDot = math.clamp(offset.Unit:Dot(direction), -1, 1)
	local frameError = math.deg(math.acos(frameDot))
	local state = CryptidService.getState()
	local previous = lastStateCapture[player]
	if previous and previous.state == state and now - previous.at < 2 then
		reject(player, "That behavior is already recorded. Wait for a new moment.")
		return
	end

	local result = EvidenceRules.evaluate({
		distance = distance,
		frameErrorDegrees = frameError,
		state = state,
		wasAware = CryptidService.isAware(player),
		tuning = Gameplay.Evidence,
	})
	if not result then
		reject(player, "The camera could not evaluate that frame.")
		return
	end

	lastStateCapture[player] = { state = state, at = now }
	RoundService.addEvidence(result, distance)
	CryptidService.photographed(player)
	Remotes.Event:FireClient(player, {
		type = "photo",
		evidenceCount = RoundService.getEvidenceCount(),
		points = result.points,
		maxPoints = result.maxPoints,
		tier = result.tier,
		behavior = result.behavior,
		breakdown = result.breakdown,
		distanceBand = if distance <= Gameplay.Evidence.CloseRange
			then "close"
			elseif distance <= Gameplay.Evidence.GoodRange then "near"
			elseif distance <= Gameplay.Evidence.LongRange then "far"
			else "distant",
	})
end

local function handleProvoke(player: Player)
	if player ~= RoundService.getOwner() or not RoundService.canPhotograph() then
		return
	end
	if not allow(player, "provoke", 0.5, 1) then
		return
	end
	local now = os.clock()
	if now - (lastProvokeAt[player] or 0) < Gameplay.ProvokeCooldown then
		return
	end
	lastProvokeAt[player] = now
	local ok, reason = CryptidService.provoke(player)
	if ok then
		RoundService.record("cryptid_provoked")
	else
		Remotes.Event:FireClient(player, { type = "hint", text = reason or "Nothing answers." })
	end
end

function EvidenceService.start()
	Remotes.Action.OnServerEvent:Connect(function(player, action: any, payload: any, extra: any)
		local currentRound = RoundService.getRoundNumber()
		if lastRoundNumber[player] ~= currentRound then
			lastRoundNumber[player] = currentRound
			lastShutterAt[player] = nil
			lastStateCapture[player] = nil
			lastProvokeAt[player] = nil
		end
		if type(action) ~= "string" then
			return
		end
		if action == "shutter" then
			handleShutter(player, payload, extra)
		elseif action == "provoke" then
			handleProvoke(player)
		elseif action == "restart" then
			if allow(player, "restart", 0.3, 1) then
				local ok, reason = RoundService.restart(player)
				if not ok and reason then
					Remotes.Event:FireClient(player, { type = "hint", text = reason })
				end
			end
		elseif action == "camera_opened" then
			if allow(player, "camera_opened", 1, 1) and player == RoundService.getOwner() then
				RoundService.record("camera_opened")
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		buckets[player] = nil
		lastShutterAt[player] = nil
		lastStateCapture[player] = nil
		lastProvokeAt[player] = nil
		lastRoundNumber[player] = nil
	end)
end

return EvidenceService
