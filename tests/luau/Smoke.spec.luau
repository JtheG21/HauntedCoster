--!strict
-- Confirms the test pipeline (Rojo sync + runner) works. Safe to keep.
return function(t)
	t.test("runner executes specs", function()
		t.eq(1 + 1, 2)
	end)
	t.test("shared modules are reachable", function()
		local ReplicatedStorage = game:GetService("ReplicatedStorage")
		t.truthy(ReplicatedStorage:FindFirstChild("Shared"), "ReplicatedStorage.Shared missing (is Rojo connected?)")
	end)
end
