--!strict
-- Client finale and results HUD (TASK-0007). Display only; reads server-published attributes.
--   Finale:  players left, your status (in / out / guard up) and your Echo charges with their keys
--   Results: one row per category (Speed, Teamwork, Combat)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ResultsHud = {}

local CATEGORIES = { "Speed", "Teamwork", "Combat" }

local function label(parent: Instance, name: string, position: UDim2, size: UDim2): TextLabel
	local text = Instance.new("TextLabel")
	text.Name = name
	text.AnchorPoint = Vector2.new(0.5, 0)
	text.Position = position
	text.Size = size
	text.BackgroundTransparency = 0.35
	text.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	text.TextColor3 = Color3.new(1, 1, 1)
	text.TextScaled = true
	text.Font = Enum.Font.GothamBold
	text.Parent = parent
	return text
end

function ResultsHud.start()
	local player = Players.LocalPlayer
	local gui = Instance.new("ScreenGui")
	gui.Name = "ResultsHud"
	gui.ResetOnSpawn = false

	local status = label(gui, "FinaleStatus", UDim2.new(0.5, 0, 0, 50), UDim2.fromOffset(460, 36))
	local echoes = label(gui, "Echoes", UDim2.new(0.5, 0, 0, 92), UDim2.fromOffset(460, 30))

	local panel = Instance.new("Frame")
	panel.Name = "Results"
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.45)
	panel.Size = UDim2.fromOffset(420, 150)
	panel.BackgroundTransparency = 1
	panel.Parent = gui
	local rows: { [string]: TextLabel } = {}
	for i, category in CATEGORIES do
		rows[category] = label(panel, category, UDim2.new(0.5, 0, 0, (i - 1) * 50), UDim2.fromOffset(420, 44))
	end

	gui.Parent = player:WaitForChild("PlayerGui")

	local accumulated = 0
	RunService.Heartbeat:Connect(function(dt)
		accumulated += dt
		if accumulated < 0.2 then
			return
		end
		accumulated = 0
		local state = ReplicatedStorage:GetAttribute("MatchState")
		local inMatch = player:GetAttribute("InMatch") == true

		local inFinale = state == "Finale" and inMatch
		status.Visible = inFinale
		echoes.Visible = false
		if inFinale then
			local remaining = ReplicatedStorage:GetAttribute("FinaleRemaining")
			local left = if typeof(remaining) == "number" then `{remaining} left` else ""
			if player:GetAttribute("FinaleAlive") == false then
				status.Text = `You're out! {left}`
			elseif player:GetAttribute("FinaleGuard") == true then
				status.Text = `Guard up: the next hit is absorbed. {left}`
			else
				status.Text = `Knock your rivals off! {left}`
			end
			local ki = player:GetAttribute("Echo_Ki")
			local shinobi = player:GetAttribute("Echo_Shinobi")
			local parts = {}
			if typeof(ki) == "number" and ki > 0 then
				table.insert(parts, `Echo Ki x{ki} [G]`)
			end
			if typeof(shinobi) == "number" and shinobi > 0 then
				table.insert(parts, `Echo Guard x{shinobi} [V]`)
			end
			echoes.Visible = #parts > 0 and player:GetAttribute("FinaleAlive") == true
			echoes.Text = table.concat(parts, "   ")
		end

		local showResults = state == "Results" and ReplicatedStorage:GetAttribute("Result_Combat") ~= nil
		panel.Visible = showResults
		if showResults then
			for _, category in CATEGORIES do
				local value = ReplicatedStorage:GetAttribute(`Result_{category}`)
				rows[category].Text = `{category}: {if typeof(value) == "string" then value else "-"}`
			end
		end
	end)
end

return ResultsHud
