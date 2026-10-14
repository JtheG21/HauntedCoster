--!strict
-- The Curio Shop (TASK-0051, SYS-Haunted-Monetization-UI): a permanent catalog of the five cosmetic categories with
-- category and ownership/acquisition filters, catalog cards, an item details view with a rotatable preview (or a
-- replayable effect preview), and the owned-item actions (equip per ghost, select capture effect or theme, place
-- decorations). Every action asks the server; the UI only reflects authoritative state. Robux items show a buy
-- button only for a configured product; otherwise they say they are not on sale. Back returns to the same
-- category, filter and scroll position.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Cosmetics = require(Shared:WaitForChild("Config"):WaitForChild("Cosmetics"))
local Monsters = require(Shared.Config:WaitForChild("Monsters"))
local Variants = require(Shared.Config:WaitForChild("Variants"))
local CosmeticRules = require(Shared:WaitForChild("Rules"):WaitForChild("CosmeticRules"))
local Theme = require(script.Parent.Theme)
local Preview = require(script.Parent.Preview)
local State = require(script.Parent.Parent.State)
local Effects = require(script.Parent.Parent.Art.Effects)

local ShopUI = {}

local CREATURE_ART = {
	Wisp = "creature_wisp",
	Hound = "creature_hound",
	Gentleman = "creature_gentleman",
	BellWraith = "creature_bellwraith",
}
local FILTERS = { "All", "Owned", "Coins", "Robux", "Rewards" }

local modal: Theme.Modal
local catalogView: Frame
local detailView: Frame
local grid: ScrollingFrame
local category: Cosmetics.Category = "Skin"
local filter = "All"
local current: string? = nil -- item id in the details view
local pending = false
local toast: (string, string?) -> () = function(_text: string, _kind: string?) end
local placeDecoration: (string, string?) -> () = function(_id: string, _key: string?) end
local previews: { Preview.Handle } = {}
local detailPreview: Preview.Handle? = nil

local function snapC(): { [string]: any }?
	local s = State.snap
	return s and s.cosmetics
end

local function owns(id: string): boolean
	local c = snapC()
	return c ~= nil and c.owned[id] == true
end

local function writable(): boolean
	local s = State.snap
	return s ~= nil and s.cosmeticsWritable == true
end

-- How an item is acquired, for card chips and the details view: text, colour, kind.
local function acquisition(item: Cosmetics.Item): (string, Color3, string)
	local a = item.acquire
	if a.coins then
		return `{Theme.fmt(a.coins)} Coins`, Theme.Colors.gold, "coins"
	elseif a.product then
		local c = snapC()
		if c and c.productsLive[a.product] then
			return "Robux", Theme.Colors.robux, "robux"
		end
		return "Not on sale yet", Theme.Colors.dim, "robux"
	elseif a.reward then
		local m = Cosmetics.MilestoneById[a.reward]
		return `Reward: {m and m.name or a.reward}`, Theme.Colors.ghost, "reward"
	end
	return "", Theme.Colors.dim, "none"
end

local function previewKey(item: Cosmetics.Item): (string?, { [string]: any }?)
	if item.category == "Skin" then
		local species = item.species and item.species[1]
		if species then
			local mats: { [string]: Enum.Material } = {}
			for part, name in (item.look.material or {}) :: { [string]: string } do
				local ok, m = pcall(function()
					return (Enum.Material :: any)[name]
				end)
				if ok and m then
					mats[part] = m
				end
			end
			return CREATURE_ART[species], { tint = item.look.tint, material = mats }
		end
	elseif item.category == "Theme" then
		local tier = (State.snap and State.snap.houseTier) or 0
		return `house_t{math.clamp(tier, 0, 2)}`, { tint = item.look.tint }
	elseif item.category == "Decoration" then
		return item.look.art, nil
	end
	return nil, nil
end

