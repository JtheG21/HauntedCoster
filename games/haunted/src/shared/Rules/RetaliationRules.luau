--!strict
-- Failed-capture retaliation (TASK-0031, ADR-0007 "final miss only"): when a capture's misses run out,
-- the target and up to `maxExtra` wild monsters near the player turn and chase them for a few seconds. A
-- pursuer that reaches the player knocks them down briefly (no damage), then gives up. Pure rules: who
-- joins, how a pursuer steps (never leaving its habitat region), catches and when a pursuit ends.

local Shared = script.Parent.Parent
local World = require(Shared.Config.World)
local Monsters = require(Shared.Config.Monsters)
local ChaseRules = require(script.Parent.ChaseRules)

local RetaliationRules = {}

export type Candidate = { id: number, at: Vector3, available: boolean }

-- The pursuers: the target first, then the nearest available monsters within `radius` of the player,
-- at most `maxExtra` of them. Ids are returned in that order.
function RetaliationRules.pickPursuers(targetId: number, playerAt: Vector3, candidates: { Candidate }): { number }
	local cfg = Monsters.Retaliation
	local picked = { targetId }
	local near: { { id: number, d: number } } = {}
	for _, c in candidates do
		if c.id ~= targetId and c.available then
			local d = Vector3.new(c.at.X - playerAt.X, 0, c.at.Z - playerAt.Z).Magnitude
			if d <= cfg.radius then
				table.insert(near, { id = c.id, d = d })
			end
		end
	end
	table.sort(near, function(a, b)
		return a.d < b.d
	end)
	for i = 1, math.min(cfg.maxExtra, #near) do
		table.insert(picked, near[i].id)
	end
	return picked
end

-- One pursuit step from `at` towards `toward`, at most `step` studs on the ground (keeping `at`'s height).
-- The pursuer stays inside the habitat region it started in (`ChaseRules.fleeRegion`): a step that would
-- leave it, or enter the walled crypt from outside, is not taken.
function RetaliationRules.pursueStep(at: Vector3, toward: Vector3, step: number): Vector3
	local flat = Vector3.new(toward.X - at.X, 0, toward.Z - at.Z)
	local dist = flat.Magnitude
	if dist < 0.01 then
		return at
	end
	local move = flat.Unit * math.min(step, dist)
	local nextAt = at + move
	local region, avoid = ChaseRules.fleeRegion(at)
	if not ChaseRules.contains(region, nextAt.X, nextAt.Z) then
		return at
	end
	if avoid and World.inRect(avoid, nextAt.X, nextAt.Z) then
		return at
	end
	return nextAt
end

-- A pursuer reaches the player (flat distance; monsters hover).
function RetaliationRules.caught(pursuerAt: Vector3, playerAt: Vector3): boolean
	return Vector3.new(pursuerAt.X - playerAt.X, 0, pursuerAt.Z - playerAt.Z).Magnitude
		<= Monsters.Retaliation.catchDistance
end

-- Why a pursuit ends, or nil while it goes on. `elapsed` since it started; `farthest` is the distance from
-- the player to the closest pursuer still chasing.
function RetaliationRules.endReason(elapsed: number, closest: number, playerAlive: boolean, pursuers: number): string?
	local cfg = Monsters.Retaliation
	if not playerAlive then
		return "dead"
	elseif pursuers <= 0 then
		return "done"
	elseif elapsed >= cfg.seconds then
		return "timeout"
	elseif closest > cfg.giveUpDistance then
		return "escaped"
	end
	return nil
end

-- A pursuer that already knocked this player down can't do it again until its cooldown has passed, and no
-- pursuer can knock a player who was knocked down by anyone in the last knockdown + grace seconds (no
-- stun-lock: a player who gets up always gets a head start).
function RetaliationRules.canKnock(lastByThis: number?, now: number, lastOfPlayer: number?): boolean
	local cfg = Monsters.Retaliation
	if lastOfPlayer and now - lastOfPlayer < cfg.knockdownSeconds + cfg.graceSeconds then
		return false
	end
	return lastByThis == nil or now - lastByThis >= cfg.cooldownSeconds
end

return RetaliationRules
