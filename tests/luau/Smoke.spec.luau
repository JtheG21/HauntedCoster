--!strict
-- Confirms the test pipeline (Rojo sync + runner) works. Safe to keep.
local TestRunner = require(script.Parent.TestRunner)

return function(t: TestRunner.T)
	t.test("runner executes specs", function()
		t.eq(1 + 1, 2)
	end)
	t.test("shared modules are reachable", function()
		local ReplicatedStorage = game:GetService("ReplicatedStorage")
		t.truthy(ReplicatedStorage:FindFirstChild("Shared"), "ReplicatedStorage.Shared missing (is Rojo connected?)")
	end)
end
