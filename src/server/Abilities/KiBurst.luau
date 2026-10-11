--!strict
-- Ki Vanguard "Ki Burst" (TASK-0004): hold to charge, release to blast in front of you.
-- Charge time is measured on the server between the KiCharge and KiBurst requests.
-- Breaks CrackedWalls (above a charge threshold) and pushes HeavyBlocks.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AbilityConfig = require(Shared:WaitForChild("AbilityConfig"))
local FactionConfig = require(Shared:WaitForChild("FactionConfig"))
local KnockbackRules = require(Shared:WaitForChild("KnockbackRules"))

local Components = script.Parent.Parent.Components
local CrackedWall = require(Components.CrackedWall)
local HeavyBlock = require(Components.HeavyBlock)

local KiBurst = {}

local chargeStarts: { [Player]: number } = {}
local started = false

local function flash(position: Vector3, fraction: number)
	local orb = Instance.new("Part")
	orb.Name = "KiBurstFlash"
	orb.Shape = Enum.PartType.Ball
	orb.Size = Vector3.one * KnockbackRules.lerp(2, 5, fraction)
	orb.Position = position
	orb.Anchored = true
	orb.CanCollide = false
	orb.CanQuery = false
	orb.CanTouch = false
	orb.Material = Enum.Material.Neon
	orb.Color = FactionConfig.Factions.Ki.color
	orb.Transparency = 0.3
	orb.Parent = Workspace
	task.delay(0.2, function()
		orb:Destroy()
	end)
end

local function record(player: Player, key: string, value: number)
	local diagnostics = ServerStorage:FindFirstChild("AbilityDiagnostics")
	if diagnostics then
		diagnostics:SetAttribute(`{key}_{player.UserId}`, value)
	end
end

function KiBurst.chargeHandler(player: Player, _character: Model, _root: BasePart)
	chargeStarts[player] = os.clock()
end

function KiBurst.burstHandler(player: Player, character: Model, root: BasePart)
	local config = AbilityConfig.KiBurst
	local fraction = KnockbackRules.chargeFraction(chargeStarts[player], os.clock(), config)
	chargeStarts[player] = nil

	local origin = root.Position
	local look = root.CFrame.LookVector
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }

	local walls, blocks = 0, 0
	local pushed: { [BasePart]: boolean } = {}
	for _, part in Workspace:GetPartBoundsInRadius(origin, config.Range, params) do
		if not KnockbackRules.inFront(origin, look, part.Position, config.Range) then
			continue
		end
		if CrackedWall.isWall(part) then
			if fraction >= config.WallBreakFraction and CrackedWall.tryBreak(part, config.WallRespawnSeconds) then
				walls += 1
			end
		elseif HeavyBlock.isBlock(part) and not pushed[part] then
			pushed[part] = true
			local direction = KnockbackRules.pushDirection(origin, part.Position, look)
			local speed = KnockbackRules.lerp(config.MinPushSpeed, config.MaxPushSpeed, fraction)
			HeavyBlock.push(part, direction * speed)
			blocks += 1
		end
	end

	flash(origin + look * 3, fraction)
	record(player, "KiFraction", fraction)
	record(player, "KiWalls", walls)
	record(player, "KiBlocks", blocks)
end

function KiBurst.start()
	if started then
		return
	end
	started = true
	Players.PlayerRemoving:Connect(function(player)
		chargeStarts[player] = nil
	end)
end

return KiBurst
