--!strict
-- Shop and Owned screens (TASK-0061). Read-only: it shows what the server says is owned and what the catalog
-- lists. No prices and no Buy button exist until a supported grant path does. What each card says comes from
-- ShopRules; this file only draws it and remembers the tab, filters and scroll position across Back.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Rules = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Rules")
local ShopRules = require(Rules:WaitForChild("ShopRules"))
local Theme = require(script.Parent.Theme)
local State = require(script.Parent.Parent.State)

local ShopUI = {}

local panel: Frame
local content: ScrollingFrame
local filterBar: Frame
local titleLabel: TextLabel
local backButton: TextButton
local tab = "Shop"
local filter: ShopRules.Filter = { category = nil, ownership = "all", acquisition = "all" }
local selected: string? = nil
local listScroll = 0
local catalog: any? = nil
local tabButtons: { [string]: TextButton } = {}

local CATEGORY_LABEL = {
	Skin = "Skins",
	Aura = "Auras",
	CaptureEffect = "Capture FX",
	Theme = "Themes",
	Decoration = "Decor",
}

local function clear()
	for _, c in content:GetChildren() do
		if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then
			c:Destroy()
		end
	end
end

local function card(height: number?): Frame
	local f = Theme.frame(content, {
		Size = UDim2.new(1, 0, 0, height or 0),
		AutomaticSize = if height then Enum.AutomaticSize.None else Enum.AutomaticSize.Y,
		BackgroundColor3 = Theme.Colors.panel2,
	})
	Theme.corner(f, 8)
	Theme.pad(f, 8)
	return f
end

local function viewInput(): ShopRules.Input
	local snap = State.snap
	return {
		catalog = catalog,
		cosmetics = if snap then snap.cosmetics else nil,
		persistence = if snap then snap.persistence else "loading",
	}
end

local function chip(parent: Instance, text: string, on: boolean, order: number, onClick: () -> ()): TextButton
	local b =
		Theme.button(parent, text, onClick, { Size = UDim2.fromOffset(92, 30), LayoutOrder = order, TextSize = 14 })
	if not on then
		b.BackgroundColor3 = Theme.Colors.buttonOff
	end
	return b
end

local function describe(c: ShopRules.Card): string
	local lines = { ShopRules.acquisitionLabel(c) }
	if c.rewardId and not c.owned then
		table.insert(lines, "Reward: " .. c.rewardId)
	end
	if not c.listed then
		table.insert(lines, "No longer in the shop; you keep it.")
	end
	local item = if catalog then catalog.Items[c.id] else nil
	if item and item.species then
		table.insert(lines, "Fits: " .. table.concat(item.species, ", "))
	end
	if item and item.tiers then
		local names = {}
		for _, tier in item.tiers do
			table.insert(names, tostring(tier))
		end
		table.insert(lines, "House tiers: " .. table.concat(names, ", "))
	end
	return table.concat(lines, "\n")
end

local render

local function showDetails(c: ShopRules.Card)
	listScroll = content.CanvasPosition.Y
	selected = c.id
	render(false)
end

local function renderFilters()
	for _, ch in filterBar:GetChildren() do
		if not ch:IsA("UIListLayout") then
			ch:Destroy()
		end
	end
	local order = 0
	local function add(text: string, on: boolean, fn: () -> ())
		order += 1
		chip(filterBar, text, on, order, fn)
	end
	add("All", filter.category == nil, function()
		filter.category = nil
		render(true)
	end)
	for _, cat in ShopRules.Categories do
		add(CATEGORY_LABEL[cat], filter.category == cat, function()
			filter.category = cat
			render(true)
		end)
	end
	if tab == "Shop" then
		add(
			if filter.ownership == "owned"
				then "Owned"
				elseif filter.ownership == "unowned" then "Not owned"
				else "Any owner",
			filter.ownership ~= "all",
			function()
				filter.ownership = if filter.ownership == "all"
					then "owned"
					elseif filter.ownership == "owned" then "unowned"
					else "all"
				render(true)
			end
		)
		add(
			if filter.acquisition == "earnable"
				then "Earnable"
				elseif filter.acquisition == "notYet" then "Not yet"
				else "Any source",
			filter.acquisition ~= "all",
			function()
				filter.acquisition = if filter.acquisition == "all"
					then "earnable"
					elseif filter.acquisition == "earnable" then "notYet"
					else "all"
				render(true)
			end
		)
	end
end