local function swatch(parent: GuiObject, item: Cosmetics.Item)
	local color: Color3 = item.look.color or Theme.Colors.ghost
	local orb = Theme.frame(parent, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(64, 64),
		BackgroundColor3 = color,
		BackgroundTransparency = 0.15,
	})
	Theme.corner(orb, 32)
	Theme.stroke(orb, color:Lerp(Color3.new(1, 1, 1), 0.4), 3)
	Theme.label(orb, if item.category == "Aura" then "Aura" else "Burst", {
		Size = UDim2.fromScale(1, 1),
		TextXAlignment = Enum.TextXAlignment.Center,
		Font = Theme.Title,
		TextSize = 18,
		TextColor3 = Color3.fromRGB(20, 12, 24),
	})
end

local function clearPreviews()
	for _, h in previews do
		h.destroy()
	end
	table.clear(previews)
end

local function matches(item: Cosmetics.Item): boolean
	if item.category ~= category then
		return false
	end
	local _, _, kind = acquisition(item)
	if filter == "Owned" then
		return owns(item.id)
	elseif filter == "Coins" then
		return kind == "coins"
	elseif filter == "Robux" then
		return kind == "robux"
	elseif filter == "Rewards" then
		return kind == "reward"
	end
	return true
end

local renderDetails: (string) -> ()

local function renderCatalog()
	clearPreviews()
	for _, c in grid:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	local c = snapC()
	if not c then
		Theme.notice(grid, "Loading your collection...", "loading")
		return
	end
	local items = {}
	for _, item in Cosmetics.Items do
		if matches(item) then
			table.insert(items, item)
		end
	end
	table.sort(items, function(a, b)
		return a.order < b.order
	end)
	if #items == 0 then
		Theme.notice(grid, if filter == "Owned" then "Nothing owned here yet." else "Nothing matches this filter.")
		return
	end
	for i, item in items do
		local card = Instance.new("TextButton")
		card.Name = item.id
		card.LayoutOrder = i
		card.Text = ""
		card.AutoButtonColor = false
		card.BackgroundColor3 = Theme.Colors.panel2
		card.BorderSizePixel = 0
		card.Parent = grid
		Theme.corner(card, 10)
		local equipped = c.capture == item.id or c.theme == item.id
		Theme.stroke(
			card,
			if owns(item.id) then Theme.Colors.stroke else Theme.Colors.strokeDim,
			if equipped then 2.5 else 1
		)
		card.Activated:Connect(function()
			renderDetails(item.id)
		end)
		local art = Theme.frame(card, {
			Size = UDim2.new(1, -12, 0, 120),
			Position = UDim2.fromOffset(6, 6),
			BackgroundColor3 = Color3.fromRGB(12, 9, 18),
			BackgroundTransparency = 0,
		})
		Theme.corner(art, 8)
		local key, opts = previewKey(item)
		if key then
			local h = Preview.mount(art)
			h.set(key, opts :: any)
			table.insert(previews, h)
		else
			swatch(art, item)
		end
		Theme.label(card, item.name, {
			Position = UDim2.fromOffset(10, 130),
			Size = UDim2.new(1, -20, 0, 22),
			Font = Theme.Bold,
			TextSize = 15,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextWrapped = false,
		})
		local text, color = acquisition(item)
		local tagRow = Theme.frame(card, {
			Position = UDim2.fromOffset(10, 156),
			Size = UDim2.new(1, -20, 0, 22),
			BackgroundTransparency = 1,
		})
		Theme.list(tagRow, 4, true)
		if owns(item.id) then
			Theme.chip(tagRow, if equipped then "Equipped" else "Owned", Theme.Colors.robux, { LayoutOrder = 1 })
		else
			Theme.chip(tagRow, text, color:Lerp(Theme.Colors.panel, 0.55), { LayoutOrder = 1 })
		end
	end
end

-- Details ---------------------------------------------------------------------------------------------

local function act(...: any): (boolean, string?, any)
	if pending then
		return false, "Please wait", nil
	end
	pending = true
	local ok, reason, data = State.invoke("Cosmetic", ...)
	pending = false
	if ok == nil then
		toast("The shop didn't answer. Try again.", "error")
		return false, nil, nil
	end
	if not ok and reason then
		toast(reason, "error")
	end
	return ok == true, reason, data
end

local function speciesNames(item: Cosmetics.Item): string
	if not item.species then
		return "every ghost"
	end
	local names = {}
	for _, sp in item.species do
		table.insert(names, Monsters.Species[sp] and Monsters.Species[sp].name or sp)
	end
	return table.concat(names, ", ")
