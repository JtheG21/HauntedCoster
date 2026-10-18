--!strict
-- Equip and remove ghost skins and auras (TASK-0062). The client only names a ghost, a slot and an item;
-- the server checks ownership, species and variant, saves the choice and rebuilds the plot models, which
-- replicate the look to everyone. Cosmetics never touch gameplay.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared.Config.Catalog)
local CaptureFxRules = require(Shared.Rules.CaptureFxRules)
local CosmeticRules = require(Shared.Rules.CosmeticRules)
local LookRules = require(Shared.Rules.LookRules)
local ProfileRules = require(Shared.Rules.ProfileRules)
local Remotes = require(script.Parent.Parent.Remotes)
local ContainmentService = require(script.Parent.ContainmentService)
local PlayerDataService = require(script.Parent.PlayerDataService)
local StateService = require(script.Parent.StateService)

local CosmeticService = {}

local started = false

local function catalog(): CosmeticRules.Catalog
	return { Items = Catalog.Items, Rewards = Catalog.Rewards }
end

-- Shared by the remote and the Studio scenarios. Returns ok and a player-facing message.
function CosmeticService.equip(player: Player, uid: any, slot: any, id: any): (boolean, string?)
	local req, bad = LookRules.parse(uid, slot, id)
	if not req then
		return false, bad
	end
	local profile = PlayerDataService.get(player)
	if not profile then
		return false, "Your data is still loading."
	end
	local m = ProfileRules.findOwned(profile, req.uid)
	if not m then
		return false, LookRules.message("noGhost")
	end
	local ok, reason = false, nil :: string?
	if req.id == nil then
		ok, reason = true, nil -- removing never needs a compatibility check
	else
		reason = LookRules.variantRefusal(req.slot, m.variant)
		if reason then
			return false, reason
		end
		-- Dry run on a copy, so a refusal leaves the saved state untouched.
		local probe = CosmeticRules.sanitize((profile.cosmetics or {}) :: any, { [m.uid] = m.species }, catalog())
		local err
		ok, err = CosmeticRules.equipLook(probe, catalog(), req.uid, m.species, req.slot, req.id)
		if not ok then
			return false, LookRules.message(err)
		end
	end
	local changed = true
	local applied = PlayerDataService.update(player, function(p)
		if req.id == nil then
			changed = CosmeticRules.removeLook(p.cosmetics, req.uid, req.slot)
		else
			changed = CosmeticRules.equipLook(p.cosmetics, catalog(), req.uid, m.species, req.slot, req.id)
		end
	end)
	if not changed then
		return false, "Something went wrong. Try again."
	end
	if not applied then
		return false, "Your data is still loading."
	end
	ContainmentService.refreshVisuals(player)
	StateService.markDirty(player)
	return true, nil
end

-- Equip or remove the capture effect (id = nil removes). Nothing else about the player changes.
function CosmeticService.equipCaptureEffect(player: Player, id: any): (boolean, string?)
	local req, bad = CaptureFxRules.parse(id)
	if not req then
		return false, bad
	end
	local profile = PlayerDataService.get(player)
	if not profile then
		return false, "Your data is still loading."
	end
	local failure: string? = nil
	local applied = PlayerDataService.update(player, function(p)
		local ok, reason = CosmeticRules.setCaptureEffect(p.cosmetics, catalog(), req.id)
		if not ok then
			failure = CaptureFxRules.message(reason)
		end
	end)
	if failure then
		return false, failure
	end
	if not applied then
		return false, "Your data is still loading."
	end
	StateService.markDirty(player)
	return true, nil
end

function CosmeticService.start()
	if started then
		return
	end
	started = true
	Remotes.func("EquipLook").OnServerInvoke = function(player, uid, slot, id)
		if not Remotes.allow(player, "EquipLook", 6, 8) then
			return false, "Slow down."
		end
		return CosmeticService.equip(player, uid, slot, id)
	end
	Remotes.func("EquipCaptureEffect").OnServerInvoke = function(player, id)
		if not Remotes.allow(player, "EquipCaptureEffect", 6, 8) then
			return false, "Slow down."
		end
		return CosmeticService.equipCaptureEffect(player, id)
	end
end

return CosmeticService
