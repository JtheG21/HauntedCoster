--!strict
-- Original demonstration logic; not extracted from the supplied game.
local State = {}
function State.describe(raw: number)
	assert(raw == raw and raw > -math.huge and raw < math.huge, "charge must be finite")
	local charge = math.clamp(raw, 0, 100)
	local phase = if charge == 0 then "DEPLETED" elseif charge <= 25 then "LOW" else "NORMAL"
	return {
		charge = charge,
		phase = phase,
		enabled = charge > 0,
		hint = if charge == 0
			then "Lamp unavailable. Refill to restore."
			elseif charge <= 25 then "Reserve low. Conserve power."
			else "Reserve stable. Lamp available.",
	}
end
function State.drain(charge: number, seconds: number, active: boolean): number
	assert(seconds == seconds and seconds >= 0 and seconds < math.huge, "seconds must be finite and nonnegative")
	return State.describe(charge - seconds * (if active then 8 else 2)).charge
end
return State
