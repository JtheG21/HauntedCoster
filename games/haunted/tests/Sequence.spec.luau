--!strict
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Sequence = require(ReplicatedStorage.Shared.Sequence)
local Demo = require(ReplicatedStorage.Shared.Config.SequenceDemo)

return function(t: TestRunner.T)
	local function def(cues: { Sequence.Cue }): Sequence.Def
		return { id = "t", cues = cues }
	end
	local function reason(d: Sequence.Def, markers: { [string]: boolean }?): string?
		local _, r = Sequence.validate(d, markers)
		return r
	end
	local function ids(actions: { Sequence.Action }): string
		local parts = {}
		for _, a in actions do
			table.insert(parts, `{a.op}:{a.cue.id}`)
		end
		return table.concat(parts, ",")
	end

	t.test("demo sequence is valid", function()
		local ok, r = Sequence.validate(Demo)
		t.truthy(ok, tostring(r))
	end)

	t.test("rejects invalid tables with named reasons", function()
		t.eq(reason({ id = "t", cues = {} }), "empty")
		t.eq(
			reason(def({ { id = "a", at = 0, kind = "effect" }, { id = "a", at = 1, kind = "effect" } })),
			"duplicate_id:a"
		)
		t.eq(reason(def({ { id = "a", at = 0, kind = "laser" } })), "bad_kind:a")
		t.eq(reason(def({ { id = "a", at = -1, kind = "effect" } })), "negative_time:a")
		t.eq(reason(def({ { id = "a", at = 0 / 0, kind = "effect" } })), "bad_time:a")
		t.eq(reason(def({ { id = "a", at = 0, kind = "effect", duration = 0 } })), "bad_duration:a")
		t.eq(reason(def({ { id = "a", at = 0, kind = "effect", cleanup = false } })), "cleanup_required:a")
		t.eq(
			reason(def({ { id = "a", at = 0, kind = "effect", marker = "hit" } }), { charge = true }),
			"unknown_marker:a"
		)
		t.eq(reason(def({ { id = "a", at = 0, kind = "effect", marker = "charge" } }), { charge = true }), nil)
	end)

	t.test("timeline orders by time, stops before starts, then definition order", function()
		local d = def({
			{ id = "late", at = 2, kind = "effect" },
			{ id = "first", at = 0, kind = "effect", duration = 2 },
			{ id = "same", at = 2, kind = "callback", cleanup = false },
		})
		t.eq(ids(Sequence.timeline(d)), "start:first,stop:first,start:late,start:same")
	end)

	t.test("runner emits cues once as time passes", function()
		local r = Sequence.newRunner(def({
			{ id = "a", at = 1, kind = "effect", duration = 1 },
			{ id = "b", at = 3, kind = "callback", cleanup = false },
		}))
		t.eq(ids(r:advance(0.5)), "")
		t.eq(ids(r:advance(0.6)), "start:a")
		t.eq(ids(r:advance(1.0)), "stop:a")
		t.eq(ids(r:advance(1.0)), "start:b")
		t.truthy(r:isDone())
		t.eq(ids(r:advance(5)), "")
	end)

	t.test("cancel at any time stops every active cue, latest first, once", function()
		local d = def({
			{ id = "a", at = 0, kind = "camera", duration = 10 },
			{ id = "b", at = 1, kind = "effect", duration = 10 },
			{ id = "c", at = 2, kind = "sound" },
		})
		for _, step in { 0, 0.5, 1.5, 2.5, 20 } do
			local r = Sequence.newRunner(d)
			local started: { [string]: boolean } = {}
			local stopped: { [string]: boolean } = {}
			local function take(actions: { Sequence.Action })
				for _, a in actions do
					if a.op == "start" then
						started[a.cue.id] = true
					else
						t.truthy(started[a.cue.id], "stop before start")
						t.truthy(not stopped[a.cue.id], "double stop")
						stopped[a.cue.id] = true
					end
				end
			end
			take(r:advance(step))
			take(r:cancel())
			take(r:cancel())
			for id in started do
				t.truthy(stopped[id], `{id} left running after cancel at {step}`)
			end
			t.truthy(r:isDone())
		end
		local r = Sequence.newRunner(d)
		r:advance(2.5)
		t.eq(ids(r:cancel()), "stop:c,stop:b,stop:a")
	end)

	t.test("natural finish also cleans up and is deterministic", function()
		local function run(dts: { number }): string
			local r = Sequence.newRunner(Demo)
			local all = {}
			for _, dt in dts do
				table.insert(all, ids(r:advance(dt)))
			end
			t.truthy(r:isDone())
			return table.concat(all, "|")
		end
		local a = run({ 0.5, 0.5, 1, 1, 1, 1, 1, 1 })
		t.eq(a, run({ 0.5, 0.5, 1, 1, 1, 1, 1, 1 }))
		local coarse = Sequence.newRunner(Demo)
		local started, stopped = 0, 0
		for _, act in coarse:advance(100) do
			if act.op == "start" then
				started += 1
			else
				stopped += 1
			end
		end
		t.eq(started, 5)
		t.eq(stopped, 4) -- the callback is fire-and-forget
	end)

	t.test("invalid sequence cannot start a runner", function()
		local ok = pcall(function()
			Sequence.newRunner({ id = "bad", cues = {} })
		end)
		t.eq(ok, false)
	end)
end
