--!strict
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnswerRules = require(ReplicatedStorage.Shared.AnswerRules)

local ALL: AnswerRules.Allow = { negative = true, decimal = true, fraction = true }
local INT_ONLY: AnswerRules.Allow = { negative = false, decimal = false, fraction = false }

local function p(text: string, allow: AnswerRules.Allow?): AnswerRules.Parsed?
	return AnswerRules.parse(text, allow or ALL)
end

local function expectRational(text: string, num: number, den: number, allow: AnswerRules.Allow?)
	local r = p(text, allow)
	if r == nil then
		error(`"{text}" should parse`)
	end
	if r.num ~= num or r.den ~= den then
		error(`"{text}" parsed as {r.num}/{r.den}, expected {num}/{den}`)
	end
end

local ACCEPT: { { string | number } } = {
	{ "7", 7, 1 },
	{ "  7  ", 7, 1 },
	{ "\t7\n", 7, 1 },
	{ "007", 7, 1 },
	{ "0", 0, 1 },
	{ "-5", -5, 1 },
	{ "\u{2212}5", -5, 1 },
	{ "-0", 0, 1 },
	{ "0.5", 1, 2 },
	{ ".5", 1, 2 },
	{ "-.5", -1, 2 },
	{ "2.50", 5, 2 },
	{ "0.125", 1, 8 },
	{ "3.0", 3, 1 },
	{ "1/2", 1, 2 },
	{ "2/4", 1, 2 },
	{ "-3/6", -1, 2 },
	{ "0/9", 0, 1 },
	{ "6/3", 2, 1 },
	{ "0000007", 7, 1 },
	{ "9999999", 9999999, 1 },
	{ "9999999/1", 9999999, 1 },
}

local REJECT: { string } = {
	"",
	"   ",
	"+5",
	"5.",
	".",
	"1/0",
	"1/2/3",
	"1e3",
	"0x10",
	"2+2",
	"2*3",
	"(3)",
	"1 000",
	"1 /2",
	"1,5",
	"1,000",
	"abc",
	"5a",
	"--5",
	"-+5",
	"1/-2",
	"1.5/2",
	"1/2.5",
	"1..5",
	"0.1234",
	"12345678",
	"1/12345678",
	"\u{0661}",
	"5\u{2212}",
	"\u{00A0}5",
	"123456789012345",
	"0000000000000001",
}

