--!strict
-- Onboarding trial (TASK-0006): a first-time player (this session) starts in the trial area with a
-- prompt for their faction's power. Using it, or 30 s passing, finishes the trial and sends them to
-- the lobby. Records `FirstPowerSeconds` (time from join to first power use) for EXP-0001.
-- Session-only in M2 (no persistence).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local MatchConfig = require(Shared:WaitForChild("MatchConfig"))
local FactionConfig = require(Shared:WaitForChild("FactionConfig"))

local TrialService = {}

local joinedAt: { [Player]: number } = {}
local done: { [Player]: boolean } = {}
local teleporter: ((player: Player, zoneName: string) -> ())? = nil
local started = false

local function trialPower(player: Player): { ability: string, prompt: string }?
	local faction = player:GetAttribute(FactionConfig.AttributeName)
	return if typeof(faction) == "string" then (MatchConfig.TrialPower :: any)[faction] else nil
end

function TrialService.isDone(player: Player): boolean
	return done[player] == true
end

function TrialService.complete(player: Player, reason: string)
	if done[player] then
		return
	end
	done[player] = true
	player:SetAttribute("TrialDone", true)
	player:SetAttribute("TrialPrompt", nil)
	player:SetAttribute("TrialEndReason", reason)
	if teleporter then
		teleporter(player, "Lobby")
	end
end

local function begin(player: Player)
	if done[player] then
		return
	end
	local power = trialPower(player)
	player:SetAttribute("TrialPrompt", if power then power.prompt else "Use your power")
	if teleporter then
		teleporter(player, "Trial")
	end
	task.delay(MatchConfig.TrialMaxSeconds, function()
		if player.Parent == Players then
			TrialService.complete(player, "timeout")
		end
	end)
end

-- Call from an AbilityService.onActivated listener.
function TrialService.onAbility(player: Player, abilityId: string)
	if done[player] then
		return
	end
	local power = trialPower(player)
	if power and power.ability == abilityId then
		local t = joinedAt[player]
		if t then
			player:SetAttribute("FirstPowerSeconds", math.floor((os.clock() - t) * 10) / 10)
		end
		TrialService.complete(player, "power_used")
	end
end

function TrialService.setTeleporter(fn: (player: Player, zoneName: string) -> ())
	teleporter = fn
end

function TrialService.start()
	if started then
		return
	end
	started = true
	local function watch(player: Player)
		joinedAt[player] = os.clock()
		local first = true
		player.CharacterAdded:Connect(function()
			if first then
				first = false
				task.defer(begin, player)
			end
		end)
		if player.Character then
			first = false
			task.defer(begin, player)
		end
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		joinedAt[player] = nil
		done[player] = nil
	end)
end

return TrialService
