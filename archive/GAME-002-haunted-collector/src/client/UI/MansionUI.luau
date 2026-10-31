--!strict
-- Mansion menu: house tiers and speed upgrades, owned monster roster, and exhibit slots.

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local Economy = require(Config:WaitForChild("Economy"))
local Monsters = require(Config:WaitForChild("Monsters"))
local Variants = require(Config:WaitForChild("Variants"))
local EconomyRules = require(ReplicatedStorage.Shared:WaitForChild("Rules"):WaitForChild("EconomyRules"))
local Theme = require(script.Parent.Theme)
local State = require(script.Parent.Parent.State)

local MansionUI = {}

-- Set by the client entry point so the Mansion can open the Shop without requiring it.
MansionUI.openShop = function() end

local panel: Frame
local content: ScrollingFrame
local tab = "Upgrades"
local toast: (string, string?) -> () = function(_text: string, _kind: string?) end
local tabButtons: { [string]: TextButton } = {}

local function clear()
	for _, c in content:GetChildren() do
		if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then
			c:Destroy()
		end
	end
end

local function row(height: number?): Frame
	local f = Theme.frame(content, {
		Size = UDim2.new(1, 0, 0, height or 0),
		AutomaticSize = if height then Enum.AutomaticSize.None else Enum.AutomaticSize.Y,
		BackgroundColor3 = Theme.Colors.panel2,
	})
	Theme.corner(f, 8)
	Theme.pad(f, 8)
	return f
end

local function nameOf(m: { [string]: any }): string
	local species = Monsters.Species[m.species]
	local label = Variants.label(m.variant)
	return (if label then label .. " " else "") .. (if species then species.name else m.species)
end

local function exhibitSlotOf(snap: { [string]: any }, uid: string): number?
	for _, e in snap.exhibits or {} do
		if e.uid == uid then
			return e.slot
		end
	end
	return nil
end

local buying = false

local function buy(item: string)
	-- One request at a time, carrying the level we saw, so double-clicks can't buy two levels.
	local snap = State.snap
	if buying or not snap then
		return
	end
	buying = true
	local expected = if item == "speed" then snap.speedLevel else snap.houseTier
	local ok, reason = State.invoke("Purchase", item, expected)
	buying = false
	if not ok then
		if reason == "Already upgraded" then
			-- A click on a stale panel (e.g. a double-click): the first one went through, nothing was charged twice.
			toast("Already upgraded: your earlier click went through.", "info")
		else
			toast(reason or "Can't buy that", "error")
		end
	end
end

local function renderUpgrades(snap: { [string]: any })
	local tierIdx = (snap.houseTier or 0) + 1
	local tier = Economy.HouseTiers[tierIdx]
	local nextTier = Economy.HouseTiers[tierIdx + 1]
	local house = row()
	Theme.list(house, 4)
	Theme.label(house, `House: {tier.name}`, { Font = Theme.Title, TextSize = 24, TextColor3 = Theme.Colors.gold })
	Theme.label(
		house,
		`Containment {#(snap.owned or {})}/{tier.containment}  ·  Exhibit slots {tier.exhibitSlots}  ·  Ride x{tier.rideMultiplier}`,
		{ TextSize = 14, TextColor3 = Theme.Colors.dim }
	)
	if nextTier then
		Theme.label(house, `Next: {nextTier.name} ({Theme.fmt(nextTier.cost)} coins)`, { Font = Theme.Bold })
		Theme.label(house, nextTier.blurb, { AutomaticSize = Enum.AutomaticSize.Y, TextSize = 14 })
		local b = Theme.button(house, `Upgrade House ({Theme.fmt(nextTier.cost)})`, function()
			buy("house")
		end, { Size = UDim2.fromOffset(240, 40) })
		Theme.setEnabled(b, (snap.coins or 0) >= nextTier.cost)
	else
		Theme.label(house, "Fully upgraded.", { TextColor3 = Theme.Colors.good })
	end

	local speed = row()
	Theme.list(speed, 4)
	local lvl = snap.speedLevel or 0
	Theme.label(
		speed,
		`Running Shoes: level {lvl}/{#Economy.SpeedLevelCosts}`,
		{ Font = Theme.Title, TextSize = 22, TextColor3 = Theme.Colors.gold }
	)
	Theme.label(
		speed,
		string.format(
			"Walk speed %d, carrying %.1f (%d%%). Each level also lightens the load on the way home.",
			EconomyRules.walkSpeed(lvl, false),
			EconomyRules.walkSpeed(lvl, true),
			math.round(EconomyRules.carryMultiplier(lvl) * 100)
		),
		{ AutomaticSize = Enum.AutomaticSize.Y, TextSize = 14 }
	)
	local cost = Economy.SpeedLevelCosts[lvl + 1]
	if cost then
		local b = Theme.button(speed, `Buy +{Economy.SpeedPerLevel} speed ({cost})`, function()
			buy("speed")
		end, { Size = UDim2.fromOffset(240, 40) })
		Theme.setEnabled(b, (snap.coins or 0) >= cost)
	end

	local pay = snap.ridePreview
	if pay then
		local r = row()
		Theme.list(r, 4)
		Theme.label(
			r,
			`Ghost Train payout: {pay.total} coins per ride`,
			{ Font = Theme.Title, TextSize = 22, TextColor3 = Theme.Colors.gold }
		)
		Theme.label(
			r,
			string.format(
				"Base %d  x  house %.1f  x  route quality %.2f  x  (1 + exhibits %d%%, %d in range).\nUpgrade your house, add exhibits near the track, or build a twistier route to earn more. %ds cooldown between paid rides.",
				pay.base,
				pay.tier,
				pay.quality,
				math.floor(pay.exhibitBonus * 100 + 0.5),
				pay.counted,
				Economy.RideCooldownSeconds
			),
			{ AutomaticSize = Enum.AutomaticSize.Y, TextSize = 14 }
		)
	end
