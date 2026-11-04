--!strict
-- ModePadService (TASK-0122): tells a client when its character walks onto a hub mode pad. Pads are the ModePad-tagged
-- parts under Workspace.Hub (Mode attribute -> ModePadConfig.Modes). One poll loop every PollSeconds checks each player's
-- HumanoidRootPart against each pad (ModePadRules.isInside), steps the per-player state (ModePadRules.step: enter only,
-- with a cooldown) and fires ModePadOpen to that player alone, and ModePadLeave when they step off (TASK-0137). The client only ever opens a screen; it asks the server
-- for nothing, so there is no client -> server remote here.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ModePadConfig = require(Shared:WaitForChild("ModePadConfig"))
local ModePadRules = require(Shared:WaitForChild("ModePadRules"))

local Remotes = require(script.Parent.Parent.Remotes)
local BlitzService = require(script.Parent.BlitzService)
local RoundService = require(script.Parent.RoundService)
local SkillTestService = require(script.Parent.SkillTestService)
local VsService = require(script.Parent.VsService)

local TAG = "ModePad"

type PadRecord = {
	name: string,
	screen: string,
	pad: ModePadRules.Pad,
}

local ModePadService = {}

local started = false
local pads: { PadRecord } = {}
-- player -> the character the states belong to, and pad index -> step state
type PlayerState = { character: Model, pads: { [number]: ModePadRules.State } }
local states: { [Player]: PlayerState } = {}

local function readPads(hub: Instance): { PadRecord }
	local records: { PadRecord } = {}
	for _, part in CollectionService:GetTagged(TAG) do
		if not part:IsDescendantOf(hub) then
			continue
		end
		if not part:IsA("BasePart") then
			warn(`[MathShow] ModePad {part:GetFullName()} is not a part; skipped`)
			continue
		end
		local mode = part:GetAttribute("Mode")
		local screen = ModePadRules.screenFor(mode)
		if screen == nil then
			warn(`[MathShow] ModePad {part:GetFullName()} has unknown Mode {tostring(mode)}; skipped`)
			continue
		end
		local cf, size = part.CFrame, part.Size
		-- Yaw from the right vector (right = cos, 0, -sin), so a little pitch or roll cannot skew it.
		local right = cf.RightVector
		table.insert(records, {
			name = part.Name,
			screen = screen,
			pad = {
				cx = cf.Position.X,
				cy = cf.Position.Y,
				cz = cf.Position.Z,
				sx = size.X,
				sy = size.Y,
				sz = size.Z,
				yaw = math.atan2(-right.Z, right.X),
			},
		})
	end
	return records
end

-- A player in the current match (RoundService: ShowState.participant), in the VS queue or a VS match, or in a Blitz or Skill
-- Test run is busy: pads stay quiet for them. Each service holds its own server-side state; these are read-only queries.
local function isBusy(player: Player): boolean
	return RoundService.isParticipant(player)
		or VsService.isBusy(player)
		or BlitzService.isRunning(player)
		or SkillTestService.isRunning(player)
end

-- No yields in here: the only wait in the loop is the one after it.
local function poll()
	local now = os.clock()
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not root or not root:IsA("BasePart") then
			states[player] = nil -- loading: nothing to track
			continue
		end
		local position = root.Position
		local pos: ModePadRules.Pos = { x = position.X, y = position.Y, z = position.Z }
		-- Keyed by character: a respawn between two polls is a new character, so spawning onto a pad counts as an entry.
		local existing = states[player]
		local playerState: PlayerState
		if existing and existing.character == character then
			playerState = existing
		else
			playerState = { character = character :: Model, pads = {} }
			states[player] = playerState
		end
		local blocked = isBusy(player)
		for index, record in pads do
			local prev = playerState.pads[index] or { inside = false }
			local inside = ModePadRules.isInside(record.pad, pos)
			local left = ModePadRules.left(prev, inside)
			local nextState, trigger = ModePadRules.step(prev, inside, now, blocked)
			playerState.pads[index] = nextState
			if trigger then
				Remotes.ModePadOpen:FireClient(player, { screen = record.screen })
			elseif left then
				Remotes.ModePadLeave:FireClient(player, { screen = record.screen })
			end
		end
	end
end

function ModePadService.start()
	if started then
		return
	end
	started = true

	Players.PlayerRemoving:Connect(function(player: Player)
		states[player] = nil
	end)

	local hub = Workspace:FindFirstChild("Hub")
	if not hub then
		warn("[MathShow] ModePadService: Workspace.Hub not found; no mode pads")
		return
	end
	pads = readPads(hub)
	if #pads == 0 then
		warn("[MathShow] ModePadService: no ModePad parts under Workspace.Hub")
		return
	end
	print(`[MathShow] ModePadService: {#pads} pads`)

	task.spawn(function()
		while true do
			local ok, err = pcall(function()
				poll()
			end)
			if not ok then
				warn(`[MathShow] ModePadService poll failed: {err}`)
			end
			task.wait(ModePadConfig.PollSeconds)
		end
	end)
end

return ModePadService
