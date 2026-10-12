--!strict
-- Habitat module contract (TASK-0026, TASK-0027, ADR-0007): all four modules fit the shared footprint and
-- gates, and the validator catches a module that breaks the contract.
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local World = require(Shared.Config.World)
local Habitats = require(Shared.Config.Habitats)
local HabitatRules = require(Shared.Rules.HabitatRules)

return function(t: TestRunner.T)
	t.test("all four habitat modules fit the module contract", function()
		t.eq(#Habitats.List, 4)
		for _, h in Habitats.List do
			local problems = HabitatRules.validate(h)
			t.eq(#problems, 0, table.concat(problems, "; "))
		end
	end)

	t.test("rotation order and ids", function()
		local ids = {}
		for _, h in Habitats.List do
			table.insert(ids, h.id)
		end
		t.eq(table.concat(ids, ","), "Cemetery,Woodland,SpiderWoodland,Settlement")
		t.eq(Habitats.active().id, "Cemetery", "the cemetery is active by default")
	end)

	t.test("every gate path of every module starts at its gate", function()
		for _, h in Habitats.List do
			for gate, id in h.gatePaths do
				local first: Vector3? = nil
				for _, path in h.paths do
					if path.id == id then
						first = path.points[1]
					end
				end
				t.truthy(first ~= nil, `{h.id} gate {gate}`)
				local inner = World.gatePoint(gate, World.Hub.moduleRadius)
				t.truthy(((first :: Vector3) - inner).Magnitude < 4, `{h.id} gate {gate} path starts at the gate`)
			end
		end
	end)

	t.test("only the cemetery has the crypt and the Bell Wraith; the roster weights follow ADR-0007", function()
		local function weight(h: Habitats.Habitat, species: string): number
			local w = 0
			for _, z in h.zones do
				w += z.spawns[species] or 0
			end
			return w
		end
		for _, h in Habitats.List do
			if h.id ~= "Cemetery" then
				t.eq(h.crypt, nil, `{h.id} has no crypt`)
				t.eq(weight(h, "BellWraith"), 0, `{h.id} has no Bell Wraith`)
			end
		end
		local wood = Habitats.Woodland
		t.truthy(
			weight(wood, "Hound") > weight(wood, "Wisp") and weight(wood, "Hound") > weight(wood, "Gentleman"),
			"Woodland weights Hounds"
		)
		local spider = Habitats.SpiderWoodland
		t.truthy(
			weight(spider, "Gentleman") > weight(spider, "Wisp")
				and weight(spider, "Gentleman") > weight(spider, "Hound"),
			"Spider Woodland weights Gentlemen"
		)
		local town = Habitats.Settlement
		for _, species in { "Wisp", "Hound", "Gentleman" } do
			t.truthy(weight(town, species) > 0, `Settlement has {species}`)
		end
	end)

	t.test("setActive switches the active module and rejects unknown ids", function()
		t.truthy(Habitats.setActive("Woodland"))
		t.eq(Habitats.active().id, "Woodland")
		t.truthy(Habitats.zoneById("Thicket") ~= nil, "zones follow the active module")
		t.eq(Habitats.zoneById("OldRows"), nil)
		t.truthy(Habitats.anyZoneById("OldRows") ~= nil, "anyZoneById searches every module")
		t.eq(Habitats.setActive("Nowhere"), false)
		t.eq(Habitats.active().id, "Woodland", "an unknown id changes nothing")
		Habitats.setActive("Cemetery")
	end)

	t.test("every gate leads in: each cemetery gate path starts at its gate", function()
		for gate, id in Habitats.Cemetery.gatePaths do
			local first: Vector3? = nil
			for _, path in Habitats.Cemetery.paths do
				if path.id == id then
					first = path.points[1]
				end
			end
			t.truthy(first ~= nil, `gate {gate}`)
			local inner = World.gatePoint(gate, World.Hub.moduleRadius)
			t.truthy(((first :: Vector3) - inner).Magnitude < 4, `gate {gate} path starts at the gate`)
		end
	end)

	t.test("the Weeping Angel and Bell Tower are the cemetery's landmarks", function()
		t.truthy(Habitats.landmarkById("Angel") ~= nil)
		t.truthy(Habitats.landmarkById("BellTower") ~= nil)
	end)

	t.test("the validator rejects a module that breaks the contract", function()
		local broken = table.clone(Habitats.Cemetery)
		broken.id = "Broken"
		broken.zones = {
			{
				id = "Outside",
				name = "Outside",
				rect = { x1 = 100, x2 = 140, z1 = 0, z2 = 20 }, -- past the footprint
				dark = false,
				gated = false,
				maxMonsters = 1,
				spawns = { Wisp = 1 },
			},
			{
				id = "Blocking",
				name = "Blocking",
				rect = { x1 = -6, x2 = 6, z1 = 96, z2 = 104 }, -- in the south gate corridor
				dark = false,
				gated = false,
				maxMonsters = 1,
				spawns = { Wisp = 1 },
			},
		}
		broken.zones[2].spawns = { Ghoul = 1, Wisp = 0 }
		broken.landmarks = {
			{ id = "Lonely", name = "Lonely", zone = "Nowhere", position = Vector3.new(0, 0, 0) },
			{ id = "Astray", name = "Astray", zone = "Outside", position = Vector3.new(0, 0, -50) },
		}
		broken.gatePaths = { "SouthPath" }
		broken.starter = nil
		local problems = table.concat(HabitatRules.validate(broken), "\n")
		for _, expected in
			{
				"leaves the footprint",
				"gate corridor",
				"one gate path",
				"unknown species Ghoul",
				"bad weight for Wisp",
				"missing zone Nowhere",
				"isn't inside its zone Outside",
			}
		do
			t.truthy(string.find(problems, expected, 1, true) ~= nil, expected)
		end
	end)

	t.test("path clearance and gate corridors", function()
		t.truthy(HabitatRules.pathClearance(Habitats.Cemetery, 0, 112) < 0, "on the south path")
		t.truthy(HabitatRules.inGateCorridor(0, 105), "inside the south gate")
		t.truthy(not HabitatRules.inGateCorridor(0, 60), "well inside the hub")
		t.truthy(not HabitatRules.inGateCorridor(0, 130), "outside the wall")
	end)
end
