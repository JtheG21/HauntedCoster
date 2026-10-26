--!strict
-- GAME-004 MathShow: server entry point. Starts services in dependency order.
local Services = script.Services

local LeaderstatsService = require(Services.LeaderstatsService)
local RoundService = require(Services.RoundService)

LeaderstatsService.start()
RoundService.start()

print("[MathShow] server ready")
