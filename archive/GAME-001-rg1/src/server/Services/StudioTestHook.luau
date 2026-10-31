--!strict
-- Studio-only multi-client test hook (TASK-0009).
-- When a test is launched with StudioTestService:ExecuteMultiplayerTestAsync(n, { scenario = "Name" }),
-- this runs TestService.Tests.multiclient.<Name> on the server and ends the test with its result.
-- It does nothing in live servers, or in Studio sessions started without test args.

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local TestService = game:GetService("TestService")

local StudioTestHook = {}

function StudioTestHook.start()
	if not RunService:IsStudio() or not RunService:IsServer() then
		return
	end
	local studioTestService = game:GetService("StudioTestService")
	local ok, args = pcall(function()
		return studioTestService:GetTestArgs()
	end)
	if not ok or typeof(args) ~= "table" or typeof(args.scenario) ~= "string" then
		return
	end

	task.spawn(function()
		local tests = TestService:WaitForChild("Tests", 10)
		local scenarios = tests and tests:FindFirstChild("multiclient")
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
		print(`[StudioTestHook] {args.scenario} result {HttpService:JSONEncode(result)}`)
		studioTestService:EndTest(result)
	end)
end

return StudioTestHook
