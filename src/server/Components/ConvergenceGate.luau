--!strict
-- Convergence Gates (TASK-0005): a barrier that only opens when powers from different factions
-- are applied together, which is the rivals-must-cooperate moment.
--
-- Setup: tag the barrier BasePart "ConvergenceGate" and give it ObjectValue children:
--   ShinobiPlate -> a PressurePlate; Shinobi power = an Echo Clone standing on it ("ClonePresent")
--   KiTarget     -> a part tagged "KiTarget"; Ki power = a strong Ki Burst ("LastKiHit" attribute)
--   PassZone     -> part just past the gate; players inside during an opening earn Echo charges
--   ApproachZone -> part in front of the gate; the first player inside starts the shrine timer
--   Bypass       -> a slower route's blocker, opened by the Echo Shrine (optional)
-- Optional "Powers" attribute ("Shinobi,Ki") overrides GateConfig.DefaultPowers.
-- Published attributes (read by the client HUD): Required, State ("closed"|"open"), ShrineAt.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local FactionConfig = require(Shared:WaitForChild("FactionConfig"))
local GateConfig = require(Shared:WaitForChild("GateConfig"))
local GateRules = require(Shared:WaitForChild("GateRules"))

local EchoService = require(script.Parent.Parent.Services.EchoService)

local ConvergenceGate = {}

type GateState = {
	openUntil: number,
	openingPowers: { string },
	awarded: { [Player]: boolean }, -- one Echo award per player per gate (audit F2; reset per match later)
	presentAtOpen: { [Player]: boolean }, -- players already in the PassZone when it opened don't earn
	firstArrival: number?,
	shrineOpen: boolean, -- once triggered the bypass stays open (audit F3: no cycling)
	cloneSeenAt: number?,
	cloneConsumed: boolean, -- audit F1: the clone that opened the gate never counts again
	cloneOwner: number?, -- UserId of the clone that supplied the Shinobi input (Teamwork credit)
}

local states: { [BasePart]: GateState } = {}
local started = false

local function linked(gate: BasePart, name: string): BasePart?
	local link = gate:FindFirstChild(name)
	local target = if link and link:IsA("ObjectValue") then link.Value else nil
	return if target and target:IsA("BasePart") then target else nil
end

local function gatePowers(gate: BasePart): { string }
	local attr = gate:GetAttribute("Powers")
	if typeof(attr) == "string" and #attr > 0 then
		return string.split(attr, ",")
	end
	return table.clone(GateConfig.DefaultPowers :: { string })
end

-- Which players count as "present" for gate requirements. Default: everyone in the server;
-- MatchService narrows it to the current match (TASK-0006).
local presentProvider: () -> { Player } = function()
	return Players:GetPlayers()
end
local contributionListener: (player: Player) -> () = function(_player: Player) end

local function presentFactions(): { string }
	local present = {}
	for _, player in presentProvider() do
		local faction = player:GetAttribute(FactionConfig.AttributeName)
		if typeof(faction) == "string" and not table.find(present, faction) then
			table.insert(present, faction)
		end
	end
	return present
end

local function playersIn(zone: BasePart): { Player }
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { zone }
	local found: { Player } = {}
	for _, part in Workspace:GetPartsInPart(zone, params) do
		local model = part:FindFirstAncestorOfClass("Model")
		local player = if model then Players:GetPlayerFromCharacter(model) else nil
		local humanoid = if model then model:FindFirstChildOfClass("Humanoid") else nil
		if player and humanoid and humanoid.Health > 0 and not table.find(found, player) then
			table.insert(found, player)
		end
	end
	return found
end

local function setBlocked(part: BasePart, blocked: boolean)
	part.CanCollide = blocked
	part.Transparency = if blocked then 0 else GateConfig.OpenTransparency
end

local function getState(gate: BasePart): GateState
	local state = states[gate]
	if not state then
		state = {
			openUntil = 0,
			openingPowers = {},
			awarded = {},
			presentAtOpen = {},
			firstArrival = nil,
			shrineOpen = false,
			cloneSeenAt = nil,
			cloneConsumed = false,
			cloneOwner = nil,
		}
		states[gate] = state
		setBlocked(gate, true)
		gate:SetAttribute("State", "closed")
	end
	return state
end

