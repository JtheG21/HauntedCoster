--!strict
-- Always-on HUD: coins and income, save-status banner, objective, carry timer with home arrow,
-- area name, toasts and the main buttons.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local World = require(Config:WaitForChild("World"))
local Habitats = require(Config:WaitForChild("Habitats"))
local Economy = require(Config:WaitForChild("Economy"))
local Theme = require(script.Parent.Theme)
local State = require(script.Parent.Parent.State)

local Hud = {}

export type Callbacks = {
	openJournal: () -> (),
	openMansion: () -> (),
	openEditor: () -> (),
	toggleLight: () -> boolean,
}

local player = Players.LocalPlayer
local toastHolder: Frame
local editorButton: TextButton
local lightButton: TextButton? = nil

-- Keeps the Light button label in step however the light was toggled (button, F or DPadDown).
function Hud.setLight(on: boolean)
	if lightButton then
		lightButton.Text = if on then "Light: ON" else "Light: OFF"
	end
end

function Hud.toast(text: string, kind: string?)
	if not toastHolder then
		return
	end
	local color = if kind == "success"
		then Theme.Colors.good
		elseif kind == "error" then Theme.Colors.bad
		else Theme.Colors.text
	local f = Theme.panel(toastHolder, {
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 0.1,
	})
	Theme.pad(f, 8)
	local l = Theme.label(f, text, {
		TextColor3 = color,
		TextXAlignment = Enum.TextXAlignment.Center,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.fromScale(1, 0),
		TextSize = 17,
	})
	task.delay(5, function()
		if f.Parent then
			TweenService:Create(l, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
			TweenService:Create(f, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
			task.wait(0.45)
			f:Destroy()
		end
	end)
	-- Keep at most 4 toasts.
	local kids = {}
	for _, c in toastHolder:GetChildren() do
		if c:IsA("Frame") then
			table.insert(kids, c)
		end
	end
	if #kids > 4 then
		kids[1]:Destroy()
	end
end

local function zoneAt(pos: Vector3): string?
	local z = Habitats.zoneAt(pos.X, pos.Z)
	if z then
		return z.name .. (if z.dark then " (dark)" else "")
	end
	if World.inHub(pos.X, pos.Z) then
		return Habitats.active().name
	end
	return nil
end

function Hud.mount(gui: ScreenGui, cb: Callbacks)
	-- Coins
	local coinPanel = Theme.panel(gui, {
		Position = UDim2.fromOffset(12, 12),
		Size = UDim2.fromOffset(210, 62),
	})
	Theme.pad(coinPanel, 8)
	local coins = Theme.label(coinPanel, "Coins: 0", {
		Font = Theme.Bold,
		TextSize = 24,
		TextColor3 = Theme.Colors.gold,
		Size = UDim2.new(1, 0, 0, 26),
	})
	local income = Theme.label(coinPanel, "+0/s", {
		Position = UDim2.fromOffset(0, 26),
		TextSize = 14,
		TextColor3 = Theme.Colors.dim,
	})

	-- Persistence banner
	local banner = Theme.label(gui, "", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 6),
		Size = UDim2.fromOffset(520, 24),
		BackgroundTransparency = 0.2,
		BackgroundColor3 = Color3.fromRGB(120, 40, 30),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextSize = 14,
		Visible = false,
	})
	Theme.corner(banner, 6)

	-- Objective
	local obj = Theme.panel(gui, {
		Position = UDim2.fromOffset(12, 84),
		Size = UDim2.fromOffset(290, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	})
	Theme.pad(obj, 10)
	Theme.list(obj, 4)
	local objTitle = Theme.label(obj, "Objective", {
		Font = Theme.Title,
		TextSize = 22,
		TextColor3 = Theme.Colors.gold,
		LayoutOrder = 1,
	})
	local objText = Theme.label(obj, "", {
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.fromScale(1, 0),
		TextSize = 15,
		LayoutOrder = 2,
	})

	-- Carry timer + home arrow
	local carry = Theme.panel(gui, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 36),
		Size = UDim2.fromOffset(360, 74),
		Visible = false,
	})
	Theme.pad(carry, 8)
	local carryText = Theme.label(carry, "", {
		Font = Theme.Bold,
		TextSize = 17,
		TextXAlignment = Enum.TextXAlignment.Center,
	})
	local barBack = Theme.frame(carry, {
		Position = UDim2.fromOffset(0, 26),
		Size = UDim2.new(1, 0, 0, 10),
		BackgroundColor3 = Color3.fromRGB(50, 40, 60),
	})
	Theme.corner(barBack, 5)
	local bar = Theme.frame(barBack, { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Colors.good })
	Theme.corner(bar, 5)
	local homeText = Theme.label(carry, "", {
		Position = UDim2.fromOffset(0, 40),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextSize = 15,
		TextColor3 = Theme.Colors.clue,
	})
	local arrow = Theme.label(gui, "^", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(60, 60),
		Font = Theme.Bold,
		TextSize = 54,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextColor3 = Theme.Colors.gold,
		TextStrokeTransparency = 0.2,
		Visible = false,
	})

	-- Area name
	local area = Theme.label(gui, "", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 120),
		Size = UDim2.fromOffset(400, 40),
		Font = Theme.Title,
		TextSize = 34,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextColor3 = Theme.Colors.text,
		TextStrokeTransparency = 0.4,
		TextTransparency = 1,
		TextStrokeColor3 = Color3.new(0, 0, 0),
	})

	-- Toasts
	toastHolder = Theme.frame(gui, {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -76),
		Size = UDim2.fromOffset(460, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	})
	local tl = Theme.list(toastHolder, 6)
	tl.VerticalAlignment = Enum.VerticalAlignment.Bottom

	-- Buttons
	local bar2 = Theme.frame(gui, {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -12, 1, -12),
		Size = UDim2.fromOffset(0, 48),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
	})
	local bl = Theme.list(bar2, 8, true)
	bl.HorizontalAlignment = Enum.HorizontalAlignment.Right
	lightButton = Theme.button(bar2, "Light: ON", function()
		Hud.setLight(cb.toggleLight())
	end, { Size = UDim2.fromOffset(104, 48), LayoutOrder = 1 })
	Theme.button(bar2, "Journal", cb.openJournal, { Size = UDim2.fromOffset(104, 48), LayoutOrder = 2 })
	Theme.button(bar2, "Mansion", cb.openMansion, { Size = UDim2.fromOffset(104, 48), LayoutOrder = 3 })
	editorButton = Theme.button(bar2, "Edit Track", cb.openEditor, {
		Size = UDim2.fromOffset(110, 48),
		LayoutOrder = 4,
		Visible = false,
		BackgroundColor3 = Color3.fromRGB(150, 70, 120),
	})

	local function render(snap: { [string]: any })
		coins.Text = `Coins: {Theme.fmt(snap.coins or 0)}`
		local rate = snap.incomeRate or 0
		income.Text = string.format("+%.1f/s from %d monsters", rate, #(snap.owned or {}))
		local p = snap.persistence
		banner.Visible = p == "memory" or p == "readonly"
		banner.Text = if p == "memory"
			then "Test mode: DataStores unavailable, progress is NOT saved"
			elseif p == "readonly" then "Your save couldn't be loaded safely; progress this session won't be saved"
			else ""
		local tut = snap.tutorial
		if tut then
			objTitle.Text = if tut.step <= tut.total then `Objective {tut.step}/{tut.total}` else "Objective"
			objText.Text = tut.hint
		end
		local tier = Economy.HouseTiers[(snap.houseTier or 0) + 1]
		editorButton.Visible = tier ~= nil and tier.unlocksEditor
	end
	State.Changed:Connect(render)
	if State.snap then
		render(State.snap)
	end

	local lastZone: string? = nil
	RunService.RenderStepped:Connect(function()
		local snap = State.snap
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		-- Carry timer and home arrow
		local c = snap and snap.carrying
		if c and root then
			local left = math.max(0, c.deadline - Workspace:GetServerTimeNow())
			carry.Visible = true
			carryText.Text = string.format(
				"Carrying %s%s: %ds",
				if c.variantLabel then c.variantLabel .. " " else "",
				c.name,
				math.ceil(left)
			)
			local frac = math.clamp(left / c.returnSeconds, 0, 1)
			bar.Size = UDim2.fromScale(frac, 1)
			bar.BackgroundColor3 = if frac < 0.3 then Theme.Colors.bad else Theme.Colors.good
			local idx = snap and snap.plotIndex
			if idx then
				local home = World.plotToWorld(idx, World.Plot.pen)
				local dist = (Vector3.new(home.X, 0, home.Z) - Vector3.new(root.Position.X, 0, root.Position.Z)).Magnitude
				homeText.Text = `Home pen: {math.floor(dist)} studs (follow your beacon)`
				local cam = Workspace.CurrentCamera
				if cam then
					local look = cam.CFrame.LookVector
					local toHome = home - root.Position
					local a1 = math.atan2(look.X, look.Z)
					local a2 = math.atan2(toHome.X, toHome.Z)
					local rel = a1 - a2
					arrow.Visible = true
					arrow.Position = UDim2.new(0.5, math.sin(rel) * 110, 0.5, -math.cos(rel) * 110)
					arrow.Rotation = math.deg(rel)
				end
			end
		elseif snap and snap.chase and root then
			-- Escaped capture: countdown and an arrow to the monster instead of home (Round 20 Q1).
			local ch = snap.chase
			local left = math.max(0, ch.deadline - Workspace:GetServerTimeNow())
			carry.Visible = true
			carryText.Text = string.format("It broke free! Catch the %s: %ds", ch.name, math.ceil(left))
			bar.Size = UDim2.fromScale(math.clamp(left / ch.seconds, 0, 1), 1)
			bar.BackgroundColor3 = Theme.Colors.bad
			local m = ch.monster
			local target = if typeof(m) == "Instance" and m:IsA("Model") and m.PrimaryPart then m.PrimaryPart else nil
			local cam = Workspace.CurrentCamera
			if target and cam then
				local to = target.Position - root.Position
				homeText.Text =
					`{math.floor(Vector3.new(to.X, 0, to.Z).Magnitude)} studs away. Get close and press E to grab it`
				local look = cam.CFrame.LookVector
				local rel = math.atan2(look.X, look.Z) - math.atan2(to.X, to.Z)
				arrow.Visible = true
				arrow.Position = UDim2.new(0.5, math.sin(rel) * 110, 0.5, -math.cos(rel) * 110)
				arrow.Rotation = math.deg(rel)
			else
				arrow.Visible = false
			end
		else
			carry.Visible = false
			arrow.Visible = false
		end
		-- Area name banner
		if root then
			local z = zoneAt(root.Position)
			if z ~= lastZone then
				lastZone = z
				if z then
					area.Text = z
					area.TextTransparency = 0
					area.TextStrokeTransparency = 0.4
					task.delay(2.5, function()
						if area.Text == z then
							TweenService
								:Create(area, TweenInfo.new(0.8), { TextTransparency = 1, TextStrokeTransparency = 1 })
								:Play()
						end
					end)
				end
			end
		end
	end)
end

return Hud
