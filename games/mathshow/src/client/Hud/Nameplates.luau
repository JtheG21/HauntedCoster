--!strict
-- Nameplates (TASK-0151): an overhead "LV 12 · QUICK COUNTER" plate on every character, drawn by this client from the
-- server-set Player attributes Level, Title and PlateColor (QuestService, TASK-0150). Client-only and one-way: it sends
-- nothing and trusts nothing beyond the attribute types. No Level attribute yet = no plate. Cosmetic: every build and
-- update is pcall-isolated, warns once per failure and leaves the character untouched.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local MenuCopy = require(Shared:WaitForChild("MenuCopy"))

local HudTheme = require(script.Parent.Theme)
local MenuTheme = require(script.Parent.Parent.Menu.MenuTheme)

local Nameplates = {}

local PLATE_NAME = "MathShowNameplate"
local NP = MenuTheme.Nameplate

local started = false
local tracked: { [Player]: { RBXScriptConnection } } = {}

local function safe(what: string, fn: () -> ())
	local ok, err = pcall(function()
		fn()
	end)
	if not ok then
		warn(`[MathShow] Nameplate {what} failed: {err}`)
	end
end

local function plateText(player: Player): string?
	local level = player:GetAttribute("Level")
	if typeof(level) ~= "number" or level ~= level or level < 1 then
		return nil
	end
	local text = string.gsub(MenuCopy.Quests.Level, "{level}", tostring(math.floor(level)))
	local title = player:GetAttribute("Title")
	if typeof(title) == "string" and title ~= "" then
		text = `{text} · {string.upper(title)}`
	end
	return text
end

local function plateColor(player: Player): Color3
	local color = player:GetAttribute("PlateColor")
	return if typeof(color) == "Color3" then color else NP.Default
end

-- Builds, updates or removes the plate on the player's current character.
local function refresh(player: Player)
	safe("refresh", function()
		local character = player.Character
		local head = if character then character:FindFirstChild("Head") else nil
		if not character or not head or not head:IsA("BasePart") then
			return
		end
		local existing = character:FindFirstChild(PLATE_NAME)
		local str = plateText(player)
		if str == nil then
			if existing then
				existing:Destroy()
			end
			return
		end
		local gui: BillboardGui
		local label: TextLabel
		if existing and existing:IsA("BillboardGui") and existing:FindFirstChild("Label") then
			gui = existing
			label = existing:FindFirstChild("Label") :: TextLabel
		else
			if existing then
				existing:Destroy()
			end
			gui = Instance.new("BillboardGui")
			gui.Name = PLATE_NAME
			gui.Size = UDim2.fromOffset(NP.Width, NP.Height)
			gui.StudsOffset = NP.StudsOffset
			gui.MaxDistance = NP.MaxDistance
			gui.LightInfluence = 0
			gui.AlwaysOnTop = false
			gui.ResetOnSpawn = false
			gui.Adornee = head
			label = Instance.new("TextLabel")
			label.Name = "Label"
			label.BackgroundTransparency = 1
			label.Size = UDim2.fromScale(1, 1)
			label.FontFace = HudTheme.Font.Body
			label.TextSize = NP.TextSize
			label.TextStrokeColor3 = HudTheme.Color.Tag
			label.TextStrokeTransparency = NP.StrokeTransparency
			label.TextXAlignment = Enum.TextXAlignment.Center
			label.TextTruncate = Enum.TextTruncate.AtEnd
			label.Parent = gui
			gui.Parent = character -- a child of the character, so it goes with it on respawn
		end
		gui.Adornee = head
		label.Text = str
		label.TextColor3 = plateColor(player)
	end)
end

local function track(player: Player)
	if tracked[player] then
		return
	end
	local connections: { RBXScriptConnection } = {}
	tracked[player] = connections
	local function onCharacter(character: Model)
		safe("character", function()
			character:WaitForChild("Head", 10)
			refresh(player)
		end)
	end
	table.insert(connections, player.CharacterAdded:Connect(onCharacter))
	for _, name in { "Level", "Title", "PlateColor" } do
		table.insert(
			connections,
			player:GetAttributeChangedSignal(name):Connect(function()
				refresh(player)
			end)
		)
	end
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end
end

local function untrack(player: Player)
	local connections = tracked[player]
	tracked[player] = nil
	if connections then
		for _, c in connections do
			c:Disconnect()
		end
	end
end

function Nameplates.start()
	if started then
		return
	end
	started = true
	safe("start", function()
		Players.PlayerAdded:Connect(track)
		Players.PlayerRemoving:Connect(untrack)
		for _, player in Players:GetPlayers() do
			track(player)
		end
	end)
end

return Nameplates
