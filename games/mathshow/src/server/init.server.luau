--!strict
-- GAME-004 MathShow: server entry point. Starts services in dependency order.
local Services = script.Services

local LeaderstatsService = require(Services.LeaderstatsService)
local ProfileService = require(Services.ProfileService)
local BlitzService = require(Services.BlitzService)
local SkillTestService = require(Services.SkillTestService)
local RoundService = require(Services.RoundService)

LeaderstatsService.start()
ProfileService.start()
SkillTestService.start()
BlitzService.start()
RoundService.start()

print("[MathShow] server ready")
