--!strict
-- Capture meter maths. The server owns the clock: it starts the session, and judges each release
-- from its own receive time minus measured latency. The client only draws the same needle.

local CaptureRules = {}

CaptureRules.LatencySlack = 0.04 -- seconds of extra forgiveness either side of the press (jitter only)
CaptureRules.MinReleaseGap = 0.35 -- seconds between counted releases (anti-spam; mashing still burns misses)
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

-- Width of the window the judge really accepts: the zone plus the distance the needle travels in
-- `slack` seconds either side (the needle covers 2 bar-widths per period). The meter draws this, so
-- the green zone on screen matches what is judged.
function CaptureRules.judgedWidth(width: number, period: number, slack: number): number
	if period <= 0 then
		return width
	end
	return width + 2 * slack * (2 / period)
end

-- True if the needle was inside the zone at any moment within `slack` seconds of `elapsed`. Exact: the
-- needle is continuous, so over [a, b] it covers every position between its lowest and highest value
-- there (its value at a and b, or 1 / 0 if a peak / trough falls inside). That is precisely the window
-- `judgedWidth` describes.
function CaptureRules.judge(elapsed: number, period: number, center: number, width: number, slack: number): boolean
	local half = width / 2
	local a, b = elapsed - slack, elapsed + slack
	local na, nb = CaptureRules.needle(a, period), CaptureRules.needle(b, period)
	local lo, hi = math.min(na, nb), math.max(na, nb)
	if period > 0 then
		if math.floor((b - period / 2) / period) >= math.ceil((a - period / 2) / period) then
			hi = 1 -- a peak lies inside the window
		end
		if math.floor(b / period) >= math.ceil(a / period) then
			lo = 0 -- a trough lies inside the window
		end
	end
	return hi >= center - half and lo <= center + half
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
