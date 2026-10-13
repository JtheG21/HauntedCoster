--!strict
-- Haunted-tree gaze rules (TASK-0041 AC2-AC4, AC6-AC7): the eye-contact test, the global per-tree
-- freeze with its one-second recovery, and the appearance picks.
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local HauntedTrees = require(Shared.Config.HauntedTrees)
local GazeRules = require(Shared.Rules.GazeRules)

local G = HauntedTrees.gaze

-- A face 4 studs up, looking down +Z, about 2.4 studs across.
local FACE: GazeRules.Face = { pos = Vector3.new(0, 4, 0), forward = Vector3.new(0, 0, 1), radius = 1.2 }

-- A player standing `dist` studs in front of the face, camera 0.5 behind the head, aimed `offDeg` to the side.
local function view(dist: number, offDeg: number, side: number?): GazeRules.View
	local head = Vector3.new(side or 0, 4.5, dist)
	local cam = head + Vector3.new(0, 0.5, 0.5)
	local toFace = (FACE.pos - cam).Unit
	local look = (CFrame.fromAxisAngle(Vector3.yAxis, math.rad(offDeg)) * CFrame.new()):VectorToWorldSpace(toFace)
	return { camPos = cam, camLook = look, headPos = head }
end

return function(t: TestRunner.T)
	t.test("config: initial thresholds inside the brief's bands, all three palettes and archetypes", function()
		t.truthy(G.range >= 9 and G.range <= 14, "range 9-14 studs")
		t.truthy(G.angle >= 10 and G.angle <= 15, "aim 10-15 degrees")
		t.eq(G.resumeDelay, 1)
		t.truthy(G.ttl > G.keepalive * 2, "a report survives one lost keepalive")
		t.eq(#HauntedTrees.archetypes, 3)
		local ids = {}
		for _, p in HauntedTrees.palettes do
			ids[p.id] = true
		end
		t.truthy(ids.Dark and ids.Amber and ids.Violet, "dark, orange-yellow and purple palettes")
		t.truthy(not HauntedTrees.palettes[1].neon, "dark eyes never glow")
	end)

	t.test("eye contact: inside range and aim counts; past range or clearly off-aim does not", function()
		t.truthy(GazeRules.qualifies(view(8, 0), FACE), "straight at it from 8 studs")
		t.truthy(GazeRules.qualifies(view(G.range - 0.5, 0), FACE), "just inside range")
		t.truthy(not GazeRules.qualifies(view(G.range + 1, 0), FACE), "just past range")
		t.truthy(
			GazeRules.qualifies(view(10, G.angle), FACE),
			"aim at the configured angle still hits (face size helps)"
		)
		t.truthy(not GazeRules.qualifies(view(10, 40), FACE), "a glance 40 degrees away misses")
		t.truthy(not GazeRules.qualifies(view(10, 180), FACE), "looking away misses")
	end)

	t.test("eye contact: the face size widens the cone more up close", function()
		local near = GazeRules.aimError(view(4, 20), FACE)
		local far = GazeRules.aimError(view(11, 20), FACE)
		t.truthy(near < far, "the same 20-degree offset is closer to the face edge at 4 studs")
	end)

	t.test("eye contact: from behind or edge-on the face is not visible", function()
		local behind: GazeRules.View =
			{ camPos = Vector3.new(0, 5, -8), camLook = Vector3.new(0, 0, 1), headPos = Vector3.new(0, 4.5, -7.5) }
		t.truthy(not GazeRules.qualifies(behind, FACE), "standing behind the trunk")
		t.truthy(not GazeRules.qualifies(view(0.5, 0, 10), FACE), "far off to the side, almost edge-on")
		t.truthy(GazeRules.qualifies(view(7, 0, 4), FACE), "a modest side angle still works")
	end)

	t.test("eye contact: hysteresis keeps a current gaze a little past the entry threshold", function()
		local edge = view(G.range + 1, 0)
		t.truthy(not GazeRules.qualifies(edge, FACE, false), "not enough to start")
		t.truthy(GazeRules.qualifies(edge, FACE, true), "enough to continue")
		t.truthy(not GazeRules.qualifies(view(G.range + G.exitSlack + 1, 0), FACE, true), "slack is bounded")
	end)

	t.test("server plausibility: allows latency slack, rejects far and behind reporters", function()
		t.truthy(GazeRules.plausible(Vector3.new(0, 4.5, G.range + 2), FACE))
		t.truthy(not GazeRules.plausible(Vector3.new(0, 4.5, 40), FACE), "40 studs away")
		t.truthy(not GazeRules.plausible(Vector3.new(0, 4.5, -6), FACE), "behind the tree")
	end)

	t.test("freeze: one observer freezes; the resume waits a full second after they look away", function()
		local s = GazeRules.newTree()
		t.truthy(GazeRules.observe(s, "A", 0), "first observer changes the state")
		t.truthy(s.frozen)
		GazeRules.release(s, "A", 2)
		t.truthy(s.frozen, "still frozen right after looking away")
		t.truthy(not GazeRules.step(s, 2.99), "not yet at 0.99 s")
		t.truthy(s.frozen)
		t.truthy(GazeRules.step(s, 3.0), "resumes at exactly 1 s")
		t.truthy(not s.frozen)
		t.eq(GazeRules.nextEvent(s), nil, "idle tree needs no further steps")
	end)

	t.test("freeze: stays frozen while any observer remains (A leaves, B keeps looking)", function()
		local s = GazeRules.newTree()
		GazeRules.observe(s, "A", 0)
		t.truthy(not GazeRules.observe(s, "B", 0.2), "second observer doesn't re-trigger")
		GazeRules.release(s, "A", 1)
		t.eq(s.resumeAt, nil, "no resume pending while B looks")
		GazeRules.observe(s, "B", 1.2) -- keepalive
		GazeRules.step(s, 2.3)
		t.truthy(s.frozen)
		GazeRules.release(s, "B", 2.4)
		t.eq(s.resumeAt, 3.4, "the delay starts when the last observer leaves")
		GazeRules.step(s, 3.4)
		t.truthy(not s.frozen)
	end)

	t.test("freeze: a new look during the delay cancels it; no partial timer carries over", function()
		local s = GazeRules.newTree()
		GazeRules.observe(s, "A", 0)
		GazeRules.release(s, "A", 1)
		GazeRules.step(s, 1.9)
		GazeRules.observe(s, "B", 1.9)
		t.eq(s.resumeAt, nil, "pending resume cancelled")
		GazeRules.release(s, "B", 2.0)
		t.truthy(not GazeRules.step(s, 2.5), "0.5 s after the new release is not enough")
		t.truthy(not GazeRules.step(s, 2.99), "the earlier 0.9 s did not carry over")
		t.truthy(GazeRules.step(s, 3.0))
	end)

	t.test("freeze: a report that stops renewing expires, then the full delay applies", function()
		local s = GazeRules.newTree()
		GazeRules.observe(s, "A", 0) -- e.g. a client that disconnected without a release
		t.eq(GazeRules.nextEvent(s), G.ttl)
		GazeRules.step(s, G.ttl)
		t.eq(GazeRules.observerCount(s), 0, "stale report dropped")
		t.truthy(s.frozen, "still frozen for the delay")
		t.truthy(not GazeRules.step(s, G.ttl + G.resumeDelay - 0.01))
		t.truthy(GazeRules.step(s, G.ttl + G.resumeDelay))
	end)

	t.test("freeze: keepalives hold the freeze indefinitely only while they keep coming", function()
		local s = GazeRules.newTree()
		local now = 0
		for _ = 1, 50 do
			GazeRules.observe(s, "A", now)
			GazeRules.step(s, now)
			now += G.keepalive
		end
		t.truthy(s.frozen)
		t.eq(GazeRules.observerCount(s), 1)
		GazeRules.step(s, now + G.ttl)
		GazeRules.step(s, now + G.ttl + G.resumeDelay)
		t.truthy(not s.frozen, "stops when the keepalives stop")
	end)

	t.test("freeze: releasing an unknown or departed observer is harmless", function()
		local s = GazeRules.newTree()
		GazeRules.release(s, "ghost", 0)
		t.truthy(not s.frozen)
		t.eq(s.resumeAt, nil)
		GazeRules.observe(s, "A", 0)
		GazeRules.release(s, "A", 0.5)
		GazeRules.release(s, "A", 0.8) -- a duplicate release must not restart the delay
		t.eq(s.resumeAt, 1.5)
	end)

	t.test("rapid toggling: the state never holds more than one entry per observer", function()
		local s = GazeRules.newTree()
		local now = 0
		for i = 1, 200 do
			if i % 2 == 1 then
				GazeRules.observe(s, "A", now)
				GazeRules.observe(s, "B", now)
			else
				GazeRules.release(s, "A", now)
			end
			GazeRules.step(s, now)
			now += 0.03
			t.truthy(GazeRules.observerCount(s) <= 2)
		end
		t.truthy(s.frozen, "B never released, so still frozen")
	end)

	t.test("appearance: picks cover every entry with roughly equal odds", function()
		local rng = Random.new(41)
		local counts: { [string]: number } = {}
		local n = 3000
		for _ = 1, n do
			local p = GazeRules.pick(HauntedTrees.palettes, rng:NextNumber())
			counts[p.id] = (counts[p.id] or 0) + 1
		end
		for _, p in HauntedTrees.palettes do
			local share = (counts[p.id] or 0) / n
			t.truthy(share > 0.28 and share < 0.39, `{p.id} share {share} near 1/3`)
		end
		t.eq(GazeRules.pick(HauntedTrees.archetypes, 0), "Pillar")
		t.eq(GazeRules.pick(HauntedTrees.archetypes, 0.9999), "Angular", "roll just under 1 stays in range")
	end)

	t.test("appearance: exactly half the slots get a face, not as a rigid alternation", function()
		local faced = GazeRules.facedSlots(16, 0.5, Random.new(7))
		local n, alternating = 0, true
		for i = 1, 16 do
			if faced[i] then
				n += 1
			end
			if i > 1 and faced[i] == faced[i - 1] then
				alternating = false
			end
		end
		t.eq(n, 8)
		t.truthy(not alternating, "neighbouring slots sometimes match")
		local odd = GazeRules.facedSlots(5, 0.5, Random.new(3))
		local m = 0
		for i = 1, 5 do
			if odd[i] then
				m += 1
			end
		end
		t.truthy(m == 2 or m == 3, "an odd count rounds to about half")
	end)
end
