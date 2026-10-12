--!strict
-- Failed-capture retaliation (TASK-0031, ADR-0007 "final miss only"). When a capture's last miss lets
-- the target flee, it and up to two wild monsters near the player turn and chase that player for a few
-- seconds (Npc_template's Idle -> Hunting -> WindingDown states, adapted: anchored models stepped by the
-- server like the escape chase, only the failing player as a target, no Humanoids). A pursuer that
-- reaches the player knocks them down briefly (a server-flagged ragdoll, no damage) and gives up. Every
-- pursuit ends on timeout, distance, death, leaving or a habitat swap; pursuers then roam again.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Monsters = require(Shared:WaitForChild("Config"):WaitForChild("Monsters"))
local RetaliationRules = require(Shared:WaitForChild("Rules"):WaitForChild("RetaliationRules"))
local EncounterService = require(script.Parent.EncounterService)
local StateService = require(script.Parent.StateService)

local RetaliationService = {}

local STEP_SECONDS = 0.25
local KNOCKDOWN_ATTR = "KnockedDownUntil" -- server time; the client ragdolls while it is in the future

type Pursuit = {
	player: Player,
	pursuers: { EncounterService.Encounter },
	startedAt: number,
	knocks: number,
}

local started = false
local pursuits: { [Player]: Pursuit } = {}
-- Per pursuer, per player: when it last knocked them down (cooldown).
local lastKnock: { [EncounterService.Encounter]: { [Player]: number } } = setmetatable({}, { __mode = "k" }) :: any
local knockCount = 0
local failNextTick = false -- test hook: the next tick errors
local failNextBegin = false -- test hook: the next begin errors once it has set two pursuers
local lastFailedBegin: { EncounterService.Encounter } = {} -- test view: what the last failed begin had set
local tickErrors = 0
local lastKnockOf: { [Player]: number } = {} -- server time each player was last knocked down

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local function release(e: EncounterService.Encounter)
	EncounterService.setPursuing(e, nil)
end

local function finish(player: Player, why: string)
	local p = pursuits[player]
	if not p then
		return
	end
	pursuits[player] = nil
	for _, e in p.pursuers do
		release(e)
	end
	if player.Parent and (why == "timeout" or why == "escaped") then
		StateService.toast(player, "They gave up the chase.", "info")
	end
end

-- Knock a player down for the configured time: no damage, the client ragdolls while the attribute says so.
local function knockDown(player: Player)
	local character = player.Character
	if not character then
		return
	end
	knockCount += 1
	character:SetAttribute(KNOCKDOWN_ATTR, Workspace:GetServerTimeNow() + Monsters.Retaliation.knockdownSeconds)
	StateService.toast(player, "Knocked down! Get up and run!", "error")
end

function RetaliationService.isKnockedDown(player: Player): boolean
	local character = player.Character
	local untilT = character and character:GetAttribute(KNOCKDOWN_ATTR)
	return type(untilT) == "number" and untilT > Workspace:GetServerTimeNow()
end

-- Starts a pursuit on `player` led by `target` (the monster that just escaped the capture).
function RetaliationService.begin(player: Player, target: EncounterService.Encounter): number
	if pursuits[player] then
		finish(player, "replaced")
	end
	local root = rootOf(player)
	if not root or not target.alive then
		return 0
	end
	local ids = RetaliationRules.pickPursuers(target.id, root.Position, EncounterService.candidatesForPursuit())
	local pursuers = {}
	local trying: EncounterService.Encounter? = nil
	-- An error part-way through must not leave monsters marked as pursuing with no pursuit record (nothing
	-- would release them): release the ones already set, then re-raise for CaptureService.onFled's pcall.
	local ok, err = pcall(function()
		for _, id in ids do
			local e = EncounterService.byId(id)
			if e and e.alive then
				trying = e
				if EncounterService.setPursuing(e, player) then
					table.insert(pursuers, e)
				end
				trying = nil
				if failNextBegin and #pursuers >= 2 then
					failNextBegin = false
					error("injected begin failure (test)")
				end
			end
		end
	end)
	if not ok then
		-- setPursuing itself may have thrown after marking `trying` for this player.
		local half = trying :: EncounterService.Encounter?
		if half and EncounterService.pursuingOf(half) == player and not table.find(pursuers, half) then
			table.insert(pursuers, half)
		end
		lastFailedBegin = table.clone(pursuers)
		for _, e in pursuers do
			pcall(function()
				release(e)
			end)
		end
		error(err, 0)
	end
	if #pursuers == 0 then
		return 0
	end
	pursuits[player] = { player = player, pursuers = pursuers, startedAt = os.clock(), knocks = 0 }
	StateService.toast(player, "It turned on you! Run!", "error")
	return #pursuers
