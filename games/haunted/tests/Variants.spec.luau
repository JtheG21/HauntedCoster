--!strict
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Variants = require(ReplicatedStorage.Shared.Config.Variants)

return function(t: TestRunner.T)
	local function tally(zone: string, n: number): { [string]: number }
		local rng = Random.new(99)
		local counts: { [string]: number } = {}
		for _ = 1, n do
			local v = Variants.roll(zone, rng)
			counts[v] = (counts[v] or 0) + 1
		end
		return counts
	end

	t.test("Ashen never rolls outside the crypt", function()
		for _, zone in { "Gate", "OldRows", "Hollow" } do
			t.eq(tally(zone, 5000).Ashen, nil, zone)
		end
	end)

	t.test("Spectral rolls at roughly its configured chance anywhere", function()
		local c = tally("OldRows", 10000)
		local rate = (c.Spectral or 0) / 10000
		t.truthy(math.abs(rate - Variants.ById.Spectral.chance) < 0.02, `rate {rate}`)
	end)

	t.test("the crypt rolls Ashen, and most spawns stay Normal elsewhere", function()
		local crypt = tally("Crypt", 10000)
		local ashenRate = (crypt.Ashen or 0) / 10000
		t.truthy(math.abs(ashenRate - Variants.ById.Ashen.chance) < 0.02, `ashen rate {ashenRate}`)
		local gate = tally("Gate", 10000)
		t.truthy((gate.Normal or 0) > 8500, "normal at gate")
	end)

	t.test("variants carry a moderate income bonus", function()
		for _, v in Variants.List do
			t.truthy(v.incomeMultiplier > 1.2 and v.incomeMultiplier < 2, v.id)
		end
		t.eq(Variants.multiplier("Normal"), 1)
		t.eq(Variants.multiplier("Bogus"), 1)
	end)
end
