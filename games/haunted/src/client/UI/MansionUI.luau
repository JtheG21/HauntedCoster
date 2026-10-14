--!strict
-- Mansion menu (TASK-0049): house tiers and speed upgrades (with a preview of the next house), the ghost roster
-- with each ghost's appearance slots (skin, aura), exhibit slots, and customisation (mansion theme, capture
-- effect, decorations). Coin upgrades stay visually distinct from cosmetics, which link to the Curio Shop only
-- when the player chooses.

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local Economy = require(Config:WaitForChild("Economy"))
local Monsters = require(Config:WaitForChild("Monsters"))
local Variants = require(Config:WaitForChild("Variants"))
local EconomyRules = require(ReplicatedStorage.Shared:WaitForChild("Rules"):WaitForChild("EconomyRules"))
local CosmeticRules = require(ReplicatedStorage.Shared.Rules:WaitForChild("CosmeticRules"))
local Cosmetics = require(Config:WaitForChild("Cosmetics"))
local Theme = require(script.Parent.Theme)
local Preview = require(script.Parent.Preview)
local State = require(script.Parent.Parent.State)

local MansionUI = {}

local panel: Frame
local content: ScrollingFrame
local tab = "Upgrades"
local toast: (string, string?) -> () = function(_text: string, _kind: string?) end
local setTab: (string) -> () = function(_name: string) end
local housePreview: Preview.Handle? = nil
local appearanceFor: string? = nil -- ghost uid whose appearance picker is open
local openShop: (string?) -> () = function(_id: string?) end
local openDecorate: () -> () = function() end
local render: (boolean?) -> ()

local function clear()
	if housePreview then
		housePreview.destroy()
		housePreview = nil
	end
	for _, c in content:GetChildren() do
		if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then
			c:Destroy()
		end
	end
end

