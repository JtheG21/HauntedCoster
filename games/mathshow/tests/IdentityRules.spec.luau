--!strict
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Rules = require(ReplicatedStorage.Shared.IdentityRules)
local Copy = require(ReplicatedStorage.Shared.IdentityCopy)
local TierConfig = require(ReplicatedStorage.Shared.TierConfig)

-- README rule 4 / the C2 prompt: these glyphs are missing from the font, icons replace them.
local BANNED = { "√", "π", "∫", "∞", "≤", "≥", "≠", "ⁿ", "✓", "✕", "▲", "▼", "→", "★" }

local function strings(tbl: { [any]: any }, out: { string }): { string }
	for _, v in tbl do
		if type(v) == "string" then
			table.insert(out, v)
		elseif type(v) == "table" then
			strings(v, out)
		end
	end
	return out
end

return function(t: TestRunner.T)
	t.test("status priority: DISCONNECTED > WATCHING > FIRST_CORRECT > SUBMITTED > YOU > BOT", function()
		local all: { [string]: boolean? } =
			{ DISCONNECTED = true, WATCHING = true, FIRST_CORRECT = true, SUBMITTED = true, YOU = true, BOT = true }
		t.eq(Rules.pickStatus(all), "DISCONNECTED")
		all.DISCONNECTED = nil
		t.eq(Rules.pickStatus(all), "WATCHING")
		all.WATCHING = nil
		t.eq(Rules.pickStatus(all), "FIRST_CORRECT")
		all.FIRST_CORRECT = nil
		t.eq(Rules.pickStatus(all), "SUBMITTED")
		all.SUBMITTED = nil
		t.eq(Rules.pickStatus(all), "YOU")
		all.YOU = nil
		t.eq(Rules.pickStatus(all), "BOT")
		all.BOT = nil
		t.eq(Rules.pickStatus(all), nil)
		t.eq(Rules.pickStatus({ YOU = false }), nil)
	end)

	t.test("card variant follows the same order and defaults", function()
		t.eq(Rules.variantOf({}), "Default")
		t.eq(Rules.variantOf({ isBot = true }), "Bot")
		t.eq(Rules.variantOf({ isBot = true, isYou = true }), "You")
		t.eq(Rules.variantOf({ isYou = true, firstCorrect = true }), "FirstCorrect")
		t.eq(Rules.variantOf({ firstCorrect = true, spectating = true }), "Spectating")
		t.eq(Rules.variantOf({ spectating = true, connected = false }), "Disconnected")
		t.eq(Rules.variantOf({ connected = true }), "Default")
	end)

	t.test("tagText accepts 2-5 characters and refuses the rest", function()
		t.eq(Rules.tagText("A1"), "[A1]")
		t.eq(Rules.tagText("WWWWW"), "[WWWWW]")
		t.eq(Rules.tagText("W"), nil)
		t.eq(Rules.tagText("WWWWWW"), nil)
		t.eq(Rules.tagText(""), nil)
		t.eq(Rules.tagText("A B"), nil)
		t.eq(Rules.tagText("A\nB"), nil)
		t.eq(Rules.tagText(5), nil)
		t.eq(Rules.tagText(nil), nil)
	end)

	t.test("chip widths: tag = text + 20 (min 48), status = text + 42", function()
		t.eq(Rules.tagWidth(10), 48)
		t.eq(Rules.tagWidth(28), 48)
		t.eq(Rules.tagWidth(28.2), 49)
		t.eq(Rules.tagWidth(80), 100)
		t.eq(Rules.statusWidth(54), 96)
		t.eq(Rules.statusWidth(108), 150)
	end)

	t.test("fillWidth: hidden at 0, at least 16, proportional, capped at the track", function()
		t.eq(Rules.fillWidth(0, 300), 0)
		t.eq(Rules.fillWidth(-5, 300), 0)
		t.eq(Rules.fillWidth(0 / 0, 300), 0)
		t.eq(Rules.fillWidth("50", 300), 0)
		t.eq(Rules.fillWidth(1, 300), 16)
		t.eq(Rules.fillWidth(50, 300), 150)
		t.eq(Rules.fillWidth(100, 300), 300)
		t.eq(Rules.fillWidth(250, 300), 300)
		t.eq(Rules.fillWidth(100, 120), 120)
		t.eq(Rules.fillWidth(5, 10), 10, "a track narrower than the minimum is never overfilled")
	end)

	t.test("delta text uses U+2212 for losses and plain digits for gains", function()
		t.eq(Rules.deltaText(12), "+12")
		t.eq(Rules.deltaText(-8), "−8")
		t.eq(Rules.deltaText(0), "0")
		t.eq(Rules.deltaText(0 / 0), "0")
		t.eq(Rules.deltaText(12.9), "+12")
		t.eq(Rules.deltaText("x"), "0")
		t.eq(Rules.rankChangeKind(3), "up")
		t.eq(Rules.rankChangeKind(-3), "down")
		t.eq(Rules.rankChangeKind(0), "same")
		t.eq(Rules.rankChangeText(-24), "24")
	end)

	t.test("progress texts", function()
		t.eq(Rules.gainText(64, 12), "64 + 12")
		t.eq(Rules.lossText(64, 8), "64 − 8")
		t.eq(Rules.gainText(250, -3), "100 + 0")
		t.eq(Rules.standingText(42), "STANDING 42")
		t.eq(Rules.standingText(0), "STANDING 1")
		t.eq(Rules.standingText(42, true), "NO. 42")
		t.eq(Rules.provisionalText(3, 5), "3 of 5 placement matches")
	end)

	t.test("trackText per size", function()
		t.eq(Rules.trackText("platinum", "groupBattle", "direct", "compact"), nil)
		t.eq(Rules.trackText("platinum", "groupBattle", "direct", "standard"), "PLATINUM · GROUP")
		t.eq(Rules.trackText("platinum", "team3v3", "direct", "long"), "PLATINUM · 3V3 · DIRECT ANSWER")
		t.eq(Rules.trackText("copper", "blitz", "choice", "long"), "COPPER · BLITZ · MULTIPLE CHOICE")
		t.eq(Rules.trackText("nope", "blitz", "choice", "standard"), nil)
		t.eq(Rules.trackText("gold", "vs", "choice", "standard"), nil)
		t.eq(Rules.trackText("gold", "blitz", "essay", "long"), nil)
		t.eq(Rules.modeKey("vs"), nil)
	end)

	t.test("statLine adds firsts only when there were some", function()
		t.eq(Rules.statLine(7, 10, 0), "7/10 correct")
		t.eq(Rules.statLine(7, 10, 3), "7/10 correct · 3 first")
		t.eq(Rules.statLine(-1, 0 / 0, nil), "0/0 correct")
	end)

	t.test("headshot falls back on failure or after 3 s, never earlier", function()
		t.eq(Rules.headshotState(false, false, 0), "pending")
		t.eq(Rules.headshotState(false, false, 2.99), "pending")
		t.eq(Rules.headshotState(false, false, 3), "fallback")
		t.eq(Rules.headshotState(false, true, 0.1), "fallback")
		t.eq(Rules.headshotState(true, false, 5), "ready")
		t.eq(Rules.headshotState(false, false, 0 / 0), "fallback")
	end)

	t.test("copy: tiers match TierConfig and no banned glyph appears", function()
		for _, id in TierConfig.Ids do
			t.truthy((Copy.Tier :: { [string]: string })[id], `copy for tier {id}`)
		end
		local n = 0
		for _ in Copy.Tier do
			n += 1
		end
		t.eq(n, #TierConfig.Ids)
		for _, s in strings(Copy :: any, {}) do
			for _, glyph in BANNED do
				t.eq(s:find(glyph, 1, true), nil, `"{s}" contains {glyph}`)
			end
		end
	end)

	t.test("copy: the minus is U+2212 and ALL CAPS wording is literal", function()
		t.eq(Copy.Minus, "\u{2212}")
		t.eq(Copy.Status.CHALLENGE_UNLOCKED, "CHALLENGE UNLOCKED")
		t.eq(Copy.Format.direct, "DIRECT ANSWER")
	end)
end
