--!strict
-- Pure mode-pad logic (TASK-0122): is a position on a pad, and when does standing on one fire. No Instances; plain
-- numbers and tables. Non-finite input never triggers and never throws.

local ModePadConfig = require(script.Parent.ModePadConfig)

-- Centre, size and yaw (radians, rotation about Y as in CFrame.Angles(0, yaw, 0)) of a pad part.
export type Pad = { cx: number, cy: number, cz: number, sx: number, sy: number, sz: number, yaw: number }
export type Pos = { x: number, y: number, z: number }
export type State = { inside: boolean, lastTriggerAt: number? }

local ModePadRules = {}

local function finite(n: any): boolean
	return typeof(n) == "number" and n == n and n ~= math.huge and n ~= -math.huge
end

-- The menu screen for a pad's Mode attribute, or nil when the mode is not in the config.
function ModePadRules.screenFor(mode: any): string?
	if typeof(mode) ~= "string" then
		return nil
	end
	return (ModePadConfig.Modes :: { [string]: string })[mode]
end

-- Inside the yaw-rotated footprint (edges count) and from the top surface up to VerticalTolerance above it.
function ModePadRules.isInside(pad: Pad, pos: Pos): boolean
	if typeof(pad) ~= "table" or typeof(pos) ~= "table" then
		return false
	end
	for _, v in { pad.cx, pad.cy, pad.cz, pad.sx, pad.sy, pad.sz, pad.yaw, pos.x, pos.y, pos.z } do
		if not finite(v) then
			return false
		end
	end
	local dx, dz = pos.x - pad.cx, pos.z - pad.cz
	local c, s = math.cos(pad.yaw), math.sin(pad.yaw)
	local lx = dx * c - dz * s
	local lz = dx * s + dz * c
	if math.abs(lx) > pad.sx / 2 or math.abs(lz) > pad.sz / 2 then
		return false
	end
	local above = pos.y - (pad.cy + pad.sy / 2)
	return above >= 0 and above <= ModePadConfig.VerticalTolerance
end

-- One poll for one player and pad. Triggers only on an outside -> inside transition once CooldownSeconds have passed
-- since the last trigger; standing still never retriggers. blocked (in a match, a run or the VS queue) suppresses the trigger
-- but `inside` still updates, so unblocking while still on the pad does not fire: the player has to leave and re-enter.
-- Bad input returns prev unchanged and no trigger.
function ModePadRules.step(prev: State, insideNow: boolean, now: number, blocked: boolean): (State, boolean)
	if typeof(insideNow) ~= "boolean" or typeof(blocked) ~= "boolean" or not finite(now) or typeof(prev) ~= "table" then
		return prev, false
	end
	local last = prev.lastTriggerAt
	if last ~= nil and not finite(last) then
		last = nil
	end
	local entered = insideNow and not prev.inside
	local ready = last == nil or now - last >= ModePadConfig.CooldownSeconds
	local trigger = entered and ready and not blocked
	return { inside = insideNow, lastTriggerAt = if trigger then now else last }, trigger
end

return table.freeze(ModePadRules)
