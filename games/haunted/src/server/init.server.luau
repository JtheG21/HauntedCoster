--!strict
-- GAME-002 Haunted Collector: server entry point. Builds the world, then starts services in
-- dependency order. Cross-service hooks are wired here so services don't require each other in cycles.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local BuildInfo = require(ReplicatedStorage.Shared.BuildInfo)
print(`[HauntedCollector] server build {BuildInfo.stamp()}`)

local Remotes = require(script.Remotes)
local HubBuilder = require(script.World.HubBuilder)
local CemeteryBuilder = require(script.World.Habitats.Cemetery)
local Habitats = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Habitats"))
local HabitatRules = require(ReplicatedStorage.Shared:WaitForChild("Rules"):WaitForChild("HabitatRules"))
local Services = script.Services

local PlayerDataService = require(Services.PlayerDataService)
local StateService = require(Services.StateService)
local PlotService = require(Services.PlotService)
local MovementService = require(Services.MovementService)
local EncounterService = require(Services.EncounterService)
local CaptureService = require(Services.CaptureService)
local ContainmentService = require(Services.ContainmentService)
local EconomyService = require(Services.EconomyService)
local TrainService = require(Services.TrainService)
local TutorialService = require(Services.TutorialService)

-- The persistent outer world, then the active habitat module inside the hub wall (ADR-0007).
local hub = HubBuilder.build(Workspace)
for _, problem in HabitatRules.validate(Habitats.active()) do
	warn(`[Habitats] {problem}`)
end
local habitatFolder = Instance.new("Folder")
habitatFolder.Name = "Habitat"
habitatFolder.Parent = Workspace
CemeteryBuilder.build(Habitats.active()).model.Parent = habitatFolder
HubBuilder.setGateLabel(hub, Habitats.active().name)

require(script.StudioTestHook).start()

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
