--!strict
-- Studio-only test hook (same pattern as GAME-001 TASK-0009). When a play test is started with
-- StudioTestService:ExecutePlayModeAsync({ scenario = "Name" }) (or the multiplayer variant), this runs
-- TestService.Tests.scenarios.<Name> on the server and ends the test with its result.
-- It does nothing in live servers or in normal Studio play sessions.

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local TestService = game:GetService("TestService")

local StudioTestHook = {}

local started = false

-- A named play-test argument, in Studio test runs only (nil in live servers and normal play). Used to pick
-- the starting habitat: ExecutePlayModeAsync({ scenario = "Reachability", habitat = "Woodland" }).
function StudioTestHook.arg(name: string): any
	if not RunService:IsStudio() or not RunService:IsServer() then
		return nil
	end
	local ok, args = pcall(function()
		return game:GetService("StudioTestService"):GetTestArgs()
	end)
	if ok and typeof(args) == "table" then
		return (args :: any)[name]
	end
	return nil
end

function StudioTestHook.start()
	if started or not RunService:IsStudio() or not RunService:IsServer() then
		return
	end
	started = true
	local studioTestService = game:GetService("StudioTestService")
	local ok, args = pcall(function()
		return studioTestService:GetTestArgs()
	end)
	if not ok or typeof(args) ~= "table" or typeof(args.scenario) ~= "string" then
		return
	end
	task.spawn(function()
		local tests = TestService:WaitForChild("Tests", 10)
		local scenarios = tests and tests:FindFirstChild("scenarios")
		local module = scenarios and scenarios:FindFirstChild(args.scenario)
		local result: any
		if module and module:IsA("ModuleScript") then
			local success, value = pcall(function()
				return (require(module) :: any)(args)
			end)
			result = if success then value else { ok = false, error = tostring(value) }
		else
			result = { ok = false, error = `unknown scenario '{args.scenario}'` }
		end
		local encoded = HttpService:JSONEncode(result)
		print(`[StudioTestHook] {args.scenario} result {encoded}`)
		studioTestService:EndTest(result)
	end)
end

return StudioTestHook
