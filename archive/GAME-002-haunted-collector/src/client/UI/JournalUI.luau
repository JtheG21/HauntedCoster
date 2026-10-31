--!strict
-- Collection journal: known/unknown monsters, their variants and where they live, and trophies.
-- Completion only gives cosmetic trophies on the mansion plot.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local Monsters = require(Config:WaitForChild("Monsters"))
local Variants = require(Config:WaitForChild("Variants"))
local Habitats = require(Config:WaitForChild("Habitats"))
local MilestoneRules = require(ReplicatedStorage.Shared.Rules.MilestoneRules)
local Theme = require(script.Parent.Theme)
local State = require(script.Parent.Parent.State)

local JournalUI = {}

local panel: Frame
local content: ScrollingFrame
local lastSig = ""
local roster = MilestoneRules.rosterFrom(Monsters.Order, Habitats.List)
local claimMessage: string? = nil -- the server's last answer to a Claim, shown with the milestones
local render

local function clear()
	for _, c in content:GetChildren() do
		if not c:IsA("UIListLayout") then
			c:Destroy()
		end
	end
end

local function card(): Frame
	local f = Theme.frame(content, {
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Theme.Colors.panel2,
	})
	Theme.corner(f, 8)
	Theme.pad(f, 8)
	Theme.list(f, 3)
	return f
end

local function text(parent: Instance, s: string, props: { [string]: any }?)
	local p: { [string]: any } = { AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.fromScale(1, 0), TextSize = 14 }
	for k, v in (props or {}) :: { [string]: any } do
		p[k] = v
	end
	return Theme.label(parent, s, p)
end

-- Where `species` spawns, for the unknown-creature hint: every habitat in the rotation that has it, with
-- the zone names for the active habitat.
local function habitatsOf(species: string): string
	local names = {}
	for _, h in Habitats.List do
		local zones = {}
		for _, zone in h.zones do
			if zone.spawns[species] then
				table.insert(zones, zone.name)
			end
		end
		if #zones > 0 then
			table.insert(names, if h == Habitats.active() then `{h.name} ({table.concat(zones, ", ")})` else h.name)
		end
	end
	return if #names > 0 then table.concat(names, "; ") else "unknown"
end

-- True if `species` can spawn in any of `zoneIds` (from the zone spawn tables), so the journal lists
-- zone-only variants exactly for the species that can roll them.
local function spawnsIn(species: string, zoneIds: { string }): boolean
	for _, zoneId in zoneIds do
		local zone = Habitats.anyZoneById(zoneId)
		if zone and zone.spawns[species] then
			return true
		end
	end
	return false
end

function render(force: boolean?)
	if not panel.Visible then
		return
	end
	local snap = State.snap
	if not snap or not snap.journal then
		return
	end
	local j = snap.journal
	local sig = table.concat({
		tostring(#(snap.owned or {})),
		tostring(next(j.seen) ~= nil),
	}, ":")
	for k in j.seen do
		sig ..= k
	end
	for k in j.variants do
		sig ..= k
	end
	for k in j.caught do
		sig ..= "c" .. k
	end
	local claimed = if snap.cosmetics then snap.cosmetics.rewardsClaimed else {}
	for k in claimed do
		sig ..= "r" .. k
	end
	sig ..= tostring(claimMessage)
	if sig == lastSig and not force then
		return
	end
	lastSig = sig
	clear()

	local caught, seen = 0, 0
	for _, id in Monsters.Order do
		if j.caught[id] then
			caught += 1
		end
		if j.seen[id] then
			seen += 1
		end
	end
	local summary = card()
	text(summary, `Caught {caught}/{#Monsters.Order} species  ·  Seen {seen}`, { Font = Theme.Bold, TextSize = 16 })
	text(summary, "Trophies for milestones appear on your plot (cosmetic only).", { TextColor3 = Theme.Colors.dim })

	-- Collection milestones: Claim grants the reward once (the server decides); Claimed rewards sit in Owned.
	local mh = card()
	text(mh, "Collection rewards", { Font = Theme.Bold, TextSize = 18 })
	if claimMessage then
		text(mh, claimMessage, { TextColor3 = Theme.Colors.gold })
	end
	for _, st in MilestoneRules.statuses(j, snap.cosmetics, roster) do
		local row = card()
		text(row, st.title, { Font = Theme.Bold })
		if st.state == "claimed" then
			text(row, "Claimed", { TextColor3 = Theme.Colors.good })
		elseif st.state == "eligible" then
			Theme.button(row, "Claim", function()
				local ok, msg = State.invoke("ClaimReward", st.id)
				claimMessage = if ok == true
					then nil
					else (if type(msg) == "string" then msg else "Something went wrong. Try again.")
				render(true)
			end, { Size = UDim2.fromOffset(90, 34) })
		else
			text(row, `{st.have}/{st.need}`, { TextColor3 = Theme.Colors.dim })
		end
	end

	for _, id in Monsters.Order do
		local s = Monsters.Species[id]
		local c = card()
		if j.seen[id] then
			text(c, `{s.name}{if j.caught[id] then "  (caught)" else "  (seen)"}`, {
				Font = Theme.Title,
				TextSize = 22,
				TextColor3 = Monsters.RarityColor[s.rarity],
			})
			text(c, `{s.family} · {s.rarity} · {s.incomePerSecond}/s base`)
			text(c, s.blurb, { TextColor3 = Theme.Colors.dim })
			local found = {}
			for _, v in Variants.List do
				local allowed = v.zones == nil or spawnsIn(id, v.zones)
				if allowed then
					table.insert(found, if j.variants[id .. ":" .. v.id] then v.label else "???")
				end
			end
			text(c, `Variants: {table.concat(found, ", ")}`, { TextColor3 = Theme.Colors.clue })
		else
			text(c, "??? Unknown creature", { Font = Theme.Title, TextSize = 22, TextColor3 = Theme.Colors.dim })
			text(c, `Rarity: {s.rarity}. Seen around: {habitatsOf(id)}. Inspect one to learn more.`)
		end
	end
end

function JournalUI.open()
	panel.Visible = true
	render(true)
	task.spawn(State.invoke, "Ack", "journal")
end

function JournalUI.close()
	panel.Visible = false
end

function JournalUI.toggle()
	if panel.Visible then
		JournalUI.close()
	else
		JournalUI.open()
	end
end

function JournalUI.mount(gui: ScreenGui)
	panel = Theme.panel(gui, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0, 520, 0.75, 0),
		Visible = false,
		ZIndex = 5,
	})
	local size = Instance.new("UISizeConstraint")
	size.MaxSize = Vector2.new(520, 600)
	size.MinSize = Vector2.new(300, 260)
	size.Parent = panel
	Theme.pad(panel, 12)
	Theme.label(
		panel,
		"Monster Journal",
		{ Font = Theme.Title, TextSize = 30, Size = UDim2.new(1, -60, 0, 34), TextColor3 = Theme.Colors.gold }
	)
	Theme.button(panel, "X", JournalUI.close, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromOffset(40, 34),
		BackgroundColor3 = Theme.Colors.buttonOff,
	})
	content = Instance.new("ScrollingFrame")
	content.Position = UDim2.fromOffset(0, 44)
	content.Size = UDim2.new(1, 0, 1, -44)
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

return JournalUI
