--!strict
-- Journal milestone status (TASK-0066). Pure. Eligibility reads only the journal (what capture recorded), so
-- no cosmetic, skin or purchase can complete a discovery. Claiming is CosmeticRules.claimReward; this decides
-- whether the Claim button is offered and whether the server allows it.

local CosmeticRules = require(script.Parent.CosmeticRules)
local Milestones = require(script.Parent.Parent.Config.Milestones)

local MilestoneRules = {}

export type Journal = { seen: { [string]: boolean }, caught: { [string]: boolean }, variants: { [string]: boolean } }
export type Roster = { species: { string }, habitatSpecies: { [string]: { string } } }
export type Status = { id: string, title: string, state: string, have: number, need: number }

-- The real roster: every species, and the species that can spawn in each habitat's zones.
function MilestoneRules.rosterFrom(order: { string }, habitats: { any }): Roster
	local bySpecies: { [string]: { string } } = {}
	for _, h in habitats do
		local seen: { [string]: boolean } = {}
		local list: { string } = {}
		for _, zone in h.zones do
			for sp in zone.spawns do
				if not seen[sp] then
					seen[sp] = true
					table.insert(list, sp)
				end
			end
		end
		table.sort(list)
		bySpecies[h.id] = list
	end
	return { species = order, habitatSpecies = bySpecies }
end

-- Untrusted remote argument: a milestone ID.
function MilestoneRules.parse(id: any): (Milestones.Milestone?, string?)
	if not CosmeticRules.isId(id) then
		return nil, "Something went wrong. Try again."
	end
	local m = Milestones.ById[id :: string]
	if not m then
		return nil, "That milestone isn't available."
	end
	return m, nil
end

local function variantFound(journal: Journal, variant: string): boolean
	for key in journal.variants do
		local _, v = string.match(key, "^(%w+):(%w+)$")
		if v == variant then
			return true
		end
	end
	return false
end

-- (have, need) progress toward a milestone.
function MilestoneRules.progress(journal: Journal, m: Milestones.Milestone, roster: Roster): (number, number)
	if m.kind == "variant" then
		return if m.variant and variantFound(journal, m.variant) then 1 else 0, 1
	end
	local pool = roster.species
	if m.kind == "habitat" then
		pool = roster.habitatSpecies[m.habitat or ""] or {}
	end
	local have = 0
	for _, sp in pool do
		if journal.caught[sp] then
			have += 1
		end
	end
	local need = if m.kind == "bestiary" and m.count then math.min(m.count, #pool) else #pool
	return math.min(have, need), need
end

function MilestoneRules.eligible(journal: Journal, m: Milestones.Milestone, roster: Roster): boolean
	local have, need = MilestoneRules.progress(journal, m, roster)
	return need > 0 and have >= need
end

local MESSAGES: { [string]: string } = {
	claimed = "You already claimed that reward.",
	notEligible = "Keep collecting: that milestone isn't complete yet.",
	unknown = "That reward isn't available.",
	badReward = "That reward isn't available.",
	full = "Your collection is full.",
}

function MilestoneRules.message(reason: string?): string
	return MESSAGES[reason or ""] or "Something went wrong. Try again."
end

-- Every milestone with its state: "locked" (still collecting), "eligible" (Claim offered) or "claimed".
function MilestoneRules.statuses(journal: Journal?, cosmetics: CosmeticRules.State?, roster: Roster): { Status }
	local out: { Status } = {}
	local empty: Journal = { seen = {}, caught = {}, variants = {} }
	for _, m in Milestones.List do
		local have, need = MilestoneRules.progress(journal or empty, m, roster)
		local state = "locked"
		if cosmetics and cosmetics.rewardsClaimed[m.id] then
			state = "claimed"
		elseif need > 0 and have >= need then
			state = "eligible"
		end
		table.insert(out, { id = m.id, title = m.title, state = state, have = have, need = need })
	end
	return out
end

return MilestoneRules
