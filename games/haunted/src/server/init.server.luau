--!strict
-- GAME-002 Haunted Collector: server entry point. Builds the world, then starts services in
-- dependency order. Cross-service hooks are wired here so services don't require each other in cycles.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local BuildInfo = require(ReplicatedStorage.Shared.BuildInfo)
print(`[HauntedCollector] server build {BuildInfo.stamp()}`)

local Remotes = require(script.Remotes)
local HubBuilder = require(script.World.HubBuilder)
local StudioTestHook = require(script.StudioTestHook)
local Services = script.Services

local PlayerDataService = require(Services.PlayerDataService)
local StateService = require(Services.StateService)
local PlotService = require(Services.PlotService)
local MovementService = require(Services.MovementService)
local HabitatService = require(Services.HabitatService)
local EncounterService = require(Services.EncounterService)
local CaptureService = require(Services.CaptureService)
local ContainmentService = require(Services.ContainmentService)
local EconomyService = require(Services.EconomyService)
local TrainService = require(Services.TrainService)
local TutorialService = require(Services.TutorialService)

-- The persistent outer world, then every habitat module (one active inside the hub wall, ADR-0007).
-- In Studio test runs the `habitat` argument picks the starting module.
local hub = HubBuilder.build(Workspace)
local initialHabitat = StudioTestHook.arg("habitat")
HabitatService.start(hub, if type(initialHabitat) == "string" then initialHabitat else nil)

StudioTestHook.start()

PlayerDataService.start()
StateService.start()
PlotService.start()
MovementService.start()
EncounterService.start()
CaptureService.start()
ContainmentService.start()
EconomyService.start()
TrainService.start()
TutorialService.start()

-- A habitat swap clears the old module's wild monsters and populates the new one.
HabitatService.onDeactivating(function()
	EncounterService.clearWild()
end)
HabitatService.onActivated(function()
	EncounterService.populate()
end)
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
	local flag = if what == "journal" then "journalOpened" elseif what == "mansion" then "mansionOpened" else nil
	if flag and Remotes.allow(player, "Ack", 1, 3) then
		PlayerDataService.update(player, function(p)
			p.flags[flag] = true
		end)
	end
	return nil
end

print("[HauntedCollector] server ready")
