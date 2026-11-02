--!strict
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.GlyphConfig)
local Rules = require(ReplicatedStorage.Shared.GlyphRules)

type PlayerState = Rules.PlayerState
local origin = { x = 0, y = 0, z = 0 }
local spawns: { Rules.Spawn } = {
	{ id = "a", position = origin, rarity = "common" },
	{ id = "b", position = { x = 0, y = 0, z = 0 }, rarity = "rare" },
}

local function freezeState(state: PlayerState): PlayerState
	for _, glyph in state.glyphs do
		table.freeze(glyph)
	end
	table.freeze(state.glyphs)
	table.freeze(state.collectTimes)
	return table.freeze(state)
end

return function(t: TestRunner.T)
	local function expect(state: PlayerState, id: unknown, pos: Rules.Position, now: number, reason: string)
		local ok, actual = Rules.validateCollect(state, id, pos, now, spawns)
		t.eq(ok, reason == "ok")
		t.eq(actual, reason)
	end

	t.test("glyph defaults and nested tuning are frozen", function()
		t.eq(Config.CollectRadius, 8)
		t.eq(Config.RateLimit, 4)
		t.eq(Config.RespawnSeconds.common, 90)
		t.eq(Config.RespawnSeconds.rare, 300)
		t.eq(Config.Value.common, 1)
		t.eq(Config.Value.rare, 5)
		t.eq(Config.Rarity[1], "common")
		t.eq(Config.Rarity[2], "rare")
		t.eq(Config.RateWindowSeconds, 1)
		t.eq(Config.RawRequestLimit, 10)
		t.eq(#Config.Symbols, 7)
		local tables: { any } = { Config, Config.RespawnSeconds, Config.Value, Config.Rarity, Config.Symbols }
		for _, value in tables do
			t.truthy(table.isfrozen(value))
		end
	end)

	t.test("new player starts with all glyphs available and independent state", function()
		local state = Rules.newPlayerState(spawns)
		t.eq(state.sessionCount, 0)
		t.eq(#state.collectTimes, 0)
		for _, spawn in spawns do
			t.eq(state.glyphs[spawn.id].collected, false)
			t.eq(state.glyphs[spawn.id].respawnAt, nil)
			t.eq(state.glyphs[spawn.id].rarity, spawn.rarity)
		end
		state.glyphs.a.collected = true
		t.eq(Rules.newPlayerState(spawns).glyphs.a.collected, false)
		t.eq(spawns[1].rarity, "common")
	end)

	t.test("wrong types fail before id lookup", function()
		local state = Rules.newPlayerState(spawns)
		expect(state, nil, origin, 0, "invalid_type")
		local invalidIds: { unknown } = { 1, true, {}, function() end }
		for _, id in invalidIds do
			expect(state, id, origin, 0, "invalid_type")
		end
	end)

	t.test("unknown id fails before distance", function()
		expect(Rules.newPlayerState(spawns), "missing", { x = 100, y = 0, z = 0 }, 0, "unknown_id")
		expect(Rules.newPlayerState(spawns), "", origin, 0, "unknown_id")
	end)

	t.test("exact radius succeeds; radius plus epsilon fails on each axis", function()
		local state = Rules.newPlayerState(spawns)
		for _, axis in { "x", "y", "z" } do
			for _, sign in { -1, 1 } do
				local pos = { x = 0, y = 0, z = 0 }
				pos[axis] = sign * Config.CollectRadius
				expect(state, "a", pos, 0, "ok")
				pos[axis] = sign * (Config.CollectRadius + 0.000001)
				expect(state, "a", pos, 0, "out_of_range")
			end
		end
	end)

	t.test("distance uses all three coordinates relative to the spawn", function()
		local shifted: { Rules.Spawn } = { { id = "a", position = { x = 10, y = 20, z = 30 }, rarity = "common" } }
		local state = Rules.newPlayerState(shifted)
		local ok = Rules.validateCollect(state, "a", { x = 14, y = 24, z = 34 }, 0, shifted)
		t.eq(ok, true)
		ok = Rules.validateCollect(state, "a", { x = 15, y = 25, z = 35 }, 0, shifted)
		t.eq(ok, false)
	end)

	t.test("double collect fails; distance has priority over collected", function()
		local state = Rules.applyCollect(Rules.newPlayerState(spawns), "a", 10)
		expect(state, "a", origin, 10, "already_collected")
		expect(state, "a", { x = 9, y = 0, z = 0 }, 10, "out_of_range")
	end)

	t.test("common and rare collects add configured values and respawn deadlines", function()
		local state = Rules.applyCollect(Rules.newPlayerState(spawns), "a", 10)
		t.eq(state.sessionCount, 1)
		t.eq(state.glyphs.a.respawnAt, 100)
		state = Rules.applyCollect(state, "b", 11)
		t.eq(state.sessionCount, 6)
		t.eq(state.glyphs.b.respawnAt, 311)
		t.eq(state.collectTimes[1], 11)
		t.eq(#state.collectTimes, 1)
	end)

	t.test("respawns happen exactly at each rarity deadline and preserve earned value", function()
		local state = Rules.applyCollect(Rules.newPlayerState(spawns), "a", 0)
		state = Rules.applyCollect(state, "b", 0)
		local before = Rules.tickRespawns(state, 90 - 0.000001)
		t.eq(before.glyphs.a.collected, true)
		local exact = Rules.tickRespawns(state, 90)
		t.eq(exact.glyphs.a.collected, false)
		t.eq(exact.glyphs.a.respawnAt, nil)
		t.eq(exact.glyphs.b.collected, true)
		expect(exact, "a", origin, 90, "ok")
		t.eq(Rules.tickRespawns(state, 300 - 0.000001).glyphs.b.collected, true)
		t.eq(Rules.tickRespawns(state, 300).glyphs.b.collected, false)
		t.eq(Rules.tickRespawns(state, 400).sessionCount, 6)
	end)

	t.test("rolling rate window excludes exactly one-second-old collects", function()
		local many: { Rules.Spawn } = {}
		for i = 1, Config.RateLimit + 1 do
			table.insert(many, { id = tostring(i), position = origin, rarity = "common" })
		end
		local state = Rules.newPlayerState(many)
		for i = 1, Config.RateLimit do
			local ok = Rules.validateCollect(state, tostring(i), origin, 0, many)
			t.eq(ok, true)
			state = Rules.applyCollect(state, tostring(i), 0)
		end
		local id = tostring(Config.RateLimit + 1)
		for _, now in { 0, 1 - 0.000001 } do
			local ok, reason = Rules.validateCollect(state, id, origin, now, many)
			t.eq(ok, false)
			t.eq(reason, "rate_limited")
		end
		for _, now in { 1, 1 + 0.000001 } do
			local ok = Rules.validateCollect(state, id, origin, now, many)
			t.eq(ok, true)
		end
		local _, reason = Rules.validateCollect(state, "1", origin, 0, many)
		t.eq(reason, "already_collected")
	end)

	t.test("rolling window expires timestamps individually across second boundaries", function()
		local state = Rules.newPlayerState(spawns)
		state.collectTimes = { 0.5, 0.75, 0.9, 1.1 }
		expect(state, "a", origin, 1.499999, "rate_limited")
		expect(state, "a", origin, 1.5, "ok")
		local nextState = Rules.applyCollect(state, "a", 1.5)
		t.eq(#nextState.collectTimes, 4)
		t.eq(nextState.collectTimes[1], 0.75)
		t.eq(nextState.collectTimes[4], 1.5)
	end)

	t.test("validate, apply and tick preserve frozen inputs and return independent state", function()
		local initial = freezeState(Rules.newPlayerState(spawns))
		expect(initial, "a", origin, 0, "ok")
		local collected = freezeState(Rules.applyCollect(initial, "a", 0))
		t.eq(initial.glyphs.a.collected, false)
		t.eq(initial.glyphs.a.respawnAt, nil)
		t.eq(initial.sessionCount, 0)
		t.eq(#initial.collectTimes, 0)
		local available = Rules.tickRespawns(collected, 90)
		t.eq(collected.glyphs.a.collected, true)
		t.eq(collected.glyphs.a.respawnAt, 90)
		available.glyphs.b.collected = true
		available.collectTimes[1] = 1000
		t.eq(collected.glyphs.b.collected, false)
		t.eq(collected.collectTimes[1], 0)
		local noop = Rules.tickRespawns(collected, 1)
		t.truthy(noop ~= collected and noop.glyphs.a ~= collected.glyphs.a)
	end)

	t.test("empty spawn lists produce empty state and reject all ids", function()
		local state = Rules.newPlayerState({})
		t.eq(next(state.glyphs), nil)
		t.eq(state.sessionCount, 0)
		local ok, reason = Rules.validateCollect(state, "a", origin, 0, {})
		t.eq(ok, false)
		t.eq(reason, "unknown_id")
		t.eq(next(Rules.tickRespawns(freezeState(state), 100).glyphs), nil)
	end)

	local function record(id: string, rarity: string, x: number, y: number, z: number): Rules.SpawnRecord
		return { id = id, rarity = rarity, x = x, y = y, z = z }
	end

	t.test("parseSpawns keeps valid records in order with their rarity and position", function()
		local parsed, warnings = Rules.parseSpawns({ record("a", "common", 1, 2, 3), record("b", "rare", -4, 5, 6) })
		t.eq(#parsed, 2)
		t.eq(#warnings, 0)
		t.eq(parsed[1].id, "a")
		t.eq(parsed[1].rarity, "common")
		t.eq(parsed[1].position.z, 3)
		t.eq(parsed[2].id, "b")
		t.eq(parsed[2].rarity, "rare")
		t.eq(parsed[2].position.x, -4)
	end)

	t.test("parseSpawns drops unknown rarities with a warning; valid rarities come from GlyphConfig.Rarity", function()
		local records: { Rules.SpawnRecord } = { record("x", "epic", 0, 0, 0), record("y", "Common", 0, 0, 0) }
		for index, rarity in Config.Rarity do
			table.insert(records, record(`ok{index}`, rarity, 0, 0, 0))
		end
		local parsed, warnings = Rules.parseSpawns(records)
		t.eq(#parsed, #Config.Rarity)
		t.eq(#warnings, 2)
		t.truthy(string.find(warnings[1], "x", 1, true) ~= nil)
		t.truthy(string.find(warnings[1], "rarity", 1, true) ~= nil)
	end)

	t.test("parseSpawns keeps the first of a duplicate id and warns once per duplicate", function()
		local parsed, warnings = Rules.parseSpawns({
			record("a", "common", 1, 0, 0),
			record("a", "rare", 2, 0, 0),
			record("a", "common", 3, 0, 0),
		})
		t.eq(#parsed, 1)
		t.eq(parsed[1].rarity, "common")
		t.eq(parsed[1].position.x, 1)
		t.eq(#warnings, 2)
		t.truthy(string.find(warnings[1], "duplicate", 1, true) ~= nil)
	end)

	t.test("parseSpawns drops NaN and infinite coordinates on any axis, and an empty id", function()
		local nan = 0 / 0
		local parsed, warnings = Rules.parseSpawns({
			record("nx", "common", nan, 0, 0),
			record("ny", "common", 0, math.huge, 0),
			record("nz", "common", 0, 0, -math.huge),
			record("", "common", 0, 0, 0),
			record("ok", "common", 0, 0, 0),
		})
		t.eq(#parsed, 1)
		t.eq(parsed[1].id, "ok")
		t.eq(#warnings, 4)
		t.truthy(string.find(warnings[1], "non-finite", 1, true) ~= nil)
	end)

	t.test("parseSpawns of an empty list returns no spawns and no warnings", function()
		local parsed, warnings = Rules.parseSpawns({})
		t.eq(#parsed, 0)
		t.eq(#warnings, 0)
	end)

	t.test("a dropped duplicate does not hide a later valid id", function()
		local parsed = Rules.parseSpawns({
			record("a", "common", 0, 0, 0),
			record("a", "rare", 0, 0, 0),
			record("b", "rare", 0, 0, 0),
		})
		t.eq(#parsed, 2)
		t.eq(parsed[2].id, "b")
	end)

	t.test("the rate window is RateWindowSeconds wide: exactly that old falls out, just inside still counts", function()
		local state = Rules.newPlayerState(spawns)
		local window = Config.RateWindowSeconds
		local stamps: { number } = {}
		for _ = 1, Config.RateLimit do
			table.insert(stamps, 10)
		end
		state.collectTimes = stamps
		expect(state, "a", origin, 10 + window - 0.000001, "rate_limited")
		expect(state, "a", origin, 10 + window, "ok")
		local nextState = Rules.applyCollect(state, "a", 10 + window)
		t.eq(#nextState.collectTimes, 1)
	end)

	t.test("a non-finite now is rejected as bad_time before anything else", function()
		local state = Rules.newPlayerState(spawns)
		for _, now in { 0 / 0, math.huge, -math.huge } do
			expect(state, "a", origin, now, "bad_time")
			expect(state, 42, origin, now, "bad_time")
		end
	end)

	t.test("out_of_range beats rate_limited", function()
		local state = Rules.newPlayerState(spawns)
		local stamps: { number } = {}
		for _ = 1, Config.RateLimit do
			table.insert(stamps, 5)
		end
		state.collectTimes = stamps
		expect(state, "a", origin, 5, "rate_limited")
		expect(state, "a", { x = Config.CollectRadius + 1, y = 0, z = 0 }, 5, "out_of_range")
	end)
end
