--!strict
local EvidenceRules = require("../../src/shared/Rules/EvidenceRules")
local CameraRules = require("../../src/shared/Rules/CameraRules")
local RoundRules = require("../../src/shared/Rules/RoundRules")

local tuning = {
    CloseRange = 12,
    GoodRange = 30,
    LongRange = 55,
    TightFrameDegrees = 4,
    ClearFrameDegrees = 12,
}
local function capture(state: string, distance: number, frame: number, aware: boolean)
    return EvidenceRules.evaluate({
        state = state,
        distance = distance,
        frameErrorDegrees = frame,
        wasAware = aware,
        tuning = tuning,
    })
end

local cases = {
    { "perfect close pursuit is the best test grade", function()
        local result = capture("Pursuing", 10, 1, true)
        assert(result and result.tier == "Remarkable" and result.points == 8)
    end },
    { "baseline photo is valid and explains weak framing", function()
        local result = capture("Roaming", 20, 16, false)
        assert(result and result.tier == "Sighting")
        assert(table.find(result.breakdown, "Loose framing") ~= nil)
        assert(table.find(result.breakdown, "Quiet approach") ~= nil)
    end },
    { "state-specific photo quality changes with the actual state", function()
        local passive = capture("Roaming", 20, 2, true)
        local investigating = capture("Investigating", 20, 2, true)
        assert(passive and investigating and investigating.points > passive.points)
    end },
    { "invalid distances, angles and thresholds are refused", function()
        assert(capture("Roaming", 0/0, 0, false) == nil)
        assert(capture("Roaming", 10, math.huge, false) == nil)
        local result = EvidenceRules.evaluate({
            state = "Roaming", distance = 10, frameErrorDegrees = 1, wasAware = false,
            tuning = { CloseRange = 10, GoodRange = 5, LongRange = 50, TightFrameDegrees = 4, ClearFrameDegrees = 12 },
        })
        assert(result == nil)
    end },
    { "camera directions must be finite, normalized and within the facing cone", function()
        assert(CameraRules.isPlausibleDirection(0,0,-1,0,0,-1,-0.18))
        assert(not CameraRules.isPlausibleDirection(0,0,1,0,0,-1,-0.18))
        assert(not CameraRules.isPlausibleDirection(math.huge,0,-1,0,0,-1,-0.18))
        assert(not CameraRules.isPlausibleDirection(0,0,-4,0,0,-1,-0.18))
    end },
    { "round actions follow phase and investigating photos alone provoke", function()
        assert(RoundRules.canPhotograph("active"))
        assert(not RoundRules.canPhotograph("failed"))
        assert(RoundRules.canRestart("failed") and not RoundRules.canRestart("active"))
        assert(RoundRules.photoStartsPursuit("Investigating"))
        assert(not RoundRules.photoStartsPursuit("Roaming"))
    end },
}
local passed = 0
for _, case in cases do
    local ok, err = pcall(case[2])
    if not ok then error(case[1] .. ": " .. tostring(err)) end
    passed += 1
end
print("Hike or Die pure rules: " .. tostring(passed) .. " passed, 0 failed")
return passed
