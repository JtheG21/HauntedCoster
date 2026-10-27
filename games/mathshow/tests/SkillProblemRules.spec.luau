--!strict
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SkillProblemRules = require(ReplicatedStorage.Shared.SkillProblemRules)

return function(t: TestRunner.T)
	t.test("every rank gives a valid problem for many seeds", function()
		for rank = 0, 9 do
			for seed = 1, 200 do
				local p = SkillProblemRules.generate(rank, seed) :: SkillProblemRules.Problem
				t.truthy(p, "rank " .. rank)
				t.eq(p.rank, rank)
				t.eq(p.answer, math.floor(p.answer), `rank {rank} seed {seed} answer is an integer`)
				t.truthy(math.abs(p.answer) <= 1e6, "answer within limit")
				t.truthy(
					#p.text > 0 and utf8.len(p.text) :: number <= SkillProblemRules.MaxText,
					`rank {rank}: {p.text}`
				)
				t.eq(p.kind, if rank >= 5 then "choice" else "integer")
				if rank <= 4 then
					t.truthy(p.answer >= 0, `typed rank {rank} answer is not negative: {p.text}`)
				end
			end
		end
	end)

	t.test("choice ranks carry four distinct choices with the answer at correctIndex", function()
		for rank = 5, 9 do
			for seed = 1, 200 do
				local p = SkillProblemRules.generate(rank, seed) :: SkillProblemRules.Problem
				local choices = p.choices :: { string }
				t.eq(#choices, 4)
				local seen: { [string]: boolean } = {}
				for _, c in choices do
					t.eq(seen[c], nil, `rank {rank} seed {seed} duplicate {c}`)
					seen[c] = true
					t.truthy(#c <= 14, "a choice never exceeds 14 characters")
				end
				t.eq(choices[p.correctIndex :: number], tostring(p.answer))
			end
		end
	end)

	t.test("typed ranks have no choices", function()
		for rank = 0, 4 do
			local p = SkillProblemRules.generate(rank, 7) :: SkillProblemRules.Problem
			t.eq(p.choices, nil)
			t.eq(p.correctIndex, nil)
		end
	end)

	t.test("generation is deterministic and varies with the seed", function()
		for rank = 0, 9 do
			local a = SkillProblemRules.generate(rank, 123) :: SkillProblemRules.Problem
			local b = SkillProblemRules.generate(rank, 123) :: SkillProblemRules.Problem
			t.eq(a.text, b.text)
			t.eq(a.answer, b.answer)
			local distinct: { [string]: boolean } = {}
			for seed = 1, 60 do
				distinct[(SkillProblemRules.generate(rank, seed) :: SkillProblemRules.Problem).text] = true
			end
			local count = 0
			for _ in distinct do
				count += 1
			end
			t.truthy(count >= 5, `rank {rank} varies ({count} distinct)`)
		end
	end)

	t.test("known answers", function()
		-- find a seed whose text we can check by hand: rank 7 is d/dx (x^3 + c x) at x = a -> 3 a^2 + c
		local p = SkillProblemRules.generate(7, 1) :: SkillProblemRules.Problem
		local c, a = p.text:match("x\u{00B3} %+ (%d+)x%) at x = (%d+)")
		t.truthy(c and a, p.text)
		t.eq(p.answer, 3 * (tonumber(a) :: number) ^ 2 + (tonumber(c) :: number))
		local q = SkillProblemRules.generate(0, 5) :: SkillProblemRules.Problem
		local x, y = q.text:match("(%d+) %+ (%d+) = %?")
		t.eq(q.answer, (tonumber(x) :: number) + (tonumber(y) :: number))
	end)

	t.test("invalid ranks give nil", function()
		t.eq(SkillProblemRules.generate(-1, 1), nil)
		t.eq(SkillProblemRules.generate(10, 1), nil)
		t.eq(SkillProblemRules.generate(2.5, 1), nil)
		t.eq(SkillProblemRules.generate(0 / 0, 1), nil)
		t.eq(SkillProblemRules.generate("3" :: any, 1), nil)
	end)
end
