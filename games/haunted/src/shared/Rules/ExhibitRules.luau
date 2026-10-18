--!strict
-- Pure input checks for the SetExhibit remote (TASK-0058). The service keeps the rate limit and the update.

local Shared = script.Parent.Parent
local Economy = require(Shared.Config.Economy)
local ProfileRules = require(script.Parent.ProfileRules)

type Profile = ProfileRules.Profile

local ExhibitRules = {}

-- The player-facing refusal for a SetExhibit request, or nil when it is allowed. `slot` and `uid` come
-- straight from the client, so they are untyped. The order is loading, slot shape, slot range, ownership.
function ExhibitRules.setRefusal(profile: Profile?, slot: any, uid: any): string?
	if not profile then
		return "Still loading"
	end
	if type(slot) ~= "number" or slot % 1 ~= 0 then
		return "Bad slot"
	end
	local tier = Economy.HouseTiers[profile.houseTier + 1]
	if type(profile.houseTier) ~= "number" or profile.houseTier % 1 ~= 0 or not tier then
		return "Something went wrong. Try again after rejoining."
	end
	local slots = tier.exhibitSlots
	if slot < 1 or slot > slots then
		return "That exhibit slot is locked"
	end
	if uid ~= nil and (type(uid) ~= "string" or not ProfileRules.findOwned(profile, uid)) then
		return "You don't own that monster"
	end
	return nil
end

return ExhibitRules