end

-- A habitat swap, the player leaving or dying: every pursuit ends at once.
function RetaliationService.stopAll(why: string)
	for player in pursuits do
		finish(player, why)
	end
end

-- Test views (scenarios).
function RetaliationService.pursuersOf(player: Player): { EncounterService.Encounter }
	local p = pursuits[player]
	return if p then table.clone(p.pursuers) else {}
end

function RetaliationService.knockCount(): number
	return knockCount
end

function RetaliationService.tickErrorCount(): number
	return tickErrors
end

-- Test-only (scenarios): the next begin raises an error once it has set two pursuers (the target and an
-- extra); `false` clears it.
function RetaliationService.failNextBeginForTest(on: boolean?)
	failNextBegin = on ~= false
	if failNextBegin then
		lastFailedBegin = {}
	end
end

-- Test view: the monsters the last failed begin had set (all of them must have been released).
function RetaliationService.lastFailedBeginForTest(): { EncounterService.Encounter }
	return table.clone(lastFailedBegin)
end

-- Test-only (scenarios): the next tick raises an error, to prove the loop recovers.
function RetaliationService.failNextTickForTest()
	failNextTick = true
end

local function tick()
	if failNextTick then
		failNextTick = false
		error("injected tick failure (test)")
	end
	local now = os.clock()
	local serverNow = Workspace:GetServerTimeNow()
	for player, p in pursuits do
		local root = rootOf(player)
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local alive = root ~= nil and humanoid ~= nil and humanoid.Health > 0 and player.Parent ~= nil
		-- Pursuers that died (captured, cleared) or gave up drop out.
		local still = {}
		for _, e in p.pursuers do
			if e.alive and EncounterService.pursuingOf(e) == player then
				table.insert(still, e)
			end
		end
		p.pursuers = still
		local closest = math.huge
		if root then
			for _, e in still do
				closest = math.min(closest, (e.root.Position - root.Position).Magnitude)
			end
		end
		local why = RetaliationRules.endReason(now - p.startedAt, closest, alive, #still)
		if why then
			finish(player, why)
		elseif root then
			local knocked = RetaliationService.isKnockedDown(player)
			for _, e in still do
				if not knocked and RetaliationRules.caught(e.root.Position, root.Position) then
					local mine = lastKnock[e] or {}
					lastKnock[e] = mine
					if RetaliationRules.canKnock(mine[player], serverNow, lastKnockOf[player]) then
						mine[player] = serverNow
						lastKnockOf[player] = serverNow
						p.knocks += 1
						knockDown(player)
						knocked = true
					end
					-- A pursuer that reached the player gives up either way (ADR-0007).
					release(e)
				else
					local nextAt = RetaliationRules.pursueStep(
						e.root.Position,
						root.Position,
						Monsters.Retaliation.speed * STEP_SECONDS
					)
					EncounterService.stepTo(e, nextAt, STEP_SECONDS)
				end
			end
		end
	end
end

-- The tick failed part-way: end every pursuit so no monster is left stuck chasing (uncapturable, with
-- Inspect off), then carry on with the next tick (the same recovery as RotationService.swap, TASK-0029).
local function abandonAll(err: any)
	tickErrors += 1
	warn(`[RetaliationService] tick failed, ending every pursuit: {err}`)
	local all = pursuits
	pursuits = {}
	for _, p in all do
		for _, e in p.pursuers do
			local ok, releaseErr = pcall(function()
				release(e)
			end)
			if not ok then
				warn(`[RetaliationService] could not release a pursuer: {releaseErr}`)
			end
		end
	end
end

function RetaliationService.start()
	if started then
		return
	end
	started = true
	task.spawn(function()
		while true do
			task.wait(STEP_SECONDS)
			local ok, err = pcall(function()
				tick()
			end)
			if not ok then
				abandonAll(err)
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		finish(player, "left")
		lastKnockOf[player] = nil
		for _, byPlayer in lastKnock do
			byPlayer[player] = nil
		end
	end)
end

return RetaliationService
