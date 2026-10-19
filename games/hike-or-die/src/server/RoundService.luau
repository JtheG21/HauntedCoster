--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")

local Gameplay = require(ReplicatedStorage.Shared.Config.Gameplay)
local RoundRules = require(ReplicatedStorage.Shared.Rules.RoundRules)
local CryptidService = require(script.Parent.CryptidService)
local Remotes = require(script.Parent.Remotes)

local RoundService: any = {}

type Evidence = {
	points: number,
	maxPoints: number,
	tier: string,
	behavior: string,
	breakdown: { string },
	distanceBand: string,
}

local phase = "waiting"
local roundNumber = 0
local owner: Player? = nil
local evidence: { Evidence } = {}
local eventCounts: { [string]: number } = {}
local prompt: ProximityPrompt? = nil
local restartSequence = 0
local activeRestartToken: number? = nil

local function record(name: string)
	eventCounts[name] = (eventCounts[name] or 0) + 1
end

local function publish(extra: { [string]: any }?)
	local payload: { [string]: any } = {
		type = "round",
		phase = phase,
		round = roundNumber,
		evidenceCount = #evidence,
	}
	if extra then
		for key, value in extra do
			payload[key] = value
		end
	end
	Remotes.Event:FireAllClients(payload)
end

local function distanceBand(distance: number): string
	if distance <= 12 then
		return "close"
	end
	if distance <= 30 then
		return "near"
	end
	if distance <= 55 then
		return "far"
	end
	return "distant"
end

local function printSummary(outcome: string)
	local total = 0
	for _, item in evidence do
		total += item.points
	end
	print("[HikeOrDieTelemetry] " .. HttpService:JSONEncode({
		event_counts = eventCounts,
		outcome = outcome,
		photos = #evidence,
		points = total,
	}))
end

local function startRound(restarted: boolean)
	roundNumber += 1
	phase = "active"
	evidence = {}
	eventCounts = { session_started = 1 }
	if restarted then
		record("restart_selected")
	end
	CryptidService.start(roundNumber, function(caughtPlayer)
		if caughtPlayer == owner and phase == "active" then
			RoundService.fail(caughtPlayer, "The cryptid caught you. Your unbanked photos were lost.")
			local character = caughtPlayer.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 then
				humanoid.Health = 0
			end
		end
	end)
	local trail = Workspace:FindFirstChild("HikeOrDieTrail")
	local exit = trail and trail:FindFirstChild("ExitBeacon", true)
	if exit and exit:IsA("BasePart") and not prompt then
		local exitPrompt = Instance.new("ProximityPrompt")
		exitPrompt.Name = "Extract"
		exitPrompt.ActionText = "Extract"
		exitPrompt.ObjectText = "Trail Exit"
		exitPrompt.KeyboardKeyCode = Enum.KeyCode.E
		exitPrompt.GamepadKeyCode = Enum.KeyCode.ButtonX
		exitPrompt.HoldDuration = 0
		exitPrompt.MaxActivationDistance = Gameplay.ExtractDistance
		exitPrompt.RequiresLineOfSight = false
		exitPrompt.Parent = exit
		exitPrompt.Triggered:Connect(function(triggeringPlayer)
			RoundService.extract(triggeringPlayer)
		end)
		prompt = exitPrompt
	end
	publish({ variation = roundNumber })
end

local function onPlayer(player: Player)
	if not owner then
		owner = player
		startRound(false)
	elseif owner ~= player then
		Remotes.Event:FireClient(player, {
			type = "locked",
			message = "Gate 1 is a solo prototype. Start a one-player server to test it.",
		})
		return
	end

	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid", 10)
		if humanoid and humanoid:IsA("Humanoid") then
			humanoid.Died:Connect(function()
				if phase == "active" and player == owner then
					RoundService.fail(player, "You went down before reaching the exit.")
				end
			end)
		end
	end)
end

function RoundService.getPhase(): string
	return phase
end

function RoundService.getRoundNumber(): number
	return roundNumber
end

function RoundService.getOwner(): Player?
	return owner
end

function RoundService.isOwner(player: Player): boolean
	return player == owner
end

function RoundService.canPhotograph(): boolean
	return RoundRules.canPhotograph(phase)
end

