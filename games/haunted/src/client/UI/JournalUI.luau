--!strict
-- The Bestiary (TASK-0049): Creatures (a 3D preview per species, silhouettes for the undiscovered, natural variants
-- found), Habitats (which species each hunting ground holds and how many are caught) and Rewards (collection
-- milestones with progress, the cosmetic they unlock, and a server-confirmed Claim). Owning a paid skin never
-- counts as a discovery; reward previews open the Shop only if the player asks.

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local Monsters = require(Config:WaitForChild("Monsters"))
local Variants = require(Config:WaitForChild("Variants"))
local Habitats = require(Config:WaitForChild("Habitats"))
local Cosmetics = require(Config:WaitForChild("Cosmetics"))
local CosmeticRules = require(ReplicatedStorage.Shared:WaitForChild("Rules"):WaitForChild("CosmeticRules"))
local Theme = require(script.Parent.Theme)
local Preview = require(script.Parent.Preview)
local State = require(script.Parent.Parent.State)

local JournalUI = {}

local CREATURE_ART = {
	Wisp = "creature_wisp",
	Hound = "creature_hound",
	Gentleman = "creature_gentleman",
	BellWraith = "creature_bellwraith",
}

local panel: Frame
local content: ScrollingFrame
local tab = "Creatures"
local setTab: (string) -> () = function(_name: string) end
local lastSig = ""
local previews: { Preview.Handle } = {}
local toast: (string, string?) -> () = function(_text: string, _kind: string?) end
local openShop: (string?) -> () = function(_id: string?) end
local claiming = false

local function clear()
	for _, h in previews do
		h.destroy()
	end
	table.clear(previews)
	for _, c in content:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
end

local function text(parent: Instance, s: string, props: { [string]: any }?): TextLabel
	local p: { [string]: any } = { AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.fromScale(1, 0), TextSize = 14 }
	for k, v in (props or {}) :: { [string]: any } do
		p[k] = v
	end
	return Theme.label(parent, s, p)
end

local function habitatsOf(species: string): string
	local names = {}
	for _, h in Habitats.List do
		for _, zone in h.zones do
			if zone.spawns[species] then
				table.insert(names, h.name)
				break
			end
		end
	end
	return if #names > 0 then table.concat(names, ", ") else "unknown"
end

local function bar(parent: Instance, frac: number, color: Color3?)
	local back = Theme.frame(parent, {
		Size = UDim2.new(1, 0, 0, 8),
		BackgroundColor3 = Theme.Colors.panel3,
		BackgroundTransparency = 0,
	})
	Theme.corner(back, 4)
	local fill = Theme.frame(back, {
		Size = UDim2.fromScale(math.clamp(frac, 0, 1), 1),
		BackgroundColor3 = color or Theme.Colors.gold,
		BackgroundTransparency = 0,
	})
	Theme.corner(fill, 4)
end

