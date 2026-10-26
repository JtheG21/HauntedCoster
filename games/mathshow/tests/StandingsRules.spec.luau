--!strict
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StandingsConfig = require(ReplicatedStorage.Shared.StandingsConfig)
local StandingsRules = require(ReplicatedStorage.Shared.StandingsRules)

local NAN = 0 / 0
local INF = math.huge

local function entry(userId: number, points: number, name: string?)
	return { userId = userId, name = name or `P{userId}`, points = points }
end

-- n players with distinct points, best first (userId 1 has the most).
local function field(n: number): { any }
	local list = {}
	for i = 1, n do
		table.insert(list, entry(i, (n - i + 1) * 10))
	end
	return list
end

return function(t: TestRunner.T)
	t.test("isValidScores accepts well-formed lists", function()
		t.truthy(StandingsRules.isValidScores({}))
		t.truthy(StandingsRules.isValidScores({ entry(1, 0) }))
		t.truthy(StandingsRules.isValidScores({ entry(2, 300), entry(1, 100, "") }))
	end)

	t.test("isValidScores rejects non-lists and holes", function()
		t.eq(StandingsRules.isValidScores(nil), false)
		t.eq(StandingsRules.isValidScores("x"), false)
		t.eq(StandingsRules.isValidScores(5), false)
		t.eq(StandingsRules.isValidScores({ [1] = entry(1, 1), [3] = entry(2, 1) }), false)
		t.eq(StandingsRules.isValidScores({ a = entry(1, 1) }), false)
		t.eq(StandingsRules.isValidScores({ 5 }), false)
	end)

	t.test("isValidScores rejects bad fields", function()
		t.eq(StandingsRules.isValidScores({ entry(1, NAN) }), false)
		t.eq(StandingsRules.isValidScores({ entry(1, INF) }), false)
		t.eq(StandingsRules.isValidScores({ entry(1, -1) }), false)
		t.eq(StandingsRules.isValidScores({ entry(1, 1.5) }), false)
		t.eq(StandingsRules.isValidScores({ entry(1.5, 1) }), false)
		t.eq(StandingsRules.isValidScores({ entry(NAN, 1) }), false)
		t.eq(StandingsRules.isValidScores({ { userId = "1", name = "a", points = 1 } }), false)
		t.eq(StandingsRules.isValidScores({ { userId = 1, name = 5, points = 1 } }), false)
		t.eq(StandingsRules.isValidScores({ { userId = 1, name = "a" } }), false)
		t.eq(StandingsRules.isValidScores({ entry(1, 1), entry(1, 2) }), false)
	end)

	t.test("cleanPoints floors, clamps and caps", function()
		t.eq(StandingsRules.cleanPoints(0), 0)
		t.eq(StandingsRules.cleanPoints(7.9), 7)
		t.eq(StandingsRules.cleanPoints(-1), 0)
		t.eq(StandingsRules.cleanPoints(NAN), 0)
		t.eq(StandingsRules.cleanPoints(INF), 0)
		t.eq(StandingsRules.cleanPoints(-INF), 0)
		t.eq(StandingsRules.cleanPoints("5"), 0)
		t.eq(StandingsRules.cleanPoints(nil), 0)
		t.eq(StandingsRules.cleanPoints(StandingsConfig.MaxPoints), StandingsConfig.MaxPoints)
		t.eq(StandingsRules.cleanPoints(StandingsConfig.MaxPoints + 1000), StandingsConfig.MaxPoints)
	end)

	t.test("displayName handles empty and non-strings", function()
		t.eq(StandingsRules.displayName(""), "?")
		t.eq(StandingsRules.displayName(nil), "?")
		t.eq(StandingsRules.displayName(5), "?")
		t.eq(StandingsRules.displayName("Ann"), "Ann")
	end)

	t.test("displayName cuts at MaxNameChars with an ellipsis", function()
		local max = StandingsConfig.MaxNameChars
		local exact = string.rep("a", max)
		t.eq(StandingsRules.displayName(exact), exact)
		local cut = StandingsRules.displayName(exact .. "b")
		t.eq(utf8.len(cut), max)
		t.eq(cut, string.rep("a", max - 1) .. "\u{2026}")
	end)

	t.test("displayName never splits multi-byte characters", function()
		local max = StandingsConfig.MaxNameChars
		local name = string.rep("\u{00e9}", max + 5) -- two bytes each
		local cut = StandingsRules.displayName(name)
		t.eq(utf8.len(cut), max)
		t.eq(cut, string.rep("\u{00e9}", max - 1) .. "\u{2026}")
		t.eq(StandingsRules.displayName(string.rep("\u{4e2d}", max)), string.rep("\u{4e2d}", max))
		t.eq(StandingsRules.displayName("\255\254"), "?") -- invalid UTF-8
	end)

	t.test("build of an empty or invalid list is empty", function()
		local m = StandingsRules.build({}, 1)
		t.truthy(m.empty)
		t.eq(#m.podium + #m.others, 0)
		t.eq(m.you, nil)
		t.eq(m.hiddenCount, 0)
		t.truthy(StandingsRules.build(nil, 1).empty)
		t.truthy(StandingsRules.build({ entry(1, -3) }, 1).empty)
	end)

	t.test("build fills the podium for 1, 2 and 3 players", function()
		for n = 1, 3 do
			local m = StandingsRules.build(field(n), 1)
			t.eq(m.empty, false)
			t.eq(#m.podium, n)
			t.eq(#m.others, 0)
			t.eq(m.you, nil)
			t.eq(m.hiddenCount, 0)
			t.eq(m.podium[1].userId, 1)
			t.eq(m.podium[1].rank, 1)
			t.truthy(m.podium[1].isYou)
		end
	end)

	t.test("build at exactly podium plus list shows everyone", function()
		local n = StandingsConfig.PodiumSize + StandingsConfig.ListRows
		local m = StandingsRules.build(field(n), 99)
		t.eq(#m.podium, StandingsConfig.PodiumSize)
		t.eq(#m.others, StandingsConfig.ListRows)
		t.eq(m.hiddenCount, 0)
		t.eq(m.you, nil)
		t.eq(m.others[StandingsConfig.ListRows].rank, n)
	end)

	t.test("build counts hidden rows one past the list", function()
		local n = StandingsConfig.PodiumSize + StandingsConfig.ListRows + 1
		local m = StandingsRules.build(field(n), 99)
		t.eq(m.hiddenCount, 1)
		t.eq(m.you, nil)
	end)

	t.test("build puts a local player beyond the list in you", function()
		local n = StandingsConfig.PodiumSize + StandingsConfig.ListRows + 3
		local m = StandingsRules.build(field(n), n - 1)
		local you = m.you
		t.truthy(you ~= nil)
		t.eq((you :: any).userId, n - 1)
		t.eq((you :: any).rank, n - 1)
		t.truthy((you :: any).isYou)
		t.eq(m.hiddenCount, 2) -- the last two players; you is not counted
		local last = StandingsRules.build(field(n), n)
		t.eq(last.hiddenCount, 2)
		t.eq((last.you :: any).userId, n)
	end)

	t.test("build marks a local player in the list or podium without you", function()
		local m = StandingsRules.build(field(6), 4)
		t.eq(m.you, nil)
		t.truthy(m.others[1].isYou)
		t.eq(m.others[1].rank, 4)
		local absent = StandingsRules.build(field(4), 777)
		for _, row in absent.podium do
			t.eq(row.isYou, false)
		end
		t.eq(absent.you, nil)
	end)

	t.test("build gives ties a shared competition rank", function()
		local m = StandingsRules.build({ entry(2, 50), entry(1, 50), entry(3, 10) }, 1)
		t.eq(m.podium[1].userId, 1)
		t.eq(m.podium[2].userId, 2)
		t.eq(m.podium[1].rank, 1)
		t.eq(m.podium[2].rank, 1)
		t.eq(m.podium[3].rank, 3)
	end)

	t.test("build keeps a tie together across the podium and list boundary", function()
		local m = StandingsRules.build({
			entry(1, 90),
			entry(2, 80),
			entry(3, 50),
			entry(4, 50),
			entry(5, 10),
		}, 99)
		t.eq(m.podium[3].rank, 3)
		t.eq(m.others[1].rank, 3)
		t.eq(m.others[2].rank, 5)
	end)

	t.test("build sorts like the server: points desc, userId asc", function()
		local m = StandingsRules.build({ entry(9, 10), entry(4, 30), entry(2, 30), entry(7, 20) }, 1)
		local order = {}
		for _, row in m.podium do
			table.insert(order, row.userId)
		end
		for _, row in m.others do
			table.insert(order, row.userId)
		end
		t.eq(table.concat(order, ","), "2,4,7,9")
	end)

	t.test("build with all-zero scores ranks everyone first", function()
		local m = StandingsRules.build({ entry(3, 0), entry(1, 0), entry(2, 0) }, 2)
		for _, row in m.podium do
			t.eq(row.rank, 1)
			t.eq(row.points, 0)
		end
		t.eq(m.podium[1].userId, 1)
	end)

	t.test("build cleans names and does not mutate its input", function()
		local input = { entry(1, 5, ""), entry(2, 9, "Zed") }
		local m = StandingsRules.build(input, 1)
		t.eq(m.podium[1].name, "Zed")
		t.eq(m.podium[2].name, "?")
		t.eq(input[1].userId, 1)
	end)

	t.test("formatNumber groups thousands", function()
		t.eq(StandingsRules.formatNumber(0), "0")
		t.eq(StandingsRules.formatNumber(999), "999")
		t.eq(StandingsRules.formatNumber(1000), "1,000")
		t.eq(StandingsRules.formatNumber(1102), "1,102")
		t.eq(StandingsRules.formatNumber(123456), "123,456")
		t.eq(StandingsRules.formatNumber(1234567), "1,234,567")
		t.eq(StandingsRules.formatNumber(-4), "0")
		t.eq(StandingsRules.formatNumber(NAN), "0")
		t.eq(StandingsRules.pointsLabel(1102), "1,102 PTS")
	end)

	t.test("moreLabel is empty without hidden rows", function()
		t.eq(StandingsRules.moreLabel(0), "")
		t.eq(StandingsRules.moreLabel(-2), "")
		t.eq(StandingsRules.moreLabel(NAN), "")
		t.eq(StandingsRules.moreLabel(nil), "")
		t.eq(StandingsRules.moreLabel(3), "+3 MORE")
	end)

	t.test("topTag says TIED FOR FIRST only when second shares rank 1", function()
		local solo = StandingsRules.build({ entry(1, 50), entry(2, 40) }, 1)
		t.eq(StandingsRules.topTag(solo), "TOP SCORE")
		local tied = StandingsRules.build({ entry(1, 50), entry(2, 50), entry(3, 10) }, 1)
		t.eq(StandingsRules.topTag(tied), "TIED FOR FIRST")
		local alone = StandingsRules.build({ entry(1, 50) }, 1)
		t.eq(StandingsRules.topTag(alone), "TOP SCORE")
		local thirdTied = StandingsRules.build({ entry(1, 90), entry(2, 50), entry(3, 50) }, 1)
		t.eq(StandingsRules.topTag(thirdTied), "TOP SCORE")
		t.eq(StandingsRules.topTag(StandingsRules.build({}, 1)), "TOP SCORE")
	end)

	t.test("emptyMessage only for an empty board", function()
		t.eq(StandingsRules.emptyMessage(StandingsRules.build({}, 1)), "NO SCORES THIS MATCH")
		t.eq(StandingsRules.emptyMessage(StandingsRules.build(nil, 1)), "NO SCORES THIS MATCH")
		t.eq(StandingsRules.emptyMessage(StandingsRules.build({ entry(1, 5) }, 1)), nil)
	end)

	t.test("build ranks a player below the 8th spot with their real rank", function()
		-- Ties above them keep the shared rank; the pinned row shows the rank, not the index.
		local list = field(10)
		list[1].points = list[2].points -- rank 1, 1, 3, ...
		local m = StandingsRules.build(list, 10)
		t.eq(m.podium[2].rank, 1)
		t.eq(m.podium[3].rank, 3)
		t.eq((m.you :: any).rank, 10)
		t.eq(m.hiddenCount, 1) -- rank 9 hides; the pinned rank-10 row is not counted
	end)

	t.test("scoreFor finds a player's points or falls back to 0", function()
		local scores = { entry(1, 300), entry(2, 120) }
		t.eq(StandingsRules.scoreFor(scores, 2), 120)
		t.eq(StandingsRules.scoreFor(scores, 1), 300)
		t.eq(StandingsRules.scoreFor(scores, 99), 0)
		t.eq(StandingsRules.scoreFor({}, 1), 0)
		t.eq(StandingsRules.scoreFor(nil, 1), 0)
		t.eq(StandingsRules.scoreFor({ entry(1, -3) }, 1), 0)
		t.eq(StandingsRules.scoreFor(scores, nil), 0)
	end)
end
