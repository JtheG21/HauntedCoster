--!strict
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Catalog = require(ReplicatedStorage.Shared.Config.Catalog)
local Habitats = require(ReplicatedStorage.Shared.Config.Habitats)
local Milestones = require(ReplicatedStorage.Shared.Config.Milestones)
local Monsters = require(ReplicatedStorage.Shared.Config.Monsters)
local Variants = require(ReplicatedStorage.Shared.Config.Variants)
local CosmeticRules = require(ReplicatedStorage.Shared.Rules.CosmeticRules)
local MilestoneRules = require(ReplicatedStorage.Shared.Rules.MilestoneRules)

local roster = MilestoneRules.rosterFrom(Monsters.Order, Habitats.List)
local live: CosmeticRules.Catalog = { Items = Catalog.Items, Rewards = Catalog.Rewards }

local function journal(caught: { string }, variants: { string }?): MilestoneRules.Journal
	local j: MilestoneRules.Journal = { seen = {}, caught = {}, variants = {} }
	for _, sp in caught do
		j.caught[sp] = true
		j.seen[sp] = true
	end
	local keys: { string } = variants or {}
	for _, key in keys do
		j.variants[key] = true
	end
	return j
end

local function stateOf(list: { MilestoneRules.Status }, id: string): MilestoneRules.Status
	for _, s in list do
		if s.id == id then
			return s
		end
	end
	error(`no milestone {id}`)
end

return function(t: TestRunner.T)
	t.test("every milestone matches the real roster and has a catalog reward", function()
		for _, m in Milestones.List do
			t.truthy(Catalog.Rewards[m.id] ~= nil, `{m.id} has no reward`)
			if m.kind == "habitat" then
				t.truthy(Habitats.ById[m.habitat or ""] ~= nil, `{m.id}: unknown habitat`)
				t.truthy(#(roster.habitatSpecies[m.habitat or ""] or {}) > 0, `{m.id}: habitat has no species`)
			elseif m.kind == "variant" then
				t.truthy(Variants.ById[m.variant or ""] ~= nil, `{m.id}: unknown variant`)
			elseif m.kind == "bestiary" then
				t.truthy(m.count == nil or m.count <= #Monsters.Order, `{m.id}: count above the roster`)
			else
				t.truthy(false, `{m.id}: unknown kind`)
			end
		end
		for id, reward in Catalog.Rewards do
			t.truthy(Milestones.ById[id] ~= nil, `reward {id} has no milestone`)
			for _, item in reward.grants do
				t.truthy(Catalog.Items[item] ~= nil, `reward {id} grants unlisted {item}`)
			end
		end
	end)

	t.test("nothing is eligible with an empty journal", function()
		for _, s in MilestoneRules.statuses(journal({}), CosmeticRules.default(), roster) do
			t.eq(s.state, "locked")
		end
		for _, s in MilestoneRules.statuses(nil, nil, roster) do
			t.eq(s.state, "locked")
		end
	end)

	t.test("habitat completion needs every species that spawns there", function()
		local cem = roster.habitatSpecies.Cemetery
		local partial = journal({ cem[1] })
		t.eq(stateOf(MilestoneRules.statuses(partial, nil, roster), "hab_Cemetery").state, "locked")
		local full = journal(cem)
		local st = stateOf(MilestoneRules.statuses(full, nil, roster), "hab_Cemetery")
		t.eq(st.state, "eligible")
		t.eq(st.have, st.need)
	end)

	t.test("bestiary milestones count caught species", function()
		local two = journal({ Monsters.Order[1], Monsters.Order[2] })
		local list = MilestoneRules.statuses(two, nil, roster)
		t.eq(stateOf(list, "bestiary_half").state, "eligible")
		t.eq(stateOf(list, "bestiary_all").state, "locked")
		local all = MilestoneRules.statuses(journal(Monsters.Order), nil, roster)
		t.eq(stateOf(all, "bestiary_all").state, "eligible")
	end)

	t.test("seen is not caught", function()
		local j = journal({})
		j.seen[Monsters.Order[1]] = true
		t.eq(stateOf(MilestoneRules.statuses(j, nil, roster), "bestiary_half").state, "locked")
	end)

	t.test("a natural variant discovery completes the variant milestone", function()
		local j = journal({ "Wisp" }, { "Wisp:Spectral" })
		local list = MilestoneRules.statuses(j, nil, roster)
		t.eq(stateOf(list, "var_Spectral").state, "eligible")
		t.eq(stateOf(list, "var_Ashen").state, "locked")
	end)

	t.test("owning a skin or any cosmetic never completes a discovery", function()
		local cos = CosmeticRules.default()
		for id in Catalog.Items do
			cos.entitlements[id] = true
		end
		cos.ghostLooks.u1 = { skin = "SkinMoss", aura = "AuraEmbers" }
		cos.captureEffect = "FxSparks"
		cos.mansionTheme = "ThemeMoonlit"
		for _, s in MilestoneRules.statuses(journal({}), cos, roster) do
			t.eq(s.state, "locked")
		end
	end)

	t.test("claim grants once and a replay is refused", function()
		local cos = CosmeticRules.default()
		local ok = CosmeticRules.claimReward(cos, live, "hab_Cemetery")
		t.truthy(ok)
		t.eq(cos.entitlements.SkinMoss, true)
		t.eq(cos.rewardsClaimed.hab_Cemetery, true)
		local again, why = CosmeticRules.claimReward(cos, live, "hab_Cemetery")
		t.eq(again, false)
		t.eq(why, "claimed")
		local st =
			stateOf(MilestoneRules.statuses(journal(roster.habitatSpecies.Cemetery), cos, roster), "hab_Cemetery")
		t.eq(st.state, "claimed")
	end)

	t.test("parse rejects bad and unknown ids", function()
		t.truthy(MilestoneRules.parse("hab_Cemetery") ~= nil)
		t.eq(MilestoneRules.parse(5), nil)
		t.eq(MilestoneRules.parse("a b"), nil)
		t.eq(MilestoneRules.parse("nope"), nil)
		t.eq(MilestoneRules.parse({}), nil)
	end)

	t.test("messages are friendly", function()
		t.truthy(string.find(MilestoneRules.message("claimed"), "already") ~= nil)
		t.eq(MilestoneRules.message("zzz"), "Something went wrong. Try again.")
	end)
end
