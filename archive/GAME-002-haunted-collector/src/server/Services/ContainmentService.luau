--!strict
-- Owned monsters at home: passive income after acclimation, capped offline income, pen residents and
-- exhibit placement (monsters on exhibit boost the train instead of earning passive income).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Rules = Shared:WaitForChild("Rules")
local Economy = require(Config:WaitForChild("Economy"))
local World = require(Config:WaitForChild("World"))
local Monsters = require(Config:WaitForChild("Monsters"))
local EconomyRules = require(Rules:WaitForChild("EconomyRules"))
local ExhibitRules = require(Rules:WaitForChild("ExhibitRules"))
local ProfileRules = require(Rules:WaitForChild("ProfileRules"))
local LookRules = require(Rules:WaitForChild("LookRules"))
local CatalogConfig = require(Config:WaitForChild("Catalog"))
local Remotes = require(script.Parent.Parent.Remotes)
local MonsterModels = require(script.Parent.Parent.World.MonsterModels)
local PlayerDataService = require(script.Parent.PlayerDataService)
local StateService = require(script.Parent.StateService)
local PlotService = require(script.Parent.PlotService)

local ContainmentService = {}

local MAX_RESIDENT_MODELS = 6

local started = false
local carry: { [Player]: number } = {} -- fractional coins not yet credited
local exhibitChanged: { () -> () } = {}

function ContainmentService.onExhibitsChanged(cb: () -> ())
	table.insert(exhibitChanged, cb)
end

