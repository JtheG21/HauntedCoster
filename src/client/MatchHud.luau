--!strict
-- Client match HUD (TASK-0006): phase banner with countdown, the onboarding prompt, and the last
-- results line. Display only; reads server-published attributes.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local MatchHud = {}

local PHASE_TEXT = {
	Lobby = "Lobby: waiting for players",
	Countdown = "Match starts in %d",
	Course = "Race to the finish! %d s left",
	Finale = "Finale! %d s",
	Results = "Results",
}

function MatchHud.start()
	local player = Players.LocalPlayer
	local gui = Instance.new("ScreenGui")
	gui.Name = "MatchHud"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false

	local banner = Instance.new("TextLabel")
	banner.Name = "Banner"
	banner.AnchorPoint = Vector2.new(0.5, 0)
	banner.Position = UDim2.new(0.5, 0, 0, 8)
	banner.Size = UDim2.fromOffset(420, 36)
	banner.BackgroundTransparency = 0.35
	banner.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	banner.TextColor3 = Color3.new(1, 1, 1)
	banner.TextScaled = true
	banner.Font = Enum.Font.GothamBold
	banner.Parent = gui

	local prompt = banner:Clone()
	prompt.Name = "Prompt"
	prompt.Position = UDim2.new(0.5, 0, 0, 50)
	prompt.Size = UDim2.fromOffset(460, 44)
	prompt.BackgroundColor3 = Color3.fromRGB(240, 170, 40)
	prompt.TextColor3 = Color3.fromRGB(20, 20, 30)
	prompt.Parent = gui

	gui.Parent = player:WaitForChild("PlayerGui")

	local accumulated = 0
	RunService.Heartbeat:Connect(function(dt)
		accumulated += dt
		if accumulated < 0.2 then
			return
		end
		accumulated = 0
		local state = ReplicatedStorage:GetAttribute("MatchState")
		local endsAt = ReplicatedStorage:GetAttribute("PhaseEndsAt")
		local remaining = if typeof(endsAt) == "number"
			then math.max(0, math.ceil(endsAt - Workspace:GetServerTimeNow()))
			else 0
		local template = if typeof(state) == "string" then PHASE_TEXT[state] else nil
		local text = if template then string.format(template, remaining) else "..."
		if state == "Results" then
			-- The ResultsHud panel shows the categories; the banner only falls back to the summary line.
			local results = ReplicatedStorage:GetAttribute("LastResults")
			local hasPanel = ReplicatedStorage:GetAttribute("Result_Combat") ~= nil
			text = if hasPanel or typeof(results) ~= "string" then text else "Results: " .. results
		elseif state ~= "Lobby" and state ~= "Countdown" and player:GetAttribute("InMatch") ~= true then
			text = "Match in progress: you'll join the next one"
		end
		banner.Text = text

		local trialPrompt = player:GetAttribute("TrialPrompt")
		prompt.Visible = typeof(trialPrompt) == "string"
		if prompt.Visible then
			prompt.Text = "Try your power: " .. (trialPrompt :: string)
		end
	end)
end

return MatchHud
