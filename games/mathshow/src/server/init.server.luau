--!strict
-- GAME-004 MathShow: server entry point. Starts services in dependency order.
local Services = script.Services
local StudioTestHook = require(script.StudioTestHook)

local LeaderstatsService = require(Services.LeaderstatsService)
local ProfileService = require(Services.ProfileService)
local BlitzService = require(Services.BlitzService)
local VsService = require(Services.VsService)
local SkillTestService = require(Services.SkillTestService)
local RoundService = require(Services.RoundService)

LeaderstatsService.start()
ProfileService.start()
SkillTestService.start()
BlitzService.start()
VsService.start()
RoundService.start()

StudioTestHook.start() -- Studio multi-client test scenarios only (tests/multiclient); inert otherwise

print("[MathShow] server ready")
