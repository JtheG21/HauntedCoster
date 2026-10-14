--!strict
-- Inspect card (rarity, value, variant) and the reusable capture meter.
-- The meter only draws the needle; the server times and judges every CATCH press.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Monsters = require(Shared:WaitForChild("Config"):WaitForChild("Monsters"))
local CaptureRules = require(Shared:WaitForChild("Rules"):WaitForChild("CaptureRules"))
local SoundBank = require(Shared:WaitForChild("Config"):WaitForChild("SoundBank"))
local Sfx = require(script.Parent.Parent.Sfx)
local Theme = require(script.Parent.Theme)
local State = require(script.Parent.Parent.State)

local CaptureUI = {}

local player = Players.LocalPlayer
local toast: (string, string?) -> () = function(_text: string, _kind: string?) end

local card: Frame
local cardTitle: TextLabel
local cardBody: TextLabel
local cardLock: TextLabel
local tryButton: TextButton
local currentMonster: Model? = nil

local meter: Frame
local meterTitle: TextLabel
local meterInfo: TextLabel
local zone: Frame
local needle: Frame
local catchButton: TextButton
local active: { [string]: any }? = nil
local meterStart = 0
local busy = false

local function closeCard()
	card.Visible = false
	currentMonster = nil
end

local function closeMeter()
	meter.Visible = false
	active = nil
	ContextActionService:UnbindAction("HauntedCatch")
end

local function setZone(center: number, nominalWidth: number, period: number)
	local width = CaptureRules.judgedWidth(nominalWidth, period, CaptureRules.LatencySlack)
	zone.Position = UDim2.fromScale(center - width / 2, 0)
	zone.Size = UDim2.fromScale(width, 1)
end

local function pips(): string
	local a = active
	if not a then
		return ""
	end
	return string.format(
		"Hits %d/%d   Misses left %d   (Space / tap CATCH / A)",
		a.hits,
		a.hitsNeeded,
		a.missesAllowed - a.misses
	)
end

local function flash(color: Color3)
	meter.BackgroundColor3 = color
	task.delay(0.15, function()
		meter.BackgroundColor3 = Theme.Colors.panel
	end)
end

local function release()
	local a = active
	if not a or busy then
		return
	end
	busy = true
	local result = State.invoke("CaptureRelease")
	busy = false
	if not active or type(result) ~= "table" then
		return
	end
	if result.outcome == "hit" then
		a.hits = result.hits
		flash(Theme.Colors.good)
		if type(result.zoneCenter) == "number" then
			setZone(result.zoneCenter, a.zoneWidth, a.period)
		end
	elseif
		-- A miss closes the session too: the monster was startled and hopped away (Round 20 Q2). The
		-- CaptureEnded event carries the toast, since it can arrive before this reply.
		result.outcome == "miss"
		or result.outcome == "success"
		or result.outcome == "fled"
		or result.outcome == "cancelled"
	then
		closeMeter()
		return
	end
	meterInfo.Text = pips()
end

local function startCapture()
	local monster = currentMonster
	if not monster then
		return
	end
	local result = State.invoke("CaptureStart", monster)
	if type(result) ~= "table" then
		return
	end
	if not result.ok then
		toast(result.reason or "Can't capture", "error")
		return
	end
	closeCard()
	Sfx.play("capture_start")
	active = {
		period = result.period,
		zoneWidth = result.zoneWidth,
		hitsNeeded = result.hitsNeeded,
		missesAllowed = result.missesAllowed,
		-- Hits and misses carry over from earlier attempts on the same monster.
		hits = result.hits or 0,
		misses = result.misses or 0,
	}
	meterStart = os.clock()
	setZone(result.zoneCenter, result.zoneWidth, result.period)
	meterTitle.Text = string.format(
		"Capturing %s%s (%s)",
		if result.variantLabel then result.variantLabel .. " " else "",
		result.name,
		result.rarity
	)
	meterTitle.TextColor3 = Monsters.RarityColor[(result.rarity :: any) :: Monsters.Rarity] or Theme.Colors.text
	meterInfo.Text = pips()
	meter.Visible = true
	ContextActionService:BindActionAtPriority(
		"HauntedCatch",
		function(_, inputState)
			if inputState == Enum.UserInputState.Begin then
				task.spawn(release)
			end
			return Enum.ContextActionResult.Sink
		end,
		false,
		Enum.ContextActionPriority.High.Value + 10,
		Enum.KeyCode.Space,
		Enum.KeyCode.ButtonA,
		Enum.KeyCode.ButtonR2
	)
end

local function showCard(info: { [string]: any })
	currentMonster = info.monster
	local rarity: Monsters.Rarity = (info.rarity :: any) :: Monsters.Rarity
	cardTitle.Text = (if info.variantLabel then info.variantLabel .. " " else "") .. info.name
	cardTitle.TextColor3 = Monsters.RarityColor[rarity] or Theme.Colors.text
	local lines = {
		`{info.family}  ·  {rarity}{if info.variantLabel then "  ·  VARIANT" else ""}`,
		string.format("Est. value: %.1f coins/s at home (or a train exhibit bonus)", info.income),
		`Capture: {info.hitsNeeded} hit(s) needed  ·  Return home in {info.returnSeconds}s`,
		info.blurb,
	}
	cardBody.Text = table.concat(lines, "\n")
	local lock = info.locked or (if info.claimed then "Someone else is capturing it." else nil)
	cardLock.Text = lock or ""
	cardLock.Visible = lock ~= nil
	Theme.setEnabled(tryButton, lock == nil)
	card.Visible = true
