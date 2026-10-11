print("Hello world, from server!")

local CollectibleService = require(script.Services.CollectibleService)
CollectibleService.start()

local AbilityService = require(script.Services.AbilityService)
local Dash = require(script.Abilities.Dash)
AbilityService.register("Dash", { handler = Dash.handler })
AbilityService.start()
