--!strict
-- Capture meter maths. The server owns the clock: it starts the session, and judges each release
-- from its own receive time minus measured latency. The client only draws the same needle.

local CaptureRules = {}

CaptureRules.LatencySlack = 0.09 -- seconds of extra forgiveness either side of the press
CaptureRules.MinReleaseGap = 0.2 -- seconds between counted releases (anti-spam)
CaptureRules.SessionTimeout = 20

-- Needle position in [0, 1]: a triangle wave, 0 -> 1 -> 0 every `period` seconds.
function CaptureRules.needle(t: number, period: number): number
	if period <= 0 then
		return 0
	end
	local phase = (t % period) / period
	return if phase < 0.5 then phase * 2 else (1 - phase) * 2
end

-- Picks a green-zone centre that keeps the whole zone on the bar.
function CaptureRules.zoneCenter(rng: Random, width: number): number
	local half = width / 2
	return rng:NextNumber(half + 0.08, 1 - half - 0.08)
end

-- True if the needle was inside the zone at any moment within `slack` seconds of `elapsed`.
function CaptureRules.judge(elapsed: number, period: number, center: number, width: number, slack: number): boolean
	local half = width / 2
	local step = 0.005
	local t = elapsed - slack
	while t <= elapsed + slack do
		if math.abs(CaptureRules.needle(t, period) - center) <= half then
			return true
		end
		t += step
	end
	return false
end

export type Outcome = "hit" | "miss" | "success" | "fled"

-- Advances a session's counters and returns the outcome.
function CaptureRules.applyRelease(
	hit: boolean,
	hits: number,
	misses: number,
	hitsNeeded: number,
	missesAllowed: number
): (Outcome, number, number)
	if hit then
		hits += 1
		return (if hits >= hitsNeeded then "success" else "hit"), hits, misses
	end
	misses += 1
	return (if misses >= missesAllowed then "fled" else "miss"), hits, misses
end

return CaptureRules
