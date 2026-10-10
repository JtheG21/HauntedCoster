--!strict
-- Minimal test runner. Synced to TestService.Tests by Rojo.
-- Run in Studio (Edit mode, command bar or Studio MCP):
--   require(game.TestService.Tests.TestRunner).run()
-- Each *.spec module returns function(t) and calls t.test(name, fn) / t.eq(actual, expected, msg?).

local TestRunner = {}

export type T = {
	test: (name: string, fn: () -> ()) -> (),
	eq: (actual: any, expected: any, msg: string?) -> (),
	truthy: (value: any, msg: string?) -> (),
}

function TestRunner.run(): (number, number)
	local passed, failed = 0, 0
	for _, child in script.Parent:GetChildren() do
		if child:IsA("ModuleScript") and child.Name:match("%.spec$") then
			local t: T = {
				test = function(name, fn)
					local ok, err = pcall(fn)
					if ok then
						passed += 1
					else
						failed += 1
						warn(`FAIL {child.Name} > {name}: {err}`)
					end
				end,
				eq = function(actual, expected, msg)
					if actual ~= expected then
						error(`{msg or "eq"}: expected {tostring(expected)}, got {tostring(actual)}`, 2)
					end
				end,
				truthy = function(value, msg)
					if not value then
						error(msg or "expected truthy value", 2)
					end
				end,
			}
			local ok, err = pcall(function()
				(require(child) :: any)(t)
			end)
			if not ok then
				failed += 1
				warn(`FAIL {child.Name} (load): {err}`)
			end
		end
	end
	print(`[TestRunner] {passed} passed, {failed} failed`)
	return passed, failed
end

return TestRunner
