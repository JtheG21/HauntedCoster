--!strict
-- Validated purchases: speed upgrades and house tiers. The client only names the item; price,
-- funds and requirements are checked here (EconomyRules), and the purchase is applied atomically.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Economy = require(Shared:WaitForChild("Config"):WaitForChild("Economy"))
local EconomyRules = require(Shared:WaitForChild("Rules"):WaitForChild("EconomyRules"))
local Remotes = require(script.Parent.Parent.Remotes)
local PlayerDataService = require(script.Parent.PlayerDataService)
local StateService = require(script.Parent.StateService)
local PlotService = require(script.Parent.PlotService)
local MovementService = require(script.Parent.MovementService)

local EconomyService = {}

local started = false
local tierCallbacks: { (Player, number) -> () } = {}

function EconomyService.onTierChanged(cb: (Player, number) -> ())
	table.insert(tierCallbacks, cb)
end

-- `expected` is the level/tier the client saw when it pressed the button. A repeated click (or a queued
-- duplicate request) arrives with a stale value and is rejected, so one click buys exactly one level.
local function onPurchase(player: Player, item: any, expected: any): (boolean, string?)
	if not Remotes.allow(player, "Purchase", 2, 3) then
		return false, "Slow down"
	end
	if item ~= "speed" and item ~= "house" then
		return false, "Unknown item"
	end
	local profile = PlayerDataService.get(player)
	if not profile then
		return false, "Still loading"
	end
	if not PlotService.plotIndex(player) then
		return false, "You need a home plot"
	end
	local current = if item == "speed" then profile.speedLevel else profile.houseTier
	if type(expected) ~= "number" or expected ~= current then
		return false, "Already upgraded"
	end
	-- Validate and apply in one synchronous step (no yield between the check and the charge).
	local ok, reason = EconomyRules.purchase(profile, item)
	if not ok then
		return false, reason
	end
	PlayerDataService.markDirty(player)
	if item == "speed" then
		MovementService.apply(player)
		StateService.toast(
			player,
			`Speed upgraded to level {profile.speedLevel}! You run faster (and carry faster).`,
			"success"
		)
	else
		local tier = Economy.HouseTiers[profile.houseTier + 1]
		PlotService.rebuildHouse(player)
		StateService.toast(player, `Your house is now a {tier.name}! {tier.blurb}`, "success")
		for _, cb in tierCallbacks do
			task.spawn(cb, player, profile.houseTier)
		end
	end
	return true, nil
end

-- Shared by the Purchase remote and the Studio test scenarios.
EconomyService.purchase = onPurchase

function EconomyService.start()
	if started then
		return
	end
	started = true
	Remotes.func("Purchase").OnServerInvoke = onPurchase
end

return EconomyService
