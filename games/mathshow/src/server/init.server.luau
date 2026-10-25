--!strict
-- GAME-004 MathShow: server entry point. Starts services in dependency order.
local Services = script.Services

local RoundService = require(Services.RoundService)

RoundService.start()

print("[MathShow] server ready")