end

function CaptureUI.mount(gui: ScreenGui, toastFn: (string, string?) -> ())
	toast = toastFn
	card = Theme.panel(gui, {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -16, 0.45, 0),
		Size = UDim2.fromOffset(330, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Visible = false,
	})
	Theme.pad(card, 12)
	Theme.list(card, 8)
	cardTitle =
		Theme.label(card, "", { Font = Theme.Title, TextSize = 28, Size = UDim2.new(1, 0, 0, 32), LayoutOrder = 1 })
	cardBody = Theme.label(card, "", {
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.fromScale(1, 0),
		TextSize = 15,
		LayoutOrder = 2,
	})
	cardLock = Theme.label(card, "", {
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.fromScale(1, 0),
		TextColor3 = Theme.Colors.bad,
		LayoutOrder = 3,
	})
	local row = Theme.frame(card, { Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1, LayoutOrder = 4 })
	Theme.list(row, 8, true)
	tryButton = Theme.button(row, "Try Capture", function()
		if tryButton.Active then
			startCapture()
		end
	end, { Size = UDim2.fromOffset(170, 44), BackgroundColor3 = Theme.Colors.button })
	Theme.button(
		row,
		"Close",
		closeCard,
		{ Size = UDim2.fromOffset(110, 44), BackgroundColor3 = Theme.Colors.buttonOff }
	)

	meter = Theme.panel(gui, {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -150),
		Size = UDim2.fromOffset(460, 170),
		Visible = false,
	})
	Theme.pad(meter, 12)
	meterTitle = Theme.label(meter, "", {
		Font = Theme.Title,
		TextSize = 26,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.new(1, 0, 0, 28),
	})
	local track = Theme.frame(meter, {
		Position = UDim2.fromOffset(0, 36),
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundColor3 = Color3.fromRGB(45, 35, 60),
	})
	Theme.corner(track, 6)
	zone = Theme.frame(track, { BackgroundColor3 = Theme.Colors.good, BackgroundTransparency = 0.15 })
	Theme.corner(zone, 6)
	needle = Theme.frame(track, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.new(0, 6, 1, 12),
		Position = UDim2.fromScale(0, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		ZIndex = 3,
	})
	Theme.corner(needle, 3)
	meterInfo = Theme.label(meter, "", {
		Position = UDim2.fromOffset(0, 72),
		TextSize = 14,
		TextColor3 = Theme.Colors.dim,
		TextXAlignment = Enum.TextXAlignment.Center,
	})
	catchButton = Theme.button(meter, "CATCH!", function()
		task.spawn(release)
	end, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, -50, 0, 100),
		Size = UDim2.fromOffset(220, 50),
		TextSize = 24,
		BackgroundColor3 = Color3.fromRGB(170, 60, 90),
	})
	local _giveUp = Theme.button(meter, "Give up", function()
		(State.remote("CaptureCancel") :: RemoteEvent):FireServer()
		closeMeter()
	end, {
		AnchorPoint = Vector2.new(0, 0),
		Position = UDim2.new(0.5, 76, 0, 100),
		Size = UDim2.fromOffset(100, 50),
		BackgroundColor3 = Theme.Colors.buttonOff,
	})
	local inspectEvent = State.remote("Inspect") :: RemoteEvent
	inspectEvent.OnClientEvent:Connect(function(info)
		if type(info) == "table" and not active then
			showCard(info)
		end
	end)
	local endedEvent = State.remote("CaptureEnded") :: RemoteEvent
	endedEvent.OnClientEvent:Connect(function(info)
		if type(info) == "table" then
			local role = SoundBank.captureEndRole(info.result)
			if role then
				Sfx.play(role)
			end
		end
		if type(info) == "table" and info.result == "timeout" then
			toast("You hesitated too long and it wandered off.", "error")
		elseif type(info) == "table" and info.result == "startled" then
			local left = if type(info.missesLeft) == "number" then info.missesLeft else 0
			toast(
				`Missed! It darted away. Walk up and Inspect (R) to try again ({left} miss{if left == 1
					then ""
					else "es"} left).`,
				"error"
			)
		end
		closeMeter()
	end)

	RunService.RenderStepped:Connect(function()
		local a = active
		if a then
			needle.Position = UDim2.fromScale(CaptureRules.needle(os.clock() - meterStart, a.period), 0.5)
		end
		-- Close the card when the monster is gone or far away.
		if card.Visible then
			local m = currentMonster
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if
				not m
				or not m.Parent
				or not m.PrimaryPart
				or not root
				or (root.Position - m.PrimaryPart.Position).Magnitude > 30
			then
				closeCard()
			end
		end
	end)
	local _ = catchButton
end

return CaptureUI
