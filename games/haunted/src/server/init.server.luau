--!strict
-- GAME-002 Haunted Collector: server entry point. Builds the world, then starts services in
-- dependency order. Cross-service hooks are wired here so services don't require each other in cycles.

local Workspace = game:GetService("Workspace")

local Remotes = require(script.Remotes)
local GraveyardBuilder = require(script.World.GraveyardBuilder)
local Services = script.Services

local PlayerDataService = require(Services.PlayerDataService)
local StateService = require(Services.StateService)
local PlotService = require(Services.PlotService)
local MovementService = require(Services.MovementService)
local LandmarkService = require(Services.LandmarkService)
local EncounterService = require(Services.EncounterService)
local CaptureService = require(Services.CaptureService)
local ContainmentService = require(Services.ContainmentService)
local EconomyService = require(Services.EconomyService)
local TrainService = require(Services.TrainService)
local TutorialService = require(Services.TutorialService)

local world = GraveyardBuilder.build(Workspace)

require(script.StudioTestHook).start()

PlayerDataService.start()
StateService.start()
PlotService.start()
MovementService.start()
LandmarkService.start(world.landmarkAnchors, world.cryptGate)
EncounterService.start()
CaptureService.start()
ContainmentService.start()
EconomyService.start()
TrainService.start()
TutorialService.start()

-- Monsters being carried home still count toward rare spawn caps.
EncounterService.setOutsideCounter(CaptureService.carriedCount)
-- Securing a monster updates the pen and the train's payout preview.
CaptureService.onSecured(function(player)
	ContainmentService.refreshVisuals(player)
	TrainService.refresh(player)
end)
-- A new house tier changes exhibit slots, containment and ride multiplier.
EconomyService.onTierChanged(function(player)
	ContainmentService.refreshVisuals(player)
	TrainService.refresh(player)
end)

-- UI-only acknowledgements (never grant rewards).
Remotes.func("Ack").OnServerInvoke = function(player, what)
	if what == "journal" and Remotes.allow(player, "Ack", 1, 3) then
		PlayerDataService.update(player, function(p)
			p.flags.journalOpened = true
		end)
	end
	return nil
end

print("[HauntedCollector] server ready")
