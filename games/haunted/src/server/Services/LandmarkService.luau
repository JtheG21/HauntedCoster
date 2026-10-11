--!strict
-- Landmarks: investigate prompts that record journal clues, set progression flags (shortcut, bell),
-- and gate the Sealed Crypt. The client hides the gates locally; the server enforces access.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local World = require(Shared:WaitForChild("Config"):WaitForChild("World"))
local Economy = require(Shared.Config:WaitForChild("Economy"))
local ProfileRules = require(Shared:WaitForChild("Rules"):WaitForChild("ProfileRules"))
local PlayerDataService = require(script.Parent.PlayerDataService)
local StateService = require(script.Parent.StateService)
local PlotService = require(script.Parent.PlotService)

type Profile = ProfileRules.Profile

local LandmarkService = {}

local MAX_DISTANCE = 18

local started = false
local anchors: { [string]: BasePart } = {}
local investigatedCallbacks: { (Player, string) -> () } = {}

function LandmarkService.landmarkCount(profile: Profile): number
	local n = 0
	for _, lm in World.Landmarks do
		if profile.journal.clues[lm.id] then
			n += 1
		end
	end
	return n
end

function LandmarkService.cryptOpen(profile: Profile): boolean
	local tier = Economy.HouseTiers[profile.houseTier + 1]
	return tier ~= nil
		and tier.unlocksCrypt
		and LandmarkService.landmarkCount(profile) >= World.Graveyard.cryptLandmarksNeeded
end

function LandmarkService.onInvestigated(cb: (Player, string) -> ())
	table.insert(investigatedCallbacks, cb)
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

function LandmarkService.investigate(player: Player, lmId: string)
	local lm = World.landmarkById(lmId)
	local anchor = anchors[lmId]
	local root = rootOf(player)
	local profile = PlayerDataService.get(player)
	if not (lm and anchor and root and profile) then
		return
	end
	if (root.Position - anchor.Position).Magnitude > MAX_DISTANCE then
		return
	end
	if profile.journal.clues[lm.id] then
		StateService.toast(player, `{lm.name}: already in your journal.`, "info")
		return
	end
	if lm.requiresFlag and not profile.flags[lm.requiresFlag] then
		StateService.toast(
			player,
			`{lm.name}: the bell hangs silent. Perhaps once your ghost train has had a rider...`,
			"info"
		)
		return
	end
	PlayerDataService.update(player, function(p)
		p.journal.clues[lm.id] = true
		if lm.setsFlag then
			p.flags[lm.setsFlag] = true
		end
	end)
	StateService.toast(player, `Clue recorded: {lm.clue}`, "clue")
	PlotService.rebuildTrophies(player)
	for _, cb in investigatedCallbacks do
		task.spawn(cb, player, lm.id)
	end
end

function LandmarkService.start(landmarkAnchors: { [string]: BasePart }, cryptGate: BasePart)
	if started then
		return
	end
	started = true
	anchors = landmarkAnchors
	for id, anchor in anchors do
		local lm = World.landmarkById(id)
		if lm then
			local prompt = Instance.new("ProximityPrompt")
			prompt.Name = "Investigate"
			prompt.ActionText = "Investigate"
			prompt.ObjectText = lm.name
			prompt.HoldDuration = 0.5
			prompt.MaxActivationDistance = 12
			prompt.RequiresLineOfSight = false
			prompt.Parent = anchor
			prompt.Triggered:Connect(function(player)
				if PlayerDataService.get(player) then
					LandmarkService.investigate(player, id)
				end
			end)
		end
	end

	StateService.addProvider(function(player, snap)
		local profile = PlayerDataService.get(player)
		if profile then
			snap.cryptOpen = LandmarkService.cryptOpen(profile)
			snap.landmarkCount = LandmarkService.landmarkCount(profile)
		end
	end)

	-- Server-side enforcement: anyone inside the crypt without access is moved back out of the gate.
	local crypt = World.Graveyard.crypt
	local outside = Vector3.new(World.Graveyard.cryptGate.X, 3, crypt.z2 + 6)
	task.spawn(function()
		while true do
			task.wait(1)
			for _, player in Players:GetPlayers() do
				local root = rootOf(player)
				local profile = PlayerDataService.get(player)
				if root and profile and World.inRect(crypt, root.Position.X, root.Position.Z) then
					if not LandmarkService.cryptOpen(profile) then
						local character = player.Character
						if character then
							character:PivotTo(CFrame.new(outside))
						end
						StateService.toast(
							player,
							"The crypt rejects you. Investigate 3 landmarks and restore your house first.",
							"error"
						)
					end
				end
			end
		end
	end)
	-- Keep the gate's collision on server-side; access is granted per player on their client.
	cryptGate.CanCollide = true
end

return LandmarkService