return function(t: TestRunner.T)
	t.test("accepts the documented forms and reduces them", function()
		for _, row in ACCEPT do
			expectRational(row[1] :: string, row[2] :: number, row[3] :: number)
		end
	end)

	t.test("rejects the documented forms", function()
		for _, text in REJECT do
			t.eq(p(text), nil, `"{text}" should be rejected`)
		end
	end)

	t.test("non-string input is rejected", function()
		t.eq(AnswerRules.parse(5 :: any, ALL), nil)
		t.eq(AnswerRules.parse(nil :: any, ALL), nil)
		t.eq(AnswerRules.parse({} :: any, ALL), nil)
	end)

	t.test("length cap is on raw text: 14 bytes ok, 15 not", function()
		t.truthy(p("00000000000007"))
		t.eq(p("000000000000007"), nil)
		t.eq(p("      7        "), nil, "padding counts toward the cap")
	end)

	t.test("digit cap counts significant digits, not leading zeros", function()
		t.truthy(p("0009999999"))
		t.eq(p("10000000"), nil)
	end)

	t.test("allow flags switch whole forms off", function()
		t.eq(p("-5", INT_ONLY), nil)
		t.eq(p("0.5", INT_ONLY), nil)
		t.eq(p("1/2", INT_ONLY), nil)
		t.truthy(p("5", INT_ONLY))
		t.eq(p("-5", { negative = false, decimal = true, fraction = true }), nil)
		t.eq(p("0.5", { negative = true, decimal = false, fraction = true }), nil)
		t.eq(p("1/2", { negative = true, decimal = true, fraction = false }), nil)
	end)

	t.test("equal treats 1/2, 0.5, 2/4 and .5 as the same value", function()
		local base = p("1/2") :: AnswerRules.Parsed
		for _, text in { "0.5", "2/4", ".5", "3/6", "0.50" } do
			t.truthy(AnswerRules.equal(base, p(text) :: AnswerRules.Parsed), text)
		end
		t.eq(AnswerRules.equal(base, p("1/3") :: AnswerRules.Parsed), false)
		t.eq(AnswerRules.equal(base, p("-1/2") :: AnswerRules.Parsed), false)
	end)

	t.test("negative zero equals zero", function()
		t.truthy(AnswerRules.equal(p("-0") :: AnswerRules.Parsed, p("0") :: AnswerRules.Parsed))
		t.truthy(AnswerRules.equal(p("-0.0") :: AnswerRules.Parsed, p("0/5") :: AnswerRules.Parsed))
		t.eq(tostring((p("-0") :: AnswerRules.Parsed).num), "0")
	end)

	t.test("equal is exact at the largest inputs", function()
		local a = p("999999/999998") :: AnswerRules.Parsed
		local b = p("999998/999997") :: AnswerRules.Parsed
		t.eq(AnswerRules.equal(a, b), false)
		t.truthy(AnswerRules.equal(a, { num = 999999 * 3, den = 999998 * 3 }))
	end)

	t.test("normalize gives one canonical string per value", function()
		t.eq(AnswerRules.normalize(p("2/4") :: AnswerRules.Parsed, ALL), "1/2")
		t.eq(AnswerRules.normalize(p("-0.5") :: AnswerRules.Parsed, ALL), "-1/2")
		t.eq(AnswerRules.normalize(p("006") :: AnswerRules.Parsed, ALL), "6")
		t.eq(AnswerRules.normalize(p("-0") :: AnswerRules.Parsed, ALL), "0")
		local decimalOnly: AnswerRules.Allow = { negative = true, decimal = true, fraction = false }
		t.eq(AnswerRules.normalize(p("1/2") :: AnswerRules.Parsed, decimalOnly), "0.5")
		t.eq(AnswerRules.normalize(p("5/4") :: AnswerRules.Parsed, decimalOnly), "1.25")
		t.eq(AnswerRules.normalize(p("-1/8") :: AnswerRules.Parsed, decimalOnly), "-0.125")
		t.eq(AnswerRules.normalize(p("1/3") :: AnswerRules.Parsed, decimalOnly), nil)
		t.eq(AnswerRules.normalize(p("1/2") :: AnswerRules.Parsed, INT_ONLY), nil)
		t.eq(AnswerRules.normalize(p("-4") :: AnswerRules.Parsed, INT_ONLY), nil)
	end)

	t.test("fuzz: 2000 random strings never error and results are well-formed", function()
		local rng = Random.new(20261027)
		local alphabet = {
			"0",
			"1",
			"2",
			"5",
			"9",
			"-",
			".",
			"/",
			" ",
			"+",
			"e",
			"x",
			"(",
			")",
			"\u{2212}",
			"\n",
			"a",
			"\u{00E9}",
			",",
		}
		local accepted = 0
		for _ = 1, 2000 do
			local len = rng:NextInteger(0, 18)
			local parts: { string } = {}
			for i = 1, len do
				parts[i] = alphabet[rng:NextInteger(1, #alphabet)]
			end
			local text = table.concat(parts)
			local ok, result = pcall(AnswerRules.parse, text, ALL)
			t.truthy(ok, "parse errored")
			if result ~= nil then
				accepted += 1
				local r = result :: AnswerRules.Parsed
				t.truthy(r.den > 0, "den > 0")
				t.eq(r.num % 1, 0)
				t.eq(r.den % 1, 0)
				t.truthy(AnswerRules.equal(r, r))
				local shown = AnswerRules.normalize(r, ALL)
				t.truthy(shown ~= nil, "normalize")
				local back = AnswerRules.parse(shown, ALL)
				t.truthy(back ~= nil and AnswerRules.equal(back, r), "round trip")
			end
		end
		t.truthy(accepted > 0, "the fuzz alphabet should produce some valid strings")
	end)
end
