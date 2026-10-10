print("Hello world, from server!")

local StudioTestHook = require(script.Services.StudioTestHook)
StudioTestHook.start()

local CollectibleService = require(script.Services.CollectibleService)
CollectibleService.start()
