--!strict
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LevelRewards = require(ReplicatedStorage.Shared.LevelRewards)
local XpConfig = require(ReplicatedStorage.Shared.XpConfig)
local XpRules = require(ReplicatedStorage.Shared.XpRules)

local DAY = XpConfig.SecondsPerDay

return function(t: TestRunner.T)
	t.test("level curve edges", function()
		t.eq(XpRules.levelForXp(0), 1, "zero")
		t.eq(XpRules.levelForXp(-5), 1, "negative")
		t.eq(XpRules.levelForXp(99), 1, "one short of level 2")
		t.eq(XpRules.levelForXp(100), 2, "exact threshold 2")
		t.eq(XpRules.levelForXp(235), 3, "exact threshold 3 (100 + 135)")
		t.eq(XpRules.xpIntoLevel(150), 50, "into level 2")
		t.eq(XpRules.xpForNextLevel(0), 100, "level 1 cost")
		t.eq(XpRules.xpForNextLevel(100), 135, "level 2 cost")
	end)

	t.test("level 50 is reached at exactly 46060 XP", function()
		t.eq(XpRules.totalXpForLevel(1), 0)
		t.eq(XpRules.totalXpForLevel(50), 46060)
		t.eq(XpRules.levelForXp(46059), 49, "46059")
		t.eq(XpRules.levelForXp(46060), 50, "46060")
		t.eq(XpRules.xpForNextLevel(46059), XpRules.costOf(49), "last level still costs")
	end)

	t.test("beyond the cap stays at 50 with an empty bar", function()
		t.eq(XpRules.levelForXp(10 ^ 9), 50)
		t.eq(XpRules.xpForNextLevel(46060), 0)
		t.eq(XpRules.xpForNextLevel(10 ^ 9), 0)
		t.eq(XpRules.xpIntoLevel(10 ^ 9), 0)
		t.eq(XpRules.levelForXp(0 / 0), 1, "NaN")
	end)

	t.test("totalXpForLevel agrees with levelForXp at every threshold", function()
		for level = 1, XpConfig.LevelCap do
			local total = XpRules.totalXpForLevel(level)
			t.eq(XpRules.levelForXp(total), level, `level {level}`)
			if level > 1 then
				t.eq(XpRules.levelForXp(total - 1), level - 1, `just below {level}`)
			end
		end
	end)

	t.test("playAward respects the daily cap", function()
		t.eq(XpRules.playAward(0, 20), 20, "empty day")
		t.eq(XpRules.playAward(399, 20), 1, "one left")
		t.eq(XpRules.playAward(400, 20), 0, "full")
		t.eq(XpRules.playAward(500, 20), 0, "over full")
		t.eq(XpRules.playAward(-1, 20), 0, "negative stored")
		t.eq(XpRules.playAward(0, -5), 0, "negative nominal")
		t.eq(XpRules.playAward(0.5, 20), 0, "fractional stored")
		t.eq(XpRules.playAward(0, 2.5), 0, "fractional nominal")
		t.eq(XpRules.playAward(0 / 0, 20), 0, "NaN stored")
		t.eq(XpRules.playAward(0, math.huge), 0, "infinite nominal")
	end)

	t.test("390 + 10 + 10 applied in sequence ends at 400", function()
		local stored = 390
		for _ = 1, 2 do
			stored += XpRules.playAward(stored, 10)
		end
		t.eq(stored, 400)
	end)

	t.test("top3 sorts score descending then userId ascending", function()
		local ids = XpRules.top3({
			{ userId = 9, score = 50, eligible = true },
			{ userId = 3, score = 50, eligible = true },
			{ userId = 5, score = 80, eligible = true },
			{ userId = 1, score = 50, eligible = true },
		})
		t.eq(#ids, 3)
		t.eq(ids[1], 5, "highest score")
		t.eq(ids[2], 1, "tie: lower userId first")
		t.eq(ids[3], 3, "tie: next lowest userId")
	end)

	t.test("top3 skips zero scores and ineligible players", function()
		local ids = XpRules.top3({
			{ userId = 1, score = 0, eligible = true },
			{ userId = 2, score = -3, eligible = true },
			{ userId = 3, score = 90, eligible = false },
			{ userId = 4, score = 10, eligible = true },
		})
		t.eq(#ids, 1)
		t.eq(ids[1], 4)
		t.eq(#XpRules.top3({}), 0, "empty")
	end)

	t.test("dayOf floors to the UTC day", function()
		t.eq(XpRules.dayOf(0), 0)
		t.eq(XpRules.dayOf(DAY - 1), 0)
		t.eq(XpRules.dayOf(DAY), 1)
		t.eq(XpRules.dayOf(-1), nil, "negative")
		t.eq(XpRules.dayOf(0 / 0), nil, "NaN")
	end)

	t.test("classifyDay around midnight with the 300 s skew bound", function()
		local day = 20000
		local midnight = (day + 1) * DAY
		t.eq(XpRules.classifyDay(day, midnight - 301), "current", "well before midnight")
		t.eq(XpRules.classifyDay(day + 1, midnight - 301), "invalid", "ahead beyond the bound")
		t.eq(XpRules.classifyDay(day + 1, midnight - 300), "adjacentAhead", "exactly 300 s before midnight")
		t.eq(XpRules.classifyDay(day + 1, midnight - 1), "adjacentAhead", "1 s before midnight")
		t.eq(XpRules.classifyDay(day + 1, midnight), "current", "at midnight")
		t.eq(XpRules.classifyDay(day, midnight), "behind", "stored yesterday")
		t.eq(XpRules.classifyDay(day, midnight + 300), "behind", "midnight + 300 s")
		t.eq(XpRules.classifyDay(day + 2, midnight - 1), "invalid", "two days ahead")
	end)

	t.test("classifyDay rejects corrupt input", function()
		t.eq(XpRules.classifyDay(-1, 1000), "invalid", "negative epoch")
		t.eq(XpRules.classifyDay(1.5, 1000), "invalid", "fractional epoch")
		t.eq(XpRules.classifyDay(0 / 0, 1000), "invalid", "NaN epoch")
		t.eq(XpRules.classifyDay(1, -5), "invalid", "negative wall clock")
	end)

	t.test("level rewards follow the table", function()
		t.eq(LevelRewards.rewardsFor(4), nil, "nothing before level 5")
		local at5 = LevelRewards.rewardsFor(5)
		t.truthy(at5 and at5.title and at5.title.name == "Number Rookie", "level 5 title")
		t.eq(at5 and at5.plate, nil, "no plate at 5")
		local at19 = LevelRewards.rewardsFor(19)
		t.eq(at19 and at19.title and at19.title.name, "Sum Seeker", "level 19 keeps level 15 title")
		t.eq(at19 and at19.plate and at19.plate.name, "Silver Mist", "level 19 keeps level 10 plate")
		local at50 = LevelRewards.rewardsFor(50)
		t.eq(at50 and at50.title and at50.title.name, "MathShow Legend")
		t.eq(at50 and at50.plate and at50.plate.name, "Pearl White")
		t.eq(#LevelRewards.Titles, 10, "ten titles")
		t.eq(#LevelRewards.Plates, 5, "five plates")
		t.eq(LevelRewards.Plates[2].g, 224, "Holo Cyan green")
		t.eq(LevelRewards.rewardsFor(0 / 0), nil, "NaN")
	end)

	t.test("configs are frozen", function()
		t.truthy(table.isfrozen(XpConfig), "XpConfig")
		t.truthy(table.isfrozen(XpConfig.PlayAward), "PlayAward")
		t.truthy(table.isfrozen(LevelRewards), "LevelRewards")
		t.truthy(table.isfrozen(LevelRewards.Titles[1]), "title entry")
	end)

	t.test("AUD-01 F3: xpIntoLevel and xpForNextLevel normalise invalid xp", function()
		for _, bad in { -5, -math.huge, math.huge, 0 / 0 } do
			t.eq(XpRules.xpIntoLevel(bad), 0, "xpIntoLevel " .. tostring(bad))
			t.eq(XpRules.xpForNextLevel(bad), XpRules.costOf(1), "xpForNextLevel " .. tostring(bad))
		end
	end)
end