end

local function renderMonsters(snap: { [string]: any })
	local owned = snap.owned or {}
	local head = row()
	Theme.label(
		head,
		`Owned monsters: {#owned}/{snap.capacity or "?"}  ·  Income +{string.format("%.1f", snap.incomeRate or 0)}/s`,
		{ Font = Theme.Bold }
	)
	if #owned == 0 then
		local r = row()
		Theme.label(
			r,
			"No monsters yet. Capture one in the graveyard and secure it at your pen.",
			{ AutomaticSize = Enum.AutomaticSize.Y }
		)
		return
	end
	local now = snap.now or os.time()
	for _, m in owned do
		local species = Monsters.Species[m.species]
		local r = row(38)
		local status
		local slot = exhibitSlotOf(snap, m.uid)
		if slot then
			status = `On exhibit {slot} (boosts rides)`
		else
			local left = (snap.acclimationSeconds or 30) - (now - m.acquiredAt)
			local rate = species.incomePerSecond * Variants.multiplier(m.variant)
			status = if left > 0 then `Settling in: {math.ceil(left)}s` else string.format("+%.1f/s", rate)
		end
		Theme.label(r, `{nameOf(m)}  ({species.rarity})`, {
			Size = UDim2.fromScale(0.6, 1),
			TextColor3 = Monsters.RarityColor[species.rarity],
			Font = Theme.Bold,
		})
		Theme.label(r, status, {
			Position = UDim2.fromScale(0.6, 0),
			Size = UDim2.fromScale(0.4, 1),
			TextXAlignment = Enum.TextXAlignment.Right,
			TextSize = 14,
		})
	end
end