end

local function previewEffect(item: Cosmetics.Item)
	local char = Players.LocalPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not (root and root:IsA("BasePart")) then
		return
	end
	if item.category == "CaptureEffect" then
		Effects.burst(root.Position + root.CFrame.LookVector * 6, item.look)
	else
		local a = Effects.aura(root, item.look, 1.2)
		task.delay(5, function()
			a:Destroy()
		end)
	end
	toast("Preview playing beside you (only you can see it).", "info")
end

renderDetails = function(id: string)
	local item = Cosmetics.ById[id]
	if not item then
		return
	end
	current = id
	catalogView.Visible = false
	detailView.Visible = true
	if detailPreview then
		detailPreview.destroy()
		detailPreview = nil
	end
	for _, ch in detailView:GetChildren() do
		if ch:IsA("GuiObject") then
			ch:Destroy()
		end
	end
	local c = snapC()
	Theme.button(detailView, "< Back", function()
		ShopUI.back()
	end, { Size = UDim2.fromOffset(96, 36), TextSize = 15 }, "secondary")
	local left = Theme.frame(detailView, {
		Position = UDim2.fromOffset(0, 46),
		Size = UDim2.new(0.48, -6, 1, -46),
		BackgroundColor3 = Color3.fromRGB(12, 9, 18),
		BackgroundTransparency = 0,
	})
	Theme.corner(left, 10)
	Theme.stroke(left, Theme.Colors.strokeDim, 1)
	local key, opts = previewKey(item)
	if key then
		detailPreview = Preview.mount(left);
		(detailPreview :: Preview.Handle).set(key, opts :: any)
		Theme.label(left, "Drag to turn", {
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -6),
			Size = UDim2.fromOffset(160, 18),
			TextXAlignment = Enum.TextXAlignment.Center,
			TextSize = 12,
			TextColor3 = Theme.Colors.dim,
		})
	else
		swatch(left, item)
		Theme.button(left, "Play preview", function()
			previewEffect(item)
		end, {
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -12),
			Size = UDim2.fromOffset(150, 40),
		}, "secondary")
	end
	local right = Theme.scroll(detailView, {
		Position = UDim2.new(0.48, 6, 0, 46),
		Size = UDim2.new(0.52, -6, 1, -46),
	})
	Theme.list(right, 8)
	Theme.heading(right, item.name, { LayoutOrder = 1, AutomaticSize = Enum.AutomaticSize.Y, TextSize = 28 })
	Theme.chip(right, Cosmetics.CategoryNames[item.category], Theme.Colors.panel3, { LayoutOrder = 2 })
	Theme.label(right, item.blurb, {
		LayoutOrder = 3,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.fromScale(1, 0),
		TextColor3 = Theme.Colors.dim,
	})
	local fit = if item.category == "Skin" or item.category == "Aura"
		then `Fits: {speciesNames(item)}. Each ghost wears its own; natural variants still show.`
		elseif item.category == "Theme" then "Fits every house tier (Shabby Shack, Restored Manor, Grand Mansion)."
		elseif item.category == "Decoration" then `One unlock, place up to {item.limit or 1} on your plot.`
		else "Plays when you secure a capture. Never changes timing or success."
	Theme.label(
		right,
		fit,
		{ LayoutOrder = 4, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.fromScale(1, 0), TextSize = 15 }
	)
	local acquireText, acquireColor, kind = acquisition(item)
	local actions = Theme.frame(right, {
		LayoutOrder = 5,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	})
	Theme.list(actions, 8)
	if not writable() then
		Theme.label(actions, "Saving is unavailable right now, so purchases and changes are paused.", {
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.fromScale(1, 0),
			TextColor3 = Theme.Colors.bad,
		})
	end
	if not c then
		Theme.notice(actions, "Loading ownership...", "loading")
		return
	end
	if not owns(id) then
		Theme.label(actions, acquireText, { Font = Theme.Bold, TextColor3 = acquireColor, TextSize = 18 })
		if kind == "coins" then
			local price = item.acquire.coins :: number
			local coins = (State.snap and State.snap.coins) or 0
			local buy = Theme.button(actions, `Buy for {Theme.fmt(price)} Coins`, function()
				local ok = act("buy", id)
				if ok then
					renderDetails(id)
				end
			end, { Size = UDim2.new(1, 0, 0, 46) })
			Theme.setEnabled(buy, writable() and coins >= price)
			if coins < price then
				Theme.label(actions, `You have {Theme.fmt(coins)}. Needs {Theme.fmt(price - coins)} more.`, {
					TextColor3 = Theme.Colors.dim,
					TextSize = 14,
				})
			end
		elseif kind == "robux" then
			if c.productsLive[item.acquire.product] then
				local b = Theme.button(actions, "Buy with Robux", function()
					local ok = act("buyRobux", id)
					if ok then
						toast("Confirm in the Roblox purchase window. Your item arrives once Roblox confirms.", "info")
					end
				end, { Size = UDim2.new(1, 0, 0, 46) }, "robux")
				Theme.setEnabled(b, writable())
			else
				Theme.label(actions, "This item isn't on sale yet.", { TextColor3 = Theme.Colors.dim, TextSize = 14 })
			end
		elseif kind == "reward" then
			local p = c.progress[item.acquire.reward]
			if p then
				Theme.label(actions, if p.done then "Complete!" else `Progress: {p.have}/{p.need}`, {
					TextColor3 = if p.done then Theme.Colors.good else Theme.Colors.dim,
				})
				if p.done and not p.claimed then
					local b = Theme.button(actions, "Claim reward", function()
						local ok = act("claim", item.acquire.reward)
						if ok then
							renderDetails(id)
						end
					end, { Size = UDim2.new(1, 0, 0, 46) })
					Theme.setEnabled(b, writable())
				end
			end
		end
		return
	end
	-- Owned: equipment and placement.
	Theme.chip(actions, "Owned", Theme.Colors.robux)
	if item.category == "Skin" or item.category == "Aura" then
		local slot = if item.category == "Skin" then "skins" else "auras"
		local any = false
		for _, m in (State.snap and State.snap.owned or {}) :: { any } do
			if CosmeticRules.compatible(item, m.species) then
				any = true
				local row = Theme.card(actions, { Size = UDim2.new(1, 0, 0, 50) })
				Theme.pad(row, 8, 6)
				local wearing = c[slot][m.uid]
				local variant = if m.variant ~= Variants.Normal then `{m.variant} ` else ""
				Theme.label(row, `{variant}{Monsters.Species[m.species].name}`, {
					Size = UDim2.new(1, -120, 0, 20),
					Font = Theme.Bold,
					TextSize = 15,
				})
				Theme.label(
					row,
					if wearing == id
						then "Wearing this"
						elseif wearing then `Wearing {Cosmetics.ById[wearing].name}`
						else "Natural look",
					{
						Position = UDim2.fromOffset(0, 20),
						Size = UDim2.new(1, -120, 0, 18),
						TextSize = 13,
						TextColor3 = Theme.Colors.dim,
					}
				)
				local b = Theme.button(row, if wearing == id then "Remove" else "Equip", function()
					local ok = act("equip", slot, m.uid, if wearing == id then nil else id)
					if ok then
						renderDetails(id)
					end
				end, {
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.fromScale(1, 0.5),
					Size = UDim2.fromOffset(108, 38),
					TextSize = 15,
				}, if wearing == id then "secondary" else nil)
				Theme.setEnabled(b, writable())
			end
		end
		if not any then
			Theme.label(actions, `Catch a {speciesNames(item)} to wear this.`, { TextColor3 = Theme.Colors.dim })
		end
		if item.category == "Aura" then
			Theme.button(actions, "Play preview", function()
				previewEffect(item)
			end, { Size = UDim2.new(1, 0, 0, 40) }, "secondary")
		end
	elseif item.category == "CaptureEffect" or item.category == "Theme" then
		local slot = if item.category == "Theme" then "theme" else "capture"
		local on = c[slot] == id
		local b = Theme.button(
			actions,
			if on then "Remove" else (if slot == "theme" then "Apply to my house" else "Equip"),
			function()
				local ok = act("select", slot, if on then nil else id)
				if ok then
					renderDetails(id)
				end
			end,
			{ Size = UDim2.new(1, 0, 0, 46) },
			if on then "secondary" else nil
		)
		Theme.setEnabled(b, writable())
		if item.category == "CaptureEffect" then
			Theme.button(actions, "Play preview", function()
				previewEffect(item)
			end, { Size = UDim2.new(1, 0, 0, 40) }, "secondary")
		end
	elseif item.category == "Decoration" then
		local placed = 0
		for _, p in c.placements do
			if p.id == id then
				placed += 1
			end
		end
		Theme.label(actions, `Placed {placed} of {item.limit or 1}.`, { TextColor3 = Theme.Colors.dim })
		local b = Theme.button(actions, "Place on my plot", function()
			ShopUI.close()
			placeDecoration(id, nil)
		end, { Size = UDim2.new(1, 0, 0, 46) })
		Theme.setEnabled(b, writable() and placed < (item.limit or 1))
	end
