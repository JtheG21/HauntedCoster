--!strict
local PathfindingService = game:GetService("PathfindingService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Gameplay = require(ReplicatedStorage.Shared.Config.Gameplay)
local Remotes = require(script.Parent.Remotes)

local CryptidService = {}

type State = "Roaming" | "Investigating" | "Pursuing" | "Returning"
type LostCallback = (Player) -> ()

local model: Model? = nil
local root: BasePart? = nil
local currentState: State = "Returning"
local targetPlayer: Player? = nil
local home = Vector3.new(0, 8, 0)
local roamIndex = 1
local roamDeadline = 0
local investigationDeadline = 0
local chaseDeadline = 0
local lastSeenAt = 0
local chaseStartedAt = 0
local lostCallback: LostCallback? = nil
local running = false
local runVersion = 0
local stateEvent = Remotes.Event

local COLORS = {
	Roaming = Color3.fromRGB(147, 205, 178),
	Investigating = Color3.fromRGB(231, 198, 112),
	Pursuing = Color3.fromRGB(221, 83, 70),
	Returning = Color3.fromRGB(130, 156, 151),
}

local function makePart(
	parent: Model,
	name: string,
	size: Vector3,
	offset: Vector3,
	color: Color3,
	shape: Enum.PartType?
): BasePart
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Shape = shape or Enum.PartType.Block
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = true
	part.Material = Enum.Material.SmoothPlastic
	part.Color = color
	part.CFrame = CFrame.new(offset)
	part.Parent = parent
	return part
end

local function buildModel(at: Vector3): (Model, BasePart)
	local creature = Instance.new("Model")
	creature.Name = "RidgeWalker_Blockout"
	local pivot = makePart(creature, "Root", Vector3.new(2, 5, 2), Vector3.zero, Color3.new(1, 1, 1))
	pivot.Transparency = 1
	creature.PrimaryPart = pivot
	makePart(creature, "Body", Vector3.new(4, 5, 2.5), Vector3.new(0, 3, 0), COLORS.Roaming)
	makePart(
		creature,
		"Head",
		Vector3.new(2.8, 2.8, 2.8),
		Vector3.new(0, 6.4, 0),
		Color3.fromRGB(78, 110, 90),
		Enum.PartType.Ball
	)
	makePart(creature, "BranchLeft", Vector3.new(5.8, 0.7, 0.8), Vector3.new(-3.4, 4.7, 0), Color3.fromRGB(70, 86, 67))
	makePart(creature, "BranchRight", Vector3.new(5.8, 0.7, 0.8), Vector3.new(3.4, 4.7, 0), Color3.fromRGB(70, 86, 67))
	makePart(
		creature,
		"EyeLeft",
		Vector3.new(0.45, 0.45, 0.2),
		Vector3.new(-0.55, 6.5, -1.34),
		COLORS.Investigating,
		Enum.PartType.Ball
	).Material =
		Enum.Material.Neon
	makePart(
		creature,
		"EyeRight",
		Vector3.new(0.45, 0.45, 0.2),
		Vector3.new(0.55, 6.5, -1.34),
		COLORS.Investigating,
		Enum.PartType.Ball
	).Material =
		Enum.Material.Neon
	creature:PivotTo(CFrame.new(at))
	creature.Parent = Workspace
	return creature, pivot
end

local function setState(nextState: State)
	currentState = nextState
	if model then
		model:SetAttribute("BehaviorState", nextState)
		local body = model:FindFirstChild("Body")
		local leftEye = model:FindFirstChild("EyeLeft")
		local rightEye = model:FindFirstChild("EyeRight")
		if body and body:IsA("BasePart") then
			body.Color = COLORS[nextState]
		end
		for _, eye in { leftEye, rightEye } do
			if eye and eye:IsA("BasePart") then
				eye.Color = if nextState == "Pursuing" then COLORS.Pursuing else COLORS.Investigating
			end
		end
	end
	stateEvent:FireAllClients({ type = "cryptid_state", state = nextState })
end

local function getPlayerRoot(player: Player): BasePart?
	local character = player.Character
	local candidate = character and character:FindFirstChild("HumanoidRootPart")
	return if candidate and candidate:IsA("BasePart") then candidate else nil
end

local function visibleTo(player: Player): boolean
	local creatureRoot = root
	local playerRoot = getPlayerRoot(player)
	if not creatureRoot or not playerRoot then
		return false
	end
	local origin = creatureRoot.Position + Vector3.new(0, 3, 0)
	local target = playerRoot.Position + Vector3.new(0, 2, 0)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local excluded: { Instance } = { creatureRoot }
	if model then
		table.insert(excluded, model)
	end
	if player.Character then
		table.insert(excluded, player.Character)
	end
	params.FilterDescendantsInstances = excluded
	local result = Workspace:Raycast(origin, target - origin, params)
	return result == nil
end

local function stepToward(target: Vector3, speed: number, dt: number)
	local creatureRoot = root
	local creature = model
	if not creatureRoot or not creature then
		return
	end
	local current = creatureRoot.Position
	local flatTarget = Vector3.new(target.X, current.Y, target.Z)
	local delta = flatTarget - current
	if delta.Magnitude <= 0.2 then
		return
	end
	local move = math.min(delta.Magnitude, speed * dt)
	local nextPosition = current + delta.Unit * move
	creature:PivotTo(CFrame.lookAt(nextPosition, nextPosition + delta.Unit))
end

local function pathTarget(playerRoot: BasePart): Vector3
	local creatureRoot = root
	if not creatureRoot then
		return playerRoot.Position
	end
	local path = PathfindingService:CreatePath({
		AgentRadius = 2,
		AgentHeight = 7,
		AgentCanJump = false,
		WaypointSpacing = 6,
	})
	local ok = pcall(function()
		path:ComputeAsync(creatureRoot.Position, playerRoot.Position)
	end)
	if ok and path.Status == Enum.PathStatus.Success then
		local waypoints = path:GetWaypoints()
		if #waypoints >= 2 then
			return waypoints[2].Position
		end
	end
	return playerRoot.Position
end

local function transitionToReturning()
	if currentState ~= "Returning" then
		targetPlayer = nil
		setState("Returning")
	end
end

function CryptidService.getModel(): Model?
	return model
end

function CryptidService.getRoot(): BasePart?
	return root
end

function CryptidService.getState(): State
	return currentState
end

function CryptidService.isAware(player: Player): boolean
	return targetPlayer == player or currentState == "Pursuing"
end

function CryptidService.provoke(player: Player): (boolean, string?)
	local creatureRoot = root
	local playerRoot = getPlayerRoot(player)
	if currentState ~= "Roaming" then
		return false, "The cryptid is already reacting."
	end
	if not creatureRoot or not playerRoot then
		return false, "Your camera cannot find the trail."
	end
	if (creatureRoot.Position - playerRoot.Position).Magnitude > Gameplay.ProvokeDistance then
		return false, "Move closer to the trail marker first."
	end
	targetPlayer = player
	investigationDeadline = os.clock() + Gameplay.InvestigationSeconds
	setState("Investigating")
	stateEvent:FireClient(player, { type = "hint", text = "It heard you. Watch its posture." })
	return true
end

function CryptidService.photographed(player: Player)
	if currentState == "Investigating" and targetPlayer == player then
		chaseStartedAt = os.clock()
		chaseDeadline = chaseStartedAt + Gameplay.MaxPursuitSeconds
		lastSeenAt = chaseStartedAt
		setState("Pursuing")
		stateEvent:FireAllClients({ type = "chase_started" })
	end
end

function CryptidService.start(variation: number, onCaught: LostCallback)
	CryptidService.stop()
	local spawnIndex = ((variation - 1) % #Gameplay.CryptidSpawnPoints) + 1
	home = Gameplay.CryptidSpawnPoints[spawnIndex]
	model, root = buildModel(home)
	targetPlayer = nil
	lostCallback = onCaught
	roamIndex = variation % #Gameplay.RoamPoints + 1
	roamDeadline = os.clock() + 2
	investigationDeadline = 0
	chaseDeadline = 0
	lastSeenAt = 0
	running = true
	setState("Roaming")

	local thisRun = runVersion
	task.spawn(function()
		local previous = os.clock()
		local nextPathAt = 0
		local waypoint: Vector3? = nil
		while running and runVersion == thisRun and model and model.Parent do
			local now = os.clock()
			local dt = math.min(now - previous, 0.25)
			previous = now
			if currentState == "Roaming" then
				if now >= roamDeadline then
					roamIndex = roamIndex % #Gameplay.RoamPoints + 1
					waypoint = Gameplay.RoamPoints[roamIndex]
					roamDeadline = now + 4.5
				end
				if waypoint then
					stepToward(waypoint, 5, dt)
				end
			elseif currentState == "Investigating" then
				local target = targetPlayer and getPlayerRoot(targetPlayer)
				if not target or now >= investigationDeadline then
					transitionToReturning()
				else
					stepToward(target.Position, 7, dt)
				end
			elseif currentState == "Pursuing" then
				local player = targetPlayer
				local target = player and getPlayerRoot(player)
				if not target or now >= chaseDeadline then
					transitionToReturning()
					stateEvent:FireAllClients({ type = "chase_ended", reason = "lost" })
				else
					if visibleTo(player :: Player) then
						lastSeenAt = now
					elseif now - lastSeenAt >= Gameplay.LostSightGrace then
						transitionToReturning()
						stateEvent:FireAllClients({ type = "chase_ended", reason = "out_of_sight" })
					end
					if currentState == "Pursuing" then
						if now >= nextPathAt then
							waypoint = pathTarget(target)
							nextPathAt = now + 0.8
						end
						if waypoint then
							stepToward(waypoint, 12, dt)
						end
						if
							now - chaseStartedAt >= Gameplay.CatchGraceSeconds
							and (target.Position - (root :: BasePart).Position).Magnitude <= Gameplay.CatchDistance
						then
							running = false
							local callback = lostCallback
							if callback then
								callback(player :: Player)
							end
						end
					end
				end
			elseif currentState == "Returning" then
				stepToward(home, 7, dt)
				if (home - (root :: BasePart).Position).Magnitude <= 3 then
					targetPlayer = nil
					waypoint = nil
					setState("Roaming")
					roamDeadline = now + 2
				end
			end
			task.wait(0.12)
		end
	end)
end

function CryptidService.stop()
	runVersion += 1
	running = false
	targetPlayer = nil
	if model then
		model:Destroy()
	end
	model = nil
	root = nil
end

return CryptidService
