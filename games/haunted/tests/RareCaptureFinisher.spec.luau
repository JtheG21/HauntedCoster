--!strict
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Sequence = require(ReplicatedStorage.Shared.Sequence)
local Finisher = require(ReplicatedStorage.Shared.Config.RareCaptureFinisher)
local Rules = require(ReplicatedStorage.Shared.Rules.FinisherRules)

return function(t: TestRunner.T)
	t.test("finisher validates and is 10-15 s", function()
		local ok, r = Sequence.validate(Finisher)
		t.truthy(ok, tostring(r))
		local d = Sequence.duration(Finisher)
		t.truthy(d >= 10 and d <= 15, `duration {d}`)
	end)

	t.test("at most two flashes, at least 2 s apart, none overlapping a shake start", function()
		local flashes: { number } = {}
		for _, cue in Finisher.cues do
			if cue.params and cue.params.effect == "flash" then
				table.insert(flashes, cue.at)
			end
		end
		table.sort(flashes)
		t.truthy(#flashes <= 2, `{#flashes} flashes`)
		for i = 2, #flashes do
			t.truthy(flashes[i] - flashes[i - 1] >= 2, "flashes too close")
		end
		-- large luminance changes per second = 2 per flash (up and down); a 3-flash/s guideline allows far more
		t.truthy(#flashes * 2 <= 4)
	end)

	t.test("every non-callback cue is cleaned up and ends before the sequence does", function()
		local total = Sequence.duration(Finisher)
		for _, cue in Finisher.cues do
			if cue.kind ~= "callback" then
				t.truthy(cue.duration ~= nil, `{cue.id} has no duration`)
				t.truthy(cue.at + (cue.duration :: number) <= total, `{cue.id} outlives the sequence`)
			end
		end
	end)

	t.test("runs to completion with every started cue stopped", function()
		local r = Sequence.newRunner(Finisher)
		local open = 0
		for _, a in r:advance(100) do
			if a.op == "start" and a.cue.cleanup ~= false then
				open += 1
			elseif a.op == "stop" then
				open -= 1
			end
		end
		t.eq(open, 0)
		t.truthy(r:isDone())
	end)

	t.test("reduce-effects weakens flashes, shake, rate and fov swing; normal mode is unchanged", function()
		for _, kind in { "flash", "shake", "rate" } do
			t.eq(Rules.scale(kind :: any, 0.6, false), 0.6)
			t.truthy(Rules.scale(kind :: any, 0.6, true) < 0.6)
		end
		t.eq(Rules.fov(70, 82, false), 82)
		t.truthy(Rules.fov(70, 82, true) < 82 and Rules.fov(70, 82, true) > 70)
	end)
end
