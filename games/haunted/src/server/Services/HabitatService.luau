--!strict
-- Habitat module lifecycle (ADR-0007, TASK-0027). All four modules are built once at server start and kept
-- in ServerStorage; exactly one is parented under Workspace.Habitat at a time.
--   activate(id): deactivate the current module, switch `Habitats.active()`, parent the new module, mirror
--                 the id to the Workspace attribute `ActiveHabitat` (clients follow it), relabel the hub
--                 gates, then run the activated hooks (EncounterService repopulates).
--   deactivate(): run the deactivating hooks (EncounterService clears wild monsters), then unparent.
-- Scheduling, warnings and capture-safe swaps are TASK-0029's HabitatRotation work.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Habitats = require(Shared:WaitForChild("Config"):WaitForChild("Habitats"))
local HabitatRules = require(Shared:WaitForChild("Rules"):WaitForChild("HabitatRules"))
local World = script.Parent.Parent.World
local HubBuilder = require(World.HubBuilder)
local Kit = require(World.Habitats.Kit)

local HabitatService = {}

local builders: { [string]: (Habitats.Habitat) -> Kit.Result } = {
	Cemetery = require(World.Habitats.Cemetery).build,
	Woodland = require(World.Habitats.Woodland).build,
	SpiderWoodland = require(World.Habitats.SpiderWoodland).build,
	Settlement = require(World.Habitats.Settlement).build,
}

local started = false
local hub: HubBuilder.Result
local storage: Folder
local stage: Folder
local built: { [string]: Kit.Result } = {}
local activeId: string? = nil
local onActivatedFns: { (string) -> () } = {}
local onDeactivatingFns: { (string) -> () } = {}

function HabitatService.onActivated(fn: (string) -> ())
	table.insert(onActivatedFns, fn)
end

function HabitatService.onDeactivating(fn: (string) -> ())
	table.insert(onDeactivatingFns, fn)
end

function HabitatService.activeId(): string?
	return activeId
end

-- The built module for `id` (scenarios count parts and look for prompts).
function HabitatService.built(id: string): Kit.Result?
	return built[id]
end

function HabitatService.deactivate()
	local id = activeId
	if not id then
		return
	end
	for _, fn in onDeactivatingFns do
		fn(id)
	end
	built[id].model.Parent = storage
	activeId = nil
end

function HabitatService.activate(id: string): boolean
	local result = built[id]
	if not result then
		warn(`[HabitatService] unknown habitat {id}`)
		return false
	end
	if activeId == id then
		return true
	end
	HabitatService.deactivate()
	Habitats.setActive(id)
	activeId = id
	result.model.Parent = stage
	Workspace:SetAttribute("ActiveHabitat", id)
	HubBuilder.setGateLabel(hub, Habitats.ById[id].name)
	for _, fn in onActivatedFns do
		fn(id)
	end
	return true
end

-- Builds every module (validating each) and activates `initial` (default: the first in the rotation).
function HabitatService.start(hubResult: HubBuilder.Result, initial: string?)
	if started then
		return
	end
	started = true
	hub = hubResult
	storage = Instance.new("Folder")
	storage.Name = "HabitatModules"
	storage.Parent = ServerStorage
	stage = Instance.new("Folder")
	stage.Name = "Habitat"
	stage.Parent = Workspace
	for _, def in Habitats.List do
		for _, problem in HabitatRules.validate(def) do
			warn(`[Habitats] {problem}`)
		end
		local build = builders[def.id]
		if build then
			local result = build(def)
			result.model.Parent = storage
			built[def.id] = result
		else
			warn(`[HabitatService] no builder for {def.id}`)
		end
	end
	local first = if initial and built[initial] then initial else Habitats.List[1].id
	HabitatService.activate(first)
end

return HabitatService
