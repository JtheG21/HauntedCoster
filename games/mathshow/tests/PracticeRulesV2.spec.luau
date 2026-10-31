--!strict
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Rules = require(ReplicatedStorage.Shared.PracticeRulesV2)

local function ans(skill: string, correct: boolean, seconds: number): Rules.Answer
	return { skill = skill, correct = correct, seconds = seconds }
end

return function(t: TestRunner.T)
	t.test("summarize counts correct answers, times and misses per skill", function()
		local s = Rules.summarize({
			ans("add", true, 3),
			ans("frac", false, 8),
			ans("frac", false, 9),
			ans("mult", false, 4),
			ans("add", true, 2),
			ans("mult", true, 5),
		})
		t.eq(s.total, 6)
		t.eq(s.correct, 3)
		t.eq(s.seconds[2], 8)
		t.eq(s.missesBySkill.frac, 2)
		t.eq(s.missesBySkill.mult, 1)
		t.eq(s.missesBySkill.add, nil)
	end)

	t.test("answers beyond the practice length are ignored", function()
		local many: { Rules.Answer } = {}
		for i = 1, 9 do
			many[i] = ans("add", true, 1)
		end
		t.eq(Rules.summarize(many).total, 6)
	end)

	t.test("bad times and skill tags are cleaned", function()
		local s = Rules.summarize({ ans("add", false, 0 / 0), ans("", false, -3), ans("x", true, math.huge) })
		t.eq(s.seconds[1], 0)
		t.eq(s.seconds[2], 0)
		t.eq(s.seconds[3], 0)
		t.eq(s.missesBySkill.add, 1)
		t.eq(s.missesBySkill.unknown, 1)
	end)

	t.test("weaknesses order by miss count then skill tag", function()
		local s = Rules.summarize({
			ans("zeta", false, 1),
			ans("alpha", false, 1),
			ans("beta", false, 1),
			ans("beta", false, 1),
		})
		local w = Rules.weaknesses(s)
		t.eq(w[1].skill, "beta")
		t.eq(w[1].misses, 2)
		t.eq(w[2].skill, "alpha")
		t.eq(w[3].skill, "zeta")
	end)

	t.test("suggestNext returns skill tags only, capped, and nothing for a perfect run", function()
		local s = Rules.summarize({
			ans("a", false, 1),
			ans("b", false, 1),
			ans("c", false, 1),
			ans("d", false, 1),
		})
		local next = Rules.suggestNext(s)
		t.eq(#next, 3)
		t.eq(next[1], "a")
		t.eq(type(next[1]), "string")
		t.eq(#Rules.suggestNext(Rules.summarize({ ans("a", true, 1) })), 0)
		t.eq(#Rules.suggestNext(Rules.summarize({})), 0)
	end)

	t.test("practice results carry no rating, rank or tier field", function()
		local s = Rules.summarize({ ans("a", false, 1) })
		local forbidden = { "rating", "rank", "tier", "elo", "mmr", "progress" }
		local function scan(tbl: { [any]: any })
			for key in tbl do
				if type(key) == "string" then
					for _, bad in forbidden do
						t.eq(key:lower():find(bad, 1, true), nil, `{key} looks like a competitive field`)
					end
				end
			end
		end
		scan(s)
		scan(Rules.weaknesses(s)[1])
	end)
end
