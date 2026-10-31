--!strict
-- Pushes a read-only snapshot of each player's state to their client (throttled), and sends toasts.
-- Other services contribute fields with addProvider instead of this module requiring them.

local Players = game:GetService("Players")

local Remotes = require(script.Parent.Parent.Remotes)
local PlayerDataService = require(script.Parent.PlayerDataService)

local StateService = {}

local PUSH_INTERVAL = 0.25

local started = false
local dirty: { [Player]: boolean } = {}
local providers: { (Player, { [string]: any }) -> () } = {}

function StateService.addProvider(fn: (Player, { [string]: any }) -> ())
	table.insert(providers, fn)
end

function StateService.markDirty(player: Player)
	dirty[player] = true
end

function StateService.toast(player: Player, text: string, kind: string?)
	Remotes.event("Toast"):FireClient(player, { text = text, kind = kind or "info" })
end

function StateService.toastAll(text: string, kind: string?)
	Remotes.event("Toast"):FireAllClients({ text = text, kind = kind or "info" })
end

local function build(player: Player): { [string]: any }?
	local profile = PlayerDataService.get(player)
	if not profile then
		return nil
	end
	local snap: { [string]: any } = {
		serverTime = workspace:GetServerTimeNow(),
		now = os.time(),
		persistence = PlayerDataService.persistence(player),
		coins = profile.coins,
		speedLevel = profile.speedLevel,
		houseTier = profile.houseTier,
		owned = profile.owned,
		journal = profile.journal,
		flags = profile.flags,
		stats = profile.stats,
		route = profile.route,
		exhibits = profile.exhibits,
		cosmetics = profile.cosmetics, -- read-only ownership for the Shop (TASK-0061)
	}
	for _, fn in providers do
		local ok, err = pcall(function()
			fn(player, snap)
		end)
		if not ok then
			warn(`[State] provider failed: {err}`)
		end
	end
	return snap
end

local function push(player: Player)
	local snap = build(player)
	if snap then
		Remotes.event("State"):FireClient(player, snap)
	end
end

function StateService.start()
	if started then
		return
	end
	started = true
	PlayerDataService.onDirty(StateService.markDirty)
	Remotes.event("RequestState").OnServerEvent:Connect(function(player)
		if Remotes.allow(player, "RequestState", 1, 3) then
			dirty[player] = true
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		dirty[player] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(PUSH_INTERVAL)
			for player in dirty do
				dirty[player] = nil
				if player.Parent then
					task.spawn(push, player)
				end
			end
		end
	end)
end

return StateService
