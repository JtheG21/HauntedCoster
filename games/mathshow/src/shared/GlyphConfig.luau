--!strict
return table.freeze({
	CollectRadius = 8,
	RespawnSeconds = table.freeze({ common = 90, rare = 300 }),
	RateLimit = 4,
	RateWindowSeconds = 1, -- the rolling window for RateLimit and RawRequestLimit
	RawRequestLimit = 10, -- raw GlyphCollect requests per RateWindowSeconds, success or fail
	RetryAfterSeconds = 1.0, -- the client's cadence for re-asking about a glyph in reach that the server has not taken
	Rarity = table.freeze({ "common", "rare" }),
	Value = table.freeze({ common = 1, rare = 5 }),
	Symbols = table.freeze({ "π", "Σ", "√", "+", "−", "×", "÷" }),
})