local function renderExhibits(snap: { [string]: any })
	local tier = Economy.HouseTiers[(snap.houseTier or 0) + 1]
	-- Computed by the server from the route it really pays on (see TrainService.slotsInRange).
	local inRange: { boolean } = snap.exhibitInRange or {}
	local info = row()
	Theme.label(
		info,
		`Exhibits near your track add to every ride's payout (within {Economy.ExhibitRange} studs of the rails). Monsters on exhibit don't earn passive income. Rarer and variant monsters add more.`,
		{ AutomaticSize = Enum.AutomaticSize.Y, TextSize = 14 }
	)
	local owned = snap.owned or {}
	for slot = 1, 4 do
		local r = row(48)
		local current: { [string]: any }? = nil
		for _, e in snap.exhibits or {} do
			if e.slot == slot then
				for _, m in owned do
					if m.uid == e.uid then
						current = m
					end
				end
			end
		end
		local locked = slot > tier.exhibitSlots
		Theme.label(
			r,
			if locked
				then `Slot {slot}: locked (upgrade house)`
				else `Slot {slot}: {if current then nameOf(current) else "empty"}  ·  {if inRange[slot]
					then "near the track"
					else "too far from the track (no bonus)"}`,
			{
				Size = UDim2.new(1, -150, 1, 0),
				Font = Theme.Bold,
				TextColor3 = if locked
					then Theme.Colors.dim
					elseif not inRange[slot] then Theme.Colors.dim
					else Theme.Colors.text,
				TextWrapped = true,
			}
		)
		if not locked then
			Theme.button(r, if current then "Next / Remove" else "Place monster", function()
				-- Cycle: empty -> each owned monster not shown elsewhere -> empty
				local candidates: { string } = {}
				for _, m in owned do
					local s = exhibitSlotOf(snap, m.uid)
					if s == nil or s == slot then
						table.insert(candidates, m.uid)
					end
				end
				table.insert(candidates, "") -- "" = empty slot
				local idx = 0
				for i, uid in candidates do
					if current and uid == current.uid then
						idx = i
					end
				end
				local pick = candidates[idx % #candidates + 1]
				local nextUid: string? = if pick == "" then nil else pick
				if #candidates == 1 and not current then
					toast("You have no free monsters to exhibit.", "error")
					return
				end
				local ok, reason = State.invoke("SetExhibit", slot, nextUid)
				if not ok then
					toast(reason or "Couldn't place it", "error")
				end
			end, {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.fromScale(1, 0.5),
				Size = UDim2.fromOffset(140, 34),
				TextSize = 14,
			})
		end
	end
end

local lastSig = ""

-- Rebuild only when something a button depends on changed, so taps aren't lost to re-renders.
local function signature(snap: { [string]: any }): string
	local parts: { any } = { tab }
	if tab == "Upgrades" then
		local tier = Economy.HouseTiers[(snap.houseTier or 0) + 2]
		local speedCost = Economy.SpeedLevelCosts[(snap.speedLevel or 0) + 1]
		local pay = snap.ridePreview or {}
		parts = {
			tab,
			snap.houseTier,
			snap.speedLevel,
			#(snap.owned or {}),
			tier ~= nil and (snap.coins or 0) >= tier.cost,
			speedCost ~= nil and (snap.coins or 0) >= speedCost,
			pay.total,
			pay.counted,
		}
	elseif tab == "Monsters" then
		parts = { tab, snap.now, snap.incomeRate, snap.owned, snap.exhibits }
	else
		parts = { tab, snap.houseTier, snap.owned, snap.exhibits, snap.exhibitInRange }
	end
	local ok, json = pcall(HttpService.JSONEncode, HttpService, parts)
	return if ok then json else tostring(os.clock())
end

local function render(force: boolean?)
	if not panel.Visible then
		return
	end
	local snap = State.snap
	if not snap then
		return
	end
	local sig = signature(snap)
	if sig == lastSig and not force then
		return
	end
	lastSig = sig
	clear()
	for name, b in tabButtons do
		b.BackgroundColor3 = if name == tab then Theme.Colors.button else Theme.Colors.buttonOff
	end
	if tab == "Upgrades" then
		renderUpgrades(snap)
	elseif tab == "Monsters" then
		renderMonsters(snap)
	else
		renderExhibits(snap)
	end
end

function MansionUI.open(which: string?)
	panel.Visible = true
	if which then
		tab = which
	end
	render(true)
	task.spawn(State.invoke, "Ack", "mansion")
end

function MansionUI.close()
	panel.Visible = false
end

function MansionUI.toggle()
	if panel.Visible then
		MansionUI.close()
	else
		MansionUI.open()
	end
end

function MansionUI.mount(gui: ScreenGui, toastFn: (string, string?) -> ())
	toast = toastFn
	panel = Theme.panel(gui, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0, 520, 0.72, 0),
		Visible = false,
		ZIndex = 5,
	})
	local size = Instance.new("UISizeConstraint")
	size.MaxSize = Vector2.new(520, 560)
	size.MinSize = Vector2.new(300, 260)
	size.Parent = panel
	Theme.pad(panel, 12)
	Theme.label(
		panel,
		"Your Mansion",
		{ Font = Theme.Title, TextSize = 30, Size = UDim2.new(1, -130, 0, 34), TextColor3 = Theme.Colors.gold }
	)
	Theme.button(panel, "Shop", function()
		MansionUI.close()
		MansionUI.openShop()
	end, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -48, 0, 0),
		Size = UDim2.fromOffset(72, 34),
	})
	Theme.button(panel, "X", MansionUI.close, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromOffset(40, 34),
		BackgroundColor3 = Theme.Colors.buttonOff,
	})
	local tabs = Theme.frame(
		panel,
		{ Position = UDim2.fromOffset(0, 40), Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1 }
	)
	Theme.list(tabs, 6, true)
	for i, name in { "Upgrades", "Monsters", "Exhibits" } do
		tabButtons[name] = Theme.button(tabs, name, function()
			tab = name
			render(true)
		end, { Size = UDim2.fromOffset(120, 34), LayoutOrder = i })
	end
	content = Instance.new("ScrollingFrame")
	content.Position = UDim2.fromOffset(0, 84)
	content.Size = UDim2.new(1, 0, 1, -84)
	content.BackgroundTransparency = 1
	content.BorderSizePixel = 0
	content.ScrollBarThickness = 6
	content.AutomaticCanvasSize = Enum.AutomaticSize.Y
	content.CanvasSize = UDim2.new()
	content.Parent = panel
	Theme.list(content, 8)
	State.Changed:Connect(function()
		render()
	end)
end

return MansionUI
