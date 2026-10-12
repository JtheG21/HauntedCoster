--!strict
-- Failed-capture retaliation rules (TASK-0031 AC1-AC2, ADR-0007 "final miss only").
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local World = require(Shared.Config.World)
local Monsters = require(Shared.Config.Monsters)
local Habitats = require(Shared.Config.Habitats)
local RetaliationRules = require(Shared.Rules.RetaliationRules)

return function(t: TestRunner.T)
	local cfg = Monsters.Retaliation

	t.test("ADR-0007 numbers: up to 2 extra within 30 studs, 8 s at 13.5 studs/s, 1.5 s knockdown", function()
		t.eq(cfg.maxExtra, 2)
		t.eq(cfg.radius, 30)
		t.eq(cfg.seconds, 8)
		t.eq(cfg.speed, 13.5)
		t.eq(cfg.knockdownSeconds, 1.5)
		t.truthy(cfg.speed < 16, "slower than a running player, so they can escape")
	end)

	t.test("pursuers: the target first, then the nearest available monsters in range, capped", function()
		local player = Vector3.new(0, 3, 40)
		local list = {
			{ id = 1, at = Vector3.new(5, 4, 40), available = false }, -- the target (claimed until now)
			{ id = 2, at = Vector3.new(0, 4, 50), available = true }, -- 10 studs
			{ id = 3, at = Vector3.new(0, 4, 20), available = true }, -- 20 studs
			{ id = 4, at = Vector3.new(0, 4, 65), available = true }, -- 25 studs
			{ id = 5, at = Vector3.new(0, 4, 75), available = true }, -- 35 studs: out of range
			{ id = 6, at = Vector3.new(2, 4, 41), available = false }, -- busy (claimed by someone else)
		}
		local picked = RetaliationRules.pickPursuers(1, player, list)
		t.eq(#picked, 1 + cfg.maxExtra)
		t.eq(picked[1], 1, "the target leads")
		t.eq(picked[2], 2)
		t.eq(picked[3], 3)
		t.eq(#RetaliationRules.pickPursuers(1, player, { list[1], list[5], list[6] }), 1, "alone when nobody is near")
	end)

	t.test("a pursuer closes in, one step at a time, and never leaves the habitat", function()
		local at = Vector3.new(0, 4, 60)
		local nextAt = RetaliationRules.pursueStep(at, Vector3.new(0, 3, 90), 3)
		t.truthy(math.abs((nextAt - at).Magnitude - 3) < 1e-3, "exactly one step")
		t.eq(nextAt.Y, at.Y, "keeps its hover height")
		-- The player stands outside the hub wall: the pursuer walks up to the edge and stops there.
		local p = Vector3.new(0, 4, 100)
		local outside = Vector3.new(0, 3, 140)
		for _ = 1, 40 do
			p = RetaliationRules.pursueStep(p, outside, 3)
			t.truthy(World.inHub(p.X, p.Z), "still inside the hub")
			t.truthy(World.hubDistance(p.X, p.Z) <= World.Hub.moduleRadius + 1e-3, "inside the habitat footprint")
		end
	end)

	t.test("a pursuer outside the crypt never steps into it", function()
		local walls = Habitats.cryptWalls() :: World.Rect
		local at = Vector3.new(walls.x2 + 3, 4, (walls.z1 + walls.z2) / 2)
		local inside = Vector3.new((walls.x1 + walls.x2) / 2, 3, (walls.z1 + walls.z2) / 2)
		for _ = 1, 10 do
			at = RetaliationRules.pursueStep(at, inside, 3)
			t.truthy(not World.inRect(walls, at.X, at.Z), "stays out of the crypt")
		end
	end)

	t.test("catch, end reasons and the knockdown cooldown", function()
		t.truthy(RetaliationRules.caught(Vector3.new(0, 5, 0), Vector3.new(cfg.catchDistance - 0.1, 3, 0)))
		t.truthy(not RetaliationRules.caught(Vector3.new(0, 5, 0), Vector3.new(cfg.catchDistance + 0.1, 3, 0)))
		t.eq(RetaliationRules.endReason(1, 10, true, 2), nil)
		t.eq(RetaliationRules.endReason(cfg.seconds, 10, true, 2), "timeout")
		t.eq(RetaliationRules.endReason(1, cfg.giveUpDistance + 1, true, 2), "escaped")
		t.eq(RetaliationRules.endReason(1, 10, false, 2), "dead")
		t.eq(RetaliationRules.endReason(1, 10, true, 0), "done")
		t.truthy(RetaliationRules.canKnock(nil, 100))
		t.truthy(not RetaliationRules.canKnock(100, 100 + cfg.cooldownSeconds - 1), "no chain knockdowns")
		t.truthy(RetaliationRules.canKnock(100, 100 + cfg.cooldownSeconds))
		local grace = cfg.knockdownSeconds + cfg.graceSeconds
		t.truthy(not RetaliationRules.canKnock(nil, 100 + grace - 0.1, 100), "no stun-lock by another pursuer")
		t.truthy(RetaliationRules.canKnock(nil, 100 + grace, 100), "fair game again after the grace")
	end)
end
