--!strict
-- Pure rules for the haunted-tree gaze (TASK-0041, ADR-0010): whether a camera is "looking at" a face,
-- the per-tree observer aggregation behind the global freeze, and appearance picks. No instances; time
-- is passed in, so specs can step through the one-second recovery without waiting.

local HauntedTrees = require(script.Parent.Parent.Config.HauntedTrees)

local GazeRules = {}

type Gaze = typeof(HauntedTrees.gaze)

export type View = {
	camPos: Vector3,
	camLook: Vector3, -- unit
	headPos: Vector3,
}

export type Face = {
	pos: Vector3, -- centre of the face
	forward: Vector3, -- unit, out of the bark
	radius: number, -- rough half-size of the face, widens the aim cone
}

local function angleBetween(a: Vector3, b: Vector3): number
	local m = a.Magnitude * b.Magnitude
	if m < 1e-6 then
		return 0
	end
	return math.deg(math.acos(math.clamp(a:Dot(b) / m, -1, 1)))
end

-- The head is in front of the face, not too edge-on, and within range (plus `slack`).
function GazeRules.inFront(headPos: Vector3, face: Face, range: number, maxSideAngle: number): boolean
	local toHead = headPos - face.pos
	if toHead.Magnitude > range then
		return false
	end
	return toHead:Dot(face.forward) > 0 and angleBetween(toHead, face.forward) <= maxSideAngle
end

-- The aim test alone: degrees between the camera's look and the face, minus the face's own angular size.
function GazeRules.aimError(view: View, face: Face): number
	local toFace = face.pos - view.camPos
	local d = toFace.Magnitude
	if d < 1e-3 then
		return 0
	end
	local allowance = math.deg(math.atan(face.radius / d))
	return math.max(0, angleBetween(view.camLook, toFace) - allowance)
end

-- Whether this view counts as eye contact (line of sight is checked separately, by a raycast).
-- `wasLooking` adds hysteresis so a gaze on the boundary doesn't flicker.
function GazeRules.qualifies(view: View, face: Face, wasLooking: boolean?, cfg: Gaze?): boolean
	local c = cfg or HauntedTrees.gaze
	local slack = if wasLooking then c.exitSlack else 0
	if not GazeRules.inFront(view.headPos, face, c.range + slack, c.maxSideAngle + slack) then
		return false
	end
	-- The camera must also be on the face's side (a camera clipped behind the trunk can't see it).
	if (view.camPos - face.pos):Dot(face.forward) <= 0 then
		return false
	end
	return GazeRules.aimError(view, face) <= c.angle + slack
end

-- Server plausibility for a client's "looking" report: the reporter's head could see the face.
function GazeRules.plausible(headPos: Vector3, face: Face, cfg: Gaze?): boolean
	local c = cfg or HauntedTrees.gaze
	return GazeRules.inFront(headPos, face, c.range + c.exitSlack + c.serverRangeSlack, c.maxSideAngle + c.exitSlack)
end

-- Observer aggregation ------------------------------------------------------------------------------

export type TreeState = {
	observers: { [any]: number }, -- observer -> report expiry time
	frozen: boolean,
	resumeAt: number?, -- set while frozen with no observers
}

function GazeRules.newTree(): TreeState
	return { observers = {}, frozen = false, resumeAt = nil }
end

function GazeRules.observerCount(s: TreeState): number
	local n = 0
	for _ in s.observers do
		n += 1
	end
	return n
end

-- A valid "looking" report (new or keepalive). Freezes the tree and cancels any pending resume.
-- Returns true when `frozen` changed.
function GazeRules.observe(s: TreeState, who: any, now: number, cfg: Gaze?): boolean
	local c = cfg or HauntedTrees.gaze
	s.observers[who] = now + c.ttl
	s.resumeAt = nil
	if not s.frozen then
		s.frozen = true
		return true
	end
	return false
end

-- An observer stopped looking, left or lost their character. The last one out starts the resume delay.
function GazeRules.release(s: TreeState, who: any, now: number, cfg: Gaze?)
	local c = cfg or HauntedTrees.gaze
	if s.observers[who] == nil then
		return
	end
	s.observers[who] = nil
	if s.frozen and next(s.observers) == nil then
		s.resumeAt = now + c.resumeDelay
	end
end

-- Advance the clock: expire stale reports, then resume once the delay has fully elapsed.
-- Returns true when `frozen` changed.
function GazeRules.step(s: TreeState, now: number, cfg: Gaze?): boolean
	local c = cfg or HauntedTrees.gaze
	for who, expiry in s.observers do
		if expiry <= now then
			s.observers[who] = nil
		end
	end
	if s.frozen and next(s.observers) == nil then
		if s.resumeAt == nil then
			-- Reached when the last report expired (a client that stopped renewing): the delay starts now.
			s.resumeAt = now + c.resumeDelay
		elseif now >= s.resumeAt then
			s.frozen = false
			s.resumeAt = nil
			return true
		end
	end
	return false
end

-- When `step` next needs to run (the earliest expiry or the resume), or nil when the tree is idle.
function GazeRules.nextEvent(s: TreeState): number?
	local t: number? = s.resumeAt
	for _, expiry in s.observers do
		if t == nil or expiry < t then
			t = expiry
		end
	end
	return t
end

-- Appearance -----------------------------------------------------------------------------------------

-- Equal odds over the configured lists (archetype and palette are independent).
function GazeRules.pick<T>(list: { T }, roll: number): T
	local i = math.clamp(math.floor(roll * #list) + 1, 1, #list)
	return list[i]
end

-- Exactly round(count * share) of `count` slots get a face, chosen by a seeded shuffle so they fall
-- naturally rather than alternating.
function GazeRules.facedSlots(count: number, share: number, rng: Random): { boolean }
	local order = table.create(count, 0)
	for i = 1, count do
		order[i] = i
	end
	for i = count, 2, -1 do
		local j = rng:NextInteger(1, i)
		order[i], order[j] = order[j], order[i]
	end
	local faced = table.create(count, false)
	for k = 1, math.floor(count * share + 0.5) do
		faced[order[k]] = true
	end
	return faced
end

return GazeRules
