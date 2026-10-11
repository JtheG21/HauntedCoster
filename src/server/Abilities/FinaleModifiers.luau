--!strict
-- Finale versions of the powers and the Echo-charge spends (TASK-0007).
--   Ki Burst      -> also knocks back rival finale players in front of you
--   Echo Clone    -> also gives a guard that absorbs the next knockback
--   EchoBurst     -> spend an Echo_Ki charge: a borrowed Ki Burst (fixed strength), any faction
--   EchoGuard     -> spend an Echo_Shinobi charge: a borrowed guard, any faction
-- Echo charges ADD to your own power (design open question 3, proposed default).
-- Knockback is only ever applied here, on the server, to alive finale players. The client sends an
-- ability id and nothing else.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local FactionConfig = require(Shared:WaitForChild("FactionConfig"))
local FinaleConfig = require(Shared:WaitForChild("FinaleConfig"))
local KnockbackRules = require(Shared:WaitForChild("KnockbackRules"))

local Services = script.Parent.Parent.Services
local EchoService = require(Services.EchoService)
local FinaleService = require(Services.FinaleService)

local FinaleModifiers = {}

-- Latest push per target, so an earlier push's ownership hand-back never cuts a newer push short.
local pushTokens: { [Player]: number } = {}

local function push(target: Player, direction: Vector3, speed: number)
	local character = target.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (root and root:IsA("BasePart")) then
		return
	end
	-- The server takes over the target's physics for the push (TASK-0007 rev 1). A short constraint
	-- simulated by the target's own client was missed whenever that client hitched for longer than the
	-- push, and a client could also delete it locally. Ownership goes back to the player afterwards.
	local config = FinaleConfig.Knockback
	local token = (pushTokens[target] or 0) + 1
	pushTokens[target] = token
	pcall(function()
		root:SetNetworkOwner(nil)
	end)
	task.delay(config.ServerOwnSeconds, function()
		if pushTokens[target] ~= token then
			return
		end
		pushTokens[target] = nil
		if target.Parent ~= nil and root.Parent ~= nil then
			pcall(function()
				root:SetNetworkOwner(target)
			end)
		end
	end)
	local attachment = Instance.new("Attachment")
	attachment.Name = "KnockbackAttachment"
	attachment.Parent = root
	local velocity = Instance.new("LinearVelocity")
	velocity.Name = "KnockbackVelocity"
	velocity.Attachment0 = attachment
	velocity.RelativeTo = Enum.ActuatorRelativeTo.World
	velocity.VectorVelocity = direction * speed + Vector3.new(0, config.UpSpeed, 0)
	velocity.MaxForce = config.MaxForce
	velocity.Parent = root
	task.delay(config.Duration, function()
		velocity:Destroy()
		attachment:Destroy()
	end)
end

local function flash(position: Vector3, color: Color3)
	local orb = Instance.new("Part")
	orb.Name = "FinaleBurstFlash"
	orb.Shape = Enum.PartType.Ball
	orb.Size = Vector3.one * 4
	orb.Position = position
	orb.Anchored = true
	orb.CanCollide = false
	orb.CanQuery = false
	orb.CanTouch = false
	orb.Material = Enum.Material.Neon
	orb.Color = color
	orb.Transparency = 0.3
	orb.Parent = Workspace
	task.delay(0.2, function()
		orb:Destroy()
	end)
end

-- Knocks back every alive rival in front of the attacker. Returns how many were pushed and how many
-- hits a guard absorbed.
function FinaleModifiers.knockback(attacker: Player, root: BasePart, fraction: number): (number, number)
	if not FinaleService.isAlive(attacker) then
		return 0, 0
	end
	local config = FinaleConfig.Knockback
	local origin = root.Position
	local look = root.CFrame.LookVector
	local f = if fraction == fraction then math.clamp(fraction, 0, 1) else 0
	local speed = KnockbackRules.lerp(config.MinSpeed, config.MaxSpeed, f)
	local pushed, absorbed = 0, 0
	for _, rival in FinaleService.getAliveRivals(attacker) do
		local character = rival.Character
		local target = character and character:FindFirstChild("HumanoidRootPart")
		if not (target and target:IsA("BasePart")) then
			continue
		end
		if not KnockbackRules.inFront(origin, look, target.Position, config.Range) then
			continue
		end
		if FinaleService.consumeGuard(rival) then
			absorbed += 1
			continue
		end
		push(rival, KnockbackRules.pushDirection(origin, target.Position, look), speed)
		pushed += 1
	end
	return pushed, absorbed
end

-- KiBurst hook: the player's own Ki Burst at its server-measured charge.
function FinaleModifiers.onKiBurst(player: Player, root: BasePart, fraction: number)
	FinaleModifiers.knockback(player, root, fraction)
end

-- EchoClone hook: the player's own clone also guards them in the finale.
function FinaleModifiers.onEchoClone(player: Player)
	FinaleService.grantGuard(player)
end

-- Eligibility for an Echo spend: alive in the finale and holding a charge of that power.
function FinaleModifiers.canSpend(power: string): (player: Player) -> boolean
	return function(player: Player): boolean
		return FinaleService.isAlive(player) and EchoService.get(player, power) > 0
	end
end

function FinaleModifiers.echoBurstHandler(player: Player, _character: Model, root: BasePart)
	if not EchoService.spend(player, "Ki") then
		return
	end
	FinaleModifiers.knockback(player, root, FinaleConfig.EchoBurstFraction)
	flash(root.Position + root.CFrame.LookVector * 3, FactionConfig.Factions.Ki.color)
end

function FinaleModifiers.echoGuardHandler(player: Player, _character: Model, root: BasePart)
	if not EchoService.spend(player, "Shinobi") then
		return
	end
	FinaleService.grantGuard(player)
	flash(root.Position, FactionConfig.Factions.Shinobi.color)
end

return FinaleModifiers
