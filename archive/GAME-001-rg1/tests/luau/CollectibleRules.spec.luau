--!strict
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectibleRules = require(ReplicatedStorage.Shared.CollectibleRules)

local function check(overrides: { [string]: any }): CollectibleRules.PickupCheck
	local base: { [string]: any } = {
		coinActive = true,
		isPlayerCharacter = true,
		humanoidHealth = 100,
		distance = 3,
		maxDistance = 12,
	}
	for key, value in overrides do
		base[key] = value
	end
	return base :: any
end

return function(t: TestRunner.T)
	t.test("valid touch collects", function()
		local ok, reason = CollectibleRules.canCollect(check({}))
		t.eq(ok, true)
		t.eq(reason, nil)
	end)

	t.test("inactive coin rejected", function()
		t.eq(select(2, CollectibleRules.canCollect(check({ coinActive = false }))), "inactive")
	end)

	t.test("non-character rejected", function()
		t.eq(select(2, CollectibleRules.canCollect(check({ isPlayerCharacter = false }))), "not_character")
	end)

	t.test("dead or missing humanoid rejected", function()
		t.eq(select(2, CollectibleRules.canCollect(check({ humanoidHealth = 0 }))), "dead")
		t.eq(select(2, CollectibleRules.canCollect(check({ humanoidHealth = -5 }))), "dead")
		local missing = check({})
		missing.humanoidHealth = nil
		t.eq(select(2, CollectibleRules.canCollect(missing)), "dead")
	end)

	t.test("distance limits", function()
		t.eq(CollectibleRules.canCollect(check({ distance = 12 })), true)
		t.eq(select(2, CollectibleRules.canCollect(check({ distance = 12.01 }))), "too_far")
		t.eq(select(2, CollectibleRules.canCollect(check({ distance = 0 / 0 }))), "too_far")
		local missing = check({})
		missing.distance = nil
		t.eq(select(2, CollectibleRules.canCollect(missing)), "too_far")
	end)

	t.test("award never decreases and floors", function()
		t.eq(CollectibleRules.award(5, 1), 6)
		t.eq(CollectibleRules.award(5, -3), 5)
		t.eq(CollectibleRules.award(5, 2.9), 7)
	end)

	t.test("spawn positions are distinct, on the circle, at center height", function()
		local center = Vector3.new(0, 2, 0)
		local seen = {}
		for i = 1, 10 do
			local p = CollectibleRules.spawnPosition(i, 10, center, 30)
			t.eq(p.Y, 2)
			t.truthy(math.abs((p - center).Magnitude - 30) < 1e-6, "not on radius")
			local key = `{math.round(p.X * 100)},{math.round(p.Z * 100)}`
			t.truthy(not seen[key], "duplicate position")
			seen[key] = true
		end
	end)
end
