--!strict
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CaptureFxRules = require(ReplicatedStorage.Shared.Rules.CaptureFxRules)
local CosmeticRules = require(ReplicatedStorage.Shared.Rules.CosmeticRules)

local cat: CosmeticRules.Catalog = {
	Items = { Sparks = { category = "CaptureEffect" }, Moss = { category = "Skin" } },
	Rewards = {},
}

return function(t: TestRunner.T)
	t.test("parse accepts an id or nil and rejects the rest", function()
		t.truthy(CaptureFxRules.parse("Sparks") ~= nil)
		local r = CaptureFxRules.parse(nil)
		t.truthy(r ~= nil and r.id == nil)
		t.eq(CaptureFxRules.parse(5), nil)
		t.eq(CaptureFxRules.parse("bad id"), nil)
		t.eq(CaptureFxRules.parse({}), nil)
		t.eq(CaptureFxRules.parse(string.rep("a", 65)), nil)
	end)

	t.test("resolve plays only an owned, listed capture effect", function()
		local s = CosmeticRules.default()
		t.eq(CaptureFxRules.resolve(s, cat), nil)
		s.entitlements.Sparks = true
		s.captureEffect = "Sparks"
		t.eq(CaptureFxRules.resolve(s, cat), "Sparks")
		s.entitlements.Sparks = false
		t.eq(CaptureFxRules.resolve(s, cat), nil) -- no longer owned
		s.entitlements.Sparks = true
		s.captureEffect = "Gone"
		t.eq(CaptureFxRules.resolve(s, cat), nil) -- unlisted
		s.entitlements.Moss = true
		s.captureEffect = "Moss"
		t.eq(CaptureFxRules.resolve(s, cat), nil) -- wrong category
		t.eq(CaptureFxRules.resolve(nil, cat), nil)
	end)

	t.test("equipping an effect changes nothing but the captureEffect field", function()
		local s = CosmeticRules.default()
		s.entitlements.Sparks = true
		s.ghostLooks.u1 = { skin = "Moss" }
		s.rewardsClaimed.R1 = true
		local before = { ghostLooks = s.ghostLooks, rewards = s.rewardsClaimed, theme = s.mansionTheme }
		local ok = CosmeticRules.setCaptureEffect(s, cat, "Sparks")
		t.truthy(ok)
		t.eq(s.captureEffect, "Sparks")
		t.eq(s.ghostLooks, before.ghostLooks)
		t.eq(s.rewardsClaimed, before.rewards)
		t.eq(s.mansionTheme, before.theme)
		CosmeticRules.setCaptureEffect(s, cat, nil)
		t.eq(s.captureEffect, nil)
		t.eq(s.entitlements.Sparks, true) -- removing keeps ownership
	end)

	t.test("setCaptureEffect refuses unowned, unknown and wrong-category ids", function()
		local s = CosmeticRules.default()
		local ok, why = CosmeticRules.setCaptureEffect(s, cat, "Sparks")
		t.eq(ok, false)
		t.eq(why, "notOwned")
		s.entitlements.Moss = true
		local ok2, why2 = CosmeticRules.setCaptureEffect(s, cat, "Moss")
		t.eq(ok2, false)
		t.eq(why2, "wrongCategory")
		local ok3, why3 = CosmeticRules.setCaptureEffect(s, cat, "Nope")
		t.eq(ok3, false)
		t.eq(why3, "unknown")
		t.eq(s.captureEffect, nil)
	end)

	t.test("messages are friendly and generic for the unexpected", function()
		t.truthy(string.find(CaptureFxRules.message("notOwned"), "own") ~= nil)
		t.eq(CaptureFxRules.message("zzz"), "Something went wrong. Try again.")
	end)

	t.test("parsePayload checks type, known id, position and distance", function()
		local known = { Sparks = {} }
		local from = Vector3.new(0, 0, 0)
		local ok = CaptureFxRules.parsePayload({ id = "Sparks", position = Vector3.new(5, 0, 5) }, known, from, 120)
		t.truthy(ok ~= nil and ok.id == "Sparks")
		t.eq(CaptureFxRules.parsePayload(nil, known, from, 120), nil)
		t.eq(CaptureFxRules.parsePayload({ id = "Other", position = Vector3.zero }, known, from, 120), nil)
		t.eq(CaptureFxRules.parsePayload({ id = "Sparks", position = "x" }, known, from, 120), nil)
		t.eq(CaptureFxRules.parsePayload({ id = "Sparks", position = Vector3.new(500, 0, 0) }, known, from, 120), nil)
		t.eq(CaptureFxRules.parsePayload({ id = 5, position = Vector3.zero }, known, from, 120), nil)
	end)
end
