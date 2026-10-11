print("Hello world, from server!")

local StudioTestHook = require(script.Services.StudioTestHook)
StudioTestHook.start()

local CollectibleService = require(script.Services.CollectibleService)
CollectibleService.start()

local FactionService = require(script.Services.FactionService)
FactionService.start()

local PressurePlate = require(script.Components.PressurePlate)
PressurePlate.start()
local HeavyBlock = require(script.Components.HeavyBlock)
HeavyBlock.start()
local EchoService = require(script.Services.EchoService)
EchoService.start()
local ConvergenceGate = require(script.Components.ConvergenceGate)
ConvergenceGate.start()

local AbilityService = require(script.Services.AbilityService)
local Dash = require(script.Abilities.Dash)
local EchoClone = require(script.Abilities.EchoClone)
local KiBurst = require(script.Abilities.KiBurst)
AbilityService.register("Dash", { handler = Dash.handler })
AbilityService.register("EchoClone", { handler = EchoClone.handler, canUse = FactionService.requires("Shinobi") })
AbilityService.register("KiCharge", { handler = KiBurst.chargeHandler, canUse = FactionService.requires("Ki") })
AbilityService.register("KiBurst", { handler = KiBurst.burstHandler, canUse = FactionService.requires("Ki") })
EchoClone.start()
KiBurst.start()
AbilityService.start()

-- Match flow and onboarding (TASK-0006)
local MatchService = require(script.Services.MatchService)
local TrialService = require(script.Services.TrialService)
TrialService.setTeleporter(MatchService.teleport)
MatchService.setEligibility(TrialService.isDone)
AbilityService.onActivated(TrialService.onAbility)
-- Gates only count factions in the current match; faction switches only for players not in a match.
ConvergenceGate.setPresentProvider(function()
	return if MatchService.getState() == "Lobby" or MatchService.getState() == "Countdown"
		then game:GetService("Players"):GetPlayers()
		else MatchService.getMatchPlayers()
end)
FactionService.setSwitchGuard(function(player)
	return not MatchService.isInMatch(player)
end)
-- Per-match reset: Echoes, gate awards and shrines start fresh each match.
MatchService.onMatchStart(function()
	for _, player in game:GetService("Players"):GetPlayers() do
		EchoService.reset(player)
	end
	ConvergenceGate.resetAll()
end)
MatchService.onMatchEnd(FactionService.rebalance)
TrialService.start()
MatchService.start()
