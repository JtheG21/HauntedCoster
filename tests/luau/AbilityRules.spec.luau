--!strict
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AbilityRules = require(ReplicatedStorage.Shared.AbilityRules)

local KNOWN = { Dash = true }

return function(t: TestRunner.T)
	t.test("valid request accepted", function()
		t.eq(AbilityRules.validateRequest("Dash", 0, KNOWN), true)
	end)

	t.test("bad types, lengths, unknown ids and extra args rejected", function()
		t.eq(select(2, AbilityRules.validateRequest(nil, 0, KNOWN)), "bad_type")
		t.eq(select(2, AbilityRules.validateRequest(5, 0, KNOWN)), "bad_type")
		t.eq(select(2, AbilityRules.validateRequest({}, 0, KNOWN)), "bad_type")
		t.eq(select(2, AbilityRules.validateRequest("", 0, KNOWN)), "bad_length")
		t.eq(select(2, AbilityRules.validateRequest(string.rep("a", 33), 0, KNOWN)), "bad_length")
		t.eq(select(2, AbilityRules.validateRequest("Fly", 0, KNOWN)), "unknown_ability")
		t.eq(select(2, AbilityRules.validateRequest("Dash", 1, KNOWN)), "unexpected_args")
	end)

	t.test("rate limit allows max then rejects within window", function()
		local stamps = {}
		local ok
		for i = 1, 5 do
			ok, stamps = AbilityRules.checkRate(stamps, i * 0.1, 1, 5)
			t.eq(ok, true, `request {i}`)
		end
		ok, stamps = AbilityRules.checkRate(stamps, 0.6, 1, 5)
		t.eq(ok, false, "6th in window")
		t.truthy(#stamps <= 6, "timestamps bounded")
	end)

	t.test("rate limit recovers after window", function()
		local stamps = { 0, 0.1, 0.2, 0.3, 0.4, 0.5 }
		local ok = AbilityRules.checkRate(stamps, 1.45, 1, 5)
		t.eq(ok, true)
	end)

	t.test("spam stays bounded", function()
		local stamps = {}
		for i = 1, 1000 do
			local _allowed
			_allowed, stamps = AbilityRules.checkRate(stamps, i * 0.0001, 1, 5)
		end
		t.eq(#stamps, 6)
	end)

	t.test("cooldown boundary", function()
		t.eq(AbilityRules.canActivate({ now = 10, lastUsed = nil, cooldown = 1 }), true)
		t.eq(select(2, AbilityRules.canActivate({ now = 10.5, lastUsed = 10, cooldown = 1 })), "cooldown")
		t.eq(AbilityRules.canActivate({ now = 11, lastUsed = 10, cooldown = 1 }), true)
		t.eq(select(2, AbilityRules.canActivate({ now = 0 / 0, lastUsed = 10, cooldown = 1 })), "bad_clock")
	end)

	t.test("horizontal direction", function()
		local d = AbilityRules.horizontalDirection(Vector3.new(0, 1, 0))
		t.eq(d, Vector3.new(0, 0, -1))
		local e = AbilityRules.horizontalDirection(Vector3.new(3, 5, 4))
		t.truthy(math.abs(e.Magnitude - 1) < 1e-6 and e.Y == 0, "unit and flat")
	end)
end
