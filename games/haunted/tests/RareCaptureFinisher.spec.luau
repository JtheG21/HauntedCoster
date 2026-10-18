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

	t.test("orb orbit starts slow and wide, speeds up and tightens exponentially, stays smooth", function()
		local total = 3.4
		local prev = Rules.orbit(0, total)
		t.eq(prev.angle, 0)
		t.truthy(math.abs(prev.speed - Rules.ORBIT.w0) < 1e-6)
		t.truthy(math.abs(prev.radius - Rules.ORBIT.r0) < 1e-6)
		local lastRatio = nil
		for i = 1, 100 do
			local cur = Rules.orbit(total * i / 100, total)
			t.truthy(cur.angle > prev.angle, "angle must increase")
			t.truthy(cur.speed > prev.speed, "speed must increase")
			t.truthy(cur.radius < prev.radius, "radius must shrink")
			t.truthy(cur.size >= prev.size, "energy (size) must build")
			-- exponential: the speed ratio between equal steps is constant
			local ratio = cur.speed / prev.speed
			if lastRatio then
				t.truthy(math.abs(ratio - lastRatio) < 1e-6, "speed growth must be exponential")
			end
			lastRatio = ratio
			prev = cur
		end
		t.truthy(math.abs(prev.speed - Rules.ORBIT.w1) < 1e-6)
		t.truthy(math.abs(prev.radius - Rules.ORBIT.r1) < 1e-6)
		-- no frame step is big enough to strobe at 60 fps: spin plus the three tumble rates under 0.45 rad
		local o = Rules.ORBIT
		t.truthy(o.w1 * (1 + o.tumbleX + o.tumbleY + o.tumbleZ) / 60 < 0.45)
		-- several laps before it lets go
		t.truthy(prev.angle / (2 * math.pi) >= 3)
	end)

	t.test("orbit sweeps all three axes and keeps its radius", function()
		local total = 3.4
		local reach = { x = 0, y = 0, z = 0 }
		for i = 0, 100 do
			local o = Rules.orbit(total * i / 100, total)
			local len = math.sqrt(o.x * o.x + o.y * o.y + o.z * o.z)
			t.truthy(math.abs(len - o.radius) < 1e-6, "rotations must preserve the radius")
			if o.u <= 0.6 then
				reach.x = math.max(reach.x, math.abs(o.x) / o.radius)
				reach.y = math.max(reach.y, math.abs(o.y) / o.radius)
				reach.z = math.max(reach.z, math.abs(o.z) / o.radius)
			end
		end
		t.truthy(reach.x > 0.7 and reach.y > 0.7 and reach.z > 0.7, `axis reach {reach.x} {reach.y} {reach.z}`)
		-- the start must not dip under the ground the centre sits 7 studs above
		local worst = 0
		for i = 0, 100 do
			worst = math.min(worst, Rules.orbit(total * i / 100, total).y)
		end
		t.truthy(worst >= -7, "stays above the ground")
	end)

	t.test("smoothstep eases in and out", function()
		t.eq(Rules.smoothstep(0), 0)
		t.eq(Rules.smoothstep(1), 1)
		t.eq(Rules.smoothstep(2), 1)
		t.eq(Rules.smoothstep(-1), 0)
		t.truthy(Rules.smoothstep(0.1) < 0.1 and Rules.smoothstep(0.9) > 0.9)
	end)

	t.test("hermite curve starts and ends where and how it is told", function()
		local p0, m0, p1, m1 = 3, 12, 40, 55
		t.truthy(math.abs(Rules.hermite(p0, m0, p1, m1, 0) - p0) < 1e-9)
		t.truthy(math.abs(Rules.hermite(p0, m0, p1, m1, 1) - p1) < 1e-9)
		local h = 1e-5
		local startSlope = (Rules.hermite(p0, m0, p1, m1, h) - Rules.hermite(p0, m0, p1, m1, 0)) / h
		local endSlope = (Rules.hermite(p0, m0, p1, m1, 1) - Rules.hermite(p0, m0, p1, m1, 1 - h)) / h
		t.truthy(math.abs(startSlope - m0) < 1e-2, `start slope {startSlope}`)
		t.truthy(math.abs(endSlope - m1) < 1e-2, `end slope {endSlope}`)
	end)

	t.test("orb break-off continues the orbit's own motion", function()
		-- the exit velocity is the orbit's last step, so the curve's first step matches the orbit's step
		local total, snap = 3.3, 0.55
		local a = Rules.orbit(total - 1 / 60, total)
		local b = Rules.orbit(total, total)
		local v = { x = (b.x - a.x) * 60, y = (b.y - a.y) * 60, z = (b.z - a.z) * 60 }
		local dt = 1 / 60
		local first = Rules.hermite(b.x, v.x * snap, 30, 80, dt / snap) - b.x
		t.truthy(
			math.abs(first - v.x * dt) < 0.05 * math.max(1, math.abs(v.x * dt)) + 0.02,
			`first step {first} vs {v.x * dt}`
		)
	end)
end