local function renderCreatures(snap: { [string]: any })
	local j = snap.journal
	local caught = 0
	for _, id in Monsters.Order do
		if j.caught[id] then
			caught += 1
		end
	end
	local reachable = CosmeticRules.obtainableVariants()
	local totalV, foundV = 0, 0
	for key in reachable do
		totalV += 1
		if j.variants[key] then
			foundV += 1
		end
	end
	local head = Theme.card(content, { Size = UDim2.new(1, 0, 0, 56), LayoutOrder = 0 })
	Theme.pad(head, 10, 8)
	text(head, `Species caught {caught}/{#Monsters.Order}   ·   Natural variants found {foundV}/{totalV}`, {
		Font = Theme.Bold,
		TextSize = 16,
	})
	local barHolder = Theme.frame(head, {
		Position = UDim2.fromOffset(0, 28),
		Size = UDim2.new(1, 0, 0, 10),
		BackgroundTransparency = 1,
	})
	bar(barHolder, (caught + foundV) / math.max(1, #Monsters.Order + totalV))
	for i, id in Monsters.Order do
		local s = Monsters.Species[id]
		local known = j.seen[id] == true
		local c = Theme.card(content, { Size = UDim2.new(1, 0, 0, 150), LayoutOrder = i })
		local art = Theme.frame(c, {
			Position = UDim2.fromOffset(8, 8),
			Size = UDim2.fromOffset(150, 134),
			BackgroundColor3 = Color3.fromRGB(12, 9, 18),
			BackgroundTransparency = 0,
		})
		Theme.corner(art, 8)
		local h = Preview.mount(art)
		h.set(CREATURE_ART[id])
		if not known then
			-- Undiscovered: a dark silhouette only.
			local vp = art:FindFirstChildOfClass("ViewportFrame")
			if vp then
				vp.ImageColor3 = Color3.new(0, 0, 0)
			end
		end
		table.insert(previews, h)
		local info = Theme.frame(c, {
			Position = UDim2.fromOffset(170, 8),
			Size = UDim2.new(1, -180, 1, -16),
			BackgroundTransparency = 1,
		})
		Theme.list(info, 3)
		if known then
			Theme.heading(info, s.name, {
				TextSize = 24,
				Size = UDim2.new(1, 0, 0, 28),
				TextColor3 = Monsters.RarityColor[s.rarity],
			})
			text(info, `{s.family}  ·  {s.rarity}  ·  {if j.caught[id] then "caught" else "seen"}`, {
				TextColor3 = Theme.Colors.dim,
			})
			text(info, s.blurb)
			local chips = Theme.frame(info, { Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1 })
			Theme.list(chips, 4, true)
			for k, v in Variants.List do
				if reachable[`{id}:{v.id}`] then
					local found = j.variants[`{id}:{v.id}`] == true
					Theme.chip(
						chips,
						if found then v.label else "???",
						if found then Theme.Colors.panel3 else Theme.Colors.secondary,
						{ LayoutOrder = k, TextColor3 = if found then Theme.Colors.clue else Theme.Colors.dim }
					)
				end
			end
		else
			Theme.heading(info, "??? Unknown creature", {
				TextSize = 24,
				Size = UDim2.new(1, 0, 0, 28),
				TextColor3 = Theme.Colors.dim,
			})
			text(info, `Rarity: {s.rarity}. Found in: {habitatsOf(id)}. Inspect one to fill in this page.`)
		end
	end
end

local function renderHabitats(snap: { [string]: any })
	local j = snap.journal
	for i, h in Habitats.List do
		local species: { [string]: boolean } = {}
		local list = {}
		for _, zone in h.zones do
			for sp in zone.spawns do
				if not species[sp] then
					species[sp] = true
					table.insert(list, sp)
				end
			end
		end
		table.sort(list)
		local have = 0
		local names = {}
		for _, sp in list do
			if j.caught[sp] then
				have += 1
			end
			table.insert(names, if j.seen[sp] then Monsters.Species[sp].name else "???")
		end
		local c = Theme.card(content, {
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = i,
		})
		Theme.pad(c, 10, 8)
		Theme.list(c, 4)
		Theme.heading(c, h.name, { TextSize = 22, Size = UDim2.new(1, 0, 0, 26) })
		text(c, `Caught {have}/{#list}: {table.concat(names, ", ")}`, {
			TextColor3 = if have == #list then Theme.Colors.good else Theme.Colors.text,
		})
		bar(c, have / math.max(1, #list), if have == #list then Theme.Colors.good else nil)
	end
end

local function renderRewards(snap: { [string]: any })
	local c = snap.cosmetics
	if not c then
		Theme.notice(content, "Loading rewards...", "loading")
		return
	end
	if snap.cosmeticsWritable ~= true then
		Theme.notice(content, "Saving is unavailable right now, so rewards can't be claimed yet.", "error")
	end
	for i, m in Cosmetics.Milestones do
		local p = c.progress[m.id]
		if p then
			local r = Theme.card(content, {
				Size = UDim2.fromScale(1, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				LayoutOrder = i,
			})
			Theme.pad(r, 10, 8)
			Theme.list(r, 4)
			Theme.heading(r, m.name, { TextSize = 21, Size = UDim2.new(1, 0, 0, 26) })
			local items = {}
			for _, id in CosmeticRules.rewardsFor(m.id) do
				table.insert(items, Cosmetics.ById[id].name)
			end
			text(r, `Reward: {table.concat(items, ", ")}`, { TextColor3 = Theme.Colors.ghost })
			text(
				r,
				if p.claimed
					then "Claimed"
					elseif p.done then "Complete! Claim your reward."
					else `Progress {p.have}/{p.need}`,
				{
					TextColor3 = if p.claimed
						then Theme.Colors.dim
						elseif p.done then Theme.Colors.good
						else Theme.Colors.text,
					Font = Theme.Bold,
				}
			)
			bar(r, p.have / math.max(1, p.need), if p.done then Theme.Colors.good else nil)
			local row = Theme.frame(r, { Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1 })
			Theme.list(row, 8, true)
			if p.done and not p.claimed then
				local b = Theme.button(row, "Claim", function()
					if claiming then
						return
					end
					claiming = true
					local ok, reason = State.invoke("Cosmetic", "claim", m.id)
					claiming = false
					if not ok then
						toast(reason or "Couldn't claim that yet", "error")
					end
				end, { Size = UDim2.fromOffset(120, 38), LayoutOrder = 1 })
				Theme.setEnabled(b, snap.cosmeticsWritable == true)
			end
			local first = CosmeticRules.rewardsFor(m.id)[1]
			if first then
				Theme.button(row, "Preview reward", function()
					openShop(first)
				end, { Size = UDim2.fromOffset(160, 38), LayoutOrder = 2 }, "secondary")
			end
		end
	end
end

local function render(force: boolean?)
	if not panel.Visible then
		return
	end
	local snap = State.snap
	if not snap or not snap.journal then
		return
	end
	local ok, sig = pcall(function()
		return HttpService:JSONEncode({
			tab,
			snap.journal,
			snap.cosmetics and snap.cosmetics.progress,
			snap.cosmeticsWritable,
		})
	end)
	local s = if ok then sig else tostring(os.clock())
	if s == lastSig and not force then
		return
	end
	lastSig = s
	clear()
	setTab(tab)
	if tab == "Creatures" then
		renderCreatures(snap)
	elseif tab == "Habitats" then
		renderHabitats(snap)
	else
		renderRewards(snap)
	end
end

function JournalUI.open()
	panel.Visible = true
	render(true)
	task.spawn(State.invoke, "Ack", "journal")
end

function JournalUI.close()
	panel.Visible = false
	clear()
	lastSig = ""
end

function JournalUI.isOpen(): boolean
	return (panel :: any) ~= nil and panel.Visible
end

function JournalUI.root(): GuiObject?
	return panel
end

function JournalUI.toggle()
	if panel.Visible then
		JournalUI.close()
	else
		JournalUI.open()
	end
end

function JournalUI.mount(gui: ScreenGui, toastFn: ((string, string?) -> ())?, shopFn: ((string?) -> ())?)
	if toastFn then
		toast = toastFn
	end
	if shopFn then
		openShop = shopFn
	end
	local modal = Theme.modal(gui, "Bestiary", JournalUI.close, 760, 600)
	panel = modal.root
	setTab = Theme.tabs(modal.body, { "Creatures", "Habitats", "Rewards" }, function(name)
		tab = name
		render(true)
	end)
	content = Theme.scroll(modal.body, { Position = UDim2.fromOffset(0, 48), Size = UDim2.new(1, 0, 1, -48) })
	Theme.list(content, 8)
	State.Changed:Connect(function()
		render()
	end)
end

return JournalUI
