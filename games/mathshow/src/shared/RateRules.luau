--!strict
-- Pure sliding-window rate limit for remotes. No Instances, no clock: callers pass `now`. Nothing throws on bad input.

local RateRules = {}

-- `stamps` are the times of recent allowed calls. Returns the pruned list (with `now` added when allowed) and whether
-- this call is allowed: at most `maxCount` calls in any `window` seconds. The input table is never mutated.
function RateRules.allow(stamps: { number }, now: number, maxCount: number, window: number): ({ number }, boolean)
	local kept: { number } = {}
	if typeof(now) ~= "number" or now ~= now then
		return kept, false
	end
	for _, stamp in stamps do
		if typeof(stamp) == "number" and stamp == stamp and now - stamp < window and stamp <= now then
			table.insert(kept, stamp)
		end
	end
	if #kept < maxCount then
		table.insert(kept, now)
		return kept, true
	end
	return kept, false
end

return RateRules
