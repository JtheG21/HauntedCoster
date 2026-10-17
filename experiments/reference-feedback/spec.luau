local State = require("./State")
local cases = {
	{ 100, "NORMAL", true },
	{ 25.01, "NORMAL", true },
	{ 25, "LOW", true },
	{ 0.01, "LOW", true },
	{ 0, "DEPLETED", false },
	{ -1, "DEPLETED", false },
	{ 150, "NORMAL", true },
}
for _, case in cases do
	local value = State.describe(case[1])
	assert(value.phase == case[2] and value.enabled == case[3], "boundary classification")
end
assert(State.drain(100, 5, true) == 60, "active drain")
assert(State.drain(100, 5, false) == 90, "idle drain")
assert(State.drain(5, 1, true) == 0, "depletion clamps")
local remaining = 100
for _ = 1, 50 do
	remaining = State.drain(remaining, 0.1, true)
end
assert(math.abs(remaining - State.drain(100, 5, true)) < 0.00001, "time subdivision invariance")
for _, bad in { 0 / 0, math.huge, -math.huge } do
	assert(not pcall(State.describe, bad), "invalid charge rejected")
end
assert(not pcall(State.drain, 100, -1, true), "negative time rejected")
print("Feedback state: 15 boundary/time/input assertions passed")
