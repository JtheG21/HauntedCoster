--!strict
-- Habitat rotation schedule (TASK-0029 AC1, ADR-0007): deterministic from the clock, with correct
-- boundaries, wrap-around and test overrides that never leak into the live config.
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Rotation = require(Shared.Config.Rotation)
local Habitats = require(Shared.Config.Habitats)
local RotationRules = require(Shared.Rules.RotationRules)

return function(t: TestRunner.T)
	t.test("live schedule: four habitats, 15 minutes each, warning at 60 s, closing at 15 s", function()
		t.eq(#Rotation.order, 4)
		t.eq(Rotation.slotSeconds, 900)
		t.eq(Rotation.warningSeconds, 60)
		t.eq(Rotation.closingSeconds, 15)
		for i, h in Habitats.List do
			t.eq(Rotation.order[i], h.id, `rotation order follows Habitats.List at {i}`)
		end
	end)

	t.test("same clock, same habitat: the schedule is a pure function of time", function()
		local now = 1_791_830_000.25
		local a, b = RotationRules.at(now), RotationRules.at(now)
		t.eq(a.id, b.id)
		t.eq(a.swapAt, b.swapAt)
		-- A second server started at a different moment agrees at the same instant.
		t.eq(RotationRules.at(now).id, RotationRules.at(now + 0).id)
	end)

	t.test("boundaries: open, warning at T-60, closing at T-15, swap at T-0", function()
		local slotStart = 900 * 1000 -- a slot boundary (slot 1000 -> index 1)
		local s = RotationRules.at(slotStart)
		t.eq(s.id, "Cemetery")
		t.eq(s.phase, "open")
		t.eq(s.swapAt, slotStart + 900)
		t.eq(RotationRules.at(slotStart + 839.9).phase, "open")
		t.eq(RotationRules.at(slotStart + 840).phase, "warning")
		t.eq(RotationRules.at(slotStart + 884.9).phase, "warning")
		t.eq(RotationRules.at(slotStart + 885).phase, "closing")
		t.eq(RotationRules.at(slotStart + 899.99).id, "Cemetery")
		local next = RotationRules.at(slotStart + 900)
		t.eq(next.id, "Woodland", "the swap happens exactly at the slot boundary")
		t.eq(next.phase, "open")
		t.truthy(RotationRules.capturesOpen(slotStart + 884))
		t.truthy(not RotationRules.capturesOpen(slotStart + 886), "captures close in the last 15 s")
	end)

	t.test("wrap-around: Settlement hands back to the Cemetery; clocks before the epoch work", function()
		local s = RotationRules.at(900 * 3 + 1)
		t.eq(s.id, "Settlement")
		t.eq(s.nextId, "Cemetery")
		t.eq(RotationRules.at(900 * 4 + 1).id, "Cemetery")
		t.eq(RotationRules.at(-1).id, "Settlement", "one second before the epoch is the end of the last slot")
		t.eq(RotationRules.at(3600 * 1000 + 5).id, "Cemetery", "every hour starts with the Cemetery")
	end)

	t.test("test overrides apply to a copy and never change the live config", function()
		local fast = RotationRules.withOverrides(
			Rotation,
			{ slotSeconds = 30, warningSeconds = 10, closingSeconds = 5, epoch = 100 }
		)
		t.eq(fast.slotSeconds, 30)
		t.eq(RotationRules.at(100, fast).id, "Cemetery")
		t.eq(RotationRules.at(130, fast).id, "Woodland")
		t.eq(RotationRules.at(125, fast).phase, "closing")
		t.eq(Rotation.slotSeconds, 900, "the live config is untouched")
		local bad = RotationRules.withOverrides(Rotation, { slotSeconds = 30, warningSeconds = 40 })
		t.eq(bad.slotSeconds, 900, "a nonsensical override falls back to the live values")
		t.eq(RotationRules.withOverrides(Rotation, "nope").slotSeconds, 900)
	end)

	t.test("countdown text", function()
		t.eq(RotationRules.clock(61), "1:01")
		t.eq(RotationRules.clock(0.2), "0:01")
		t.eq(RotationRules.clock(-3), "0:00")
	end)
end