local function row(height: number?): Frame
	local f = Theme.card(content, {
		Size = UDim2.new(1, 0, 0, height or 0),
		AutomaticSize = if height then Enum.AutomaticSize.None else Enum.AutomaticSize.Y,
	})
	Theme.pad(f, 10, 8)
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
	local art = Theme.frame(house, {
		Size = UDim2.new(1, 0, 0, 170),
		BackgroundColor3 = Color3.fromRGB(12, 9, 18),
		BackgroundTransparency = 0,
	})
	Theme.corner(art, 8)
	housePreview = Preview.mount(art)
	local showTier = if nextTier then tierIdx else tierIdx - 1
	local theme = snap.cosmetics and snap.cosmetics.theme and Cosmetics.ById[snap.cosmetics.theme];
	(housePreview :: Preview.Handle).set(`house_t{math.clamp(showTier, 0, 2)}`, { tint = theme and theme.look.tint })
	Theme.label(art, if nextTier then `Preview: {nextTier.name}` else `Your {tier.name}`, {
		Position = UDim2.fromOffset(8, 6),
		Size = UDim2.new(1, -16, 0, 18),
		TextSize = 13,
		TextColor3 = Theme.Colors.dim,
	})
	if nextTier then
		Theme.label(house, `Next: {nextTier.name} ({Theme.fmt(nextTier.cost)} coins)`, { Font = Theme.Bold })
		Theme.label(house, nextTier.blurb, { AutomaticSize = Enum.AutomaticSize.Y, TextSize = 14 })
		local b = Theme.button(house, `Upgrade House  ·  {Theme.fmt(nextTier.cost)} Coins`, function()
			buy("house")
		end, { Size = UDim2.fromOffset(280, 44), BackgroundColor3 = Color3.fromRGB(122, 86, 30) })
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
		local b = Theme.button(speed, `Buy +{Economy.SpeedPerLevel} speed  ·  {Theme.fmt(cost)} Coins`, function()
			buy("speed")
		end, { Size = UDim2.fromOffset(280, 44), BackgroundColor3 = Color3.fromRGB(122, 86, 30) })
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
	local c = snap.cosmetics
	for _, m in owned do
		local species = Monsters.Species[m.species]
		local r = row()
		local status
		local slot = exhibitSlotOf(snap, m.uid)
		if slot then
			status = `On exhibit {slot} (boosts rides)`
		else
			local left = (snap.acclimationSeconds or 30) - (now - m.acquiredAt)
			local rate = species.incomePerSecond * Variants.multiplier(m.variant)
			status = if left > 0 then `Settling in: {math.ceil(left)}s` else string.format("+%.1f/s", rate)
		end
		Theme.label(r, `{nameOf(m)}`, {
			Size = UDim2.new(1, -150, 0, 20),
			TextColor3 = Monsters.RarityColor[species.rarity],
			Font = Theme.Bold,
		})
		Theme.label(r, `{species.rarity}  ·  {status}`, {
			Position = UDim2.fromOffset(0, 20),
			Size = UDim2.new(1, -150, 0, 18),
			TextSize = 13,
			TextColor3 = Theme.Colors.dim,
		})
		local skin = c and c.skins[m.uid]
		local aura = c and c.auras[m.uid]
		Theme.label(
			r,
			`Look: {if skin then Cosmetics.ById[skin].name else "Natural"}{if aura
				then "  +  " .. Cosmetics.ById[aura].name
				else ""}`,
			{
				Position = UDim2.fromOffset(0, 38),
				Size = UDim2.new(1, -150, 0, 18),
				TextSize = 13,
				TextColor3 = Theme.Colors.ghost,
			}
		)
		Theme.button(r, if appearanceFor == m.uid then "Done" else "Appearance", function()
			appearanceFor = if appearanceFor == m.uid then nil else m.uid
			render(true)
		end, {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.fromScale(1, 0),
			Size = UDim2.fromOffset(136, 40),
			TextSize = 14,
		}, "secondary")
		if appearanceFor == m.uid and c then
			local pick = Theme.frame(r, {
				Position = UDim2.fromOffset(0, 62),
				Size = UDim2.fromScale(1, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
			})
			local grid = Instance.new("UIGridLayout")
			grid.CellSize = UDim2.new(0.5, -4, 0, 40)
			grid.CellPadding = UDim2.fromOffset(8, 6)
			grid.SortOrder = Enum.SortOrder.LayoutOrder
			grid.Parent = pick
			local n = 0
			local function choice(text: string, on: boolean, fn: () -> ())
				n += 1
				local b = Theme.button(
					pick,
					(if on then "> " else "") .. text,
					fn,
					{ LayoutOrder = n, TextSize = 13 },
					if on then nil else "secondary"
				)
				Theme.setEnabled(b, snap.cosmeticsWritable == true)
			end
			local function equip(slotName: string, id: string?)
				local ok, reason = State.invoke("Cosmetic", "equip", slotName, m.uid, id)
				if not ok and reason then
					toast(reason, "error")
				end
			end
			choice("Natural look", skin == nil, function()
				equip("skins", nil)
			end)
			for _, item in Cosmetics.Items do
				if item.category == "Skin" and c.owned[item.id] and CosmeticRules.compatible(item, m.species) then
					choice(item.name, skin == item.id, function()
						equip("skins", item.id)
					end)
				end
			end
			choice("No aura", aura == nil, function()
				equip("auras", nil)
			end)
			for _, item in Cosmetics.Items do
				if item.category == "Aura" and c.owned[item.id] then
					choice(item.name, aura == item.id, function()
						equip("auras", item.id)
					end)
				end
			end
			n += 1
			Theme.button(pick, "Find more looks in the Shop", function()
				openShop(nil)
			end, { LayoutOrder = n, TextSize = 13 }, "secondary")
		end
	end
end

-- Customisation: the mansion theme, the capture effect and decorations (owned items only; the Shop is a choice).
local function renderCustomize(snap: { [string]: any })
	local c = snap.cosmetics
	if not c then
		Theme.notice(content, "Loading your collection...", "loading")
		return
	end
	if snap.cosmeticsWritable ~= true then
		Theme.notice(content, "Saving is unavailable right now, so changes are paused.", "error")
	end
	local function section(title: string, category: string, slot: string)
		local r = row()
		Theme.list(r, 6)
		Theme.heading(r, title, { TextSize = 22, Size = UDim2.new(1, 0, 0, 26) })
		local any = false
		for _, item in Cosmetics.Items do
			if item.category == category and c.owned[item.id] then
				any = true
				local on = c[slot] == item.id
				local b = Theme.button(r, (if on then "Remove  " else "Apply  ") .. item.name, function()
					local ok, reason = State.invoke("Cosmetic", "select", slot, if on then nil else item.id)
					if not ok and reason then
						toast(reason, "error")
					end
				end, { Size = UDim2.new(1, 0, 0, 40), TextSize = 14 }, if on then "secondary" else nil)
				Theme.setEnabled(b, snap.cosmeticsWritable == true)
			end
		end
		if not any then
			Theme.label(r, "None owned yet.", { TextColor3 = Theme.Colors.dim, TextSize = 14 })
		end
		Theme.button(r, "Browse in the Shop", function()
			openShop(nil)
		end, { Size = UDim2.fromOffset(200, 36), TextSize = 14 }, "secondary")
	end
	section("Mansion theme", "Theme", "theme")
	section("Capture effect", "CaptureEffect", "capture")
	local r = row()
	Theme.list(r, 6)
	Theme.heading(r, "Decorations", { TextSize = 22, Size = UDim2.new(1, 0, 0, 26) })
	Theme.label(r, `{#c.placements} placed on your plot (up to {Cosmetics.Placement.maxPlaced}).`, {
		TextColor3 = Theme.Colors.dim,
		TextSize = 14,
	})
	Theme.button(r, "Decorate my plot", function()
		openDecorate()
	end, { Size = UDim2.fromOffset(220, 42) })
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
	elseif tab == "Ghosts" then
		parts = {
			tab,
			snap.now,
			snap.incomeRate,
			snap.owned,
			snap.exhibits,
			snap.cosmetics,
			appearanceFor,
			snap.cosmeticsWritable,
		}
	elseif tab == "Customize" then
		parts = { tab, snap.cosmetics, snap.cosmeticsWritable }
	else
		parts = { tab, snap.houseTier, snap.owned, snap.exhibits, snap.exhibitInRange }
	end
	local ok, json = pcall(HttpService.JSONEncode, HttpService, parts)
	return if ok then json else tostring(os.clock())
end

render = function(force: boolean?)
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
	setTab(tab)
	if tab == "Upgrades" then
		renderUpgrades(snap)
	elseif tab == "Ghosts" then
		renderMonsters(snap)
	elseif tab == "Customize" then
		renderCustomize(snap)
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

function MansionUI.isOpen(): boolean
	return (panel :: any) ~= nil and panel.Visible
end

function MansionUI.root(): GuiObject?
	return panel
end

function MansionUI.toggle()
	if panel.Visible then
		MansionUI.close()
	else
		MansionUI.open()
	end
end

function MansionUI.mount(
	gui: ScreenGui,
	toastFn: (string, string?) -> (),
	shopFn: ((string?) -> ())?,
	decorateFn: (() -> ())?
)
	toast = toastFn
	if shopFn then
		openShop = shopFn
	end
	if decorateFn then
		openDecorate = decorateFn
	end
	local modal = Theme.modal(gui, "Your Mansion", MansionUI.close, 780, 600)
	panel = modal.root
	setTab = Theme.tabs(modal.body, { "Upgrades", "Ghosts", "Exhibits", "Customize" }, function(name)
		tab = name
		render(true)
	end)
	content = Theme.scroll(modal.body, { Position = UDim2.fromOffset(0, 48), Size = UDim2.new(1, 0, 1, -48) })
	Theme.list(content, 8)
	State.Changed:Connect(function()
		render()
	end)
end

return MansionUI
