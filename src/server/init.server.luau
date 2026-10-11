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
local FinaleService = require(script.Services.FinaleService)
local FinaleModifiers = require(script.Abilities.FinaleModifiers)
AbilityService.register("Dash", { handler = Dash.handler })
AbilityService.register("EchoClone", { handler = EchoClone.handler, canUse = FactionService.requires("Shinobi") })
AbilityService.register("KiCharge", { handler = KiBurst.chargeHandler, canUse = FactionService.requires("Ki") })
AbilityService.register("KiBurst", { handler = KiBurst.burstHandler, canUse = FactionService.requires("Ki") })
AbilityService.register(
	"EchoBurst",
	{ handler = FinaleModifiers.echoBurstHandler, canUse = FinaleModifiers.canSpend("Ki") }
)
AbilityService.register(
	"EchoGuard",
	{ handler = FinaleModifiers.echoGuardHandler, canUse = FinaleModifiers.canSpend("Shinobi") }
)
KiBurst.setOnBurst(FinaleModifiers.onKiBurst)
EchoClone.setOnClone(FinaleModifiers.onEchoClone)
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
	FinaleService.resetContributions()
end)
MatchService.onMatchEnd(FactionService.rebalance)

-- Ring-out finale and category results (TASK-0007)
MatchService.setFinale({
	begin = FinaleService.begin,
	isOver = FinaleService.isOver,
	results = FinaleService.results,
	respawn = FinaleService.respawn,
	maxSeconds = require(game:GetService("ReplicatedStorage").Shared.FinaleConfig).MaxSeconds,
})
MatchService.onMatchEnd(FinaleService.reset)
-- Teamwork only counts gate help from players in the current match.
ConvergenceGate.onContribution(function(player)
	if MatchService.isInMatch(player) then
		FinaleService.recordContribution(player)
	end
end)
FinaleService.start()
TrialService.start()
MatchService.start()
