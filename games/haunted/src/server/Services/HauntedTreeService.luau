--!strict
-- Haunted-tree gaze aggregation (TASK-0041, ADR-0010). Clients report gaze edges plus keepalives on
-- `TreeGaze`; the server checks each "looking" report for plausibility (registered faced tree in the active
-- habitat, live reporter, range and facing from the head, a clear line of sight), aggregates observers per
-- tree with GazeRules, and replicates one `Frozen` attribute per tree. Purely cosmetic: nothing else reads it.
-- No per-frame loop: one task.delay per tree, scheduled only while it has observers or a resume pending.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local HauntedTrees = require(Shared.Config.HauntedTrees)
local Habitats = require(Shared.Config.Habitats)
local GazeRules = require(Shared.Rules.GazeRules)
local TreeSight = require(Shared.TreeSight)
local Remotes = require(script.Parent.Parent.Remotes)
local HabitatService = require(script.Parent.HabitatService)

local HauntedTreeService = {}

type Tree = {
	model: Model,
	root: BasePart,
	state: GazeRules.TreeState,
	token: number,
}

local trees: { [string]: Tree } = {}
local started = false

local function face(t: Tree): GazeRules.Face
	local cf = t.root.CFrame
	return { pos = cf.Position, forward = cf.LookVector, radius = (t.root:GetAttribute("Radius") :: number?) or 1 }
end

local function apply(t: Tree)
	if t.model:GetAttribute("Frozen") ~= t.state.frozen then
		t.model:SetAttribute("Frozen", t.state.frozen)
	end
end

-- (Re)schedule the tree's single pending step; older pending steps see a stale token and do nothing.
local function schedule(t: Tree)
	t.token += 1
	local token = t.token
	local at = GazeRules.nextEvent(t.state)
	if at == nil then
		return
	end
	task.delay(math.max(0, at - os.clock()), function()
		if t.token ~= token then
			return
		end
		GazeRules.step(t.state, os.clock())
		apply(t)
		schedule(t)
	end)
end

local function releaseEverywhere(player: Player)
	local now = os.clock()
	for _, t in trees do
		if t.state.observers[player] ~= nil then
			GazeRules.release(t.state, player, now)
			GazeRules.step(t.state, now)
			apply(t)
			schedule(t)
		end
	end
end

local function resetAll()
	for _, t in trees do
		t.state = GazeRules.newTree()
		t.token += 1
		apply(t)
	end
end

local function headOf(player: Player): BasePart?
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local head = char and char:FindFirstChild("Head")
	if hum and hum.Health > 0 and head and head:IsA("BasePart") then
		return head
	end
	return nil
end

local function onGaze(player: Player, id: unknown, looking: unknown)
	if typeof(id) ~= "string" or typeof(looking) ~= "boolean" then
		return
	end
	local g = HauntedTrees.gaze
	if not Remotes.allow(player, "TreeGaze", g.rate, g.burst) then
		return
	end
	local t = trees[id]
	if not t then
		return
	end
	local now = os.clock()
	if not looking then
		GazeRules.release(t.state, player, now)
		GazeRules.step(t.state, now)
		apply(t)
		schedule(t)
		return
	end
	if not t.model:IsDescendantOf(Workspace) then
		return -- the tree's habitat isn't active
	end
	local head = headOf(player)
	if not head then
		return
	end
	local f = face(t)
	if not GazeRules.plausible(head.Position, f) then
		return
	end
	local char = player.Character :: Model
	if not TreeSight.clear(head.Position, f.pos, { t.model, char }) then
		return
	end
	GazeRules.observe(t.state, player, now)
	apply(t)
	schedule(t)
end

local function register(model: Instance)
	if not model:IsA("Model") then
		return
	end
	local id = model:GetAttribute("TreeId")
	local root = model:FindFirstChild("FaceRoot")
	if typeof(id) ~= "string" or not (root and root:IsA("BasePart")) then
		warn(`[HauntedTreeService] malformed haunted tree {model:GetFullName()}`)
		return
	end
	if trees[id] then
		warn(`[HauntedTreeService] duplicate tree id {id}`)
		return
	end
	trees[id] = { model = model, root = root, state = GazeRules.newTree(), token = 0 }
end

-- Read-only view for Studio scenarios.
function HauntedTreeService.snapshot(id: string): { frozen: boolean, observers: number, resumeAt: number? }?
	local t = trees[id]
	if not t then
		return nil
	end
	return { frozen = t.state.frozen, observers = GazeRules.observerCount(t.state), resumeAt = t.state.resumeAt }
end

function HauntedTreeService.ids(): { string }
	local list = {}
	for id in trees do
		table.insert(list, id)
	end
	table.sort(list)
	return list
end

function HauntedTreeService.start()
	if started then
		return
	end
	started = true
	-- Habitat modules are built before services start and live in ServerStorage while inactive.
	for _, def in Habitats.List do
		local result = HabitatService.built(def.id)
		if result then
			for _, d in result.model:GetDescendants() do
				if CollectionService:HasTag(d, HauntedTrees.tag) then
					register(d)
				end
			end
		end
	end
	Remotes.event("TreeGaze").OnServerEvent:Connect(onGaze)
	Players.PlayerRemoving:Connect(releaseEverywhere)
	local function watch(player: Player)
		player.CharacterRemoving:Connect(function()
			releaseEverywhere(player)
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, p in Players:GetPlayers() do
		watch(p)
	end
	HabitatService.onDeactivating(resetAll)
end

return HauntedTreeService
