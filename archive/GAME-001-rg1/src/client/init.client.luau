print("Hello world, from client!")

local AbilityInput = require(script.AbilityInput)
AbilityInput.start()

local GateHud = require(script.GateHud)
GateHud.start()

local MatchHud = require(script.MatchHud)
MatchHud.start()

local ResultsHud = require(script.ResultsHud)
ResultsHud.start()
