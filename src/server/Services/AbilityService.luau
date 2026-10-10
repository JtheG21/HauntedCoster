--!strict
-- Server-authoritative ability pipeline (TASK-0002).
-- Clients only *request* an ability by id. The server validates type, rate, cooldown and
-- eligibility, then runs the registered handler. Clients never send targets, forces or positions.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AbilityConfig = require(Shared:WaitForChild("AbilityConfig"))
local AbilityRules = require(Shared:WaitForChild("AbilityRules"))

export type Handler = (player: Player, character: Model, root: BasePart) -> ()
export type Registration = {
	handler: Handler,
	-- Optional eligibility check (e.g. faction). Return false to reject.
	canUse: ((player: Player) -> boolean)?,
}

type PlayerState = {
	timestamps: { number },
	lastUsed: { [string]: number },
	rejections: number,
	lastWarn: number,
}

local AbilityService = {}

local registry: { [string]: Registration } = {}
local states: { [Player]: PlayerState } = {}
local started = false

local function getState(player: Player): PlayerState
	local state = states[player]
	if not state then
		state = { timestamps = {}, lastUsed = {}, rejections = 0, lastWarn = -math.huge }
		states[player] = state
	end
	return state
end

local function reject(player: Player, state: PlayerState, reason: string)
	state.rejections += 1
	-- Readable from tests and telemetry without requiring this module (which may load a separate copy).
	player:SetAttribute("AbilityRejections", state.rejections)
	local now = os.clock()
	if now - state.lastWarn >= AbilityConfig.WarnIntervalSeconds then
		state.lastWarn = now
		warn(`[AbilityService] rejected {player.Name}: {reason} (total {state.rejections})`)
	end
end

local function onRequest(player: Player, abilityId: unknown, ...: unknown)
	local state = getState(player)
	local now = os.clock()

	-- Rate limit first, so malformed spam is dropped as cheaply as possible.
	local allowed, kept = AbilityRules.checkRate(
		state.timestamps,
		now,
		AbilityConfig.RateWindowSeconds,
		AbilityConfig.MaxRequestsPerWindow
	)
	state.timestamps = kept
	if not allowed then
		reject(player, state, "rate_limited")
		return
	end

	local ok, reason = AbilityRules.validateRequest(abilityId, select("#", ...), registry)
	if not ok then
		reject(player, state, reason or "invalid")
		return
	end
	local id = abilityId :: string
	local registration = registry[id]
	local def = AbilityConfig.Abilities[id]
	if not def then
		reject(player, state, "no_config")
		return
	end

	local canUse = registration.canUse
	if canUse and not canUse(player) then
		reject(player, state, "not_eligible")
		return
	end

	local ready, cooldownReason = AbilityRules.canActivate({
		now = now,
		lastUsed = state.lastUsed[id],
		cooldown = def.cooldown,
	})
	if not ready then
		reject(player, state, cooldownReason or "cooldown")
		return
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (character and humanoid and humanoid.Health > 0 and root and root:IsA("BasePart")) then
		reject(player, state, "no_character")
		return
	end

	-- Commit the cooldown before running the handler so a yielding handler can't be re-entered.
	state.lastUsed[id] = now
	local success, err = pcall(function()
		registration.handler(player, character, root)
	end)
	if not success then
		warn(`[AbilityService] {id} handler error for {player.Name}: {err}`)
	end
end

function AbilityService.register(abilityId: string, registration: Registration)
	assert(AbilityConfig.Abilities[abilityId], `AbilityService: no config for '{abilityId}'`)
	assert(registry[abilityId] == nil, `AbilityService: '{abilityId}' already registered`)
	registry[abilityId] = registration
end

-- Test/diagnostic helper: number of rejected requests for a player this session.
function AbilityService.getRejectionCount(player: Player): number
	local state = states[player]
	return if state then state.rejections else 0
end

function AbilityService.start()
	if started then
		return
	end
	started = true

	-- The server owns the remote. Any pre-existing instance with the same name is replaced.
	local existing = ReplicatedStorage:FindFirstChild(AbilityConfig.RemoteName)
	if existing then
		existing:Destroy()
	end
	local remote = Instance.new("RemoteEvent")
	remote.Name = AbilityConfig.RemoteName
	remote.OnServerEvent:Connect(onRequest)
	remote.Parent = ReplicatedStorage

	Players.PlayerRemoving:Connect(function(player)
		states[player] = nil
	end)
end

return AbilityService