end

function ShopUI.back(): boolean
	if detailView and detailView.Visible then
		detailView.Visible = false
		catalogView.Visible = true
		current = nil
		if detailPreview then
			detailPreview.destroy()
			detailPreview = nil
		end
		return true
	end
	return false
end

function ShopUI.open(id: string?)
	modal.root.Visible = true
	renderCatalog()
	if id then
		renderDetails(id)
	end
end

function ShopUI.close()
	modal.root.Visible = false
	clearPreviews()
	ShopUI.back()
end

function ShopUI.isOpen(): boolean
	return (modal :: any) ~= nil and modal.root.Visible
end

function ShopUI.root(): GuiObject?
	return if (modal :: any) ~= nil then modal.root else nil
end

function ShopUI.mount(gui: ScreenGui, toastFn: (string, string?) -> (), onPlace: (string, string?) -> ())
	toast = toastFn
	placeDecoration = onPlace
	modal = Theme.modal(gui, "Curio Shop", ShopUI.close, 900, 600)
	catalogView = Theme.frame(modal.body, { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 })
	detailView = Theme.frame(modal.body, { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false })
	local names = {}
	for _, cat in Cosmetics.Categories do
		table.insert(names, (Cosmetics.CategoryNames :: { [string]: string })[cat])
	end
	local setTab = Theme.tabs(catalogView, names, function(name)
		for _, cat in Cosmetics.Categories do
			if (Cosmetics.CategoryNames :: { [string]: string })[cat] == name then
				category = cat :: any
			end
		end
		renderCatalog()
	end)
	setTab((Cosmetics.CategoryNames :: { [string]: string })[category])
	local setFilter = Theme.tabs(catalogView, FILTERS, function(name)
		filter = name
		renderCatalog()
	end, { Position = UDim2.fromOffset(0, 46), Size = UDim2.new(1, 0, 0, 34) })
	setFilter(filter)
	Theme.label(catalogView, "", {
		Position = UDim2.fromOffset(0, 86),
		Size = UDim2.new(1, 0, 0, 20),
		TextSize = 13,
		TextColor3 = Theme.Colors.dim,
		Text = "Cosmetics only change how things look. Optional, permanent, and never stronger ghosts.",
	})
	grid = Theme.scroll(catalogView, { Position = UDim2.fromOffset(0, 112), Size = UDim2.new(1, 0, 1, -112) })
	local layout = Instance.new("UIGridLayout")
	layout.CellSize = UDim2.fromOffset(168, 186)
	layout.CellPadding = UDim2.fromOffset(10, 10)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = grid
	-- Re-render only when something the shop shows changed (not on every income tick).
	local last = ""
	State.Changed:Connect(function(snap)
		if not modal.root.Visible then
			return
		end
		local item = current and Cosmetics.ById[current]
		local price = item and item.acquire.coins
		local sig = HttpService:JSONEncode(snap.cosmetics or {})
			.. tostring(snap.cosmeticsWritable)
			.. tostring(price and (snap.coins or 0) >= price)
			.. tostring(#(snap.owned or {}))
		if sig == last then
			return
		end
		last = sig
		if current then
			renderDetails(current)
		else
			renderCatalog()
		end
	end)
end

return ShopUI
