-- Temporary client observer used only by CodexReplication, never shipped.
local RS = game:GetService("ReplicatedStorage")
local deadline = os.clock() + 160
while not workspace:GetAttribute("CodexOwnerPlot") and os.clock() < deadline do task.wait(0.5) end
local index = workspace:GetAttribute("CodexOwnerPlot")
local result = { ok = false }
if index then
	deadline = os.clock() + 35
	repeat
		local plot = workspace:FindFirstChild("Plots") and workspace.Plots:FindFirstChild("Plot" .. tostring(index))
		local looks, rendered = 0, 0
		if plot then
			for _,v in plot:GetDescendants() do
				if v:IsA("Model") and v:GetAttribute("SkinId") == "SkinMoss" and v:GetAttribute("AuraId") == "AuraEmbers" then
					looks += 1
					if v:FindFirstChild("CreatureArt") then rendered += 1 end
				end
			end
		end
		local anchor = plot and plot:FindFirstChild("House") and plot.House:FindFirstChild("HouseArt")
		local theme = anchor and anchor:GetAttribute("Tint_Walls") ~= nil
		result = { ok = looks >= 1 and rendered >= 1 and theme == true, equippedModels = looks, renderedModels = rendered, themedHouse = theme == true }
		if result.ok then break end
		task.wait(0.5)
	until os.clock() >= deadline
end
RS:WaitForChild("CodexObserverResult", 10):FireServer(result)