function RoundService.addEvidence(result: Evidence, distance: number)
	if phase ~= "active" then
		return
	end
	table.insert(evidence, {
		points = result.points,
		maxPoints = result.maxPoints,
		tier = result.tier,
		behavior = result.behavior,
		breakdown = result.breakdown,
		distanceBand = distanceBand(distance),
	})
	record("evidence_captured")
	record("evidence_tier_" .. string.lower(result.tier))
	publish({ evidenceCount = #evidence })
end

function RoundService.record(name: string)
	record(name)
end

function RoundService.getEvidenceCount(): number
	return #evidence
end

function RoundService.extract(player: Player)
	if player ~= owner or not RoundRules.canExtract(phase) then
		return
	end
	local trail = Workspace:FindFirstChild("HikeOrDieTrail")
	local exit = trail and trail:FindFirstChild("ExitBeacon", true)
	local character = player.Character
	local playerRoot = character and character:FindFirstChild("HumanoidRootPart")
	if not (exit and exit:IsA("BasePart") and playerRoot and playerRoot:IsA("BasePart")) then
		return
	end
	if (exit.Position - playerRoot.Position).Magnitude > Gameplay.ExtractDistance + 2 then
		return
	end
	phase = "extracted"
	record("extracted")
	local total = 0
	for _, item in evidence do
		total += item.points
	end
	CryptidService.stop()
	publish({
		banked = #evidence,
		totalPoints = total,
		evidence = evidence,
		message = if #evidence > 0
			then "You made it out with proof."
			else "You made it out safely, but brought back no photos.",
	})
	record("session_ended")
	printSummary("extracted")
end

function RoundService.fail(player: Player, message: string)
	if player ~= owner or phase ~= "active" then
		return
	end
	phase = "failed"
	record("player_down_or_failed")
	local lost = #evidence
	evidence = {}
	CryptidService.stop()
	publish({ lost = lost, banked = 0, message = message })
	record("session_ended")
	printSummary("failed")
end

function RoundService.restart(player: Player): (boolean, string?)
	if player ~= owner then
		return false, "This round belongs to another hiker."
	end
	if not RoundRules.canRestart(phase) then
		return false, "Finish this expedition before restarting."
	end
	if activeRestartToken then
		return false, "The trail is already restarting."
	end
	restartSequence += 1
	local token = restartSequence
	activeRestartToken = token
	local expectedRound = roundNumber
	local expectedPhase = phase
	local function abortRestart(reason: string): (boolean, string?)
		if activeRestartToken == token then
			activeRestartToken = nil
		end
		return false, reason
	end
	local function restartStillValid(): boolean
		return activeRestartToken == token
			and owner == player
			and player.Parent == Players
			and roundNumber == expectedRound
			and phase == expectedPhase
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not character or not humanoid or humanoid.Health <= 0 then
		local loaded = pcall(function()
			player:LoadCharacterAsync()
		end)
		if not loaded then
			return abortRestart("The hiker could not return to the trail. Try again.")
		end
		if not restartStillValid() then
			return abortRestart("The expedition changed before the restart finished. Try again.")
		end
		character = player.Character
	end
	if not restartStillValid() then
		return abortRestart("The expedition changed before the restart finished. Try again.")
	end
	local trail = Workspace:FindFirstChild("HikeOrDieTrail")
	local spawns = trail and trail:FindFirstChild("Spawns")
	local spawn = spawns and spawns:FindFirstChild("Spawn1")
	if not character or not spawn or not spawn:IsA("BasePart") then
		return abortRestart("The trail start is not ready. Try again.")
	end
	character:PivotTo(spawn.CFrame + Vector3.new(0, 3, 0))
	activeRestartToken = nil
	startRound(true)
	return true
end

function RoundService.start()
	Players.PlayerAdded:Connect(onPlayer)
	Players.PlayerRemoving:Connect(function(player)
		if player == owner then
			activeRestartToken = nil
			CryptidService.stop()
			owner = nil
			phase = "waiting"
			task.defer(function()
				for _, nextPlayer in Players:GetPlayers() do
					if not owner then
						onPlayer(nextPlayer)
					end
				end
			end)
		end
	end)
	for _, player in Players:GetPlayers() do
		onPlayer(player)
	end
end

return RoundService
