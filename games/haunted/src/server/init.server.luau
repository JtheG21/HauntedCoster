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
local RotationService = require(Services.RotationService)
local RetaliationService = require(Services.RetaliationService)
local EncounterService = require(Services.EncounterService)
local CaptureService = require(Services.CaptureService)
local ContainmentService = require(Services.ContainmentService)
local EconomyService = require(Services.EconomyService)
local TrainService = require(Services.TrainService)
local TutorialService = require(Services.TutorialService)
local HauntedTreeService = require(Services.HauntedTreeService)
local ArtBakeService = require(Services.ArtBakeService)

-- The persistent outer world, then every habitat module (one active inside the hub wall, ADR-0007). The
-- rotation schedule picks the active module. Studio test runs (a `scenario` argument) are pinned to the
-- `habitat` argument, or the Cemetery, unless they pass a `rotation` schedule (TASK-0029 scenarios). With a
-- `rotation` schedule the scheduled habitat wins (a `habitat` argument would be swapped out at once).
local hub = HubBuilder.build(Workspace)
local testScenario = StudioTestHook.arg("scenario")
local testRotation = StudioTestHook.arg("rotation")
local testHabitat = StudioTestHook.arg("habitat")
local pinned = testScenario ~= nil and testRotation == nil
RotationService.configure(testRotation)
local initialHabitat = if type(testHabitat) == "string" and pinned
	then testHabitat
	elseif pinned then "Cemetery"
	else RotationService.scheduledId()
HabitatService.start(hub, initialHabitat)

StudioTestHook.start()
ArtBakeService.start() -- art first: clients clone its templates (TASK-0042)

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
RetaliationService.start()
RotationService.start(pinned)
HauntedTreeService.start()

-- A habitat swap clears the old module's wild monsters and populates the new one.
HabitatService.onDeactivating(function()
	RetaliationService.stopAll("swap")
	EncounterService.clearWild()
end)
-- A failed capture's last miss turns the monster (and a couple of neighbours) on the player (TASK-0031).
CaptureService.onFled(function(player, encounter)
	return RetaliationService.begin(player, encounter) > 0
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
