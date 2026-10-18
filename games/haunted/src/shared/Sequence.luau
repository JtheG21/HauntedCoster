--!strict
-- Sequence runner core (ADR-0012): pure validation, ordering and cleanup planning for timed cosmetic
-- sequences. No Roblox services here, so it runs headlessly in Lune. The client player maps the
-- start/stop actions this returns onto real effects; gameplay never depends on it.

local Sequence = {}

export type Cue = {
	id: string,
	at: number, -- seconds from sequence start
	kind: string, -- one of Sequence.KINDS
	duration: number?, -- seconds the cue stays active; a stop action is emitted at at + duration
	cleanup: boolean?, -- false only for fire-and-forget callbacks; every other kind is always cleaned up
	marker: string?, -- optional animation event marker name; checked against a known set when given
	params: { [string]: any }?,
}
export type Def = { id: string, length: number?, cues: { Cue } }
export type Action = { op: "start" | "stop", cue: Cue, t: number }

Sequence.KINDS = { camera = true, effect = true, sound = true, callback = true } :: { [string]: boolean }

local function finiteTime(n: any): boolean
	return type(n) == "number" and n == n and n ~= math.huge and n ~= -math.huge
end

-- Returns true, or false plus a named reason ("duplicate_id:x", "bad_kind:x", ...).
function Sequence.validate(def: Def, knownMarkers: { [string]: boolean }?): (boolean, string?)
	if type(def) ~= "table" or type(def.cues) ~= "table" or #def.cues == 0 then
		return false, "empty"
	end
	if def.length ~= nil and (not finiteTime(def.length) or def.length < 0) then
		return false, "bad_length"
	end
	local seen: { [string]: boolean } = {}
	for _, cue in def.cues do
		local id = cue.id
		if type(id) ~= "string" or id == "" then
			return false, "bad_id"
		end
		if seen[id] then
			return false, `duplicate_id:{id}`
		end
		seen[id] = true
		if not Sequence.KINDS[cue.kind] then
			return false, `bad_kind:{id}`
		end
		if not finiteTime(cue.at) then
			return false, `bad_time:{id}`
		end
		if cue.at < 0 then
			return false, `negative_time:{id}`
		end
		if cue.duration ~= nil and (not finiteTime(cue.duration) or cue.duration <= 0) then
			return false, `bad_duration:{id}`
		end
		if cue.cleanup == false and cue.kind ~= "callback" then
			return false, `cleanup_required:{id}`
		end
		if cue.marker ~= nil and knownMarkers ~= nil and not knownMarkers[cue.marker] then
			return false, `unknown_marker:{id}`
		end
	end
	return true, nil
end

-- Every start and timed stop, ordered by time; at equal times stops come first, then definition order.
function Sequence.timeline(def: Def): { Action }
	local ok, reason = Sequence.validate(def)
	if not ok then
		error(`invalid sequence {tostring(def and def.id)}: {reason}`, 2)
	end
	local rows: { { a: Action, order: number } } = {}
	for i, cue in def.cues do
		table.insert(rows, { a = { op = "start", cue = cue, t = cue.at }, order = i * 2 })
		if cue.duration then
			table.insert(rows, { a = { op = "stop", cue = cue, t = cue.at + cue.duration }, order = i * 2 - 1 })
		end
	end
	table.sort(rows, function(x, y)
		if x.a.t ~= y.a.t then
			return x.a.t < y.a.t
		end
		if x.a.op ~= y.a.op then
			return x.a.op == "stop"
		end
		return x.order < y.order
	end)
	local out: { Action } = {}
	for _, r in rows do
		table.insert(out, r.a)
	end
	return out
end

function Sequence.duration(def: Def): number
	local last = def.length or 0
	for _, a in Sequence.timeline(def) do
		last = math.max(last, a.t)
	end
	return last
end

export type Runner = {
	advance: (self: Runner, dt: number) -> { Action },
	cancel: (self: Runner) -> { Action },
	isDone: (self: Runner) -> boolean,
	elapsed: (self: Runner) -> number,
}

-- Stateful but deterministic: the same dt steps always give the same actions. Cues that need cleanup
-- and are still active when the sequence ends or is cancelled get a stop action, latest started first.
function Sequence.newRunner(def: Def): Runner
	local events = Sequence.timeline(def)
	local total = Sequence.duration(def)
	local index = 1
	local time = 0
	local done = false
	local active: { Cue } = {} -- start order

	local function remove(cue: Cue)
		local i = table.find(active, cue)
		if i then
			table.remove(active, i)
		end
	end

	local function finish(out: { Action }, t: number)
		for i = #active, 1, -1 do
			table.insert(out, { op = "stop", cue = active[i], t = t })
		end
		table.clear(active)
		done = true
	end

	local self = {} :: Runner
	function self.advance(_, dt: number): { Action }
		local out: { Action } = {}
		if done then
			return out
		end
		time += math.max(dt, 0)
		while index <= #events and events[index].t <= time do
			local a = events[index]
			index += 1
			if a.op == "start" then
				if a.cue.cleanup ~= false then
					table.insert(active, a.cue)
				end
				table.insert(out, a)
			elseif table.find(active, a.cue) then
				remove(a.cue)
				table.insert(out, a)
			end
		end
		if index > #events and time >= total then
			finish(out, time)
		end
		return out
	end
	function self.cancel(_): { Action }
		local out: { Action } = {}
		if not done then
			finish(out, time)
		end
		return out
	end
	function self.isDone(_): boolean
		return done
	end
	function self.elapsed(_): number
		return time
	end
	return self
end

return Sequence