-- `facing` is the world direction the model looks (the plot's front, towards the hub).
local function placeModel(
	parent: Instance,
	speciesId: string,
	variantId: string,
	pos: Vector3,
	scale: number,
	facing: Vector3,
	look: LookRules.Appearance?
)
	local model = MonsterModels.build(speciesId, variantId)
	if look then
		-- Equipped cosmetics replicate as attributes; client/Art/Creatures turns them into a look.
		model:SetAttribute("SkinId", look.skin)
		model:SetAttribute("AuraId", look.aura)
	end
	local species = Monsters.Species[speciesId]
	if scale ~= 1 then
		model:ScaleTo(scale)
		model:SetAttribute("ArtScale", scale) -- client art (client/Art/Creatures) scales to match
	end
	model:SetAttribute("Display", true) -- pen or exhibit: idle display animation, no roaming
	local at = pos + Vector3.new(0, species.hover * scale, 0)
	model:PivotTo(CFrame.lookAt(at, at + facing))
	model.Parent = parent
end

local function lookOf(profile: ProfileRules.Profile, m: ProfileRules.OwnedMonster): LookRules.Appearance
	return LookRules.appearance(
		profile.cosmetics,
		{ Items = CatalogConfig.Items, Rewards = CatalogConfig.Rewards },
		m.uid,
		m.species,
		m.variant
	)
end

-- Rebuilds the pen residents and exhibit models on the player's plot.
function ContainmentService.refreshVisuals(player: Player)
	local i = PlotService.plotIndex(player)
	local profile = PlayerDataService.get(player)
	local plot = i and PlotService.plotModel(i)
	if not (i and profile and plot) then
		return
	end
	local facing = World.plotDirToWorld(i, Vector3.new(0, 0, -1))
	local pen = plot:FindFirstChild("Pen")
	local residents = pen and pen:FindFirstChild("Residents")
	if residents then
		residents:ClearAllChildren()
		local shown = 0
		for _, m in profile.owned do
			if ProfileRules.exhibitSlotOf(profile, m.uid) == nil and shown < MAX_RESIDENT_MODELS then
				shown += 1
				local col = (shown - 1) % 3
				local row = math.floor((shown - 1) / 3)
				local pos = World.plotToWorld(i, World.Plot.pen + Vector3.new(-4.5 + col * 4.5, 0.4, -3 + row * 5))
				placeModel(residents, m.species, m.variant, pos, 0.55, facing, lookOf(profile, m))
			end
		end
	end
	local exhibits = plot:FindFirstChild("Exhibits")
	if exhibits then
		local slots = Economy.HouseTiers[profile.houseTier + 1].exhibitSlots
		for slot = 1, #World.Plot.exhibitSlots do
			local ped = exhibits:FindFirstChild(`Exhibit{slot}`)
			if ped and ped:IsA("BasePart") then
				local old = ped:FindFirstChild("Display")
				if old then
					old:Destroy()
				end
				local active = slot <= slots
				ped.Transparency = 1 -- the plinth is art (TASK-0046); locked slots say so on the label
				ped:SetAttribute("Active", active)
				local label = ped:FindFirstChild("Label")
				local text = label and label:FindFirstChild("Text")
				local uid: string? = nil
				for _, e in profile.exhibits do
					if e.slot == slot then
						uid = e.uid
					end
				end
				local m = uid and ProfileRules.findOwned(profile, uid)
				if text and text:IsA("TextLabel") then
					text.Text = if not active
						then `Exhibit {slot} (locked)`
						elseif m then `Exhibit {slot}: {Monsters.Species[m.species].name}`
						else `Exhibit {slot}: empty`
				end
				if m and active then
					local holder = Instance.new("Folder")
					holder.Name = "Display"
					holder.Parent = ped
					placeModel(
						holder,
						m.species,
						m.variant,
						ped.Position + Vector3.new(0, 0.5, 0),
						0.8,
						facing,
						lookOf(profile, m)
					)
				end
			end
		end
	end
end

local function onSetExhibit(player: Player, slot: any, uid: any): (boolean, string?)
	if not Remotes.allow(player, "SetExhibit", 4, 6) then
		return false, "Slow down"
	end
	local profile = PlayerDataService.get(player)
	local refusal = ExhibitRules.setRefusal(profile, slot, uid)
	if refusal then
		return false, refusal
	end
	PlayerDataService.update(player, function(p)
		local kept = {}
		for _, e in p.exhibits do
			if e.slot ~= slot and e.uid ~= uid then
				table.insert(kept, e)
			end
		end
		if uid then
			table.insert(kept, { slot = slot, uid = uid :: string })
		end
		p.exhibits = kept
	end)
	ContainmentService.refreshVisuals(player)
	for _, cb in exhibitChanged do
		task.spawn(cb)
	end
	return true, nil
end

-- Shared by the SetExhibit remote and the Studio test scenarios.
ContainmentService.setExhibit = onSetExhibit

local function grantOffline(player: Player)
	local profile = PlayerDataService.get(player)
	if not profile then
		return
	end
	local amount, seconds = EconomyRules.offlineIncome(profile, os.time())
	if amount > 0 then
		PlayerDataService.update(player, function(p)
			EconomyRules.addCoins(p, amount)
		end)
		StateService.toast(player, `While you were away ({math.floor(seconds / 60)} min): +{amount} coins`, "success")
	end
end

function ContainmentService.start()
	if started then
		return
	end
	started = true
	Remotes.func("SetExhibit").OnServerInvoke = onSetExhibit
	PlotService.onAssigned(function(player)
		ContainmentService.refreshVisuals(player)
	end)
	PlayerDataService.onLoaded(function(player)
		grantOffline(player)
	end)
	StateService.addProvider(function(player, snap)
		local profile = PlayerDataService.get(player)
		if profile then
			snap.incomeRate = EconomyRules.incomeRate(profile, os.time())
			snap.capacity = ProfileRules.capacity(profile)
			snap.acclimationSeconds = Economy.AcclimationSeconds
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		carry[player] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(Economy.IncomeTickSeconds)
			local now = os.time()
			for _, player in Players:GetPlayers() do
				local profile = PlayerDataService.get(player)
				if profile and PlotService.plotIndex(player) then
					local rate = EconomyRules.incomeRate(profile, now)
					if rate > 0 then
						local pending = (carry[player] or 0) + rate * Economy.IncomeTickSeconds
						local whole = math.floor(pending)
						carry[player] = pending - whole
						if whole > 0 then
							PlayerDataService.update(player, function(p)
								EconomyRules.addCoins(p, whole)
							end)
						end
					end
				end
			end
		end
	end)
end

return ContainmentService
