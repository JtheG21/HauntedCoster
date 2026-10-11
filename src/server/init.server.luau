print("Hello world, from server!")

local StudioTestHook = require(script.Services.StudioTestHook)
StudioTestHook.start()

local CollectibleService = require(script.Services.CollectibleService)
CollectibleService.start()

local FactionService = require(script.Services.FactionService)
FactionService.start()

local PressurePlate = require(script.Components.PressurePlate)
PressurePlate.start()

local AbilityService = require(script.Services.AbilityService)
local Dash = require(script.Abilities.Dash)
local EchoClone = require(script.Abilities.EchoClone)
AbilityService.register("Dash", { handler = Dash.handler })
AbilityService.register("EchoClone", { handler = EchoClone.handler, canUse = FactionService.requires("Shinobi") })
EchoClone.start()
AbilityService.start()