function render(resetScroll: boolean?)
	clear()
	for name, b in tabButtons do
		b.BackgroundColor3 = if name == tab then Theme.Colors.button else Theme.Colors.buttonOff
	end
	local view = ShopRules.view(viewInput(), tab, filter)
	local picked: ShopRules.Card? = nil
	if selected then
		for _, c in view.cards do
			if c.id == selected then
				picked = c
			end
		end
		if not picked then
			selected = nil -- it left the list (a filter or the data changed): fall back to the list
		end
	end
	backButton.Visible = picked ~= nil
	filterBar.Visible = picked == nil
	titleLabel.Text = if picked then picked.name else "Shop"
	if picked then
		local f = card()
		Theme.label(f, picked.name, { Font = Theme.Bold, TextSize = 20, AutomaticSize = Enum.AutomaticSize.Y })
		Theme.label(f, if picked.category then (CATEGORY_LABEL[picked.category] or picked.category) else "Unlisted", {
			TextColor3 = Theme.Colors.dim,
			Position = UDim2.fromOffset(0, 28),
		})
		Theme.label(f, describe(picked), {
			Position = UDim2.fromOffset(0, 54),
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.fromScale(1, 0),
		})
		return
	end
	renderFilters()
	if view.notice then
		local n = card()
		Theme.label(
			n,
			view.notice,
			{ TextColor3 = Theme.Colors.gold, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.fromScale(1, 0) }
		)
	end
	if view.status ~= "ready" then
		local n = card()
		Theme.label(
			n,
			ShopRules.emptyText(view.status, tab),
			{ AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.fromScale(1, 0), TextColor3 = Theme.Colors.dim }
		)
	end
	for _, c in view.cards do
		local f = card(64)
		Theme.label(f, c.name, { Font = Theme.Bold, Size = UDim2.new(1, -90, 0, 22) })
		Theme.label(f, ShopRules.acquisitionLabel(c), {
			Position = UDim2.fromOffset(0, 26),
			Size = UDim2.new(1, -90, 0, 20),
			TextColor3 = if c.owned then Theme.Colors.good else Theme.Colors.dim,
			TextSize = 14,
		})
		Theme.button(f, "Details", function()
			showDetails(c)
		end, {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.fromScale(1, 0.5),
			Size = UDim2.fromOffset(80, 36),
		})
	end
	if resetScroll then
		content.CanvasPosition = Vector2.zero
	else
		local y = listScroll
		task.defer(function()
			content.CanvasPosition = Vector2.new(0, y)
		end)
	end
end

local function loadCatalog()
	if catalog ~= nil then
		return
	end
	local result = State.invoke("GetCatalog")
	if type(result) == "table" and type(result.items) == "table" and type(result.rewards) == "table" then
		catalog = result
	end
	-- A nil result stays nil, so the screen says "couldn't load" instead of showing an empty shop.
	render(false)
end

function ShopUI.open()
	panel.Visible = true
	selected = nil
	render(false)
	task.spawn(loadCatalog)
end

function ShopUI.close()
	if panel then
		panel.Visible = false
	end
end

function ShopUI.toggle()
	if panel.Visible then
		ShopUI.close()
	else
		ShopUI.open()
	end
end

function ShopUI.mount(gui: ScreenGui)
	panel = Theme.panel(gui, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0, 520, 0.8, 0),
		Visible = false,
		ZIndex = 5,
	})
	local size = Instance.new("UISizeConstraint")
	size.MaxSize = Vector2.new(520, 580)
	size.MinSize = Vector2.new(300, 300)
	size.Parent = panel
	Theme.pad(panel, 12)
	titleLabel = Theme.label(panel, "Shop", {
		Font = Theme.Title,
		TextSize = 30,
		Size = UDim2.new(1, -130, 0, 34),
		Position = UDim2.fromOffset(70, 0),
		TextColor3 = Theme.Colors.gold,
	})
	backButton = Theme.button(panel, "Back", function()
		selected = nil
		render(false)
	end, { Size = UDim2.fromOffset(64, 34), Visible = false, BackgroundColor3 = Theme.Colors.buttonOff })
	Theme.button(panel, "X", ShopUI.close, {
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
	for i, name in { "Shop", "Owned" } do
		tabButtons[name] = Theme.button(tabs, name, function()
			tab = name
			selected = nil
			render(true)
		end, { Size = UDim2.fromOffset(120, 34), LayoutOrder = i })
	end
	filterBar = Theme.frame(panel, {
		Position = UDim2.fromOffset(0, 82),
		Size = UDim2.new(1, 0, 0, 64),
		BackgroundTransparency = 1,
	})
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.fromOffset(92, 30)
	grid.CellPadding = UDim2.fromOffset(6, 4)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = filterBar
	content = Instance.new("ScrollingFrame")
	content.Position = UDim2.fromOffset(0, 152)
	content.Size = UDim2.new(1, 0, 1, -152)
	content.BackgroundTransparency = 1
	content.BorderSizePixel = 0
	content.ScrollBarThickness = 6
	content.AutomaticCanvasSize = Enum.AutomaticSize.Y
	content.CanvasSize = UDim2.new()
	content.Parent = panel
	Theme.list(content, 8)
	State.Changed:Connect(function()
		if panel.Visible then
			render(false)
		end
	end)
end

return ShopUI
