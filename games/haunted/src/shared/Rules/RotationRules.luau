--!strict
-- Pure habitat rotation schedule (TASK-0029, ADR-0007). Every answer comes from an injected clock
-- (`now`, UTC seconds - Workspace:GetServerTimeNow() on the server) and a config, so all servers with the
-- same clock agree, and specs can check boundaries without waiting.

local Rotation = require(script.Parent.Parent.Config.Rotation)

local RotationRules = {}

export type Phase = "open" | "warning" | "closing"

export type State = {
	slot: number, -- slots since the epoch
	index: number, -- 1-based position in `order`
	id: string, -- the habitat that should be active now
	nextId: string,
	slotStart: number,
	swapAt: number, -- when `nextId` takes over
	secondsLeft: number,
	phase: Phase,
}

function RotationRules.at(now: number, config: Rotation.Config?): State
	local c = config or Rotation
	local n = #c.order
	local slot = math.floor((now - c.epoch) / c.slotSeconds)
	local index = slot % n + 1 -- Luau's % is floored, so clocks before the epoch still land in 1..n
	local slotStart = c.epoch + slot * c.slotSeconds
	local swapAt = slotStart + c.slotSeconds
	local left = swapAt - now
	local phase: Phase = if left <= c.closingSeconds
		then "closing"
		elseif left <= c.warningSeconds then "warning"
		else "open"
	return {
		slot = slot,
		index = index,
		id = c.order[index],
		nextId = c.order[index % n + 1],
		slotStart = slotStart,
		swapAt = swapAt,
		secondsLeft = left,
		phase = phase,
	}
end

-- New captures may start (refused in the closing window before a swap).
function RotationRules.capturesOpen(now: number, config: Rotation.Config?): boolean
	return RotationRules.at(now, config).phase ~= "closing"
end

-- A copy of `base` with test overrides applied (numbers only; order and unknown keys are ignored), for
-- Studio test runs. Rejects values that would make the schedule meaningless.
function RotationRules.withOverrides(base: Rotation.Config, overrides: any): Rotation.Config
	local c = table.clone(base)
	if type(overrides) ~= "table" then
		return c
	end
	for _, key in { "slotSeconds", "warningSeconds", "closingSeconds", "epoch" } do
		local v = overrides[key]
		if type(v) == "number" and v == v then
			(c :: any)[key] = v
		end
	end
	if
		c.slotSeconds < 10
		or c.warningSeconds >= c.slotSeconds
		or c.closingSeconds > c.warningSeconds
		or c.closingSeconds < 0
	then
		return table.clone(base)
	end
	return c
end

-- "m:ss" for HUD countdowns.
function RotationRules.clock(seconds: number): string
	local s = math.max(0, math.ceil(seconds))
	return string.format("%d:%02d", s // 60, s % 60)
end

return RotationRules
