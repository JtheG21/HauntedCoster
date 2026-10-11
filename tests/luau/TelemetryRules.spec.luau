--!strict
local TestRunner = require(script.Parent.TestRunner)
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TelemetryRules = require(ReplicatedStorage.Shared.TelemetryRules)

local function record(): TelemetryRules.MatchRecord
	return {
		matchIndex = 3,
		players = { 987654321, 123456789 },
		factions = { [987654321] = "Ki", [123456789] = "Shinobi" },
		firstPower = { [987654321] = 12.34, [123456789] = 40 },
		trialTimeouts = 1,
		gateWaits = { 4, 10, 7 },
		gateOpens = 3,
		shrineOpens = 0,
		echoEarned = { Ki = 2, Shinobi = 2 },
		echoSpent = { Ki = 1 },
		courseSeconds = 61.26,
		finaleSeconds = 14.04,
		totalSeconds = 75.3,
		finishers = { 123456789 },
		speed = 123456789,
		teamwork = 987654321,
		combatWinner = 987654321,
		combatDraw = {},
		eliminations = 1,
		serverErrors = 0,
		rejections = 2,
		ended = "results",
	}
end

return function(t: TestRunner.T)
	t.test("summarize gives count, median and max", function()
		local s = TelemetryRules.summarize({ 9, 1, 5 })
		t.eq(s.n, 3)
		t.eq(s.median, 5)
		t.eq(s.max, 9)
		t.eq(TelemetryRules.summarize({ 1, 2, 3, 10 }).median, 2.5)
	end)

	t.test("summarize of nothing (or only NaN/inf) has no median", function()
		local s = TelemetryRules.summarize({})
		t.eq(s.n, 0)
		t.eq(s.median, nil)
		t.eq(TelemetryRules.summarize({ 0 / 0, math.huge }).n, 0)
	end)

	t.test("anonymize labels players by match order", function()
		local label = TelemetryRules.anonymize({ 50, 20 })
		t.eq(label(50), "P1")
		t.eq(label(20), "P2")
		t.eq(label(99), "P?")
		t.eq(label(nil), nil)
	end)

	t.test("the summary contains no user ids", function()
		local json = HttpService:JSONEncode(TelemetryRules.buildSummary(record()))
		t.eq(string.find(json, "987654321", 1, true), nil)
		t.eq(string.find(json, "123456789", 1, true), nil)
	end)

	t.test("the summary carries the EXP-0001 metrics", function()
		local s = TelemetryRules.buildSummary(record())
		t.eq(s.match, 3)
		t.eq(s.players, 2)
		t.eq(s.factions.Ki, 1)
		t.eq(s.firstPowerS.median, 26.2) -- (12.34 + 40) / 2, rounded to 0.1
		t.eq(s.trialTimeouts, 1)
		t.eq(s.gateWaitS.median, 7)
		t.eq(s.echoSpent.Ki, 1)
		t.eq(s.courseS, 61.3)
		t.eq(s.speed, "P2:Shinobi")
		t.eq(s.teamwork, "P1:Ki")
		t.eq(s.combat, "P1:Ki")
		t.eq(s.combatDraw, nil)
		t.eq(s.ended, "results")
	end)

	t.test("a draw lists the drawn players anonymised", function()
		local r = record()
		r.combatWinner = nil
		r.combatDraw = { 123456789, 987654321 }
		local s = TelemetryRules.buildSummary(r)
		t.eq(s.combat, nil)
		t.eq(table.concat(s.combatDraw, ","), "P2:Shinobi,P1:Ki")
	end)
end