local function step(gate: BasePart, now: number)
	local state = getState(gate)
	local required = GateRules.requirements(gatePowers(gate), presentFactions())
	gate:SetAttribute("Required", table.concat(required, ","))

	-- Gather when each power was last applied.
	local plate = linked(gate, "ShinobiPlate")
	local clonePresent = plate ~= nil and plate:GetAttribute("ClonePresent") == true
	state.cloneSeenAt, state.cloneConsumed =
		GateRules.cloneInput(clonePresent, state.cloneConsumed, state.cloneSeenAt, now)
	if clonePresent and state.cloneSeenAt and plate then
		local owner = plate:GetAttribute("CloneOwner")
		state.cloneOwner = if typeof(owner) == "number" then owner else state.cloneOwner
	end
	local kiTarget = linked(gate, "KiTarget")
	local kiHit = if kiTarget then kiTarget:GetAttribute("LastKiHit") else nil
	local lastApplied: { [string]: number } = {}
	if state.cloneSeenAt then
		lastApplied.Shinobi = state.cloneSeenAt
	end
	if typeof(kiHit) == "number" then
		lastApplied.Ki = kiHit
	end

	local passZone = linked(gate, "PassZone")
	local isOpen = now < state.openUntil
	if not isOpen and GateRules.canOpen(required, lastApplied, now, GateConfig.ApplyWindowSeconds) then
		state.openingPowers = table.clone(required)
		state.openUntil = now + GateConfig.OpenSeconds
		-- Teamwork credit (TASK-0007): whoever supplied a required power, once per opening.
		local helpers: { [number]: boolean } = {}
		for _, power in required do
			local id = if power == "Shinobi"
				then state.cloneOwner
				elseif power == "Ki" and kiTarget then kiTarget:GetAttribute("LastKiHitBy")
				else nil
			if typeof(id) == "number" then
				helpers[id] = true
			end
		end
		for id in helpers do
			local helper = Players:GetPlayerByUserId(id)
			if helper then
				contributionListener(helper)
			end
		end
		state.cloneOwner = nil
		state.firstArrival = nil
		-- Consume the inputs: the Ki hit is cleared and the current clone is spent (it must leave and
		-- a clone must arrive again to count).
		state.cloneSeenAt = nil
		state.cloneConsumed = clonePresent
		if kiTarget then
			kiTarget:SetAttribute("LastKiHit", nil)
			kiTarget:SetAttribute("LastKiHitBy", nil)
		end
		-- Players already past the gate when it opens didn't pass through it.
		state.presentAtOpen = {}
		if passZone then
			for _, player in playersIn(passZone) do
				state.presentAtOpen[player] = true
			end
		end
		isOpen = true
	end

	if isOpen and passZone then
		for _, player in playersIn(passZone) do
			if not state.presentAtOpen[player] then
				for _, power in GateRules.awardFor(state.openingPowers, state.awarded[player] == true) do
					EchoService.add(player, power)
				end
				state.awarded[player] = true
			end
		end
	end
	-- Never turn solid on top of a player (audit F3): stay open while someone is inside the barrier.
	if not isOpen and gate.CanCollide == false and #playersIn(gate) > 0 then
		isOpen = true
	end
	setBlocked(gate, not isOpen)
	gate:SetAttribute("State", if isOpen then "open" else "closed")

	-- Echo Shrine fallback.
	local approach = linked(gate, "ApproachZone")
	if not isOpen and not state.shrineOpen and state.firstArrival == nil and approach and #playersIn(approach) > 0 then
		state.firstArrival = now
	end
	gate:SetAttribute(
		"ShrineAt",
		if state.firstArrival then state.firstArrival + GateConfig.ShrineDelaySeconds else nil
	)
	local bypass = linked(gate, "Bypass")
	gate:SetAttribute("HasBypass", bypass ~= nil)
	if
		bypass
		and not state.shrineOpen
		and GateRules.shrineDue(state.firstArrival, isOpen, now, GateConfig.ShrineDelaySeconds)
	then
		state.shrineOpen = true -- stays open for the rest of the match (no cycling)
	end
	if bypass then
		setBlocked(bypass, not state.shrineOpen)
	end
	gate:SetAttribute("ShrineOpen", state.shrineOpen)
end

function ConvergenceGate.setPresentProvider(provider: () -> { Player })
	presentProvider = provider
end

-- Called (in its own thread) for each player whose power helped open a gate (Teamwork; TASK-0007).
function ConvergenceGate.onContribution(listener: (player: Player) -> ())
	contributionListener = function(player: Player)
		task.spawn(listener, player)
	end
end

-- Clears every gate's per-match state (awards, shrine, inputs). Called at match start.
function ConvergenceGate.resetAll()
	for gate in states do
		states[gate] = nil
	end
end

function ConvergenceGate.start()
	if started then
		return
	end
	started = true
	CollectionService:GetInstanceRemovedSignal(GateConfig.Tag):Connect(function(instance)
		if instance:IsA("BasePart") then
			states[instance] = nil
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		for _, state in states do
			state.awarded[player] = nil
		end
	end)
	task.spawn(function()
		while true do
			local now = os.clock()
			for _, instance in CollectionService:GetTagged(GateConfig.Tag) do
				if instance:IsA("BasePart") and instance:IsDescendantOf(Workspace) then
					local ok, err = pcall(function()
						step(instance, now)
					end)
					if not ok then
						warn(`[ConvergenceGate] {instance:GetFullName()}: {err}`)
					end
				end
			end
			task.wait(GateConfig.PollSeconds)
		end
	end)
end

return ConvergenceGate
