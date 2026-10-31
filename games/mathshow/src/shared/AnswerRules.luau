--!strict
-- Exact answer parsing for typed math answers. Never evaluates anything: no load, loadstring, tonumber or
-- string.format on user text. Text is checked against fixed patterns first; digits are then turned into a number
-- by accumulating bytes, so the only numeric conversion happens after a pattern match.
--
-- Result: an exact reduced rational { num, den } of integers with den > 0 (zero is 0/1, never -0).
--
-- Accepted (after trimming surrounding whitespace):
--   integers "7", "007" (leading zeros ok); a single leading "-" or U+2212 "−" when allow.negative;
--   decimals "0.5", ".5", "-.5" when allow.decimal (at most MaxDecimals digits after the point);
--   simple fractions "a/b" when allow.fraction (b ~= 0; sign only in front of the numerator).
-- Rejected (nil): empty or whitespace only, "+5", "5.", "1/0", "1/2/3", "1e3", "0x10", "2+2", "2*3", "(3)",
--   interior spaces, commas, "--5", "1/-2", "1.5/2", any letter, any non-ASCII except the leading U+2212, raw text
--   longer than MaxInputLength bytes, more than MaxDigits significant digits in any integer part, numerator or
--   denominator, more than MaxDecimals decimals, and anything that is not a string.

local AnswerConfig = require(script.Parent.AnswerConfig)

export type Parsed = { num: number, den: number }
export type Allow = { negative: boolean, decimal: boolean, fraction: boolean }

local MINUS_SIGN = "\u{2212}" -- U+2212, 3 bytes

local AnswerRules = {}

-- digits is a non-empty run of ASCII digits (already pattern-checked). nil when it has too many significant digits.
local function digitsToInt(digits: string, maxDigits: number): number?
	local start = 1
	while start < #digits and string.byte(digits, start) == 48 do
		start += 1
	end
	if #digits - start + 1 > maxDigits then
		return nil
	end
	local n = 0
	for i = start, #digits do
		n = n * 10 + (string.byte(digits, i) - 48)
	end
	return n
end

local function gcd(a: number, b: number): number
	while b ~= 0 do
		a, b = b, a % b
	end
	return a
end

local function make(num: number, den: number): Parsed
	if num == 0 then
		return { num = 0, den = 1 }
	end
	local g = gcd(math.abs(num), den)
	return { num = num // g, den = den // g }
end

function AnswerRules.parse(text: any, allow: Allow): Parsed?
	if type(text) ~= "string" or #text > AnswerConfig.MaxInputLength then
		return nil
	end
	local s = text:match("^%s*(.-)%s*$") :: string
	local negative = false
	if s:sub(1, 1) == "-" then
		negative = true
		s = s:sub(2)
	elseif s:sub(1, 3) == MINUS_SIGN then
		negative = true
		s = s:sub(4)
	end
	if negative and not allow.negative then
		return nil
	end

	local num: number?
	local den = 1
	if s:match("^%d+$") then
		num = digitsToInt(s, AnswerConfig.MaxDigits)
	elseif s:match("^%d*%.%d+$") then
		if not allow.decimal then
			return nil
		end
		local intPart = s:match("^(%d*)%.") :: string
		local frac = s:match("%.(%d+)$") :: string
		if #frac > AnswerConfig.MaxDecimals then
			return nil
		end
		local whole = if #intPart > 0 then digitsToInt(intPart, AnswerConfig.MaxDigits) else 0
		local fraction = digitsToInt(frac, AnswerConfig.MaxDecimals)
		if whole == nil or fraction == nil then
			return nil
		end
		den = 10 ^ #frac
		num = whole * den + fraction
	elseif s:match("^%d+/%d+$") then
		if not allow.fraction then
			return nil
		end
		local a = s:match("^(%d+)/") :: string
		local b = s:match("/(%d+)$") :: string
		local numerator = digitsToInt(a, AnswerConfig.MaxDigits)
		local denominator = digitsToInt(b, AnswerConfig.MaxDigits)
		if numerator == nil or denominator == nil or denominator == 0 then
			return nil
		end
		num, den = numerator, denominator
	else
		return nil
	end
	if num == nil then
		return nil
	end
	return make(if negative then -num else num, den)
end

-- Exact: both sides are reduced to lowest terms with den > 0, and reduced rationals are equal exactly when
-- numerator and denominator match. No multiplication, so there is no overflow to guard.
function AnswerRules.equal(a: Parsed, b: Parsed): boolean
	local ra, rb = make(a.num, a.den), make(b.num, b.den)
	return ra.num == rb.num and ra.den == rb.den
end

local function plain(n: number): string
	return tostring(n)
end

-- Canonical display string within what the player may type: integer when den is 1, else "n/d" when fractions are
-- allowed, else a decimal when it terminates within MaxDecimals. nil when the value cannot be shown under `allow`.
function AnswerRules.normalize(parsed: Parsed, allow: Allow): string?
	local p = make(parsed.num, parsed.den)
	if p.num < 0 and not allow.negative then
		return nil
	end
	local sign = if p.num < 0 then "-" else ""
	local mag = math.abs(p.num)
	if p.den == 1 then
		return sign .. plain(mag)
	end
	if allow.fraction then
		return `{sign}{plain(mag)}/{plain(p.den)}`
	end
	if allow.decimal then
		local scale = 10 ^ AnswerConfig.MaxDecimals
		if scale % p.den ~= 0 then
			return nil
		end
		local scaled = mag * (scale // p.den)
		local whole = scaled // scale
		local digits = plain(scaled % scale)
		digits = string.rep("0", AnswerConfig.MaxDecimals - #digits) .. digits
		digits = digits:gsub("0+$", "")
		return `{sign}{plain(whole)}.{digits}`
	end
	return nil
end

return AnswerRules
