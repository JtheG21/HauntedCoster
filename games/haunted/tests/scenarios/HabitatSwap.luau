--!strict
-- Habitat module lifecycle (TASK-0027 AC3, ADR-0007): swaps through all four modules in rotation order and
-- back to the cemetery. After each `activate`:
--  * exactly one module sits under Workspace.Habitat, the right one, and the old one is back in storage,
--  * `Habitats.active()`, the `ActiveHabitat` attribute and the module agree,
--  * no wild monster of the old module is left, and every monster (then and after a spawner pass) belongs
--    to a zone of the new module and to that zone's roster,
--  * the module's landmarks are built.
-- Also records each module's part count (TASK-0027 risk note).
--   game:GetService("StudioTestService"):ExecutePlayModeAsync({ scenario = "HabitatSwap" })

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Habitats = require(ReplicatedStorage.Shared.Config.Habitats)
local Services = ServerScriptService:WaitForChild("Server"):WaitForChild("Services")
local HabitatService = require(Services.HabitatService) :: any
local EncounterService = require(Services.EncounterService) :: any

return function(_args: any): { [string]: any }
	local checks: { { name: string, ok: boolean, detail: string? } } = {}
	local function check(name: string, ok: boolean, detail: any?)
		table.insert(checks, { name = name, ok = ok == true, detail = if detail ~= nil then tostring(detail) else nil })
	end

	local t0 = os.clock()
	while not Workspace:FindFirstChild("Habitat") and os.clock() - t0 < 10 do
		task.wait(0.2)
	end
	task.wait(2)

	-- Every module is prebuilt; record part counts.
	local counts = {}
	for _, def in Habitats.List do
		local result = HabitatService.built(def.id)
		check(`{def.id} is prebuilt`, result ~= nil)
		if result then
			local n = 0
			for _, d in result.model:GetDescendants() do
				if d:IsA("BasePart") then
					n += 1
				end
			end
			table.insert(counts, `{def.id}:{n}`)
		end
	end
	check("part counts recorded", #counts == #Habitats.List, table.concat(counts, " "))
	check("the cemetery starts active", HabitatService.activeId() == "Cemetery", HabitatService.activeId())

	-- Every live monster is in a zone of `def` whose roster has its species; returns problems.
	local function strays(def: Habitats.Habitat): { string }
		local out = {}
		for _, e in EncounterService.snapshot() do
			if not e.fleeing then
				local zone = nil
				for _, z in def.zones do
					if z.id == e.zone then
						zone = z
					end
				end
				if not zone then
					table.insert(out, `{e.species}@{e.zone}`)
				elseif not zone.spawns[e.species] and e.species ~= (def.starter and def.starter.species) then
					table.insert(out, `{e.species} not in {e.zone} roster`)
				end
			end
		end
		return out
	end

	local order = { "Woodland", "SpiderWoodland", "Settlement", "Cemetery" }
	for _, id in order do
		local def = Habitats.ById[id]
		local previous = HabitatService.activeId()
		local before = #EncounterService.snapshot()
		HabitatService.activate(id)
		local stage = Workspace:FindFirstChild("Habitat") :: Folder
		local children = stage:GetChildren()
		check(
			`{id}: exactly one module under Workspace.Habitat, and it is {id}`,
			#children == 1 and children[1]:GetAttribute("Habitat") == id,
			`{#children} {children[1] and children[1].Name}`
		)
		local old = previous and HabitatService.built(previous)
		check(
			`{id}: the old module ({previous}) is back in storage`,
			old ~= nil and old.model.Parent == ServerStorage:FindFirstChild("HabitatModules"),
			old and old.model.Parent and old.model.Parent:GetFullName()
		)
		check(
			`{id}: active habitat and attribute agree`,
			Habitats.active().id == id and Workspace:GetAttribute("ActiveHabitat") == id,
			`{Habitats.active().id} {Workspace:GetAttribute("ActiveHabitat")}`
		)
		local now = strays(def)
		check(
			`{id}: no monster of the old module is left`,
			#now == 0,
			`{before} before; strays {table.concat(now, ", ")}`
		)
		local monsters = Workspace:FindFirstChild("Monsters")
		check(
			`{id}: every monster model is a live encounter`,
			monsters ~= nil and #monsters:GetChildren() == #EncounterService.snapshot(),
			`{monsters and #monsters:GetChildren()} models, {#EncounterService.snapshot()} encounters`
		)
		local landmarks = (children[1] and children[1]:FindFirstChild("Landmarks")) :: Instance?
		local built = 0
		for _, lm in def.landmarks do
			local m = landmarks and landmarks:FindFirstChild(lm.id)
			if m and m:FindFirstChild("Anchor") then
				built += 1
			end
		end
		check(`{id}: landmarks built`, built == #def.landmarks and built >= 2, `{built}/{#def.landmarks}`)
		task.wait(5) -- one spawner pass
		local later = strays(def)
		check(
			`{id}: after a spawner pass, only its own roster spawns`,
			#later == 0 and #EncounterService.snapshot() > 0,
			`{#EncounterService.snapshot()} monsters; strays {table.concat(later, ", ")}`
		)
	end
	local cryptGate = (Workspace:FindFirstChild("Habitat") :: Folder):FindFirstChild("CryptGate", true)
	check("back on the cemetery, its crypt gate is in the world again", cryptGate ~= nil)

	local failed = 0
	for _, c in checks do
		if not c.ok then
			failed += 1
		end
	end
	return { ok = failed == 0, passed = #checks - failed, failed = failed, checks = checks }
end
